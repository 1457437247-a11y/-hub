--[[
    奴才军队大亨 v0.2.6 完整版
    功能：自动购买、自动收集宝箱、自动刷宝石、自动跑酷、智能瞄准、ESP透视、导弹无冷却、抗AFK
    UI：🍇可拖动悬浮按钮 + 完整菜单
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    AutoBuy = false,
    AutoCollectTreasure = false,
    AutoGemFarm = false,
    AutoParkour = false,
    AimbotEnabled = false,
    TeamCheck = true,
    AimSensitivity = 0.15,
    AimFOV = 120,
    ESPEnabled = false,
    MissileNoCD = false,
    ChestESPEnabled = false,
    AntiAFK = true,
}

local Holding = false
local FOVCircle = nil
local ESPObjects = {}
local ChestESPObjects = {}
local missileLoop = nil
local autoTreasureTask = nil
local autoGemTask = nil
local autoParkourTask = nil
local afkConnection = nil

local function GetDistance(p1, p2) return (p1 - p2).Magnitude end

local function setupAntiAFK()
    if afkConnection then afkConnection:Disconnect() end
    if not Settings.AntiAFK then return end
    for _, v in pairs(getconnections(LocalPlayer.Idled)) do v:Disable() end
    afkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function CreateFOVCircle()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 0
    FOVCircle.NumSides = 64
    FOVCircle.Visible = true
    FOVCircle.Transparency = 0.7
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
end

local function GetClosestPlayer()
    if not Settings.AimbotEnabled then return nil end
    local maxDist = Settings.AimFOV
    local target = nil
    local mousePos = UserInputService:GetMouseLocation()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if not Settings.TeamCheck or (Settings.TeamCheck and v.Team ~= LocalPlayer.Team) then
                local screenPoint = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
                if screenPoint.Z > 0 then
                    local dist = (mousePos - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        target = v
                    end
                end
            end
        end
    end
    return target
end

local function SmoothAim(targetPart)
    if not targetPart then return end
    local tween = TweenService:Create(Camera, TweenInfo.new(Settings.AimSensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)})
    tween:Play()
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end
end)

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Settings.AimFOV
        FOVCircle.Visible = Settings.AimbotEnabled
    end
    if Holding and Settings.AimbotEnabled then
        local target = GetClosestPlayer()
        if target then
            local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then SmoothAim(targetPart) end
        end
    end
end)

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function safeTP(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function AutoBuyButtons()
    for _, tycoon in pairs(workspace:FindFirstChild("Tycoons") and workspace.Tycoons:GetChildren() or {}) do
        if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == LocalPlayer then
            for _, model in pairs(tycoon:FindFirstChild("Models") and tycoon.Models:GetChildren() or {}) do
                local button = model:FindFirstChild("Button")
                if button and button:IsA("BasePart") and button.Transparency == 0 and button:FindFirstChild("ProximityPrompt") then
                    pcall(function()
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = button.CFrame
                            fireproximityprompt(button.ProximityPrompt)
                            task.wait(0.3)
                        end
                    end)
                end
            end
        end
    end
end

local function CollectAllTreasures()
    local hrp = getHRP()
    if not hrp then return end
    for _, k in pairs(workspace:GetDescendants()) do
        if k.Name == "Treasure" and k:IsA("BasePart") and k:FindFirstChild("ProximityPrompt") then
            pcall(function()
                safeTP(k.CFrame + Vector3.new(0, 2, 0))
                fireproximityprompt(k.ProximityPrompt)
                task.wait(0.2)
            end)
        end
    end
end

local function StartAutoTreasureLoop(interval)
    if autoTreasureTask then task.cancel(autoTreasureTask) end
    autoTreasureTask = task.spawn(function()
        while true do
            if Settings.AutoCollectTreasure then
                CollectAllTreasures()
            end
            task.wait(interval or 2)
        end
    end)
end

local function CollectGemsFromTreasures()
    local hrp = getHRP()
    if not hrp then return end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local treasuresFolder = map:FindFirstChild("Treasures")
    if not treasuresFolder then return end
    for _, treasure in ipairs(treasuresFolder:GetChildren()) do
        if treasure:IsA("BasePart") then
            local prompt = treasure:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                pcall(function()
                    safeTP(treasure.CFrame * CFrame.new(0, 12, 0))
                    task.wait(0.2)
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                end)
            end
        end
    end
end

local function StartAutoGemLoop(interval)
    if autoGemTask then task.cancel(autoGemTask) end
    autoGemTask = task.spawn(function()
        while true do
            if Settings.AutoGemFarm then
                CollectGemsFromTreasures()
            end
            task.wait(interval or 1.5)
        end
    end)
end

local function DoParkour()
    local map = workspace:FindFirstChild("Map")
    if not map then return false end
    local obbyLand = map:FindFirstChild("ObbyLand")
    if not obbyLand then return false end
    local teleporters = obbyLand:FindFirstChild("Teleporters")
    local finish = obbyLand:FindFirstChild("Finish")
    if not teleporters or not finish then return false end
    local t11 = teleporters:FindFirstChild("11")
    local f11 = finish:FindFirstChild("11")
    if not t11 or not f11 then return false end
    safeTP(t11.CFrame)
    task.wait(0.3)
    local prompt = t11:FindFirstChildOfClass("ProximityPrompt")
    if prompt then fireproximityprompt(prompt) end
    task.wait(4.8)
    safeTP(f11.CFrame)
    task.wait(0.3)
    prompt = f11:FindFirstChildOfClass("ProximityPrompt")
    if prompt then fireproximityprompt(prompt) end
    return true
end

local function StartAutoParkourLoop()
    if autoParkourTask then task.cancel(autoParkourTask) end
    autoParkourTask = task.spawn(function()
        while true do
            if Settings.AutoParkour then
                pcall(DoParkour)
            end
            task.wait(5.5)
        end
    end)
end

StartAutoTreasureLoop(2)
StartAutoGemLoop(1.5)
StartAutoParkourLoop()
setupAntiAFK()

local function ForceFireMissile()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and (string.find(obj.Name, "Missile") or string.find(obj.Name, "导弹") or string.find(obj.Parent and obj.Parent.Name or "", "Missile")) then
            pcall(fireproximityprompt, obj)
        end
        if obj:IsA("ClickDetector") and (string.find(obj.Name, "Missile") or string.find(obj.Name, "导弹")) then
            pcall(function() obj:FireClick() end)
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and (string.find(gui.Text, "发射导弹") or string.find(gui.Text, "Fire Missile")) then
            pcall(function() gui:Click() end)
        end
        if gui:IsA("ImageButton") and (string.find(gui.Name, "Missile") or string.find(gui.Name, "导弹")) then
            pcall(function() gui:Click() end)
        end
    end
    for _, service in pairs({game:GetService("ReplicatedStorage"), LocalPlayer:FindFirstChild("PlayerScripts")}) do
        if service then
            for _, remote in ipairs(service:GetDescendants()) do
                if remote:IsA("RemoteEvent") and (string.find(remote.Name, "Missile") or string.find(remote.Name, "Fire") or string.find(remote.Name, "Launch")) then
                    pcall(function() remote:FireServer() end)
                end
            end
        end
    end
end

local function SetMissileNoCD(enable)
    Settings.MissileNoCD = enable
    if missileLoop then missileLoop:Disconnect() end
    if enable then
        missileLoop = RunService.Stepped:Connect(ForceFireMissile)
        task.spawn(function()
            while Settings.MissileNoCD do
                ForceFireMissile()
                task.wait(0.1)
            end
        end)
    end
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoobArmyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 500)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -250)
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
TitleLabel.Text = "👑 奴才军队大亨 v0.2.6"
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

local function CreateSliderOption(text, minVal, maxVal, step, getter, setter, suffix, icon)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,70)
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
    textLabel.Size = UDim2.new(0.5,0,0.4,0)
    textLabel.Position = UDim2.new(0,45,0,0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(230,230,230)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3,0,0.4,0)
    valueLabel.Position = UDim2.new(0.7,0,0,0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(getter()) .. suffix
    valueLabel.TextColor3 = Color3.fromRGB(255,255,150)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(0.8,0,0.35,0)
    slider.Position = UDim2.new(0.1,0,0.55,0)
    slider.BackgroundColor3 = Color3.fromRGB(50,50,70)
    slider.Text = tostring(getter())
    slider.TextColor3 = Color3.fromRGB(255,255,255)
    slider.Font = Enum.Font.Gotham
    slider.TextSize = 14
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0,6)
    sliderCorner.Parent = slider
    slider.Parent = frame
    
    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            val = math.clamp(val, minVal, maxVal)
            val = math.floor(val / step + 0.5) * step
            setter(val)
            slider.Text = tostring(val)
            valueLabel.Text = tostring(val) .. suffix
        else
            slider.Text = tostring(getter())
        end
    end)
    
    frame.Parent = ScrollContainer
    return frame
end

CreateToggleOption("💰 自动购买", function() return Settings.AutoBuy end, function(v) Settings.AutoBuy = v end, "💎")
CreateToggleOption("📦 自动收集宝箱", function() return Settings.AutoCollectTreasure end, function(v) Settings.AutoCollectTreasure = v end, "📦")
CreateToggleOption("💎 自动刷宝石", function() return Settings.AutoGemFarm end, function(v) Settings.AutoGemFarm = v end, "💎")
CreateToggleOption("🏃 自动跑酷", function() return Settings.AutoParkour end, function(v) Settings.AutoParkour = v end, "🏃")
CreateToggleOption("🎯 智能瞄准", function() return Settings.AimbotEnabled end, function(v) Settings.AimbotEnabled = v end, "🎯")
CreateToggleOption("⚔️ 只瞄准敌人", function() return Settings.TeamCheck end, function(v) Settings.TeamCheck = v end, "👥")
CreateToggleOption("👁️ ESP透视", function() return Settings.ESPEnabled end, function(v) Settings.ESPEnabled = v end, "👁️")
CreateToggleOption("📍 宝箱ESP", function() return Settings.ChestESPEnabled end, function(v) Settings.ChestESPEnabled = v end, "📍")
CreateToggleOption("🚀 导弹无冷却", function() return Settings.MissileNoCD end, SetMissileNoCD, "🚀")
CreateToggleOption("🛡️ 抗AFK", function() return Settings.AntiAFK end, function(v) Settings.AntiAFK = v; setupAntiAFK() end, "🛡️")

CreateSliderOption("瞄准平滑度", 0.05, 0.3, 0.01, function() return Settings.AimSensitivity end, function(v) Settings.AimSensitivity = v end, "秒", "💨")
CreateSliderOption("FOV范围", 50, 300, 5, function() return Settings.AimFOV end, function(v) Settings.AimFOV = v end, "px", "🎯")

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
fpsLabel.TextSize = 18
fpsLabel.Position = UDim2.new(0,15,0,0)
fpsLabel.Parent = fpsFrame
local grapeLabel = Instance.new("TextLabel")
grapeLabel.Size = UDim2.new(0.4,0,1,0)
grapeLabel.Position = UDim2.new(0.55,0,0,0)
grapeLabel.BackgroundTransparency = 1
grapeLabel.Text = "葡萄制作"
grapeLabel.TextColor3 = Color3.fromRGB(180,130,255)
grapeLabel.Font = Enum.Font.GothamBold
grapeLabel.TextSize = 15
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

CreateFOVCircle()
print("✅ 奴才军队大亨 v0.2.6 已加载")
