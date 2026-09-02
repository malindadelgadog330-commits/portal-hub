-- ╔══════════════════════════════════════════════════╗
-- ║   STEAL AN EGG HUB v2.0                          ║
-- ║   Game ID: 107778070777162                       ║
-- ║   Fixed: Auto Steal + Godmode + Anti Bat/Trap    ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local oldGui = CoreGui:FindFirstChild("EggHub")
if oldGui then oldGui:Destroy() end

local State = {
    autoSteal = false,
    autoHatch = false,
    autoSell = false,
    godmode = false,
    antiBat = false,
    antiTrap = false,
    speedEnabled = false,
    noclip = false,
    infJump = false,
    flyEnabled = false,
    flySpeed = 50,
    walkSpeed = 100,
    stealSpeed = 100,
    fullbright = false,
    espPlayers = false,
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
-- CARI REMOTES
-- ══════════════════════════════════════
local Remotes = {}
local function findRemotes()
    Remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            Remotes[obj.Name] = obj
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            Remotes[obj.Name] = obj
        end
    end
end
findRemotes()

-- ══════════════════════════════════════
-- AUTO STEAL (Steal egg dari player lain)
-- ══════════════════════════════════════
local stealConn = nil
local function toggleAutoSteal(en)
    State.autoSteal = en
    if en then
        stealConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            
            -- Cari semua player lain
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local char = p.Character
                    local ph = char:FindFirstChild("HumanoidRootPart")
                    if ph then
                        -- TP ke player itu
                        root.CFrame = CFrame.new(ph.Position + Vector3.new(0, 3, 0))
                        
                        -- Fire semua remote yang ada (steal mechanism)
                        for rname, remote in pairs(Remotes) do
                            local rl = rname:lower()
                            if rl:match("steal") or rl:match("egg") or rl:match("collect") or rl:match("grab") then
                                pcall(function() remote:FireServer() end)
                                pcall(function() remote:FireServer(char) end)
                                pcall(function() remote:FireServer(p) end)
                            end
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
-- GODMODE (Kebal dari segala damage)
-- ══════════════════════════════════════
local godConn = nil
local function toggleGodmode(en)
    State.godmode = en
    if en then
        godConn = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    h.Health = h.MaxHealth
                    -- Anti damage
                    pcall(function()
                        h:GetPropertyChangedSignal("Health"):Connect(function()
                            if State.godmode then
                                h.Health = h.MaxHealth
                            end
                        end)
                    end)
                end
            end
        end)
        -- Set max health tinggi
        local c = getChar()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function() h.MaxHealth = math.huge end)
                pcall(function() h.Health = math.huge end)
            end
        end
        notify("Egg Hub", "Godmode: ON - Kebal!", 3)
    else
        if godConn then godConn:Disconnect() end
        local c = getChar()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                pcall(function() h.MaxHealth = 100 end)
                pcall(function() h.Health = 100 end)
            end
        end
        notify("Egg Hub", "Godmode: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ANTI BAT (Anti dipukul bat/weapon player)
-- ══════════════════════════════════════
local antiBatConn = nil
local function toggleAntiBat(en)
    State.antiBat = en
    if en then
        -- Method 1: Block semua damage remote
        antiBatConn = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    -- Reset health kalau turun
                    if h.Health < h.MaxHealth then
                        h.Health = h.MaxHealth
                    end
                end
                -- Remove bat/weapon dari player lain yang dekat
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local tools = p.Character:FindFirstChildOfClass("Tool")
                        if tools then
                            local ph = p.Character:FindFirstChild("HumanoidRootPart")
                            local myRoot = c:FindFirstChild("HumanoidRootPart")
                            if ph and myRoot then
                                local d = (ph.Position - myRoot.Position).Magnitude
                                if d < 15 then
                                    -- TP pergi dari player yang pegang bat
                                    myRoot.CFrame = myRoot.CFrame * CFrame.new(0, 50, 0)
                                end
                            end
                        end
                    end
                end
            end
        end)
        -- Method 2: Hook humanoid untuk anti damage
        local mt = getrawmetatable(game)
        if mt then
            pcall(function()
                setreadonly(mt, false)
                local oldIndex = mt.__index
                mt.__index = newcclosure and newcclosure(function(self, key)
                    if key == "Health" and State.antiBat and self == getHum() then
                        return getHum().MaxHealth
                    end
                    return oldIndex(self, key)
                end)
                setreadonly(mt, true)
            end)
        end
        notify("Egg Hub", "Anti Bat: ON - Kebal pukul!", 3)
    else
        if antiBatConn then antiBatConn:Disconnect() end
        notify("Egg Hub", "Anti Bat: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ANTI TRAP (Anti di-trap/locked oleh player)
-- ══════════════════════════════════════
local antiTrapConn = nil
local function toggleAntiTrap(en)
    State.antiTrap = en
    if en then
        antiTrapConn = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not root or not h then return end
            
            -- Cek kalau character di-freeze/locked
            -- Root part velocity = 0 berarti mungkin di-trap
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude < 0.1 and h.MoveDirection.Magnitude > 0.1 then
                -- Character mau gerak tapi ga bisa = di-trap
                -- Force unfreeze
                pcall(function() h.PlatformStand = false end)
                pcall(function() h.Sit = false end)
                pcall(function() root.Anchored = false end)
                pcall(function() root.CanCollide = true end)
                -- Hapus BodyVelocity/BodyPosition yang mungkin dipasang trap
                for _, obj in ipairs(c:GetDescendants()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") 
                    or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") then
                        local name = obj.Name:lower()
                        if not name:match("egg") then
                            obj:Destroy()
                        end
                    end
                end
                -- TP sedikit ke atas untuk escape trap
                root.CFrame = root.CFrame * CFrame.new(0, 5, 0)
            end
            
            -- Cek Weld/Constraint yang mungkin trap
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
                    local name = obj.Name:lower()
                    if name:match("trap") or name:match("grab") or name:match("lock") or name:match("freeze") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end)
        notify("Egg Hub", "Anti Trap: ON - Anti di-kunci!", 3)
    else
        if antiTrapConn then antiTrapConn:Disconnect() end
        notify("Egg Hub", "Anti Trap: OFF", 2)
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
-- FULLBRIGHT
-- ══════════════════════════════════════
local function toggleFullbright(en)
    State.fullbright = en
    if en then
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = true
    end
end

-- ══════════════════════════════════════
-- ESP PLAYERS
-- ══════════════════════════════════════
local function toggleESPplayers(en)
    State.espPlayers = en
    if en then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("PlayerESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "PlayerESP"
                    hl.FillColor = Color3.new(1, 0, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.Parent = p.Character
                end
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local e = p.Character:FindFirstChild("PlayerESP")
                if e then e:Destroy() end
            end
        end
    end
end

-- ══════════════════════════════════════
-- SCAN GAME
-- ══════════════════════════════════════
local function scanGame()
    notify("Egg Hub", "Scanning...", 2)
    print("=== STEAL AN EGG SCAN ===")
    print("\n--- REMOTE EVENTS ---")
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            print(string.format("[%s] %s | %s", obj.ClassName, obj.Name, obj:GetFullName()))
        end
    end
    print("\n--- WORKSPACE OBJECTS ---")
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local n = obj.Name:lower()
            if n:match("egg") or n:match("bat") or n:match("trap") or n:match("treadmill")
            or n:match("base") or n:match("shop") or n:match("npc") then
                print(string.format("[%s] %s | %s", obj.ClassName, obj.Name, obj:GetFullName()))
            end
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

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 10) tc.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥚 STEAL AN EGG HUB v2.0"
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

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -50)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame
local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0, 5) layout.Parent = Scroll

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
createSection("🛡️ KEBAL / ANTI")
createToggle("🛡️ Godmode (Kebal Total)", function(s) toggleGodmode(s) end)
createToggle("🏏 Anti Bat (Anti dipukul)", function(s) toggleAntiBat(s) end)
createToggle("🔒 Anti Trap (Anti di-kunci)", function(s) toggleAntiTrap(s) end)

createSection("🥚 AUTO STEAL")
createToggle("Auto Steal (Steal egg player)", function(s) toggleAutoSteal(s) end)
createSlider("Steal Speed", 10, 500, 100, function(v) State.stealSpeed = v end)

createSection("🐣 EGG AUTO")
createToggle("Auto Hatch", function(s) toggleAutoHatch(s) end)
createToggle("Auto Sell", function(s) toggleAutoSell(s) end)

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

createSection("👁️ VISUAL")
createToggle("ESP Players", function(s) toggleESPplayers(s) end)
createToggle("Fullbright", function(s) toggleFullbright(s) end)

createSection("🔬 TOOLS")
createButton("📋 SCAN GAME STRUCTURE", Color3.fromRGB(200, 100, 50), function() scanGame() end)
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
    if State.godmode then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function() h.MaxHealth = math.huge end)
            pcall(function() h.Health = math.huge end)
        end
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
