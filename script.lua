--[[
    DQ Reborn - Remote Spy + Map Dumper
    Delta compatible
    dump remotes + args จริงๆ ออกมาดู
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoteSpy"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 320, 0, 500)
Frame.Position = UDim2.new(0, 10, 0.5, -250)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Remote Spy"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Clear Button
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.48, 0, 0, 28)
ClearBtn.Position = UDim2.new(0, 5, 0, 40)
ClearBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ClearBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ClearBtn.Text = "Clear Log"
ClearBtn.Font = Enum.Font.Gotham
ClearBtn.TextSize = 11
ClearBtn.Parent = Frame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

-- Dump All Button
local DumpBtn = Instance.new("TextButton")
DumpBtn.Size = UDim2.new(0.48, 0, 0, 28)
DumpBtn.Position = UDim2.new(0.52, -5, 0, 40)
DumpBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 140)
DumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpBtn.Text = "Dump All Remotes"
DumpBtn.Font = Enum.Font.Gotham
DumpBtn.TextSize = 11
DumpBtn.Parent = Frame
Instance.new("UICorner", DumpBtn).CornerRadius = UDim.new(0, 6)

-- Count Label
local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(1, -10, 0, 18)
CountLabel.Position = UDim2.new(0, 5, 0, 72)
CountLabel.BackgroundTransparency = 1
CountLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
CountLabel.Text = "Listening for remote calls..."
CountLabel.Font = Enum.Font.Gotham
CountLabel.TextSize = 10
CountLabel.TextXAlignment = Enum.TextXAlignment.Left
CountLabel.Parent = Frame

-- Log Scroll
local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -10, 1, -96)
LogScroll.Position = UDim2.new(0, 5, 0, 92)
LogScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 4
LogScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 140)
LogScroll.Parent = Frame
Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", LogScroll).Padding = UDim.new(0, 2)

local logCount = 0
local function Log(text, color)
    logCount = logCount + 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 28)
    label.BackgroundColor3 = logCount % 2 == 0
        and Color3.fromRGB(28, 28, 28)
        or Color3.fromRGB(22, 22, 22)
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Text = "  " .. text
    label.Font = Enum.Font.Code
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.LayoutOrder = logCount
    label.Parent = LogScroll
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, logCount * 30 + 4)
    LogScroll.CanvasPosition = Vector2.new(0, logCount * 30)
    CountLabel.Text = "Captured: " .. logCount .. " calls"
end

-- // Arg to string
local function ArgToString(arg)
    local t = type(arg)
    if t == "string" then return '"' .. arg .. '"'
    elseif t == "number" then return tostring(arg)
    elseif t == "boolean" then return tostring(arg)
    elseif t == "nil" then return "nil"
    elseif t == "userdata" then
        local ok, name = pcall(function() return arg.Name end)
        if ok and name then return "[Instance:" .. name .. "]" end
        return "[userdata]"
    elseif t == "table" then return "[table]"
    else return "[" .. t .. "]" end
end

local function ArgsToString(args)
    local parts = {}
    for _, a in ipairs(args) do
        table.insert(parts, ArgToString(a))
    end
    return table.concat(parts, ", ")
end

-- // Hook via __namecall
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local name = self:GetFullName()
        local argsStr = ArgsToString(args)

        -- color code by type
        local color
        local lower = self.Name:lower()
        if lower:find("attack") or lower:find("hit") or lower:find("damage") or lower:find("kill") then
            color = Color3.fromRGB(80, 255, 80) -- green = attack
        elseif lower:find("equip") or lower:find("item") or lower:find("inv") then
            color = Color3.fromRGB(255, 200, 80) -- yellow = item
        elseif lower:find("skill") or lower:find("cast") or lower:find("ability") then
            color = Color3.fromRGB(80, 180, 255) -- blue = skill
        else
            color = Color3.fromRGB(200, 200, 200) -- white = other
        end

        task.spawn(function()
            Log("[" .. method .. "] " .. name .. " | args: " .. argsStr, color)
        end)
    end
    return oldNamecall(self, ...)
end)

-- // Dump all remotes in map
DumpBtn.MouseButton1Click:Connect(function()
    Log("=== DUMP START ===", Color3.fromRGB(200, 80, 140))
    local count = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            count = count + 1
            Log(v:GetFullName(), Color3.fromRGB(160, 160, 160))
        end
    end
    Log("=== DUMP END: " .. count .. " remotes ===", Color3.fromRGB(200, 80, 140))
end)

-- Clear
ClearBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logCount = 0
    CountLabel.Text = "Cleared!"
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

print("[DQ Reborn] Remote Spy loaded ✓")
