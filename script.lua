--[[
    DQ Reborn - Auto Dupe Tester
    Platform: Roblox (Executor)
    Method: Auto sniff, auto filter, auto fuzz — no clicks needed
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- // State
local firedRemotes = {}
local results = {}

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoDuper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 400)
Frame.Position = UDim2.new(0, 10, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Auto Dupe Tester"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 30)
StatusLabel.Position = UDim2.new(0, 5, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 80, 140)
StatusLabel.Text = "⏳ Starting up..."
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -10, 1, -80)
LogScroll.Position = UDim2.new(0, 5, 0, 75)
LogScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 4
LogScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 140)
LogScroll.Parent = Frame
Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", LogScroll).Padding = UDim.new(0, 2)

-- // Log function
local logCount = 0
local function Log(text, color)
    logCount = logCount + 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 24)
    label.BackgroundColor3 = logCount % 2 == 0 
        and Color3.fromRGB(28, 28, 28) 
        or Color3.fromRGB(22, 22, 22)
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Text = "  " .. text
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.LayoutOrder = logCount
    label.Parent = LogScroll
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, logCount * 26 + 4)
    LogScroll.CanvasPosition = Vector2.new(0, logCount * 26)
end

-- // Keywords สำหรับ filter
local keywords = {
    "item","inv","equip","sell","loot","drop","pickup",
    "give","reward","chest","add","grant","obtain",
    "weapon","armor","gear","collect","bag","dupe"
}

local function IsItemRemote(name)
    local lower = name:lower()
    for _, kw in pairs(keywords) do
        if lower:find(kw) then return true end
    end
    return false
end

-- // Snapshot inventory count
local function SnapInventory()
    local inv = LocalPlayer:FindFirstChild("Inventory")
        or LocalPlayer:FindFirstChild("Backpack")
    if not inv then return 0 end
    return #inv:GetChildren()
end

-- // Auto run
task.spawn(function()
    -- Step 1: Hook remotes
    StatusLabel.Text = "🔍 Scanning remotes..."
    Log("Scanning all remotes in game...", Color3.fromRGB(180, 180, 100))
    task.wait(1)

    local hooked = 0
    for _, v in pairs(game:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and IsItemRemote(v:GetFullName()) then
            firedRemotes[v] = {args = {}, fired = false}
            hooked = hooked + 1
        end
    end
    Log("Found " .. hooked .. " item-related remotes", Color3.fromRGB(100, 220, 100))

    -- Step 2: Hook namecall
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if firedRemotes[self] and (method == "FireServer" or method == "InvokeServer") then
            firedRemotes[self].args = {...}
            firedRemotes[self].fired = true
        end
        return oldNamecall(self, ...)
    end)

    -- Step 3: Wait for player to interact
    StatusLabel.Text = "⏳ Waiting — open inventory/loot something!"
    Log("Waiting 10s for you to interact with inventory...", Color3.fromRGB(180, 180, 100))

    task.wait(10)

    -- Step 4: Filter fired remotes
    local fired = {}
    for remote, data in pairs(firedRemotes) do
        if data.fired then
            table.insert(fired, {remote = remote, args = data.args})
        end
    end

    if #fired == 0 then
        StatusLabel.Text = "❌ No remotes captured — interact more!"
        Log("Nothing captured. Try equipping/looting then re-run.", Color3.fromRGB(220, 80, 80))
        return
    end

    Log("Captured " .. #fired .. " fired remotes — starting fuzz!", Color3.fromRGB(100, 220, 100))
    StatusLabel.Text = "⚔ Fuzzing " .. #fired .. " remotes..."

    -- Step 5: Fuzz each one
    for _, entry in pairs(fired) do
        local name = entry.remote:GetFullName():match("([^%.]+)$") or "unknown"
        local beforeCount = SnapInventory()

        Log("Testing: " .. name, Color3.fromRGB(200, 80, 140))

        for i = 1, 15 do
            pcall(function()
                if entry.remote:IsA("RemoteEvent") then
                    entry.remote:FireServer(table.unpack(entry.args))
                else
                    entry.remote:InvokeServer(table.unpack(entry.args))
                end
            end)
            task.wait(0.08)
        end

        task.wait(0.5)
        local afterCount = SnapInventory()
        local diff = afterCount - beforeCount

        if diff > 0 then
            Log("✅ DUPE FOUND: " .. name .. " (+" .. diff .. " items!)", Color3.fromRGB(80, 255, 80))
            StatusLabel.Text = "✅ DUPE FOUND: " .. name
        else
            Log("✗ No dupe: " .. name, Color3.fromRGB(100, 100, 100))
        end
    end

    StatusLabel.Text = "✅ Done! Check log above 👆"
    Log("Fuzz complete!", Color3.fromRGB(100, 220, 100))
end)

print("[DQ Reborn] Auto Dupe Tester loaded ✓")
