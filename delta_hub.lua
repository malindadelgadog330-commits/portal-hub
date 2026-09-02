-- ╔══════════════════════════════════════════╗
-- ║     DELTA HUB v2.0 - Universal Script   ║
-- ║     by Palz x CodeBuddy                ║
-- ╚══════════════════════════════════════════╝

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ══════════════════════════════════════
-- GUI CREATION
-- ══════════════════════════════════════
local HubGui = Instance.new("ScreenGui")
HubGui.Name = "DeltaHub"
HubGui.ResetOnSpawn = false
HubGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HubGui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = HubGui

-- Corner rounding
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Drop shadow effect
local Shadow = Instance.new("UIStroke")
Shadow.Color = Color3.fromRGB(60, 80, 200)
Shadow.Thickness = 1.5
Shadow.Transparency = 0.5
Shadow.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ DELTA HUB v2.0"
TitleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 2)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TitleBar

-- Content Scroll Frame
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -42)
Content.Position = UDim2.new(0, 8, 0, 38)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
Content.BorderSizePixel = 0
Content.CanvasSize = UDim2.new(0, 0, 0, 500)
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- ══════════════════════════════════════
-- BUTTON HELPER
-- ══════════════════════════════════════
local function CreateSection(name, order)
    local Section = Instance.new("Frame")
    Section.Name = name
    Section.Size = UDim2.new(1, 0, 0, 28)
    Section.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Section.BorderSizePixel = 0
    Section.LayoutOrder = order or 0
    Section.Parent = Content
    
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = Section
    
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(1, -10, 1, 0)
    st.Position = UDim2.new(0, 10, 0, 0)
    st.BackgroundTransparency = 1
    st.Text = "  " .. name
    st.TextColor3 = Color3.fromRGB(100, 200, 255)
    st.Font = Enum.Font.GothamBold
    st.TextSize = 12
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.Parent = Section
end

local function CreateToggle(name, order, default, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, 0, 0, 32)
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    Toggle.BorderSizePixel = 0
    Toggle.LayoutOrder = order
    Toggle.Parent = Content
    
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = Toggle
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Toggle
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 42, 0, 22)
    ToggleBtn.Position = UDim2.new(1, -52, 0.5, -11)
    ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(80, 80, 90)
    ToggleBtn.Text = default and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 10
    ToggleBtn.Parent = Toggle
    
    local btc = Instance.new("UICorner")
    btc.CornerRadius = UDim.new(0, 11)
    btc.Parent = ToggleBtn
    
    local state = default or false
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.Text = state and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(80, 80, 90)
        callback(state)
    end)
    
    return ToggleBtn
end

local function CreateSlider(name, order, min, max, default, callback)
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 40)
    Slider.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    Slider.BorderSizePixel = 0
    Slider.LayoutOrder = order
    Slider.Parent = Content
    
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = Slider
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Slider
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.35, 0, 0, 20)
    ValueLabel.Position = UDim2.new(0.63, 0, 0, 2)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 13
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Slider
    
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(0.88, 0, 0, 6)
    BarBG.Position = UDim2.new(0.06, 0, 0, 26)
    BarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Slider
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = BarBG
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = BarBG
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = Fill
    
    local Knob = Instance.new("TextButton")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(1, -7, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Text = ""
    Knob.Parent = Fill
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = Knob
    
    local dragging = false
    local val = default
    
    Knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local absPos = BarBG.AbsolutePosition.X
            local absSize = BarBG.AbsoluteSize.X
            local x = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
            val = math.floor(min + (max - min) * x)
            Fill.Size = UDim2.new(x, 0, 1, 0)
            ValueLabel.Text = tostring(val)
            callback(val)
        end
    end)
    
    return ValueLabel
end

local function CreateButton(name, order, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 30)
    Btn.BackgroundColor3 = color or Color3.fromRGB(40, 80, 160)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.BorderSizePixel = 0
    Btn.LayoutOrder = order
    Btn.Parent = Content
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = Btn
    
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- ══════════════════════════════════════
-- FEATURES
-- ══════════════════════════════════════

-- 1. PLAYER SECTION
CreateSection("🎮 PLAYER", 1)

-- Speed
local WalkSpeed = 16
CreateSlider("Walk Speed", 2, 16, 200, 16, function(v)
    WalkSpeed = v
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.WalkSpeed = v
    end
end)

-- Jump Power
CreateSlider("Jump Power", 3, 50, 300, 50, function(v)
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.JumpPower = v
    end
end)

-- NoClip
local NoClip = false
CreateToggle("NoClip (walk through walls)", 4, false, function(v)
    NoClip = v
end)

RunService.Stepped:Connect(function()
    if NoClip and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- God Mode
local GodMode = false
CreateToggle("God Mode", 5, false, function(v)
    GodMode = v
    if Character and Character:FindFirstChild("Humanoid") then
        if v then
            Character.Humanoid.MaxHealth = math.huge
            Character.Humanoid.Health = math.huge
        else
            Character.Humanoid.MaxHealth = 100
            Character.Humanoid.Health = 100
        end
    end
end)

-- 2. VISUAL SECTION
CreateSection("👁️ VISUALS", 6)

-- ESP Players
local ESPEnabled = false
local ESPObjects = {}

local function CreateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if not ESPObjects[p.Name] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "DeltaESP"
                highlight.FillColor = Color3.fromRGB(100, 150, 255)
                highlight.FillTransparency = 0.7
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.2
                highlight.Adornee = p.Character
                highlight.Parent = p.Character
                
                ESPObjects[p.Name] = highlight
            end
        end
    end
end

local function RemoveESP()
    for name, esp in pairs(ESPObjects) do
        if esp then esp:Destroy() end
    end
    ESPObjects = {}
end

CreateToggle("Player ESP (Highlight)", 7, false, function(v)
    ESPEnabled = v
    if v then
        CreateESP()
    else
        RemoveESP()
    end
end)

-- FPS Counter
local FPSLabel
local ShowFPS = false
CreateToggle("FPS Counter", 8, false, function(v)
    ShowFPS = v
    if v then
        FPSLabel = Instance.new("TextLabel")
        FPSLabel.Size = UDim2.new(0, 120, 0, 22)
        FPSLabel.Position = UDim2.new(0, 10, 0, 10)
        FPSLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        FPSLabel.BackgroundTransparency = 0.4
        FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        FPSLabel.Font = Enum.Font.GothamBold
        FPSLabel.TextSize = 13
        FPSLabel.Parent = HubGui
        local fpc = Instance.new("UICorner")
        fpc.CornerRadius = UDim.new(0, 4)
        fpc.Parent = FPSLabel
    else
        if FPSLabel then FPSLabel:Destroy() end
    end
end)

local frameCount = 0
local lastFPSTime = os.clock()
RunService.RenderStepped:Connect(function()
    if ShowFPS and FPSLabel then
        frameCount += 1
        local now = os.clock()
        if now - lastFPSTime >= 1 then
            FPSLabel.Text = " FPS: " .. frameCount .. " "
            frameCount = 0
            lastFPSTime = now
        end
    end
end)

-- 3. UTILITY SECTION
CreateSection("🔧 UTILITY", 9)

-- Anti AFK
local AntiAFK = false
CreateToggle("Anti AFK", 10, false, function(v)
    AntiAFK = v
end)

if AntiAFK then
    spawn(function()
        while AntiAFK do
            if Character and Character:FindFirstChild("Humanoid") then
                Character.Humanoid.Jump = true
            end
            wait(300)
        end
    end)
end

local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end
end)

-- Teleport to Player
local TPBox
local function CreatePlayerDropdown()
    -- Just show player list buttons
end

-- Rejoin Server
CreateButton("🔄 Rejoin Server", 11, Color3.fromRGB(180, 60, 60), function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- Server Hop
CreateButton("🌐 Server Hop", 12, Color3.fromRGB(60, 120, 180), function()
    local http = game:GetService("HttpService")
    local tp = game:GetService("TeleportService")
    local placeId = game.PlaceId
    
    local servers = http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"))
    if servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                tp:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                break
            end
        end
    end
end)

-- 4. FUN SECTION
CreateSection("🎯 FUN", 13)

-- Spin Character
local Spinning = false
CreateToggle("Spin Character", 14, false, function(v)
    Spinning = v
    if v then
        spawn(function()
            while Spinning and Character and Character:FindFirstChild("HumanoidRootPart") do
                Character.HumanoidRootPart.CFrame = 
                    Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0)
                task.wait(0.02)
            end
        end)
    end
end)

-- Fling (fun)
CreateButton("🌪️ Fling (Server Lag)", 15, Color3.fromRGB(200, 100, 50), function()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local vel = Instance.new("BodyAngularVelocity")
        vel.AngularVelocity = Vector3.new(0, 999, 0)
        vel.MaxTorque = Vector3.new(0, math.huge, 0)
        vel.P = 100000
        vel.Parent = Character.HumanoidRootPart
        game:GetService("Debris"):AddItem(vel, 0.5)
    end
end)

-- ══════════════════════════════════════
-- MINIMIZE
-- ══════════════════════════════════════
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 35), "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 400), "Out", "Quad", 0.3, true)
        MinBtn.Text = "—"
    end
end)

-- ══════════════════════════════════════
-- REJOIN CHARACTER
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    wait(1)
    if WalkSpeed and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = WalkSpeed
    end
    if GodMode and char:FindFirstChild("Humanoid") then
        char.Humanoid.MaxHealth = math.huge
        char.Humanoid.Health = math.huge
    end
end)

-- ══════════════════════════════════════
-- TOGGLE HIDE (Right Ctrl)
-- ══════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ══════════════════════════════════════
-- NOTIFICATION
-- ══════════════════════════════════════
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "⚡ Delta Hub v2.0",
    Text = "Loaded! Press RightCtrl to toggle",
    Duration = 3
})

print("=== DELTA HUB v2.0 LOADED ===")
print("Press Right Ctrl to show/hide")
