--[[
    奴才军队大亨 v0.3.0
    功能：自动购买、自动收集宝箱、自动刷宝石、自动跑酷、智能瞄准、ESP透视、导弹无冷却、抗AFK
    新增：离线奖励无限重复领取 + 数字视觉修改（UI美化）
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ========== 设置 ==========
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
    AutoOfflineReward = false,      -- 普通自动领取
    RepeatOfflineReward = false,    -- 无限重复领取
    OfflineRewardInterval = 5,      -- 重复间隔(秒)
    VisualMod = false,              -- 数字视觉修改开关
    VisualMoney = "999,999,999",    -- 自定义金钱
    VisualGem = "999,999",          -- 自定义宝石
    VisualRP = "999,999,999",       -- 自定义研究积分
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
local offlineRewardLoop = nil
local repeatOfflineLoop = nil
local repeatCount = 0
local originalTexts = {}  -- 视觉修改备份

local function GetDistance(p1, p2) return (p1 - p2).Magnitude end

-- 抗AFK
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

-- FOV圆圈
local function CreateFOVCircle()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 0
    FOVCircle.NumSides = 64
    FOVCircle.Visible = true
    FOVCircle.Transparency = 0.7
    FOVCircle.Color = Color3.fromRGB(255,255,255)
end

-- 获取最近玩家
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

-- 平滑自瞄
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

-- 传送辅助
local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

local function safeTP(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end
end

-- 自动购买
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

-- 自动收集宝箱
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

-- 自动刷宝石
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

-- 自动跑酷
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

-- ========== 导弹无冷却增强 ==========
local function ForceFireMissile()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local name = (obj.Name or ""):lower()
            local parentName = (obj.Parent and obj.Parent.Name or ""):lower()
            if name:find("missile") or name:find("导弹") or parentName:find("missile") or parentName:find("导弹") then
                pcall(fireproximityprompt, obj)
            end
        end
        if obj:IsA("ClickDetector") and (obj.Name:lower():find("missile") or obj.Name:lower():find("导弹")) then
            pcall(function() obj:FireClick() end)
        end
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = (gui.Text or gui.Name or ""):lower()
            if text:find("missile") or text:find("导弹") or text:find("launch") or text:find("发射") then
                pcall(function() gui:Click() end)
            end
        end
    end
    for _, service in pairs({game:GetService("ReplicatedStorage"), LocalPlayer:FindFirstChild("PlayerScripts"), workspace}) do
        if service then
            for _, remote in ipairs(service:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = (remote.Name or ""):lower()
                    if name:find("missile") or name:find("fire") or name:find("launch") or name:find("shoot") then
                        pcall(function() remote:FireServer() end)
                    end
                end
            end
        end
    end
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, v in pairs({"Cooldown", "CD", "NextFire", "LastFire", "Reload", "Remaining", "Charge", "Timer"}) do
                    if tool:GetAttribute(v) then tool:SetAttribute(v, 0) end
                    if tool[v] ~= nil and type(tool[v]) == "number" then tool[v] = 0 end
                end
                for _, child in ipairs(tool:GetDescendants()) do
                    if child:IsA("NumberValue") and (child.Name:lower():find("cooldown") or child.Name:lower():find("cd") or child.Name:lower():find("reload")) then
                        child.Value = 0
                    end
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

-- ========== 离线奖励功能 ==========
local function FindOfflineRewardEntry()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
            local text = (gui.Text or gui.Name or ""):lower()
            if text:find("offline") or text:find("reward") or text:find("离线") or text:find("奖励") then
                return gui
            end
        end
    end
    return nil
end

local function FindClaimButton()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = gui.Text or ""
            if text:find("关闭并领取") or text:find("领取") or text:find("Claim") then
                return gui
            end
        end
    end
    return nil
end

local function FindCloseButton()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Text == "×" then
            return gui
        end
    end
    return nil
end

local function AutoCollectOfflineReward()
    local claimBtn = FindClaimButton()
    if claimBtn then
        pcall(function() claimBtn:Click() end)
        return true
    end
    return false
end

local function RepeatOfflineRewardCycle()
    repeatCount = repeatCount + 1
    local closeBtn = FindCloseButton()
    if closeBtn then
        pcall(function() closeBtn:Click() end)
        task.wait(0.5)
    end
    local entry = FindOfflineRewardEntry()
    if entry then
        pcall(function() entry:Click() end)
        task.wait(1)
    else
        return
    end
    local claimBtn = FindClaimButton()
    if claimBtn then
        pcall(function() claimBtn:Click() end)
        print(string.format("[离线奖励] 第 %d 次领取成功", repeatCount))
        task.wait(0.5)
    end
    task.wait(0.5)
    closeBtn = FindCloseButton()
    if closeBtn then
        pcall(function() closeBtn:Click() end)
    end
end

local function StartRepeatOfflineReward()
    if repeatOfflineLoop then task.cancel(repeatOfflineLoop) end
    repeatOfflineLoop = task.spawn(function()
        repeatCount = 0
        while Settings.RepeatOfflineReward do
            pcall(RepeatOfflineRewardCycle)
            task.wait(Settings.OfflineRewardInterval)
        end
    end)
end

local function ForceCollectOfflineReward()
    pcall(RepeatOfflineRewardCycle)
end

local function StartAutoOfflineRewardLoop()
    if offlineRewardLoop then task.cancel(offlineRewardLoop) end
    offlineRewardLoop = task.spawn(function()
        while Settings.AutoOfflineReward do
            pcall(AutoCollectOfflineReward)
            task.wait(2)
        end
    end)
end

StartAutoOfflineRewardLoop()

-- ========== 数字视觉修改 ==========
local function ApplyVisualMod()
    if not Settings.VisualMod then
        for label, original in pairs(originalTexts) do
            if label and label.Parent then
                pcall(function() label.Text = original end)
            end
        end
        originalTexts = {}
        return
    end
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = gui.Text or ""
            if text:match("%$%d+") or text:match("%d+%.?%d*[MK]") or text:match("M$") then
                if not originalTexts[gui] then originalTexts[gui] = gui.Text end
                gui.Text = "$" .. Settings.VisualMoney
            end
            if text:lower():match("gem") or text:lower():match("宝石") then
                if not originalTexts[gui] then originalTexts[gui] = gui.Text end
                gui.Text = Settings.VisualGem .. " gems"
            end
            if text:match("RP") or text:match("研究") or text:match("Research") then
                if not originalTexts[gui] then originalTexts[gui] = gui.Text end
                gui.Text = Settings.VisualRP .. " RP"
            end
        end
    end
end

-- ========== 玩家ESP（保持原有功能）==========
local function GetCharacterExtremes(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return nil, nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not rootPart or not head then return nil, nil end
    local footPos = rootPart.Position - Vector3.new(0, humanoid.HipHeight or 2, 0)
    return footPos, head.Position
end

local function UpdatePlayerESP()
    if not Settings.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            if esp.Box then esp.Box.Visible = false end
            if esp.Text then esp.Text.Visible = false end
        end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if ESPObjects[player] then ESPObjects[player].Box.Visible = false; ESPObjects[player].Text.Visible = false end
        elseif not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            if ESPObjects[player] then ESPObjects[player].Box.Visible = false; ESPObjects[player].Text.Visible = false end
        else
            local character = player.Character
            local footPos, headPos = GetCharacterExtremes(character)
            if footPos and headPos then
                local footScreen = Camera:WorldToViewportPoint(footPos)
                local headScreen = Camera:WorldToViewportPoint(headPos)
                local height = math.abs(headScreen.Y - footScreen.Y)
                if height > 5 then
                    local width = height * 0.55
                    local left = headScreen.X - width/2
                    local top = headScreen.Y - height*0.1
                    local bottom = top + height
                    local healthPercent = character.Humanoid.Health / character.Humanoid.MaxHealth
                    local boxColor = healthPercent > 0.5 and Color3.fromRGB(0,255,0) or (healthPercent > 0.2 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0))
                    local distance = GetDistance(Camera.CFrame.Position, headPos)
                    local info = string.format("%s | %d HP | %.1fm", player.Name, math.floor(character.Humanoid.Health), distance)
                    if not ESPObjects[player] then
                        local box = Drawing.new("Square")
                        box.Thickness = 1; box.Filled = false; box.Color = boxColor; box.Transparency = 0.7
                        local text = Drawing.new("Text")
                        text.Size = 13; text.Center = true; text.Outline = true; text.OutlineColor = Color3.new(0,0,0); text.Color = Color3.fromRGB(255,255,255); text.Font = 2
                        ESPObjects[player] = {Box = box, Text = text}
                    end
                    local esp = ESPObjects[player]
                    esp.Box.Position = Vector2.new(left, top); esp.Box.Size = Vector2.new(width, height); esp.Box.Color = boxColor; esp.Box.Visible = true
                    esp.Text.Position = Vector2.new(headScreen.X, bottom + 12); esp.Text.Text = info; esp.Text.Visible = true
                else
                    if ESPObjects[player] then ESPObjects[player].Box.Visible = false; ESPObjects[player].Text.Visible = false end
                end
            else
                if ESPObjects[player] then ESPObjects[player].Box.Visible = false; ESPObjects[player].Text.Visible = false end
            end
        end
    end
end

local function UpdateChestESP()
    if not Settings.ChestESPEnabled then
        for _, obj in pairs(ChestESPObjects) do
            if obj.Box then obj.Box.Visible = false end
            if obj.Text then obj.Text.Visible = false end
        end
        return
    end
    local chests = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name == "Treasure" or obj.Name == "Gem") and obj:IsA("BasePart") and obj:FindFirstChild("ProximityPrompt") then
            table.insert(chests, obj)
        end
    end
    for _, chest in ipairs(chests) do
        local screenPos = Camera:WorldToViewportPoint(chest.Position)
        if screenPos.Z > 0 then
            local distance = GetDistance(Camera.CFrame.Position, chest.Position)
            local text = string.format("%s (%.1fm)", chest.Name, distance)
            local color = chest.Name == "Treasure" and Color3.fromRGB(255,215,0) or Color3.fromRGB(0,255,255)
            if not ChestESPObjects[chest] then
                local box = Drawing.new("Square")
                box.Thickness = 1; box.Filled = false; box.Color = color; box.Transparency = 0.6; box.Size = Vector2.new(40,40)
                local textObj = Drawing.new("Text")
                textObj.Size = 12; textObj.Center = true; textObj.Outline = true; textObj.OutlineColor = Color3.new(0,0,0); textObj.Color = Color3.fromRGB(255,255,255); textObj.Font = 2
                ChestESPObjects[chest] = {Box = box, Text = textObj}
            end
            local esp = ChestESPObjects[chest]
            esp.Box.Position = Vector2.new(screenPos.X - 20, screenPos.Y - 20); esp.Box.Visible = true
            esp.Text.Position = Vector2.new(screenPos.X, screenPos.Y - 25); esp.Text.Text = text; esp.Text.Visible = true
        else
            if ChestESPObjects[chest] then ChestESPObjects[chest].Box.Visible = false; ChestESPObjects[chest].Text.Visible = false end
        end
    end
end

RunService.RenderStepped:Connect(function()
    UpdatePlayerESP()
    UpdateChestESP()
    ApplyVisualMod()
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        pcall(function() ESPObjects[player].Box:Remove(); ESPObjects[player].Text:Remove() end)
        ESPObjects[player] = nil
    end
end)

-- ========== UI界面 ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoobArmyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 720)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -360)
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
TitleLabel.Text = "👑 奴才军队大亨 v0.3.0"
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
        if text == "♻️ 无限重复领取" then
            if getter() then StartRepeatOfflineReward() elseif repeatOfflineLoop then task.cancel(repeatOfflineLoop) end
        end
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

-- 创建视觉修改相关的输入框
local function CreateInputOption(text, getter, setter, placeholder, icon)
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
    textLabel.Size = UDim2.new(0.4,0,1,0)
    textLabel.Position = UDim2.new(0,45,0,0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(230,230,230)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.4,0,0.7,0)
    input.Position = UDim2.new(0.55,0,0.15,0)
    input.BackgroundColor3 = Color3.fromRGB(50,50,70)
    input.PlaceholderText = placeholder
    input.Text = getter()
    input.TextColor3 = Color3.fromRGB(255,255,255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 14
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0,6)
    inputCorner.Parent = input
    input.Parent = frame
    input.FocusLost:Connect(function()
        if input.Text ~= "" then setter(input.Text) end
    end)

    frame.Parent = ScrollContainer
    return frame
end

-- 创建UI元素
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
CreateToggleOption("🎁 自动领取离线奖励", function() return Settings.AutoOfflineReward end, function(v) Settings.AutoOfflineReward = v; StartAutoOfflineRewardLoop() end, "🎁")
CreateToggleOption("♻️ 无限重复领取", function() return Settings.RepeatOfflineReward end, function(v) Settings.RepeatOfflineReward = v; if v then StartRepeatOfflineReward() elseif repeatOfflineLoop then task.cancel(repeatOfflineLoop) end end, "🔄")
CreateToggleOption("✨ 数字视觉修改(UI美化)", function() return Settings.VisualMod end, function(v) Settings.VisualMod = v end, "✨")

CreateInputOption("💰 金钱显示值", function() return Settings.VisualMoney end, function(v) Settings.VisualMoney = v end, "例: 999,999,999", "💵")
CreateInputOption("💎 宝石显示值", function() return Settings.VisualGem end, function(v) Settings.VisualGem = v end, "例: 999,999", "💎")
CreateInputOption("📊 研究积分显示值", function() return Settings.VisualRP end, function(v) Settings.VisualRP = v end, "例: 999,999,999", "📊")

local manualFrame = Instance.new("Frame")
manualFrame.Size = UDim2.new(1,0,0,40)
manualFrame.BackgroundColor3 = Color3.fromRGB(35,35,50)
manualFrame.BackgroundTransparency = 0.3
local manualCorner = Instance.new("UICorner")
manualCorner.CornerRadius = UDim.new(0,8)
manualCorner.Parent = manualFrame
local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0.9,0,0.7,0)
manualBtn.Position = UDim2.new(0.05,0,0.15,0)
manualBtn.BackgroundColor3 = Color3.fromRGB(80,120,200)
manualBtn.Text = "💪 强制领取一次离线奖励"
manualBtn.TextColor3 = Color3.fromRGB(255,255,255)
manualBtn.Font = Enum.Font.GothamBold
manualBtn.TextSize = 14
local manualBtnCorner = Instance.new("UICorner")
manualBtnCorner.CornerRadius = UDim.new(0,6)
manualBtnCorner.Parent = manualBtn
manualBtn.Parent = manualFrame
manualBtn.MouseButton1Click:Connect(ForceCollectOfflineReward)
manualFrame.Parent = ScrollContainer

CreateSliderOption("重复领取间隔(秒)", 1, 30, 1, function() return Settings.OfflineRewardInterval end, function(v) Settings.OfflineRewardInterval = v end, "秒", "⏱️")
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

-- 🍇 悬浮按钮
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0,65,0,65)
FloatingBtn.Position = UDim2.new(1,-80,0,100)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(80,80,120)
FloatingBtn.BackgroundTransparency = 0.2
FloatingBtn.Text = "🍇"
FloatingBtn.TextColor3 = Color3.fromRGB(255,255,255)
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.TextSize = 30
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1,0)
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
    MainFrame.Visible = not MainFrame.Visible
end)

CreateFOVCircle()
print("✅ 奴才军队大亨 v0.3.0 完整版已加载 | 所有功能可用")
