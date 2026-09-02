-- ╔══════════════════════════════════════════════════╗
-- ║   STEAL AN EGG HUB v1.0                          ║
-- ║   Game ID: 107778070777162                       ║
-- ║   Features: Auto Steal, Auto Hatch, Auto Sell,   ║
-- ║   Auto DNA, ESP, Speed, TP, Egg Predictor        ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Hapus GUI lama
local oldGui = CoreGui:FindFirstChild("EggHub")
if oldGui then oldGui:Destroy() end

-- State
local State = {
    autoSteal = false,
    autoHatch = false,
    autoSell = false,
    autoDNA = false,
    espEggs = false,
    espPlayers = false,
    speedEnabled = false,
    noclip = false,
    infJump = false,
    flyEnabled = false,
    flySpeed = 50,
    walkSpeed = 100,
    stealRange = 50,
    stealSpeed = 100,
    autoTrain = false,
}

local function notify(title, text, dur)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 3})
    end)
end

local function getChar() return LocalPlayer.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ══════════════════════════════════════
-- CARI REMOTE EVENTS
-- ══════════════════════════════════════
local Remotes = {}
local function findRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:match("steal") or n:match("egg") or n:match("hatch") or n:match("sell")
            or n:match("dna") or n:match("collect") or n:match("grab") or n:match("pickup")
            or n:match("place") or n:match("train") or n:match("treadmill") or n:match("upgrade") then
                Remotes[obj.Name] = obj
            end
        end
    end
    -- Cari di Workspace juga
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            Remotes[obj.Name] = obj
        end
    end
end
findRemotes()

-- ══════════════════════════════════════
-- CARI EGG / PET OBJECTS
-- ══════════════════════════════════════
local function getEggs()
    local eggs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            local n = obj.Name:lower()
            if n:match("egg") or n:match("pet") or n:match("baby") or n:match("spawn") and not n:match("spawnlocation") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(eggs, {obj = obj, part = part, name = obj.Name, pos = part.Position})
                end
            end
        end
    end
    return eggs
end

local function getPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            table.insert(list, p)
        end
    end
    return list
end

-- ══════════════════════════════════════
-- AUTO STEAL
-- ══════════════════════════════════════
local stealConn = nil
local function toggleAutoSteal(en)
    State.autoSteal = en
    if en then
        stealConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            
            -- Steal dari player lain
            for _, p in ipairs(getPlayers()) do
                local char = p.Character
                if char then
                    local ph = char:FindFirstChild("HumanoidRootPart")
                    if ph then
                        local dist = (ph.Position - root.Position).Magnitude
                        if dist < State.stealRange then
                            -- TP ke player
                            root.CFrame = CFrame.new(ph.Position + Vector3.new(0, 3, 0))
                            
                            -- Cari egg di player itu
                            for _, obj in ipairs(char:GetDescendants()) do
                                local n = obj.Name:lower()
                                if n:match("egg") or n:match("pet") then
                                    -- Fire steal remote
                                    for rname, remote in pairs(Remotes) do
                                        local rl = rname:lower()
                                        if rl:match("steal") or rl:match("grab") or rl:match("collect") or rl:match("pickup") then
                                            pcall(function() remote:FireServer(obj) end)
                                        end
                                    end
                                end
                            end
                            
                            -- Cari egg di workspace dekat player
                            for _, egg in ipairs(getEggs()) do
                                local ed = (egg.pos - ph.Position).Magnitude
                                if ed < 20 then
                                    for rname, remote in pairs(Remotes) do
                                        local rl = rname:lower()
                                        if rl:match("steal") or rl:match("grab") or rl:match("collect") then
                                            pcall(function() remote:FireServer(egg.obj) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Steal egg dari workspace langsung
            for _, egg in ipairs(getEggs()) do
                local d = (egg.pos - root.Position).Magnitude
                if d < State.stealRange then
                    -- TP ke egg
                    root.CFrame = CFrame.new(egg.pos + Vector3.new(0, 3, 0))
                    
                    -- Fire semua remote steal/collect
                    for rname, remote in pairs(Remotes) do
                        local rl = rname:lower()
                        if rl:match("steal") or rl:match("grab") or rl:match("collect") or rl:match("pickup") then
                            pcall(function() remote:FireServer(egg.obj) end)
                        end
                    end
                end
            end
            
            task.wait(1 / (State.stealSpeed / 10))
        end)
        notify("Egg Hub", "Auto Steal: ON", 3)
    else
        if stealConn then stealConn:Disconnect() end
        notify("Egg Hub", "Auto Steal: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO HATCH
-- ══════════════════════════════════════
local hatchConn = nil
local function toggleAutoHatch(en)
    State.autoHatch = en
    if en then
        hatchConn = RunService.Heartbeat:Connect(function()
            for rname, remote in pairs(Remotes) do
                local rl = rname:lower()
                if rl:match("hatch") then
                    pcall(function() remote:FireServer() end)
                end
            end
            task.wait(0.5)
        end)
        notify("Egg Hub", "Auto Hatch: ON", 3)
    else
        if hatchConn then hatchConn:Disconnect() end
        notify("Egg Hub", "Auto Hatch: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO SELL
-- ══════════════════════════════════════
local sellConn = nil
local function toggleAutoSell(en)
    State.autoSell = en
    if en then
        sellConn = RunService.Heartbeat:Connect(function()
            for rname, remote in pairs(Remotes) do
                local rl = rname:lower()
                if rl:match("sell") then
                    pcall(function() remote:FireServer() end)
                end
            end
            task.wait(1)
        end)
        notify("Egg Hub", "Auto Sell: ON", 3)
    else
        if sellConn then sellConn:Disconnect() end
        notify("Egg Hub", "Auto Sell: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO DNA STEAL
-- ══════════════════════════════════════
local dnaConn = nil
local function toggleAutoDNA(en)
    State.autoDNA = en
    if en then
        dnaConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            for _, p in ipairs(getPlayers()) do
                local char = p.Character
                if char then
                    local ph = char:FindFirstChild("HumanoidRootPart")
                    if ph then
                        local d = (ph.Position - root.Position).Magnitude
                        if d < State.stealRange then
                            for rname, remote in pairs(Remotes) do
                                local rl = rname:lower()
                                if rl:match("dna") then
                                    pcall(function() remote:FireServer(p) end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(1)
        end)
        notify("Egg Hub", "Auto DNA Steal: ON", 3)
    else
        if dnaConn then dnaConn:Disconnect() end
        notify("Egg Hub", "Auto DNA: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO TRAIN (Treadmill)
-- ══════════════════════════════════════
local trainConn = nil
local function toggleAutoTrain(en)
    State.autoTrain = en
    if en then
        -- Cari treadmill
        local treadmill = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:match("treadmill") or n:match("train") then
                treadmill = obj
                break
            end
        end
        if treadmill then
            local part = treadmill:IsA("BasePart") and treadmill or treadmill:FindFirstChildWhichIsA("BasePart")
            if part then
                local root = getRoot()
                if root then
                    root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                end
            end
        end
        trainConn = RunService.Heartbeat:Connect(function()
            for rname, remote in pairs(Remotes) do
                local rl = rname:lower()
                if rl:match("train") or rl:match("treadmill") then
                    pcall(function() remote:FireServer() end)
                end
            end
            task.wait(0.5)
        end)
        notify("Egg Hub", "Auto Train: ON", 3)
    else
        if trainConn then trainConn:Disconnect() end
        notify("Egg Hub", "Auto Train: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ESP EGGS
-- ══════════════════════════════════════
local function toggleESPeggs(en)
    State.espEggs = en
    if en then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                local n = obj.Name:lower()
                if n:match("egg") and not n:match("spawnlocation") then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part and not part:FindFirstChild("EggESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EggESP"
                        hl.FillColor = Color3.new(1, 0.8, 0)
                        hl.FillTransparency = 0.3
                        hl.OutlineColor = Color3.new(1, 1, 1)
                        hl.Parent = obj
                        
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "EggESP"
                        bb.Size = UDim2.new(0, 150, 0, 30)
                        bb.AlwaysOnTop = true
                        bb.MaxDistance = 500
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundTransparency = 1
                        l.Text = "🥚 " .. obj.Name
                        l.TextColor3 = Color3.new(1, 1, 0)
                        l.TextScaled = true
                        l.Font = Enum.Font.GothamBold
                        l.Parent = bb
                        bb.Parent = part
                    end
                end
            end
        end
        notify("Egg Hub", "ESP Eggs: ON", 3)
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local e = obj:FindFirstChild("EggESP")
            if e then e:Destroy() end
        end
        notify("Egg Hub", "ESP Eggs: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ESP PLAYERS
-- ══════════════════════════════════════
local function toggleESPplayers(en)
    State.espPlayers = en
    if en then
        for _, p in ipairs(getPlayers()) do
            if p.Character and not p.Character:FindFirstChild("PlayerESP") then
                local hl = Instance.new("Highlight")
                hl.Name = "PlayerESP"
                hl.FillColor = Color3.new(1, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.Parent = p.Character
            end
        end
        notify("Egg Hub", "ESP Players: ON", 3)
    else
        for _, p in ipairs(getPlayers()) do
            if p.Character then
                local e = p.Character:FindFirstChild("PlayerESP")
                if e then e:Destroy() end
            end
        end
        notify("Egg Hub", "ESP Players: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- SPEED
-- ══════════════════════════════════════
local function toggleSpeed(en)
    State.speedEnabled = en
    local h = getHum()
    if h then
        if en then h.WalkSpeed = State.walkSpeed else h.WalkSpeed = 16 end
    end
end

-- ══════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════
local noclipConn = nil
local function toggleNoclip(en)
    State.noclip = en
    if en then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end

-- ══════════════════════════════════════
-- INFINITE JUMP
-- ══════════════════════════════════════
local infJumpConn = nil
local function toggleInfJump(en)
    State.infJump = en
    if en then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect() end
    end
end

-- ══════════════════════════════════════
-- FLY
-- ══════════════════════════════════════
local flyConn = nil
local function toggleFly(en)
    State.flyEnabled = en
    local root = getRoot()
    if not root then return end
    if en then
        local bg = Instance.new("BodyGyro") bg.Name = "EggFly" bg.MaxTorque = Vector3.new(4000,4000,4000) bg.P = 50000 bg.Parent = root
        local bv = Instance.new("BodyVelocity") bv.Name = "EggFlyVel" bv.MaxForce = Vector3.new(4000,4000,4000) bv.Parent = root
        flyConn = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            bg.CFrame = cam.CFrame
            bv.Velocity = dir * State.flySpeed
        end)
        notify("Egg Hub", "Fly: ON (WASD+Space/Shift)", 3)
    else
        if flyConn then flyConn:Disconnect() end
        local g = root:FindFirstChild("EggFly") if g then g:Destroy() end
        local v = root:FindFirstChild("EggFlyVel") if v then v:Destroy() end
        notify("Egg Hub", "Fly: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- TELEPORT
-- ══════════════════════════════════════
local function tpTo(pos)
    local r = getRoot()
    if r then r.CFrame = CFrame.new(pos) end
end

-- ══════════════════════════════════════
-- SCAN GAME
-- ══════════════════════════════════════
local function scanGame()
    notify("Egg Hub", "Scanning...", 2)
    print("=== STEAL AN EGG SCAN ===")
    
    -- Scan Workspace
    print("\n--- WORKSPACE OBJECTS ---")
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            local n = obj.Name:lower()
            if n:match("egg") or n:match("pet") or n:match("treadmill") or n:match("spawn")
            or n:match("shop") or n:match("base") or n:match("dna") or n:match("npc") then
                local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                local pos = p and tostring(p.Position) or "no pos"
                print(string.format("[%s] %s (%s) | %s", obj.ClassName, obj.Name, pos, obj:GetFullName()))
            end
        end
    end
    
    -- Scan Remotes
    print("\n--- REMOTE EVENTS ---")
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            print(string.format("[%s] %s | %s", obj.ClassName, obj.Name, obj:GetFullName()))
        end
    end
    
    print("\n=== SCAN DONE ===")
    notify("Egg Hub", "Scan done! Check F9", 5)
end

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 10) corner.Parent = MainFrame

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 10) tc.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥚 STEAL AN EGG HUB v1.0"
Title.TextColor3 = Color3.fromRGB(255, 220, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -50)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame
local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0, 5) layout.Parent = Scroll

-- Helper
local function createSection(name)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 25)
    l.BackgroundTransparency = 1
    l.Text = "── " .. name .. " ──"
    l.TextColor3 = Color3.fromRGB(100, 100, 120)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Parent = Scroll
end

local function createToggle(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = Scroll
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 65)
        callback(state)
    end)
end

local function createButton(name, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 100, 200)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = Scroll
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(callback)
end

local function createSlider(name, min, max, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    f.BorderSizePixel = 0
    f.Parent = Scroll
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = f
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 0, 20)
    l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.35, 0, 0, 20)
    v.Position = UDim2.new(0.63, 0, 0, 2)
    v.BackgroundTransparency = 1
    v.Text = tostring(default)
    v.TextColor3 = Color3.fromRGB(100, 200, 255)
    v.Font = Enum.Font.GothamBold
    v.TextSize = 13
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = f
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.88, 0, 0, 6)
    bar.Position = UDim2.new(0.06, 0, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = f
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    
    local dragging = false
    local val = default
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            local x = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * x)
            fill.Size = UDim2.new(x, 0, 1, 0)
            v.Text = tostring(val)
            callback(val)
        end
    end)
end

-- ══════════════════════════════════════
-- TOMBOL GUI
-- ══════════════════════════════════════
createSection("🥚 AUTO STEAL")
createToggle("Auto Steal Eggs", function(s) toggleAutoSteal(s) end)
createSlider("Steal Range", 10, 500, 50, function(v) State.stealRange = v end)
createSlider("Steal Speed", 10, 500, 100, function(v) State.stealSpeed = v end)
createToggle("Auto DNA Steal", function(s) toggleAutoDNA(s) end)

createSection("🐣 EGG MANAGEMENT")
createToggle("Auto Hatch", function(s) toggleAutoHatch(s) end)
createToggle("Auto Sell", function(s) toggleAutoSell(s) end)

createSection("🏃 TRAINING")
createToggle("Auto Train (Treadmill)", function(s) toggleAutoTrain(s) end)

createSection("👁️ VISUAL")
createToggle("ESP Eggs", function(s) toggleESPeggs(s) end)
createToggle("ESP Players", function(s) toggleESPplayers(s) end)

createSection("⚡ MOVEMENT")
createSlider("Walk Speed", 16, 500, 100, function(v)
    State.walkSpeed = v
    if State.speedEnabled then
        local h = getHum()
        if h then h.WalkSpeed = v end
    end
end)
createToggle("Speed Boost", function(s) toggleSpeed(s) end)
createToggle("Noclip", function(s) toggleNoclip(s) end)
createToggle("Infinite Jump", function(s) toggleInfJump(s) end)
createToggle("Fly (WASD+Space/Shift)", function(s) toggleFly(s) end)
createSlider("Fly Speed", 10, 300, 50, function(v) State.flySpeed = v end)

createSection("🚀 TELEPORT")
createButton("📍 TP to Nearest Egg", Color3.fromRGB(200, 150, 50), function()
    local root = getRoot()
    if not root then return end
    local closest, cd = nil, math.huge
    for _, egg in ipairs(getEggs()) do
        local d = (egg.pos - root.Position).Magnitude
        if d < cd then cd = d closest = egg end
    end
    if closest then tpTo(closest.pos + Vector3.new(0, 3, 0)) notify("Egg Hub", "TP'd to egg!", 2) end
end)
createButton("📍 TP to Nearest Player", Color3.fromRGB(150, 200, 50), function()
    local root = getRoot()
    if not root then return end
    local closest, cd = nil, math.huge
    for _, p in ipairs(getPlayers()) do
        local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if ph then
            local d = (ph.Position - root.Position).Magnitude
            if d < cd then cd = d closest = p end
        end
    end
    if closest and closest.Character then
        local ph = closest.Character:FindFirstChild("HumanoidRootPart")
        if ph then tpTo(ph.Position + Vector3.new(0, 3, 0)) notify("Egg Hub", "TP'd to " .. closest.Name, 2) end
    end
end)
createButton("📍 TP to Spawn", Color3.fromRGB(100, 150, 200), function()
    local s = Workspace:FindFirstChild("SpawnLocation")
    if s then tpTo(s.Position + Vector3.new(0, 3, 0)) end
end)

createSection("🔬 TOOLS")
createButton("📋 SCAN GAME STRUCTURE", Color3.fromRGB(200, 100, 50), function() scanGame() end)

-- Rejoin
createSection("🔄 SERVER")
createButton("🔄 Rejoin Server", Color3.fromRGB(180, 60, 60), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Toggle hide
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if State.speedEnabled then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = State.walkSpeed end
    end
end)

-- Init
notify("🥚 Egg Hub", "Loaded! Press RightCtrl to toggle", 5)
print("[Egg Hub] Script loaded! Game: Steal An Egg")
print("[Egg Hub] Place ID: 107778070777162")
print("[Egg Hub] Remotes found: " .. #Remotes)

task.spawn(function()
    task.wait(3)
    scanGame()
end)
