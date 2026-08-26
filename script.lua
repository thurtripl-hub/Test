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
                    if mobHuman.Health > 0
