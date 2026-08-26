--[[
    DQ Reborn - Kill Aura Test
    Platform: Roblox (Executor)
    Delta compatible
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

-- // Config
local Config = {
    KillAura = false,
    Range = 50,
    Delay = 0.05,
}

-- // Kill Aura Loop
local function KillAuraLoop()
    while Config.KillAura do
        if Character and HumanoidRootPart then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model")
                and obj ~= Character
                and obj:FindFirstChildOfClass("Humanoid")
                and obj:FindFirstChild("HumanoidRootPart") then
                    local mobHuman = obj:FindFirstChildOfClass("Humanoid")
                    local mobHRP = obj:FindFirstChild("HumanoidRootPart")
                    if mobHuman.Health > 0 then
                        local dist = (HumanoidRootPart.Position - mobHRP.Position).Magnitude
                        if dist <= Config.Range then
                            -- try common attack remotes
                            for _, v in pairs(game:GetDescendants()) do
                                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                                    local name = v.Name:lower()
                                    if name:find("attack") or name:find("hit") or name:find("damage") or name:find("kill") then
                                        pcall(function()
                                            v:FireServer(obj, mobHuman.Health)
                                        end)
                                    end
                                end
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
Frame.Size = UDim2.new(0, 240, 0, 180)
Frame.Position = UDim2.new(0, 10, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Kill Aura Test"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Toggle
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -10, 0, 34)
Toggle.Position = UDim2.new(0, 5, 0, 44)
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
RangeLabel.Position = UDim2.new(0, 5, 0, 84)
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
RangeBox.Position = UDim2.new(0, 5, 0, 106)
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

-- Kill Counter
local KillCount = 0
local KillLabel = Instance.new("TextLabel")
KillLabel.Size = UDim2.new(1, -10, 0, 20)
KillLabel.Position = UDim2.new(0, 5, 0, 140)
KillLabel.BackgroundTransparency = 1
KillLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
KillLabel.Text = "Kills: 0"
KillLabel.Font = Enum.Font.Gotham
KillLabel.TextSize = 11
KillLabel.TextXAlignment = Enum.TextXAlignment.Left
KillLabel.Parent = Frame

-- Track kills
RunService.Heartbeat:Connect(function()
    if Config.KillAura and Character then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local h = obj:FindFirstChildOfClass("Humanoid")
                if h and h.Health <= 0 then
                    KillCount = KillCount + 1
                    KillLabel.Text = "Kills: " .. KillCount
                end
            end
        end
    end
end)

-- Toggle Logic
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

print("[DQ Reborn] Kill Aura loaded ✓")
