--[[
    ╔═══════════════════════════════════════════════╗
    ║   THE PORTAL [MMORPG] - UTILITY HUB v1.0       ║
    ║   Game ID: 122003435349029                     ║
    ║   Universe ID: 9356969539                      ║
    ║   Developer: The Box of Trolls Studio          ║
    ║   Made for: Delta Executor                     ║
    ╚═══════════════════════════════════════════════╝

    Game Info (dari analisis API + screenshot):
    - Genre: RPG / Open World & Survival RPG
    - Max Players: 50
    - Avatar Type: MorphToR15
    - Currency: Tria (badge "Trianaire" = 1M tria)
    - Races: Elf, Beastmen, Human
    - Classes: Warrior, Defender, Enchanter, Cleric
    - Activities: Farming, Mining, Fishing, Cooking,
      Crafting, Forging, Chopping trees, Dueling
    - Location: Dewdrop Village
    - Progression: Chapter-based (Chapter 1, 2, dst)
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================================
-- HAPUS GUI LAMA (anti-duplikat)
-- ============================================================
local oldGui = CoreGui:FindFirstChild("PortalHub")
if oldGui then oldGui:Destroy() end

-- ============================================================
-- BUAT SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PortalHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- ============================================================
-- VARIABEL STATE
-- ============================================================
local State = {
    speedEnabled = false,
    jumpEnabled = false,
    noclipEnabled = false,
    infJumpEnabled = false,
    flyEnabled = false,
    espEnabled = false,
    autoFarmEnabled = false,
    autoFishEnabled = false,
    autoMineEnabled = false,
    autoChopEnabled = false,
    fullbrightEnabled = false,
    originalSpeed = 16,
    originalJump = 50,
    flySpeed = 50,
    farmRange = 100,
}

-- ============================================================
-- FUNGSI UTILITY
-- ============================================================
local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
        })
    end)
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- SCAN GAME STRUCTURE (Explorer)
-- ============================================================
local function scanGameStructure()
    local results = {}
    
    -- Scan Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("Part") then
            local name = obj.Name:lower()
            if name:match("mob") or name:match("npc") or name:match("enemy") 
            or name:match("monster") or name:match("boss") or name:match("quest")
            or name:match("shop") or name:match("portal") or name:match("village")
            or name:match("dewdrop") or name:match("spawn") or name:match("item")
            or name:match("resource") or name:match("ore") or name:match("tree")
            or name:match("fish") or name:match("crop") or name:match("farm") then
                table.insert(results, {
                    name = obj.Name,
                    className = obj.ClassName,
                    path = obj:GetFullName(),
                    parent = obj.Parent and obj.Parent.Name or "?"
                })
            end
        end
    end
    
    -- Scan ReplicatedStorage untuk RemoteEvent/RemoteFunction
    local remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, {
                name = obj.Name,
                type = obj.ClassName,
                path = obj:GetFullName()
            })
        end
    end
    
    return results, remotes
end

-- ============================================================
-- FITUR: SPEED
-- ============================================================
local function toggleSpeed(enabled)
    State.speedEnabled = enabled
    local humanoid = getHumanoid()
    if humanoid then
        if enabled then
            State.originalSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 100
            notify("Portal Hub", "Speed: ON (100)", 2)
        else
            humanoid.WalkSpeed = State.originalSpeed
            notify("Portal Hub", "Speed: OFF", 2)
        end
    end
end

-- ============================================================
-- FITUR: JUMP POWER
-- ============================================================
local function toggleJump(enabled)
    State.jumpEnabled = enabled
    local humanoid = getHumanoid()
    if humanoid then
        if enabled then
            State.originalJump = humanoid.JumpPower
            humanoid.JumpPower = 150
            notify("Portal Hub", "Jump Power: ON (150)", 2)
        else
            humanoid.JumpPower = State.originalJump
            notify("Portal Hub", "Jump Power: OFF", 2)
        end
    end
end

-- ============================================================
-- FITUR: NOCLIP
-- ============================================================
local noclipLoop = nil
local function toggleNoclip(enabled)
    State.noclipEnabled = enabled
    if enabled then
        noclipLoop = RunService.Stepped:Connect(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        notify("Portal Hub", "Noclip: ON", 2)
    else
        if noclipLoop then noclipLoop:Disconnect() end
        notify("Portal Hub", "Noclip: OFF", 2)
    end
end

-- ============================================================
-- FITUR: INFINITE JUMP
-- ============================================================
local infJumpConn = nil
local function toggleInfJump(enabled)
    State.infJumpEnabled = enabled
    if enabled then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = getCharacter()
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        notify("Portal Hub", "Infinite Jump: ON", 2)
    else
        if infJumpConn then infJumpConn:Disconnect() end
        notify("Portal Hub", "Infinite Jump: OFF", 2)
    end
end

-- ============================================================
-- FITUR: FLY
-- ============================================================
local flyConn = nil
local flyPart = nil
local function toggleFly(enabled)
    State.flyEnabled = enabled
    if enabled then
        local char = getCharacter()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        flyPart = Instance.new("BodyGyro")
        flyPart.Name = "PortalFly"
        flyPart.MaxTorque = Vector3.new(4000, 4000, 4000)
        flyPart.P = 50000
        flyPart.Parent = root
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "PortalFlyVel"
        bv.MaxForce = Vector3.new(4000, 4000, 4000)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
        
        flyConn = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            local dir = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            
            flyPart.CFrame = cam.CFrame
            bv.Velocity = dir * State.flySpeed
        end)
        
        notify("Portal Hub", "Fly: ON (WASD+Space/Shift)", 3)
    else
        if flyConn then flyConn:Disconnect() end
        local char = getCharacter()
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local g = root:FindFirstChild("PortalFly")
                if g then g:Destroy() end
                local v = root:FindFirstChild("PortalFlyVel")
                if v then v:Destroy() end
            end
        end
        notify("Portal Hub", "Fly: OFF", 2)
    end
end

-- ============================================================
-- FITUR: ESP (Wallhack)
-- ============================================================
local espConns = {}
local function createESP(obj, color, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PortalESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or obj.Name
    label.TextColor3 = color or Color3.new(1, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "PortalHighlight"
    highlight.FillColor = color or Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = obj
    
    billboard.Parent = obj
    return billboard, highlight
end

local function toggleESP(enabled)
    State.espEnabled = enabled
    if enabled then
        -- ESP untuk player lain
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    createESP(head, Color3.new(0, 1, 0), player.Name)
                end
            end
        end
        
        -- ESP untuk NPC/Mob di Workspace
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name:lower()
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                if head and obj:FindFirstChildOfClass("Humanoid") then
                    if name:match("mob") or name:match("enemy") or name:match("monster") 
                    or name:match("boss") or name:match("npc") then
                        local color = Color3.new(1, 0, 0) -- merah untuk musuh
                        if name:match("npc") then color = Color3.new(0, 0.5, 1) end -- biru untuk NPC
                        createESP(head, color, obj.Name)
                    end
                end
            end
        end
        
        notify("Portal Hub", "ESP: ON - Player(N) Mob(R) NPC(B)", 3)
    else
        -- Hapus semua ESP
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local esp = obj:FindFirstChild("PortalESP")
            if esp then esp:Destroy() end
            local hl = obj:FindFirstChild("PortalHighlight")
            if hl then hl:Destroy() end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, obj in ipairs(player.Character:GetDescendants()) do
                    if obj.Name:match("PortalESP") or obj.Name:match("PortalHighlight") then
                        obj:Destroy()
                    end
                end
            end
        end
        notify("Portal Hub", "ESP: OFF", 2)
    end
end

-- ============================================================
-- FITUR: FULLBRIGHT
-- ============================================================
local function toggleFullbright(enabled)
    State.fullbrightEnabled = enabled
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        notify("Portal Hub", "Fullbright: ON", 2)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        notify("Portal Hub", "Fullbright: OFF", 2)
    end
end

-- ============================================================
-- FITUR: TELEPORT TO LOCATION
-- ============================================================
local function teleportTo(position)
    local root = getRootPart()
    if root then
        root.CFrame = CFrame.new(position)
        notify("Portal Hub", "Teleported!", 2)
    end
end

-- ============================================================
-- FITUR: AUTO-FARM (Kill mob terdekat)
-- ============================================================
local farmConn = nil
local function toggleAutoFarm(enabled)
    State.autoFarmEnabled = enabled
    if enabled then
        farmConn = RunService.Heartbeat:Connect(function()
            local root = getRootPart()
            if not root then return end
            
            -- Cari mob terdekat
            local closest = nil
            local closestDist = State.farmRange
            
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                    local name = obj.Name:lower()
                    if name:match("mob") or name:match("enemy") or name:match("monster") 
                    or name:match("boss") or name:match("beast") then
                        local mobRoot = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                        local mobHum = obj:FindFirstChildOfClass("Humanoid")
                        if mobRoot and mobHum and mobHum.Health > 0 then
                            local dist = (mobRoot.Position - root.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = {root = mobRoot, humanoid = mobHum, model = obj}
                            end
                        end
                    end
                end
            end
            
            -- Jika ketemu, teleport & attack
            if closest then
                root.CFrame = CFrame.new(closest.root.Position + Vector3.new(0, 5, 0))
                closest.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                
                -- Coba fire semua RemoteEvent di ReplicatedStorage
                pcall(function()
                    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                        if obj:IsA("RemoteEvent") then
                            local name = obj.Name:lower()
                            if name:match("attack") or name:match("damage") 
                            or name:match("hit") or name:match("combat") then
                                obj:FireServer(closest.model)
                            end
                        end
                    end
                end)
            end
        end)
        notify("Portal Hub", "Auto-Farm: ON - Cari & kill mob otomatis", 3)
    else
        if farmConn then farmConn:Disconnect() end
        notify("Portal Hub", "Auto-Farm: OFF", 2)
    end
end

-- ============================================================
-- FITUR: AUTO-RESOURCE (Mine/Chop/Fish)
-- ============================================================
local resourceConn = nil
local function toggleAutoResource(type)
    return function(enabled)
        if type == "mine" then State.autoMineEnabled = enabled
        elseif type == "chop" then State.autoChopEnabled = enabled
        elseif type == "fish" then State.autoFishEnabled = enabled end
        
        if enabled then
            local patterns = {
                mine = {"ore", "rock", "mine", "stone", "mineral"},
                chop = {"tree", "wood", "log", "branch"},
                fish = {"fish", "fishing", "water", "pond", "river"}
            }
            local searchPatterns = patterns[type] or {}
            
            resourceConn = RunService.Heartbeat:Connect(function()
                local root = getRootPart()
                if not root then return end
                
                -- Cari resource terdekat
                local closest = nil
                local closestDist = State.farmRange
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") or obj:IsA("Part") then
                        local name = obj.Name:lower()
                        for _, pattern in ipairs(searchPatterns) do
                            if name:match(pattern) then
                                local objPart = obj:IsA("Part") and obj or obj:FindFirstChildWhichIsA("Part")
                                if objPart then
                                    local dist = (objPart.Position - root.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        closest = objPart
                                    end
                                end
                                break
                            end
                        end
                    end
                end
                
                -- Teleport ke resource & fire remotes
                if closest then
                    root.CFrame = CFrame.new(closest.Position + Vector3.new(0, 3, 0))
                    pcall(function()
                        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                            if obj:IsA("RemoteEvent") then
                                local name = obj.Name:lower()
                                if name:match(type) or name:match("gather") 
                                or name:match("collect") or name:match("harvest") then
                                    obj:FireServer(closest)
                                end
                            end
                        end
                    end)
                end
            end)
            notify("Portal Hub", "Auto-" .. type .. ": ON", 2)
        else
            if resourceConn then resourceConn:Disconnect() resourceConn = nil end
            notify("Portal Hub", "Auto-" .. type .. ": OFF", 2)
        end
    end
end

-- ============================================================
-- FITUR: SCAN & PRINT GAME STRUCTURE
-- ============================================================
local function scanAndPrint()
    notify("Portal Hub", "Scanning game structure...", 2)
    local objects, remotes = scanGameStructure()
    
    print("=== PORTAL MMORPG - GAME STRUCTURE SCAN ===")
    print("")
    print("--- OBJECTS IN WORKSPACE ---")
    for i, obj in ipairs(objects) do
        print(string.format("[%d] %s (%s) | Parent: %s | Path: %s", 
            i, obj.name, obj.className, obj.parent, obj.path))
    end
    
    print("")
    print("--- REMOTE EVENTS/FUNCTIONS ---")
    for i, r in ipairs(remotes) do
        print(string.format("[%d] %s (%s) | Path: %s", 
            i, r.name, r.type, r.path))
    end
    
    print("")
    print("=== SCAN COMPLETE ===")
    notify("Portal Hub", string.format("Scan done! %d objects, %d remotes", #objects, #remotes), 5)
end

-- ============================================================
-- BUILD GUI
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 500)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Round corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌌 THE PORTAL [MMORPG] HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Scrolling frame untuk tombol
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -55)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = ScrollFrame

-- ============================================================
-- FUNGSI BUAT TOGGLE BUTTON
-- ============================================================
local function createToggle(name, callback, defaultColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = defaultColor or Color3.fromRGB(50, 50, 65)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        else
            btn.BackgroundColor3 = defaultColor or Color3.fromRGB(50, 50, 65)
        end
        callback(state)
    end)
    
    return btn
end

-- ============================================================
-- FUNGSI BUAT ACTION BUTTON
-- ============================================================
local function createButton(name, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 100, 200)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = ScrollFrame
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================================
-- SECTIONS
-- ============================================================
local function createSection(title)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = "── " .. title .. " ──"
    label.TextColor3 = Color3.fromRGB(100, 100, 120)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = ScrollFrame
end

-- ============================================================
-- BUAT SEMUA TOMBOL
-- ============================================================

createSection("⚡ MOVEMENT")

createToggle("Speed Boost (100)", function(s) toggleSpeed(s) end)
createToggle("Jump Power (150)", function(s) toggleJump(s) end)
createToggle("Infinite Jump", function(s) toggleInfJump(s) end)
createToggle("Noclip (Walk through walls)", function(s) toggleNoclip(s) end)
createToggle("Fly (WASD+Space/Shift)", function(s) toggleFly(s) end)

createSection("👁️ VISUAL")

createToggle("ESP (See players/mobs/NPC)", function(s) toggleESP(s) end)
createToggle("Fullbright", function(s) toggleFullbright(s) end)

createSection("⚔️ COMBAT")

createToggle("Auto-Farm (Kill nearest mob)", function(s) toggleAutoFarm(s) end)

createSection("🌾 RESOURCE GATHERING")

createToggle("Auto-Mine (Ore/Rock)", toggleAutoResource("mine"))
createToggle("Auto-Chop (Trees)", toggleAutoResource("chop"))
createToggle("Auto-Fish", toggleAutoResource("fish"))

createSection("🔬 GAME INTEL")

createButton("📋 SCAN GAME STRUCTURE (Print)", function()
    scanAndPrint()
end)

createSection("🚀 TELEPORT")

createButton("📍 Teleport to Dewdrop Village (guess)", function()
    -- Cari Dewdrop Village di Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():match("dewdrop") or obj.Name:lower():match("village") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                teleportTo(part.Position + Vector3.new(0, 5, 0))
                return
            end
        end
    end
    notify("Portal Hub", "Dewdrop Village tidak ditemukan. Gunakan scan dulu!", 3)
end)

createButton("📍 Teleport to nearest NPC", function()
    local root = getRootPart()
    if not root then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():match("npc") then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                teleportTo(part.Position + Vector3.new(0, 3, 0))
                return
            end
        end
    end
    notify("Portal Hub", "NPC tidak ditemukan", 3)
end)

createButton("📍 Teleport to Spawn", function()
    local spawn = Workspace:FindFirstChild("SpawnLocation")
    if spawn then
        teleportTo(spawn.Position + Vector3.new(0, 3, 0))
    else
        notify("Portal Hub", "Spawn tidak ditemukan", 3)
    end
end)

createSection("ℹ️ GAME INFO")

createButton("📖 Show Game Info", function()
    notify("THE PORTAL [MMORPG]", "Races: Elf, Beastmen, Human", 5)
    task.wait(1)
    notify("Classes", "Warrior, Defender, Enchanter, Cleric", 5)
    task.wait(1)
    notify("Currency", "Tria (target: 1M for badge)", 5)
    task.wait(1)
    notify("Activities", "Farm, Mine, Fish, Chop, Cook, Craft, Forge, Duel", 5)
end)

-- ============================================================
-- RESPAWN HANDLER (re-apply state setelah respawn)
-- ============================================================
Players.PlayerAdded:Connect(function(plr)
    if plr == LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if State.speedEnabled then toggleSpeed(true) end
            if State.jumpEnabled then toggleJump(true) end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.speedEnabled then toggleSpeed(true) end
    if State.jumpEnabled then toggleJump(true) end
end)

-- ============================================================
-- INIT
-- ============================================================
notify("🌌 Portal Hub", "Loaded! Game: The Portal [MMORPG]", 5)
notify("Portal Hub", "Made by CodeBuddy - 15 badges detected", 4)
print("[Portal Hub] Script loaded successfully!")
print("[Portal Hub] Game: The Portal [MMORPG]")
print("[Portal Hub] Place ID: 122003435349029")
print("[Portal Hub] Universe ID: 9356969539")

-- Auto-scan saat startup
task.spawn(function()
    task.wait(3)
    print("[Portal Hub] Auto-scanning game structure...")
    scanAndPrint()
end)
