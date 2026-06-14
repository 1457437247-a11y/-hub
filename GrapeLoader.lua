--[[
    葡萄加载器 v1.0
    功能：选择加载奴才军队大亨或午夜追踪者 v2.1
    点击后：只加载子脚本，不销毁自身
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 保存所有UI元素
local UIElements = {}

-- 加载奴才军队大亨
local function LoadNoobArmy()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/1457437247-a11y/-hub/refs/heads/main/NoobArmy.lua"))()
    end)
end

-- 加载午夜追踪者 v2.1
local function LoadMidnight()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/1457437247-a11y/-hub/refs/heads/main/Midnight.lua"))()
    end)
end

-- ========== 创建 UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrapeLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
UIElements.ScreenGui = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 200)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = MainFrame
MainFrame.Parent = ScreenGui
UIElements.MainFrame = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,45)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,12)
titleCorner.Parent = TitleBar
TitleBar.Parent = MainFrame
UIElements.TitleBar = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7,0,1,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🍇 葡萄加载器 v1.0"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0,15,0,0)
TitleLabel.Parent = TitleBar
UIElements.TitleLabel = TitleLabel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,30)
CloseBtn.Position = UDim2.new(1,-40,0,5)
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
UIElements.CloseBtn = CloseBtn

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1,-20,1,-60)
Container.Position = UDim2.new(0,10,0,50)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame
UIElements.Container = Container

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0,12)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Container
UIElements.UIListLayout = UIListLayout

local noobBtn = Instance.new("TextButton")
noobBtn.Size = UDim2.new(1,0,0,50)
noobBtn.BackgroundColor3 = Color3.fromRGB(200,100,50)
noobBtn.Text = "👑 奴才军队大亨 v0.2.6"
noobBtn.TextColor3 = Color3.fromRGB(255,255,255)
noobBtn.Font = Enum.Font.GothamBold
noobBtn.TextSize = 16
local noobCorner = Instance.new("UICorner")
noobCorner.CornerRadius = UDim.new(0,8)
noobCorner.Parent = noobBtn
noobBtn.Parent = Container
noobBtn.MouseButton1Click:Connect(LoadNoobArmy)
UIElements.noobBtn = noobBtn

local midBtn = Instance.new("TextButton")
midBtn.Size = UDim2.new(1,0,0,50)
midBtn.BackgroundColor3 = Color3.fromRGB(100,80,180)
midBtn.Text = "🌙 午夜追踪者 v2.1"
midBtn.TextColor3 = Color3.fromRGB(255,255,255)
midBtn.Font = Enum.Font.GothamBold
midBtn.TextSize = 16
local midCorner = Instance.new("UICorner")
midCorner.CornerRadius = UDim.new(0,8)
midCorner.Parent = midBtn
midBtn.Parent = Container
midBtn.MouseButton1Click:Connect(LoadMidnight)
UIElements.midBtn = midBtn

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(1,0,0,35)
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
fpsFrame.Parent = Container
UIElements.fpsFrame = fpsFrame

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
    MainFrame.Size = UDim2.new(0,240,0,160)
    MainFrame.Position = UDim2.new(0.5,-120,0.5,-80)
    local sizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,260,0,200),
        Position = UDim2.new(0.5,-130,0.5,-100),
        BackgroundTransparency = 0.15
    })
    sizeTween:Play()
end

local function AnimateMenuHide()
    local hideTween = TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency = 1
    })
    hideTween:Play()
    hideTween.Completed:Connect(function() MainFrame.Visible = false end)
end

CloseBtn.MouseButton1Click:Connect(AnimateMenuHide)

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
UIElements.FloatingBtn = FloatingBtn

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

print("✅ 葡萄加载器 v1.0 已启动 | 午夜追踪者 v2.1 已关联 | 点击按钮加载脚本，加载器不会消失")
