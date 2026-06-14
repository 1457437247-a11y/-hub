--[[
    午夜追踪者 v0.1.2 完整版
    功能：清除NPC车辆、速度修改、自动开始比赛、瞬间完成比赛
    UI：🍇可拖动悬浮按钮 + 完整菜单
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInput = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    RemoveNPCs = false,
    SpeedHack = false,
    AutoRace = false,
    InstantFinish = false,
}
local SpeedMultiplier = 5
local PlayerVehicle = nil

local function getVehicle()
    local char = LocalPlayer.Character
    if not char then return nil end
    local seat = char:FindFirstChild("VehicleSeat")
    if seat then
        local vehicle = seat.Parent
        if vehicle and vehicle:IsA("VehicleSeat") then vehicle = vehicle.Parent end
        return vehicle
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") and v.Occupant == char then
            return v.Parent
        end
    end
    return nil
end

local function RemoveNPCVehicles()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("Vehicle") then
            if v ~= PlayerVehicle then
                local name = (v.Name or ""):lower()
                if name:find("npc") or name:find("ai") or name:find("traffic") or name:find("enemy") or name:find("cop") or name:find("opponent") then
                    pcall(function() v:Destroy() end)
                end
            end
        end
        if v:IsA("Humanoid") and v.Parent and v.Parent ~= LocalPlayer.Character then
            local name = (v.Parent.Name or ""):lower()
            if name:find("npc") or name:find("ai") or name:find("enemy") then
                pcall(function() v.Parent:Destroy() end)
            end
        end
    end
end

local function ApplySpeedHack()
    local vehicle = getVehicle()
    if vehicle then
        local hrp = vehicle:FindFirstChild("HumanoidRootPart") or vehicle:FindFirstChildWhichIsA("BasePart")
        if hrp then
            local velocity = hrp.AssemblyLinearVelocity
            local direction = hrp.CFrame.LookVector
            hrp.AssemblyLinearVelocity = direction * (velocity.Magnitude * SpeedMultiplier)
        end
    end
end

local function InstantFinishRace()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("finish") or v.Name:lower():find("end") or v.Name:lower():find("goal") or v.Name:lower():find("终点")) then
            local vehicle = getVehicle()
            if vehicle then
                local hrp = vehicle:FindFirstChild("HumanoidRootPart") or vehicle:FindFirstChildWhichIsA("BasePart")
                if hrp then
                    hrp.CFrame = v.CFrame + Vector3.new(0, 2, 0)
                end
            end
            break
        end
    end
end

local function AutoStartRace()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = (gui.Text or gui.Name or ""):lower()
            if text:find("race") or text:find("start") or text:find("play") or text:find("go") or text:find("开始") then
                pcall(function() gui:Click() end)
                task.wait(0.5)
                VirtualInput:SendKeyEvent(true, "W", false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, "W", false, game)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    PlayerVehicle = getVehicle()
    if Settings.RemoveNPCs then RemoveNPCVehicles() end
    if Settings.SpeedHack then ApplySpeedHack() end
    if Settings.InstantFinish then InstantFinishRace() end
    if Settings.AutoRace then AutoStartRace() end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MidnightUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = true
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = MainFrame
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80,80,120)
stroke.Thickness = 1
stroke.Parent = MainFrame
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,45)
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,45)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,12)
titleCorner.Parent = TitleBar
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.6,0,1,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌙 午夜追踪者 v0.1.2"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0,15,0,0)
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,30)
CloseBtn.Position = UDim2.new(1,-40,0,7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,70,70)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0,6)
closeCorner.Parent = CloseBtn
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

local ScrollContainer = Instance.new("ScrollingFrame")
ScrollContainer.Size = UDim2.new(1,-20,1,-70)
ScrollContainer.Position = UDim2.new(0,10,0,55)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.BorderSizePixel = 0
ScrollContainer.ScrollBarThickness = 4
ScrollContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0,12)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollContainer

local function CreateToggleOption(text, getter, setter, icon)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,50)
    frame.BackgroundColor3 = Color3.fromRGB(35,35,50)
    frame.BackgroundTransparency = 0.3
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0,8)
    frameCorner.Parent = frame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0,40,1,0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextColor3 = Color3.fromRGB(200,200,255)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 22
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.5,0,1,0)
    textLabel.Position = UDim2.new(0,45,0,0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(230,230,230)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 15
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame
    
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0,50,0,26)
    switchBg.Position = UDim2.new(1,-60,0.5,-13)
    switchBg.BackgroundColor3 = getter() and Color3.fromRGB(80,180,80) or Color3.fromRGB(180,80,80)
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0,13)
    switchCorner.Parent = switchBg
    local switchSlider = Instance.new("Frame")
    switchSlider.Size = UDim2.new(0,22,0,22)
    switchSlider.Position = getter() and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11)
    switchSlider.BackgroundColor3 = Color3.fromRGB(255,255,255)
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0,11)
    sliderCorner.Parent = switchSlider
    switchSlider.Parent = switchBg
    switchBg.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Parent = switchBg
    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        switchBg.BackgroundColor3 = getter() and Color3.fromRGB(80,180,80) or Color3.fromRGB(180,80,80)
        switchSlider.Position = getter() and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11)
    end)
    
    frame.Parent = ScrollContainer
    return frame
end

CreateToggleOption("🗑️ 清除NPC车辆", function() return Settings.RemoveNPCs end, function(v) Settings.RemoveNPCs = v end, "🚗")
CreateToggleOption("⚡ 速度修改", function() return Settings.SpeedHack end, function(v) Settings.SpeedHack = v end, "🏎️")
CreateToggleOption("🏁 自动开始比赛", function() return Settings.AutoRace end, function(v) Settings.AutoRace = v end, "🎮")
CreateToggleOption("✨ 瞬间完成比赛", function() return Settings.InstantFinish end, function(v) Settings.InstantFinish = v end, "🏆")

local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1,0,0,60)
speedFrame.BackgroundColor3 = Color3.fromRGB(35,35,50)
speedFrame.BackgroundTransparency = 0.3
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0,8)
speedCorner.Parent = speedFrame
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.8,0,0.4,0)
speedLabel.Position = UDim2.new(0,10,0,5)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ 速度倍率: " .. SpeedMultiplier .. "x"
speedLabel.TextColor3 = Color3.fromRGB(230,230,230)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame
local speedSlider = Instance.new("TextBox")
speedSlider.Size = UDim2.new(0.8,0,0.35,0)
speedSlider.Position = UDim2.new(0.1,0,0.55,0)
speedSlider.BackgroundColor3 = Color3.fromRGB(50,50,70)
speedSlider.Text = tostring(SpeedMultiplier)
speedSlider.TextColor3 = Color3.fromRGB(255,255,255)
speedSlider.Font = Enum.Font.Gotham
speedSlider.TextSize = 14
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0,6)
sCorner.Parent = speedSlider
speedSlider.Parent = speedFrame
speedSlider.FocusLost:Connect(function()
    local val = tonumber(speedSlider.Text)
    if val and val > 0 then
        SpeedMultiplier = math.clamp(val, 1, 50)
        speedLabel.Text = "⚡ 速度倍率: " .. SpeedMultiplier .. "x"
        speedSlider.Text = tostring(SpeedMultiplier)
    else
        speedSlider.Text = tostring(SpeedMultiplier)
    end
end)
speedFrame.Parent = ScrollContainer

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(1,0,0,45)
fpsFrame.BackgroundColor3 = Color3.fromRGB(35,35,50)
fpsFrame.BackgroundTransparency = 0.3
local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0,8)
fpsCorner.Parent = fpsFrame
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0.5,0,1,0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(255,255,150)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 14
fpsLabel.Position = UDim2.new(0,10,0,0)
fpsLabel.Parent = fpsFrame
local grapeLabel = Instance.new("TextLabel")
grapeLabel.Size = UDim2.new(0.5,0,1,0)
grapeLabel.Position = UDim2.new(0.5,0,0,0)
grapeLabel.BackgroundTransparency = 1
grapeLabel.Text = "葡萄制作"
grapeLabel.TextColor3 = Color3.fromRGB(180,130,255)
grapeLabel.Font = Enum.Font.Gotham
grapeLabel.TextSize = 12
grapeLabel.TextXAlignment = Enum.TextXAlignment.Right
grapeLabel.Parent = fpsFrame
fpsFrame.Parent = ScrollContainer

local frameCount = 0
local lastTime = tick()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTime >= 0.5 then
        fpsLabel.Text = "FPS: " .. math.floor(frameCount / (now - lastTime))
        frameCount = 0
        lastTime = now
    end
end)

print("✅ 午夜追踪者 v0.1.2 已加载")
