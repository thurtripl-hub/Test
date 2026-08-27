--[[
    DQ Reborn - Multi-Place Auto Dumper
    =====================================
    วางไฟล์นี้ไว้ใน: Delta/autoexec/DQReborn_AutoDumper.lua
    มันจะ run อัตโนมัติทุกครั้งที่ join/teleport ไป place ใหม่
    แต่ละ place จะได้ไฟล์แยกของตัวเอง
    =====================================
    Output ตัวอย่าง:
      DQ_77649408247578_Lobby_143022.txt
      DQ_12345678_DesertTemple_143501.txt
      DQ_87654321_WinterOutpost_144012.txt
--]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────
--  Place identity — detect dungeon name
--  จาก workspace values หรือ PlaceId map
-- ─────────────────────────────────────────
local KNOWN_PLACES = {
    [77649408247578] = "Lobby",
    -- เพิ่ม PlaceId dungeon จริงๆ ตรงนี้ถ้ารู้
    -- [XXXXXXXXXX] = "Desert Temple",
}

local function getPlaceName()
    -- 1. ลองอ่านจาก workspace values ก่อน (ใช้ได้ใน dungeon server)
    local dn = workspace:FindFirstChild("dungeonName")
    if dn and dn.Value and dn.Value ~= "" then
        return dn.Value:gsub("[^%w%s]", ""):gsub("%s+", "_")
    end

    -- 2. ลองอ่านจาก ReplicatedStorage.aGame
    local aGame = game:GetService("ReplicatedStorage"):FindFirstChild("aGame")
    if aGame then
        local mn = aGame:FindFirstChild("mapName")
        if mn and mn.Value and mn.Value ~= "" then
            return mn.Value:gsub("[^%w%s]", ""):gsub("%s+", "_")
        end
    end

    -- 3. fallback ไป known place table
    if KNOWN_PLACES[game.PlaceId] then
        return KNOWN_PLACES[game.PlaceId]
    end

    -- 4. ถ้าไม่รู้จริงๆ ใช้ PlaceId เป็นชื่อ
    return "Place_" .. tostring(game.PlaceId)
end

-- ─────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────
local function safe(fn, ...)
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

local function safeDesc(root)
    local ok, l = pcall(function() return root:GetDescendants() end)
    return ok and l or {}
end

local function safeChildren(root)
    local ok, l = pcall(function() return root:GetChildren() end)
    return ok and l or {}
end

local serviceNames = {
    "Workspace","Players","ReplicatedStorage","ReplicatedFirst",
    "Lighting","StarterGui","StarterPack","StarterPlayer",
    "Teams","SoundService",
}
local function getServices()
    local out = {}
    for _, n in ipairs(serviceNames) do
        local ok, s = pcall(function() return game:GetService(n) end)
        if ok and s then table.insert(out, s) end
    end
    return out
end

-- ─────────────────────────────────────────
--  Section builders (compact, fast)
-- ─────────────────────────────────────────

local function secRemotes(lines, counts)
    table.insert(lines, "===== REMOTES =====")
    counts.remotes = 0
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction")
            or v:IsA("UnreliableRemoteEvent") then
                table.insert(lines, "["..v.ClassName.."] "..v:GetFullName())
                counts.remotes += 1
            end
        end
    end
    table.insert(lines, "Total: "..counts.remotes.."\n")
end

local function secBindables(lines, counts)
    table.insert(lines, "===== BINDABLES =====")
    counts.bindables = 0
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            if v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                table.insert(lines, "["..v.ClassName.."] "..v:GetFullName())
                counts.bindables += 1
            end
        end
    end
    table.insert(lines, "Total: "..counts.bindables.."\n")
end

local function secNPCs(lines, counts)
    table.insert(lines, "===== NPCS / PLAYERS =====")
    counts.npcs = 0
    for _, v in ipairs(safeDesc(workspace)) do
        if v:IsA("Model") then
            local h   = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h then
                local pos = hrp and tostring(hrp.Position) or "unknown"
                local hp  = tostring(h.Health).."/"..tostring(h.MaxHealth)
                local isP = false
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character == v then isP = true break end
                end
                table.insert(lines, (isP and "[PLAYER] " or "[MOB] ")
                    ..v.Name.." | HP: "..hp.." | Pos: "..pos)
                counts.npcs += 1
            end
        end
    end
    table.insert(lines, "Total: "..counts.npcs.."\n")
end

local function secScripts(lines, counts)
    table.insert(lines, "===== SCRIPTS =====")
    counts.scripts = 0
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                local src = ""
                local ok, s = pcall(function() return v.Source end)
                if ok and s and #s > 0 then src = " |src:"..#s.."b" end
                table.insert(lines, "["..v.ClassName.."] "..v:GetFullName()..src)
                counts.scripts += 1
            end
        end
    end
    table.insert(lines, "Total: "..counts.scripts.."\n")
end

local valueTypes = {
    "IntValue","NumberValue","StringValue","BoolValue",
    "Vector3Value","CFrameValue","Color3Value","ObjectValue",
}
local function secValues(lines, counts)
    table.insert(lines, "===== VALUES =====")
    counts.values = 0
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            for _, cls in ipairs(valueTypes) do
                if v:IsA(cls) then
                    local val = safe(function() return tostring(v.Value) end) or "?"
                    table.insert(lines, "["..v.ClassName.."] "..v:GetFullName().." = "..val)
                    counts.values += 1
                    break
                end
            end
        end
    end
    table.insert(lines, "Total: "..counts.values.."\n")
end

local function secAttributes(lines, counts)
    table.insert(lines, "===== ATTRIBUTES =====")
    counts.attributes = 0
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            local ok, attrs = pcall(function() return v:GetAttributes() end)
            if ok and next(attrs) then
                for k, val in pairs(attrs) do
                    table.insert(lines, "[ATTR] "..v:GetFullName().." → "..k.." = "..tostring(val))
                    counts.attributes += 1
                end
            end
        end
    end
    table.insert(lines, "Total: "..counts.attributes.."\n")
end

local function secInventory(lines, counts)
    table.insert(lines, "===== INVENTORY =====")
    counts.inventory = 0
    for _, pl in ipairs(Players:GetPlayers()) do
        table.insert(lines, "[PLAYER] "..pl.Name)
        -- leaderstats
        local ls = pl:FindFirstChild("leaderstats")
        if ls then
            for _, s in ipairs(safeChildren(ls)) do
                local v = safe(function() return tostring(s.Value) end) or "?"
                table.insert(lines, "  [STAT] "..s.Name.." = "..v)
            end
        end
        -- backpack
        local bp = pl:FindFirstChildOfClass("Backpack")
        if bp then
            for _, item in ipairs(safeChildren(bp)) do
                table.insert(lines, "  [BAG] "..item.ClassName.." : "..item.Name)
                counts.inventory += 1
            end
        end
        -- equipped
        local char = pl.Character
        if char then
            for _, item in ipairs(safeChildren(char)) do
                if item:IsA("Tool") then
                    table.insert(lines, "  [EQP] "..item.Name)
                    counts.inventory += 1
                end
            end
        end
    end
    table.insert(lines, "Total: "..counts.inventory.."\n")
end

local function secSounds(lines, counts)
    table.insert(lines, "===== SOUNDS =====")
    counts.sounds = 0
    local seen = {}
    for _, svc in ipairs(getServices()) do
        for _, v in ipairs(safeDesc(svc)) do
            if v:IsA("Sound") then
                local sid = safe(function() return v.SoundId end) or "?"
                if not seen[sid] then          -- dedupe by SoundId
                    seen[sid] = true
                    table.insert(lines,
                        "[Sound] "..v:GetFullName()
                        .." | id:"..tostring(sid)
                        .." | vol:"..tostring(safe(function() return v.Volume end) or "?")
                        .." | playing:"..tostring(safe(function() return v.Playing end) or "?")
                    )
                    counts.sounds += 1
                end
            end
        end
    end
    table.insert(lines, "Total: "..counts.sounds.."\n")
end

local function secBaseParts(lines, counts)
    table.insert(lines, "===== BASEPARTS =====")
    counts.baseparts = 0
    for _, v in ipairs(safeDesc(workspace)) do
        if v:IsA("BasePart") then
            local p  = v.Position
            local s  = v.Size
            local rx, ry, rz = v.CFrame:ToEulerAnglesXYZ()
            local d  = math.deg
            table.insert(lines, string.format(
                "[%s] %s | Pos(%.1f,%.1f,%.1f) | Sz(%.1f,%.1f,%.1f) | Rot(%.0f°,%.0f°,%.0f°) | Anch=%s",
                v.ClassName, v:GetFullName(),
                p.X,p.Y,p.Z, s.X,s.Y,s.Z,
                d(rx),d(ry),d(rz), tostring(v.Anchored)
            ))
            counts.baseparts += 1
        end
    end
    table.insert(lines, "Total: "..counts.baseparts.."\n")
end

-- ─────────────────────────────────────────
--  CORE DUMP FUNCTION
-- ─────────────────────────────────────────
local function runDump(reason)
    local placeName = getPlaceName()
    local timestamp = os.date("%H%M%S")
    local filename  = string.format("DQ_%s_%s_%s.txt",
        tostring(game.PlaceId), placeName, timestamp)

    local lines  = {}
    local counts = {}

    -- header
    table.insert(lines, "=== DQ Reborn Auto Dump ===")
    table.insert(lines, "Reason: "    .. reason)
    table.insert(lines, "Place: "     .. placeName)
    table.insert(lines, "PlaceId: "   .. tostring(game.PlaceId))
    table.insert(lines, "JobId: "     .. tostring(game.JobId))
    table.insert(lines, "Time: "      .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "Player: "    .. LocalPlayer.Name)
    table.insert(lines, "")

    secRemotes(lines, counts)
    secBindables(lines, counts)
    secNPCs(lines, counts)
    secScripts(lines, counts)
    secValues(lines, counts)
    secAttributes(lines, counts)
    secInventory(lines, counts)
    secSounds(lines, counts)
    secBaseParts(lines, counts)

    -- footer
    table.insert(lines, "===== SUMMARY =====")
    local total = 0
    for k, n in pairs(counts) do
        table.insert(lines, k..": "..n)
        total += n
    end
    table.insert(lines, "TOTAL: "..total)

    local ok, err = pcall(function()
        writefile(filename, table.concat(lines, "\n"))
    end)

    return ok, filename, total, err
end

-- ─────────────────────────────────────────
--  GUI — minimal status bar
-- ─────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name          = "DQAutoDumper"
sg.ResetOnSpawn  = false
sg.DisplayOrder  = 999
sg.Parent        = LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Size             = UDim2.new(0, 320, 0, 48)
bar.Position         = UDim2.new(1, -330, 0, 10)
bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
bar.BorderSizePixel  = 0
bar.Parent           = sg
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local topRow = Instance.new("Frame")
topRow.Size             = UDim2.new(1,0,0,24)
topRow.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
topRow.BorderSizePixel  = 0
topRow.Parent           = bar
Instance.new("UICorner", topRow).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size              = UDim2.new(1,-8,1,0)
titleLbl.Position          = UDim2.new(0,6,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3        = Color3.fromRGB(255,255,255)
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 11
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.Text              = "🗂️ DQ Auto Dumper  |  " .. tostring(game.PlaceId)
titleLbl.Parent            = topRow

local statusLbl = Instance.new("TextLabel")
statusLbl.Size             = UDim2.new(1,-8,0,20)
statusLbl.Position         = UDim2.new(0,6,0,26)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3       = Color3.fromRGB(160,160,160)
statusLbl.Font             = Enum.Font.Gotham
statusLbl.TextSize         = 10
statusLbl.TextXAlignment   = Enum.TextXAlignment.Left
statusLbl.Text             = "⏳ Waiting for game to load..."
statusLbl.Parent           = bar

-- manual dump button
local dumpBtn = Instance.new("TextButton")
dumpBtn.Size             = UDim2.new(0, 80, 0, 20)
dumpBtn.Position         = UDim2.new(1,-86,0,26)
dumpBtn.BackgroundColor3 = Color3.fromRGB(60,120,200)
dumpBtn.TextColor3       = Color3.fromRGB(255,255,255)
dumpBtn.Font             = Enum.Font.GothamBold
dumpBtn.TextSize         = 10
dumpBtn.Text             = "💾 Dump Now"
dumpBtn.Parent           = bar
Instance.new("UICorner", dumpBtn).CornerRadius = UDim.new(0, 4)

dumpBtn.MouseButton1Click:Connect(function()
    dumpBtn.Text     = "⏳..."
    statusLbl.Text   = "Dumping manually..."
    task.wait(0.05)
    local ok, fname, total, err = runDump("manual")
    if ok then
        statusLbl.Text = "✅ "..fname.." ("..total..")"
    else
        statusLbl.Text = "❌ "..tostring(err)
    end
    dumpBtn.Text = "💾 Dump Now"
end)

-- draggable
local dragging, dragStart, startPos, dragInput
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = bar.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
bar.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
end)
UserInputService.InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local d = i.Position - dragStart
        bar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                  startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- ─────────────────────────────────────────
--  AUTO DUMP — รอ game โหลดเสร็จแล้ว dump
-- ─────────────────────────────────────────
task.spawn(function()
    -- รอ character โหลด = game พร้อมแล้ว
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    -- รออีกนิดให้ remotes/values populate ครบ
    task.wait(3)

    statusLbl.Text = "⏳ Dumping auto..."
    local ok, fname, total, err = runDump("auto_on_join")

    if ok then
        titleLbl.Text  = "🗂️ DQ Auto Dumper  |  " .. getPlaceName()
        statusLbl.Text = "✅ "..fname.." ("..total.." items)"
        print("[DQAutoDumper] Saved: "..fname.." | "..total.." items")
    else
        statusLbl.Text = "❌ "..tostring(err)
        warn("[DQAutoDumper] Error: "..tostring(err))
    end
end)

print("[DQAutoDumper] Loaded | Place: "..tostring(game.PlaceId).." | "..os.date("%H:%M:%S"))
