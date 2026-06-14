--[[
    葡萄 Hub v1.0 - 多功能启动器
    包含：服务器跳转 + 奴才军队大亨 v0.2.6 + 午夜追踪者 v0.1.2
    UI：🍇可拖动悬浮按钮 + 弹入动画
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualInput = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ========== 奴才军队大亨 v0.2.6 ==========
local function LoadNoobArmy()
    print("🚀 正在加载奴才军队大亨 v0.2.6...")
    
    local Settings = {
        AutoBuy = false, AutoCollectTreasure = false, AutoGemFarm = false, AutoParkour = false,
        AimbotEnabled = false, TeamCheck = true, AimSensitivity = 0.15, AimFOV = 120,
        ESPEnabled = false, MissileNoCD = false, ChestESPEnabled = false, AntiAFK = true,
    }
    
    local Holding, FOVCircle, ESPObjects, ChestESPObjects, missileLoop = false, nil, {}, {}, nil
    local autoTreasureTask, autoGemTask, autoParkourTask, afkConnection = nil, nil, nil, nil
    
    local function GetDistance(p1, p2) return (p1 - p2).Magnitude end
    
    local function setupAntiAFK()
        if afkConnection then afkConnection:Disconnect() end
        if not Settings.AntiAFK then return end
        for _, v in pairs(getconnections(LocalPlayer.Idled)) do v:Disable() end
        afkConnection = LocalPlayer.Idled:Connect(function()
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end
    
    local function CreateFOVCircle()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness, FOVCircle.NumSides, FOVCircle.Visible, FOVCircle.Transparency = 0, 64, true, 0.7
        FOVCircle.Color = Color3.fromRGB(255,255,255)
    end
    
    local function GetClosestPlayer()
        if not Settings.AimbotEnabled then return nil end
        local maxDist, target = Settings.AimFOV, nil
        local mousePos = UserInputService:GetMouseLocation()
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                if not Settings.TeamCheck or (Settings.TeamCheck and v.Team ~= LocalPlayer.Team) then
                    local screenPoint = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
                    if screenPoint.Z > 0 then
                        local dist = (mousePos - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                        if dist < maxDist then maxDist, target = dist, v end
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
            hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
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
                    safeTP(k.CFrame + Vector3.new(0,2,0))
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
                if Settings.AutoCollectTreasure then CollectAllTreasures() end
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
                        safeTP(treasure.CFrame * CFrame.new(0,12,0))
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
                if Settings.AutoGemFarm then CollectGemsFromTreasures() end
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
                if Settings.AutoParkour then pcall(DoParkour) end
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
            if obj:IsA("ProximityPrompt") and (string.find(obj.Name, "Missile") or string.find(obj.Name, "导弹")) then
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
    
    local NoobGui = Instance.new("ScreenGui")
    NoobGui.Name = "NoobArmyUI"
    NoobGui.ResetOnSpawn = false
    NoobGui.Parent = game:GetService("CoreGui")
    
    local MainFrame2 = Instance.new("Frame")
    MainFrame2.Size = UDim2.new(0, 340, 0, 420)
    MainFrame2.Position = UDim2.new(0.5, -170, 0.5, -210)
    MainFrame2.BackgroundColor3 = Color3.fromRGB(20,20,30)
    MainFrame2.BackgroundTransparency = 0.15
    MainFrame2.BorderSizePixel = 0
    MainFrame2.ClipsDescendants = true
    MainFrame2.Visible = true
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0,12)
    corner2.Parent = MainFrame2
    MainFrame2.Parent = NoobGui
    
    local TitleBar2 = Instance.new("Frame")
    TitleBar2.Size = UDim2.new(1,0,0,40)
    TitleBar2.BackgroundColor3 = Color3.fromRGB(30,30,45)
    TitleBar2.BackgroundTransparency = 0.2
    TitleBar2.BorderSizePixel = 0
    local titleCorner2 = Instance.new("UICorner")
    titleCorner2.CornerRadius = UDim.new(0,12)
    titleCorner2.Parent = TitleBar2
    TitleBar2.Parent = MainFrame2
    
    local TitleLabel2 = Instance.new("TextLabel")
    TitleLabel2.Size = UDim2.new(0.7,0,1,0)
    TitleLabel2.BackgroundTransparency = 1
    TitleLabel2.Text = "👑 奴才军队大亨 v0.2.6"
    TitleLabel2.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel2.Font = Enum.Font.GothamBold
    TitleLabel2.TextSize = 16
    TitleLabel2.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel2.Position = UDim2.new(0,15,0,0)
    TitleLabel2.Parent = TitleBar2
    
    local CloseBtn2 = Instance.new("TextButton")
    CloseBtn2.Size = UDim2.new(0,30,0,30)
    CloseBtn2.Position = UDim2.new(1,-40,0,5)
    CloseBtn2.BackgroundColor3 = Color3.fromRGB(200,70,70)
    CloseBtn2.BackgroundTransparency = 0.3
    CloseBtn2.Text = "✕"
    CloseBtn2.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn2.Font = Enum.Font.GothamBold
    CloseBtn2.TextSize = 18
    local closeCorner2 = Instance.new("UICorner")
    closeCorner2.CornerRadius = UDim.new(0,6)
    closeCorner2.Parent = CloseBtn2
    CloseBtn2.Parent = TitleBar2
    CloseBtn2.MouseButton1Click:Connect(function() MainFrame2.Visible = false end)
    
    local ScrollContainer = Instance.new("ScrollingFrame")
    ScrollContainer.Size = UDim2.new(1,-20,1,-60)
    ScrollContainer.Position = UDim2.new(0,10,0,50)
    ScrollContainer.BackgroundTransparency = 1
    ScrollContainer.BorderSizePixel = 0
    ScrollContainer.ScrollBarThickness = 4
    ScrollContainer.Parent = MainFrame2
    
    local UIListLayout2 = Instance.new("UIListLayout")
    UIListLayout2.Padding = UDim.new(0,10)
    UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout2.Parent = ScrollContainer
    
    local function CreateToggle(text, getter, setter, icon)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,45)
        frame.BackgroundColor3 = Color3.fromRGB(35,35,50)
        frame.BackgroundTransparency = 0.3
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0,8)
        frameCorner.Parent = frame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0,35,1,0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 20
        iconLabel.Parent = frame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.5,0,1,0)
        textLabel.Position = UDim2.new(0,40,0,0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 14
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = frame
        
        local switchBg = Instance.new("Frame")
        switchBg.Size = UDim2.new(0,45,0,24)
        switchBg.Position = UDim2.new(1,-55,0.5,-12)
        switchBg.BackgroundColor3 = getter() and Color3.fromRGB(80,180,80) or Color3.fromRGB(180,80,80)
        local switchCorner = Instance.new("UICorner")
        switchCorner.CornerRadius = UDim.new(0,12)
        switchCorner.Parent = switchBg
        local switchSlider = Instance.new("Frame")
        switchSlider.Size = UDim2.new(0,20,0,20)
        switchSlider.Position = getter() and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        switchSlider.BackgroundColor3 = Color3.fromRGB(255,255,255)
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0,10)
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
            switchSlider.Position = getter() and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        end)
        
        frame.Parent = ScrollContainer
        return frame
    end
    
    local function CreateSlider(text, minVal, maxVal, step, getter, setter, suffix)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,60)
        frame.BackgroundColor3 = Color3.fromRGB(35,35,50)
        frame.BackgroundTransparency = 0.3
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0,8)
        frameCorner.Parent = frame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.8,0,0.4,0)
        textLabel.Position = UDim2.new(0,10,0,5)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text .. ": " .. tostring(getter()) .. suffix
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 14
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = frame
        
        local sliderBox = Instance.new("TextBox")
        sliderBox.Size = UDim2.new(0.8,0,0.35,0)
        sliderBox.Position = UDim2.new(0.1,0,0.55,0)
        sliderBox.BackgroundColor3 = Color3.fromRGB(50,50,70)
        sliderBox.Text = tostring(getter())
        sliderBox.Font = Enum.Font.Gotham
        sliderBox.TextSize = 14
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0,6)
        sCorner.Parent = sliderBox
        sliderBox.Parent = frame
        sliderBox.FocusLost:Connect(function()
            local val = tonumber(sliderBox.Text)
            if val then
                val = math.clamp(val, minVal, maxVal)
                val = math.floor(val / step + 0.5) * step
                setter(val)
                sliderBox.Text = tostring(val)
                textLabel.Text = text .. ": " .. tostring(val) .. suffix
            else
                sliderBox.Text = tostring(getter())
            end
        end)
        
        frame.Parent = ScrollContainer
        return frame
    end
    
    CreateToggle("💰 自动购买", function() return Settings.AutoBuy end, function(v) Settings.AutoBuy = v end, "💎")
    CreateToggle("📦 自动收集宝箱", function() return Settings.AutoCollectTreasure end, function(v) Settings.AutoCollectTreasure = v end, "📦")
    CreateToggle("💎 自动刷宝石", function() return Settings.AutoGemFarm end, function(v) Settings.AutoGemFarm = v end, "💎")
    CreateToggle("🏃 自动跑酷", function() return Settings.AutoParkour end, function(v) Settings.AutoParkour = v end, "🏃")
    CreateToggle("🎯 智能瞄准", function() return Settings.AimbotEnabled end, function(v) Settings.AimbotEnabled = v end, "🎯")
    CreateToggle("👁️ ESP透视", function() return Settings.ESPEnabled end, function(v) Settings.ESPEnabled = v end, "👁️")
    CreateToggle("🚀 导弹无冷却", function() return Settings.MissileNoCD end, SetMissileNoCD, "🚀")
    CreateToggle("🛡️ 抗AFK", function() return Settings.AntiAFK end, function(v) Settings.AntiAFK = v; setupAntiAFK() end, "🛡️")
    CreateSlider("瞄准平滑度", 0.05, 0.3, 0.01, function() return Settings.AimSensitivity end, function(v) Settings.AimSensitivity = v end, "秒")
    CreateSlider("FOV范围", 50, 300, 5, function() return Settings.AimFOV end, function(v) Settings.AimFOV = v end, "px")
    
    CreateFOVCircle()
    print("✅ 奴才军队大亨 v0.2.6 已加载")
end

-- ========== 午夜追踪者 v0.1.2 ==========
local function LoadMidnight()
    print("🌙 正在加载午夜追踪者 v0.1.2...")
    
    local M_Settings = {
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
        if M_Settings.RemoveNPCs then RemoveNPCVehicles() end
        if M_Settings.SpeedHack then ApplySpeedHack() end
        if M_Settings.InstantFinish then InstantFinishRace() end
        if M_Settings.AutoRace then AutoStartRace() end
    end)
    
    local MidnightGui = Instance.new("ScreenGui")
    MidnightGui.Name = "MidnightUI"
    MidnightGui.ResetOnSpawn = false
    MidnightGui.Parent = game:GetService("CoreGui")
    
    local MainFrame3 = Instance.new("Frame")
    MainFrame3.Size = UDim2.new(0, 260, 0, 320)
    MainFrame3.Position = UDim2.new(0.5, -130, 0.5, -160)
    MainFrame3.BackgroundColor3 = Color3.fromRGB(20,20,30)
    MainFrame3.BackgroundTransparency = 0.15
    MainFrame3.BorderSizePixel = 0
    MainFrame3.ClipsDescendants = true
    MainFrame3.Visible = true
    local corner3 = Instance.new("UICorner")
    corner3.CornerRadius = UDim.new(0,12)
    corner3.Parent = MainFrame3
    MainFrame3.Parent = MidnightGui
    
    local TitleBar3 = Instance.new("Frame")
    TitleBar3.Size = UDim2.new(1,0,0,40)
    TitleBar3.BackgroundColor3 = Color3.fromRGB(30,30,45)
    TitleBar3.BackgroundTransparency = 0.2
    TitleBar3.BorderSizePixel = 0
    local titleCorner3 = Instance.new("UICorner")
    titleCorner3.CornerRadius = UDim.new(0,12)
    titleCorner3.Parent = TitleBar3
    TitleBar3.Parent = MainFrame3
    
    local TitleLabel3 = Instance.new("TextLabel")
    TitleLabel3.Size = UDim2.new(0.7,0,1,0)
    TitleLabel3.BackgroundTransparency = 1
    TitleLabel3.Text = "🌙 午夜追踪者 v0.1.2"
    TitleLabel3.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel3.Font = Enum.Font.GothamBold
    TitleLabel3.TextSize = 16
    TitleLabel3.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel3.Position = UDim2.new(0,15,0,0)
    TitleLabel3.Parent = TitleBar3
    
    local CloseBtn3 = Instance.new("TextButton")
    CloseBtn3.Size = UDim2.new(0,30,0,30)
    CloseBtn3.Position = UDim2.new(1,-40,0,5)
    CloseBtn3.BackgroundColor3 = Color3.fromRGB(200,70,70)
    CloseBtn3.BackgroundTransparency = 0.3
    CloseBtn3.Text = "✕"
    CloseBtn3.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn3.Font = Enum.Font.GothamBold
    CloseBtn3.TextSize = 18
    local closeCorner3 = Instance.new("UICorner")
    closeCorner3.CornerRadius = UDim.new(0,6)
    closeCorner3.Parent = CloseBtn3
    CloseBtn3.Parent = TitleBar3
    CloseBtn3.MouseButton1Click:Connect(function() MainFrame3.Visible = false end)
    
    local Container3 = Instance.new("Frame")
    Container3.Size = UDim2.new(1,-20,1,-60)
    Container3.Position = UDim2.new(0,10,0,50)
    Container3.BackgroundTransparency = 1
    Container3.Parent = MainFrame3
    
    local Layout3 = Instance.new("UIListLayout")
    Layout3.Padding = UDim.new(0,10)
    Layout3.SortOrder = Enum.SortOrder.LayoutOrder
    Layout3.Parent = Container3
    
    local function CreateMToggle(text, getter, setter, icon)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,0,45)
        frame.BackgroundColor3 = Color3.fromRGB(35,35,50)
        frame.BackgroundTransparency = 0.3
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0,8)
        frameCorner.Parent = frame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0,35,1,0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 20
        iconLabel.Parent = frame
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.5,0,1,0)
        textLabel.Position = UDim2.new(0,40,0,0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 14
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = frame
        
        local switchBg = Instance.new("Frame")
        switchBg.Size = UDim2.new(0,45,0,24)
        switchBg.Position = UDim2.new(1,-55,0.5,-12)
        switchBg.BackgroundColor3 = getter() and Color3.fromRGB(80,180,80) or Color3.fromRGB(180,80,80)
        local switchCorner = Instance.new("UICorner")
        switchCorner.CornerRadius = UDim.new(0,12)
        switchCorner.Parent = switchBg
        local switchSlider = Instance.new("Frame")
        switchSlider.Size = UDim2.new(0,20,0,20)
        switchSlider.Position = getter() and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        switchSlider.BackgroundColor3 = Color3.fromRGB(255,255,255)
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0,10)
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
            switchSlider.Position = getter() and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        end)
        
        frame.Parent = Container3
        return frame
    end
    
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
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 14
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedFrame
    local speedSlider = Instance.new("TextBox")
    speedSlider.Size = UDim2.new(0.8,0,0.35,0)
    speedSlider.Position = UDim2.new(0.1,0,0.55,0)
    speedSlider.BackgroundColor3 = Color3.fromRGB(50,50,70)
    speedSlider.Text = tostring(SpeedMultiplier)
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
    speedFrame.Parent = Container3
    
    CreateMToggle("🗑️ 清除NPC车辆", function() return M_Settings.RemoveNPCs end, function(v) M_Settings.RemoveNPCs = v end, "🚗")
    CreateMToggle("⚡ 速度修改", function() return M_Settings.SpeedHack end, function(v) M_Settings.SpeedHack = v end, "🏎️")
    CreateMToggle("🏁 自动开始比赛", function() return M_Settings.AutoRace end, function(v) M_Settings.AutoRace = v end, "🎮")
    CreateMToggle("✨ 瞬间完成比赛", function() return M_Settings.InstantFinish end, function(v) M_Settings.InstantFinish = v end, "🏆")
    
    print("✅ 午夜追踪者 v0.1.2 已加载")
end

-- ========== 跳转服务器 ==========
local function TeleportToServer(serverId)
    if not serverId or serverId == "" then
        print("⚠️ 请输入服务器ID")
        return
    end
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        print("✅ 正在跳转到服务器: " .. serverId)
    end)
end

-- ========== 主UI（葡萄 Hub）==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrapeHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = MainFrame
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleBar
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🍇 葡萄 Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,70,70)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn
CloseBtn.Parent = TitleBar

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Container

local serverInput = Instance.new("TextBox")
serverInput.Size = UDim2.new(1, 0, 0, 35)
serverInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
serverInput.PlaceholderText = "服务器 ID (JobId)"
serverInput.Text = ""
serverInput.TextColor3 = Color3.fromRGB(255,255,255)
serverInput.Font = Enum.Font.Gotham
serverInput.TextSize = 14
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = serverInput
serverInput.Parent = Container

local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, 0, 0, 35)
teleportBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
teleportBtn.Text = "🚪 跳转到此服务器"
teleportBtn.TextColor3 = Color3.fromRGB(255,255,255)
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.TextSize = 14
local teleCorner = Instance.new("UICorner")
teleCorner.CornerRadius = UDim.new(0, 8)
teleCorner.Parent = teleportBtn
teleportBtn.Parent = Container
teleportBtn.MouseButton1Click:Connect(function()
    if serverInput.Text and serverInput.Text ~= "" then
        TeleportToServer(serverInput.Text)
    else
        print("⚠️ 请输入服务器ID")
    end
end)

local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, 1)
line.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
line.BackgroundTransparency = 0.5
line.Parent = Container

local noobBtn = Instance.new("TextButton")
noobBtn.Size = UDim2.new(1, 0, 0, 45)
noobBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
noobBtn.Text = "👑 奴才军队大亨 v0.2.6"
noobBtn.TextColor3 = Color3.fromRGB(255,255,255)
noobBtn.Font = Enum.Font.GothamBold
noobBtn.TextSize = 15
local noobCorner = Instance.new("UICorner")
noobCorner.CornerRadius = UDim.new(0, 8)
noobCorner.Parent = noobBtn
noobBtn.Parent = Container
noobBtn.MouseButton1Click:Connect(LoadNoobArmy)

local midBtn = Instance.new("TextButton")
midBtn.Size = UDim2.new(1, 0, 0, 45)
midBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 180)
midBtn.Text = "🌙 午夜追踪者 v0.1.2"
midBtn.TextColor3 = Color3.fromRGB(255,255,255)
midBtn.Font = Enum.Font.GothamBold
midBtn.TextSize = 15
local midCorner = Instance.new("UICorner")
midCorner.CornerRadius = UDim.new(0, 8)
midCorner.Parent = midBtn
midBtn.Parent = Container
midBtn.MouseButton1Click:Connect(LoadMidnight)

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(1, 0, 0, 35)
fpsFrame.BackgroundColor3 = Color3.fromRGB(35,35,50)
fpsFrame.BackgroundTransparency = 0.3
local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 8)
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
fpsFrame.Parent = Container

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

local function AnimateMenuShow()
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 240, 0, 200)
    MainFrame.Position = UDim2.new(0.5, -120, 0.5, -100)
    local sizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 280, 0, 320),
        Position = UDim2.new(0.5, -140, 0.5, -160),
        BackgroundTransparency = 0.15
    })
    sizeTween:Play()
end

local function AnimateMenuHide()
    local hideTween = TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    })
    hideTween:Play()
    hideTween.Completed:Connect(function() MainFrame.Visible = false end)
end

CloseBtn.MouseButton1Click:Connect(AnimateMenuHide)

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 65, 0, 65)
FloatingBtn.Position = UDim2.new(1, -80, 0, 100)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(80,80,120)
FloatingBtn.BackgroundTransparency = 0.2
FloatingBtn.Text = "🍇"
FloatingBtn.TextColor3 = Color3.fromRGB(255,255,255)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 30
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = FloatingBtn
local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(150,150,200)
btnStroke.Thickness = 1
btnStroke.Parent = FloatingBtn
FloatingBtn.Parent = ScreenGui

local dragging = false
local dragStart, startPos
FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatingBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - FloatingBtn.AbsoluteSize.X)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - FloatingBtn.AbsoluteSize.Y)
        FloatingBtn.Position = UDim2.new(0, newX, 0, newY)
    end
end)
FloatingBtn.MouseButton1Click:Connect(function()
    if MainFrame.Visible then AnimateMenuHide() else AnimateMenuShow() end
end)

print("✅ 葡萄 Hub 已加载 | 点击🍇打开菜单 | 选择脚本加载")
