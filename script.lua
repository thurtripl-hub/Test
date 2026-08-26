--[[
    DQ Reborn - Kill Aura v3
    Fixed: blacklist non-attack remotes
    Delta compatible
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

local Config = {
    KillAura = false,
    Range = 50,
    Delay = 0.05,
}

-- // Whitelist — ต้องมีคำพวกนี้
local whitelist = {"attack", "hit", "damage", "kill", "hurt", "strike", "cast"}

-- // Blacklist — ห้ามมีคำพวกนี้
local blacklist = {
    "skill", "reset", "point", "lobby", "menu", "ui",
    "setting", "config", "chat", "emote", "equip", "sell",
    "buy", "shop", "trade", "quest", "daily", "reward",
    "notify", "leaderboard", "data", "save", "load"
}

local function IsAttackRemote(name)
    local lower = name:lower()
    -- ต้องผ่าน whitelist ก่อน
    local whitelisted = false
    for _, w in pairs(whitelist) do
        if lower:find(w) then
            whitelisted = true
            break
        end
    end
    if not whitelisted then return false end
    -- ต้องไม่ติด blacklist
    for _, bl in pairs(blacklist) do
        if lower:find(bl) then return false end
    end
    return true
end

-- // Cache attack remotes
local attackRemotes = {}
local function ScanAttackRemotes()
    attackRemotes = {}
    for _, v in pairs(game:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and IsAttackRemote(v.Name) then
            table.insert(attackRemotes, v)
        end
    end
end

-- // Kill Aura Loop
local function KillAuraLoop()
    ScanAttackRemotes()
    while Config.KillAura do
        if Character and HumanoidRootPart then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model")
                and obj ~= Character
                and obj:FindFirstChildOfClass("Humanoid")
                and obj:FindFirstChild("HumanoidRootPart") then
                    local mobHuman = obj:FindFirstChildOfClass("Humanoid")
                    local mobHRP = obj:FindFirstChild("HumanoidRootPart")
                    if mobHuman and mobHuman.Health > 0 then
                        local dist = (HumanoidRootPart.Position - mobHRP.Position).Magnitude
                        if dist <= Config.Range then
                            for _, remote in pairs(attackRemotes) do
                                pcall(function()
                                    remote:FireServer(obj, mobHuman.Health)
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(Config.Delay)
    end
end

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillAuraGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 200)
Frame.Position = UDim2.new(0, 10, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Kill Aura v3"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Remote count label
local RemoteLabel = Instance.new("TextLabel")
RemoteLabel.Size = UDim2.new(1, -10, 0, 20)
RemoteLabel.Position = UDim2.new(0, 5, 0, 40)
RemoteLabel.BackgroundTransparency = 1
RemoteLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
RemoteLabel.Text = "Attack remotes: scanning..."
RemoteLabel.Font = Enum.Font.Gotham
RemoteLabel.TextSize = 10
RemoteLabel.TextXAlignment = Enum.TextXAlignment.Left
RemoteLabel.Parent = Frame

-- Toggle
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -10, 0, 34)
Toggle.Position = UDim2.new(0, 5, 0, 64)
Toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
Toggle.Text = "[ OFF ]  Kill Aura"
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 13
Toggle.Parent = Frame
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)

-- Range Label
local RangeLabel = Instance.new("TextLabel")
RangeLabel.Size = UDim2.new(1, -10, 0, 20)
RangeLabel.Position = UDim2.new(0, 5, 0, 104)
RangeLabel.BackgroundTransparency = 1
RangeLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
RangeLabel.Text = "Range: 50 studs"
RangeLabel.Font = Enum.Font.Gotham
RangeLabel.TextSize = 11
RangeLabel.TextXAlignment = Enum.TextXAlignment.Left
RangeLabel.Parent = Frame

-- Range Box
local RangeBox = Instance.new("TextBox")
RangeBox.Size = UDim2.new(1, -10, 0, 26)
RangeBox.Position = UDim2.new(0, 5, 0, 126)
RangeBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
RangeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeBox.Text = "50"
RangeBox.Font = Enum.Font.Gotham
RangeBox.TextSize = 12
RangeBox.Parent = Frame
Instance.new("UICorner", RangeBox).CornerRadius = UDim.new(0, 6)

RangeBox.FocusLost:Connect(function()
    local val = tonumber(RangeBox.Text)
    if val then
        Config.Range = math.clamp(val, 5, 500)
        RangeLabel.Text = "Range: " .. Config.Range .. " studs"
    end
end)

-- Kill Label
local KillLabel = Instance.new("TextLabel")
KillLabel.Size = UDim2.new(1, -10, 0, 20)
KillLabel.Position = UDim2.new(0, 5, 0, 162)
KillLabel.BackgroundTransparency = 1
KillLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
KillLabel.Text = "Kills: 0"
KillLabel.Font = Enum.Font.Gotham
KillLabel.TextSize = 11
KillLabel.TextXAlignment = Enum.TextXAlignment.Left
KillLabel.Parent = Frame

-- Kill tracking
local killCount = 0
local deadMobs = {}
RunService.Heartbeat:Connect(function()
    if Config.KillAura then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local h = obj:FindFirstChildOfClass("Humanoid")
                if h and h.Health <= 0 and not deadMobs[obj] then
                    deadMobs[obj] = true
                    killCount = killCount + 1
                    KillLabel.Text = "Kills: " .. killCount
                end
            end
        end
    end
end)

-- Scan on start
task.delay(2, function()
    ScanAttackRemotes()
    RemoteLabel.Text = "Attack remotes: " .. #attackRemotes .. " found"
end)

-- Toggle logic
Toggle.MouseButton1Click:Connect(function()
    Config.KillAura = not Config.KillAura
    Toggle.Text = (Config.KillAura and "[ ON ]   " or "[ OFF ]  ") .. "Kill Aura"
    Toggle.BackgroundColor3 = Config.KillAura
        and Color3.fromRGB(200, 80, 140)
        or Color3.fromRGB(35, 35, 35)
    if Config.KillAura then
        task.spawn(KillAuraLoop)
    end
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("[DQ Reborn] Kill Aura v3 loaded ✓")
