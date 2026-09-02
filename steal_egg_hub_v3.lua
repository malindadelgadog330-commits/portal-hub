-- ╔══════════════════════════════════════════════════╗
-- ║   STEAL AN EGG HUB v3.0                          ║
-- ║   Game: Steal An Egg (107778070777162)           ║
-- ║   Based on REAL game source code analysis        ║
-- ║   Features: Auto Steal, Godmode, Anti Bat/Trap  ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Hapus GUI lama
local oldGui = CoreGui:FindFirstChild("EggHubV3")
if oldGui then oldGui:Destroy() end

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local State = {
    autoSteal = false,
    autoHatch = false,
    autoSell = false,
    godmode = false,
    antiBat = false,
    antiTrap = false,
    antiAFK = false,
    speedEnabled = false,
    noclip = false,
    infJump = false,
    flyEnabled = false,
    flySpeed = 50,
    walkSpeed = 100,
    stealSpeed = 100,
    fullbright = false,
    espPlayers = false,
    espEggs = false,
}

local Runtime = { stolen = 0, failed = 0 }

-- ══════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════
local function notify(title, text, dur)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 3})
    end)
end

local function getChar() return LocalPlayer.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ══════════════════════════════════════
-- GAME MODULE RESOLUTION
-- Game ini pakai: ReplicatedStorage.Library.Client.*
-- Module: Network, EggCmds, AssetCmds, BaseUpgradeClient, ToolGameplayGuard, PlotCmds
-- ══════════════════════════════════════
local Lib, Client
local Network_m, EggCmds_m, EggState_m, AssetCmds_m, BaseUpgradeClient_m
local ToolGameplayGuard_m, PlotCmds_m, Message_m, AreaEggSlotIdentity_m
local Constants_m, NETWORK = {}

pcall(function()
    Lib = ReplicatedStorage:WaitForChild("Library", 30)
    Client = Lib and Lib:FindFirstChild("Client")
end)

local function loadModule(resolveFn)
    if not Client then return false, nil end
    local ok, result = pcall(resolveFn)
    if not ok then return false, nil end
    return true, result
end

local okNet, Network_m = loadModule(function() return require(Client.Network) end)
local okEgg, EggCmds_m = loadModule(function() return require(Client.EggCmds) end)
local okAsset, AssetCmds_m = loadModule(function() return require(Client.AssetCmds) end)
local okBase, BaseUpgradeClient_m = loadModule(function() return require(Client.BaseUpgradeClient) end)
local okGuard, ToolGameplayGuard_m = loadModule(function() return require(Client.ToolGameplayGuard) end)
local okPlot, PlotCmds_m = loadModule(function() return require(Client.PlotCmds) end)

-- EggState module (ada di PlayerScripts)
pcall(function()
    local ps = LocalPlayer:WaitForChild("PlayerScripts", 10)
    local g = ps and ps:FindFirstChild("Game")
    local pl = g and g:FindFirstChild("Plots")
    local aac = pl and pl:FindFirstChild("ActiveAssetsController")
    local m = aac and aac:FindFirstChild("AssetDnaProductResolver")
    if m then
        local ok, res = pcall(function() return require(m) end)
        if ok then AreaEggSlotIdentity_m = res end
    end
end)

-- Cari EggState di berbagai lokasi
pcall(function()
    if Client then
        local ok, res = pcall(function() return require(Client.EggState) end)
        if ok then EggState_m = res end
    end
end)

-- Constants
local Globals = Lib and Lib:FindFirstChild("Globals")
if Globals then
    local okC, res = pcall(function() return require(Globals.Constants) end)
    if okC then Constants_m = res end
end

-- Network endpoints
if Constants_m and Constants_m.NETWORK_MAP then
    NETWORK = Constants_m.NETWORK_MAP
end

-- Message module
local okMsg, Message_m = loadModule(function()
    local notif = Client:FindFirstChild("NotificationCmds")
    if notif then return require(notif.Message) end
    error("no Message")
end)

local function gameNotify(msg, color)
    if okMsg and Message_m and Message_m.Bottom then
        pcall(Message_m.Bottom, {
            Message = msg,
            Time = 2.5,
            Color = color or Color3.fromRGB(0, 212, 255),
        })
    else
        notify("Egg Hub", msg, 3)
    end
end

-- ══════════════════════════════════════
-- EGG STEAL PIPELINE (berdasarkan source code asli)
-- Flow: RequestCarryAreaEgg(Uid) -> walk to base -> server auto-claim
-- ══════════════════════════════════════

-- Get all area eggs
local function getAllAreaEggs()
    if EggState_m and EggState_m.ReadFieldEggs then
        local ok, snap = pcall(EggState_m.ReadFieldEggs)
        if ok and type(snap) == "table" and snap.Records then
            return snap.Records
        end
    end
    if okEgg and EggCmds_m and EggCmds_m.GetAreaEggSnapshot then
        local ok, snap = pcall(EggCmds_m.GetAreaEggSnapshot)
        if ok and type(snap) == "table" and snap.Records then
            return snap.Records
        end
    end
    return {}
end

-- Check if egg is own starter egg
local function isFirstAreaOwnEgg(uid)
    local owner = string.match(uid or "", "^FirstAreaEgg_(-?%d+)_")
    return owner ~= nil and tonumber(owner) == LocalPlayer.UserId
end

-- Find nearest stealable egg
local function nearestCarryableEgg(maxDistance)
    local root = getRoot()
    if not root then return nil end
    local records = getAllAreaEggs()
    if #records == 0 then return nil end
    
    local best, bestDist = nil, maxDistance or math.huge
    for _, rec in ipairs(records) do
        local stealable = rec.State == "Slot" or rec.State == "Dropped"
        if stealable and rec.BoundsCFrame and not isFirstAreaOwnEgg(rec.Uid) then
            local pos = rec.BoundsCFrame.Position or (rec.BottomCframe and rec.BottomCframe.Position)
            if pos then
                local dist = (pos - root.Position).Magnitude
                if dist < bestDist then
                    best, bestDist = rec, dist
                end
            end
        end
    end
    return best
end

-- Check if carrying egg
local function isCarrying()
    if EggState_m and EggState_m.IsCarrying then
        local ok, result = pcall(EggState_m.IsCarrying)
        if ok then return result end
    end
    -- Fallback: cek attribute
    local char = getChar()
    if char then
        return char:GetAttribute("CarryingEgg") == true
    end
    return false
end

-- Get carried egg UID
local function getCarriedUid()
    if EggState_m and EggState_m.GetCarriedUid then
        local ok, result = pcall(EggState_m.GetCarriedUid)
        if ok then return result end
    end
    return nil
end

-- Find safe zone target (belakang SeparationLine)
local function getSafeZoneTarget()
    local root = getRoot()
    if not root then return nil end
    
    -- Cari SeparationLine di workspace
    local areas = Workspace:FindFirstChild("__OBJECTS")
    areas = areas and areas:FindFirstChild("Areas")
    local sep = areas and areas:FindFirstChild("SeparationLine")
    if not sep or not sep:IsA("BasePart") then
        -- Cari di seluruh workspace
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "SeparationLine" and obj:IsA("BasePart") then
                sep = obj
                break
            end
        end
    end
    if not sep then return nil end
    
    -- Safe zone = belakang garis (sisi base)
    return sep.Position - sep.CFrame.LookVector * 10
end

-- Carry egg via game API
local function carryEgg(rec)
    if not EggState_m or not EggState_m.CarryFieldEgg then return false, "no_module" end
    
    local slotKey = nil
    if AreaEggSlotIdentity_m and AreaEggSlotIdentity_m.LooksLikeFirstAreaUid then
        local ok, key = pcall(AreaEggSlotIdentity_m.SlotKey, rec.AreaId, rec.NestId)
        if ok then slotKey = key end
    end
    
    -- Set AreaId attribute
    pcall(function() LocalPlayer:SetAttribute("AreaId", rec.AreaId) end)
    task.wait(0.2)
    
    -- Carry dengan watchdog
    local result, done = nil, false
    local th = task.spawn(function()
        local success, okBool, errMsg = pcall(EggState_m.CarryFieldEgg, rec.Uid, slotKey)
        if not success then
            result = { ok = false, err = tostring(okBool) }
        else
            result = { ok = okBool == true, err = okBool == true and nil or tostring(errMsg) }
        end
        done = true
    end)
    
    local t0 = os.clock()
    while not done and os.clock() - t0 < 10 do task.wait(0.05) end
    if not done then
        pcall(task.cancel, th)
        return false, "TIMEOUT"
    end
    
    return result.ok, result.err
end

-- Enter gameplay area (lewati gate fisik)
local function enterGameplayArea()
    local root = getRoot()
    local hum = getHum()
    if not root or not hum then return false end
    
    local areas = Workspace:FindFirstChild("__OBJECTS")
    areas = areas and areas:FindFirstChild("Areas")
    local sep = areas and areas:FindFirstChild("SeparationLine")
    if not sep then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "SeparationLine" and obj:IsA("BasePart") then
                sep = obj
                break
            end
        end
    end
    if not sep then return false end
    
    local gate = sep.Position + Vector3.new(0, 2, 0) + sep.CFrame.LookVector * 2
    local gateBack = sep.Position + Vector3.new(0, 2, 0) - sep.CFrame.LookVector * 6
    
    -- TP ke belakang gate
    root.CFrame = CFrame.lookAt(gateBack, gate)
    task.wait(0.3)
    
    -- Jalan melewati gate
    hum:MoveTo(gate)
    local t0 = os.clock()
    while os.clock() - t0 < 8 do
        task.wait(0.05)
        if (root.Position - gate).Magnitude < 3 then break end
    end
    hum:MoveTo(gate + sep.CFrame.LookVector * 5)
    task.wait(0.8)
    return true
end

-- Tween ke posisi (smooth, anti-cheat safe)
local function tweenTo(pos, speed)
    local root = getRoot()
    local hum = getHum()
    if not root or not hum then return false end
    
    local dist = (root.Position - pos).Magnitude
    if dist < 3 then return true end
    
    local time = math.clamp(dist / (speed or 50), 0.1, 30)
    local info = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = CFrame.new(pos)})
    tween:Play()
    
    local t0 = os.clock()
    while tween.PlaybackState == Enum.PlaybackState.Playing and os.clock() - t0 < time + 5 do
        task.wait(0.05)
    end
    return true
end

-- Unequip tools
local function unequipTools()
    local hum = getHum()
    if hum then pcall(hum.UnequipTools) end
end

-- ══════════════════════════════════════
-- AUTO STEAL LOOP
-- ══════════════════════════════════════
local stealThread = nil
local stealActive = false

local function startStealLoop()
    if stealActive then return end
    if not EggState_m then
        gameNotify("EggState module tidak ditemukan! Steal gagal.", Color3.fromRGB(255, 50, 50))
        return
    end
    
    stealActive = true
    stealThread = task.spawn(function()
        gameNotify("Auto Steal: Engine started!", Color3.fromRGB(77, 214, 201))
        
        while stealActive do
            local root = getRoot()
            if not root then task.wait(2) continue end
            
            if isCarrying() then
                -- Bawa egg ke safe zone
                local carriedUid = getCarriedUid()
                local sz = getSafeZoneTarget()
                if not sz then task.wait(2) continue end
                
                unequipTools()
                tweenTo(sz, State.stealSpeed)
                
                -- Tunggu claim
                local t0 = os.clock()
                while stealActive and os.clock() - t0 < 25 do
                    if not isCarrying() then break end
                    task.wait(0.1)
                end
                
                if not isCarrying() then
                    Runtime.stolen = Runtime.stolen + 1
                    gameNotify("Egg delivered! Total: " .. Runtime.stolen, Color3.fromRGB(77, 214, 201))
                else
                    -- Drop egg kalau stuck
                    if EggState_m.DropFieldEgg then
                        pcall(function() EggState_m.DropFieldEgg(nil) end)
                    end
                end
                unequipTools()
                task.wait(1)
            else
                -- Cari egg terdekat
                local target = nearestCarryableEgg(500)
                if not target then
                    task.wait(2)
                else
                    -- Tween ke egg
                    local pos = target.BoundsCframe and target.BoundsCframe.Position 
                        or (target.BottomCframe and target.BottomCframe.Position)
                    if pos then
                        tweenTo(pos, State.stealSpeed)
                        local ok, err = carryEgg(target)
                        if ok then
                            gameNotify("Egg taken: " .. tostring(target.AssetCategory or target.Uid), Color3.fromRGB(251, 191, 36))
                        else
                            -- Mungkin belum masuk gameplay area
                            if err and tostring(err):find("gameplay area") then
                                enterGameplayArea()
                                local ok2, err2 = carryEgg(target)
                                if not ok2 then
                                    Runtime.failed = Runtime.failed + 1
                                    task.wait(1)
                                end
                            else
                                Runtime.failed = Runtime.failed + 1
                                task.wait(1)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopStealLoop()
    stealActive = false
    if stealThread then
        pcall(task.cancel, stealThread)
    end
    gameNotify("Auto Steal: Stopped", Color3.fromRGB(255, 100, 100))
end

-- ══════════════════════════════════════
-- AUTO HATCH
-- ══════════════════════════════════════
local hatchThread = nil
local function toggleAutoHatch(en)
    State.autoHatch = en
    if en then
        hatchThread = task.spawn(function()
            while State.autoHatch do
                if EggCmds_m and EggCmds_m.HatchEgg then
                    pcall(EggCmds_m.HatchEgg)
                elseif EggState_m and EggState_m.HatchEgg then
                    pcall(EggState_m.HatchEgg)
                end
                task.wait(0.5)
            end
        end)
        gameNotify("Auto Hatch: ON", Color3.fromRGB(77, 214, 201))
    else
        if hatchThread then pcall(task.cancel, hatchThread) end
        gameNotify("Auto Hatch: OFF")
    end
end

-- ══════════════════════════════════════
-- AUTO SELL
-- ══════════════════════════════════════
local sellThread = nil
local function toggleAutoSell(en)
    State.autoSell = en
    if en then
        sellThread = task.spawn(function()
            while State.autoSell do
                if AssetCmds_m and AssetCmds_m.Sell then
                    pcall(AssetCmds_m.Sell)
                elseif EggCmds_m and EggCmds_m.Sell then
                    pcall(EggCmds_m.Sell)
                end
                task.wait(1)
            end
        end)
        gameNotify("Auto Sell: ON", Color3.fromRGB(77, 214, 201))
    else
        if sellThread then pcall(task.cancel, sellThread) end
        gameNotify("Auto Sell: OFF")
    end
end

-- ══════════════════════════════════════
-- GODMODE (Kebal dari damage player/guard)
-- ══════════════════════════════════════
local godConn = nil
local function toggleGodmode(en)
    State.godmode = en
    if en then
        -- Set health ke max terus
        godConn = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    if h.Health < h.MaxHealth then
                        h.Health = h.MaxHealth
                    end
                    -- Set max health tinggi
                    pcall(function()
                        if h.MaxHealth < 9999 then
                            h.MaxHealth = 9999
                            h.Health = 9999
                        end
                    end)
                end
            end
        end)
        gameNotify("Godmode: ON - Kebal!", Color3.fromRGB(77, 214, 201))
    else
        if godConn then godConn:Disconnect() end
        local h = getHum()
        if h then
            pcall(function() h.MaxHealth = 100 h.Health = 100 end)
        end
        gameNotify("Godmode: OFF")
    end
end

-- ══════════════════════════════════════
-- ANTI BAT (Anti dipukul/lempar player lain)
-- ══════════════════════════════════════
local antiBatConn = nil
local function toggleAntiBat(en)
    State.antiBat = en
    if en then
        antiBatConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local h = getHum()
            if not root or not h then return end
            
            -- Reset health kalau dipukul
            if h.Health < h.MaxHealth then
                h.Health = h.MaxHealth
            end
            
            -- Deteksi player lain pegang tool dekat lo
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local ph = p.Character:FindFirstChild("HumanoidRootPart")
                        if ph then
                            local d = (ph.Position - root.Position).Magnitude
                            if d < 15 then
                                -- TP pergi dari player yang pegang bat
                                root.CFrame = root.CFrame + Vector3.new(0, 30, 0)
                            end
                        end
                    end
                end
            end
            
            -- Cek BodyVelocity yang dipasang oleh bat
            for _, obj in ipairs(getChar():GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") then
                    local name = obj.Name:lower()
                    if not name:match("egg") and not name:match("fly") then
                        obj:Destroy()
                    end
                end
            end
        end)
        gameNotify("Anti Bat: ON - Kebal pukul!", Color3.fromRGB(77, 214, 201))
    else
        if antiBatConn then antiBatConn:Disconnect() end
        gameNotify("Anti Bat: OFF")
    end
end

-- ══════════════════════════════════════
-- ANTI TRAP (Anti di-kunci/freeze)
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
            
            -- Cek kalau di-freeze (velocity 0 tapi mau gerak)
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude < 0.1 and h.MoveDirection.Magnitude > 0.1 then
                -- Unfreeze
                pcall(function() h.PlatformStand = false end)
                pcall(function() h.Sit = false end)
                pcall(function() root.Anchored = false end)
                
                -- Hapus BodyPosition/Velocity trap
                for _, obj in ipairs(c:GetDescendants()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition")
                    or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") then
                        local name = obj.Name:lower()
                        if not name:match("egg") and not name:match("fly") then
                            obj:Destroy()
                        end
                    end
                end
                
                -- TP ke atas untuk escape
                root.CFrame = root.CFrame * CFrame.new(0, 5, 0)
            end
            
            -- Hapus Weld/Constraint trap
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
                    local name = obj.Name:lower()
                    if name:match("trap") or name:match("grab") or name:match("lock") or name:match("freeze") then
                        obj:Destroy()
                    end
                end
            end
        end)
        gameNotify("Anti Trap: ON - Anti di-kunci!", Color3.fromRGB(77, 214, 201))
    else
        if antiTrapConn then antiTrapConn:Disconnect() end
        gameNotify("Anti Trap: OFF")
    end
end

-- ══════════════════════════════════════
-- ANTI AFK
-- ══════════════════════════════════════
local afkConn = nil
local function toggleAntiAFK(en)
    State.antiAFK = en
    if en then
        afkConn = task.spawn(function()
            while State.antiAFK do
                local h = getHum()
                if h then
                    -- Pulse gerakan subtle
                    pcall(function()
                        local root = getRoot()
                        if root then
                            root.CFrame = root.CFrame * CFrame.new(0.001, 0, 0.001)
                        end
                    end)
                end
                task.wait(30)
            end
        end)
        gameNotify("Anti AFK: ON")
    else
        if afkConn then pcall(task.cancel, afkConn) end
        gameNotify("Anti AFK: OFF")
    end
end

-- ══════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════
local function toggleSpeed(en)
    State.speedEnabled = en
    local h = getHum()
    if h then
        if en then h.WalkSpeed = State.walkSpeed else h.WalkSpeed = 16 end
    end
end

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
        gameNotify("Fly: ON (WASD+Space/Shift)")
    else
        if flyConn then flyConn:Disconnect() end
        local g = root:FindFirstChild("EggFly") if g then g:Destroy() end
        local v = root:FindFirstChild("EggFlyVel") if v then v:Destroy() end
        gameNotify("Fly: OFF")
    end
end

-- ══════════════════════════════════════
-- FULLBRIGHT
-- ══════════════════════════════════════
local Lighting = game:GetService("Lighting")
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
-- ESP
-- ══════════════════════════════════════
local function toggleESPplayers(en)
    State.espPlayers = en
    if en then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("PESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "PESP"
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
                local e = p.Character:FindFirstChild("PESP")
                if e then e:Destroy() end
            end
        end
    end
end

-- ESP Eggs - highlight egg di workspace
local function toggleESPeggs(en)
    State.espEggs = en
    if en then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:match("egg") and obj:IsA("Model") then
                if not obj:FindFirstChild("EESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "EESP"
                    hl.FillColor = Color3.new(1, 0.8, 0)
                    hl.FillTransparency = 0.3
                    hl.Parent = obj
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local e = obj:FindFirstChild("EESP")
            if e then e:Destroy() end
        end
    end
end

-- ══════════════════════════════════════
-- SCAN GAME
-- ══════════════════════════════════════
local function scanGame()
    gameNotify("Scanning game structure...", Color3.fromRGB(255, 200, 0))
    print("=== STEAL AN EGG SCAN ===")
    
    print("\n--- GAME MODULES ---")
    print("Network:", okNet and "FOUND" or "MISSING")
    print("EggCmds:", okEgg and "FOUND" or "MISSING")
    print("EggState:", EggState_m and "FOUND" or "MISSING")
    print("AssetCmds:", okAsset and "FOUND" or "MISSING")
    print("BaseUpgrade:", okBase and "FOUND" or "MISSING")
    print("ToolGameplayGuard:", okGuard and "FOUND" or "MISSING")
    print("PlotCmds:", okPlot and "FOUND" or "MISSING")
    
    print("\n--- EGGSTATE FUNCTIONS ---")
    if EggState_m then
        for k, v in pairs(EggState_m) do
            print("  " .. tostring(k) .. ": " .. type(v))
        end
    end
    
    print("\n--- EGGCMDS FUNCTIONS ---")
    if EggCmds_m then
        for k, v in pairs(EggCmds_m) do
            print("  " .. tostring(k) .. ": " .. type(v))
        end
    end
    
    print("\n--- AREA EGGS ---")
    local eggs = getAllAreaEggs()
    print("Total eggs: " .. #eggs)
    for i, rec in ipairs(eggs) do
        if i > 10 then break end
        print(string.format("  [%d] Uid=%s State=%s Cat=%s", i, tostring(rec.Uid), tostring(rec.State), tostring(rec.AssetCategory)))
    end
    
    print("\n--- SEPARATION LINE ---")
    local sep = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "SeparationLine" then
            sep = obj
            print("  Found: " .. obj:GetFullName())
            break
        end
    end
    if not sep then print("  SeparationLine NOT FOUND") end
    
    print("\n=== SCAN DONE ===")
    gameNotify("Scan done! Check F9 console", Color3.fromRGB(77, 214, 201), 5)
end

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggHubV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 540)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
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
Title.Text = "🥚 STEAL AN EGG HUB v3.0"
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
CloseBtn.MouseButton1Click:Connect(function() 
    stopStealLoop()
    ScreenGui:Destroy() 
end)

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
createToggle("💤 Anti AFK", function(s) toggleAntiAFK(s) end)

createSection("🥚 AUTO STEAL EGG")
createToggle("🥚 Auto Steal (Ambil egg -> bawa ke base)", function(s)
    if s then startStealLoop() else stopStealLoop() end
end)
createSlider("Steal Speed", 10, 300, 100, function(v) State.stealSpeed = v end)

createSection("🐣 EGG AUTO")
createToggle("Auto Hatch", function(s) toggleAutoHatch(s) end)
createToggle("Auto Sell", function(s) toggleAutoSell(s) end)

createSection("⚡ MOVEMENT")
createSlider("Walk Speed", 16, 500, 100, function(v)
    State.walkSpeed = v
    if State.speedEnabled then
        local h = getHum() if h then h.WalkSpeed = v end
    end
end)
createToggle("Speed Boost", function(s) toggleSpeed(s) end)
createToggle("Noclip", function(s) toggleNoclip(s) end)
createToggle("Infinite Jump", function(s) toggleInfJump(s) end)
createToggle("Fly (WASD+Space/Shift)", function(s) toggleFly(s) end)
createSlider("Fly Speed", 10, 300, 50, function(v) State.flySpeed = v end)

createSection("👁️ VISUAL")
createToggle("ESP Players", function(s) toggleESPplayers(s) end)
createToggle("ESP Eggs", function(s) toggleESPeggs(s) end)
createToggle("Fullbright", function(s) toggleFullbright(s) end)

createSection("🔧 TOOLS")
createButton("📋 SCAN GAME STRUCTURE", Color3.fromRGB(200, 100, 50), function() scanGame() end)
createButton("🏠 TP to Base (Safe Zone)", Color3.fromRGB(100, 150, 200), function()
    local sz = getSafeZoneTarget()
    if sz then
        local root = getRoot()
        if root then root.CFrame = CFrame.new(sz) end
    end
end)
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
            pcall(function() h.MaxHealth = 9999 h.Health = 9999 end)
        end
    end
end)

-- Init
gameNotify("Egg Hub v3.0 Loaded! RightCtrl to toggle", Color3.fromRGB(77, 214, 201), 5)
print("[Egg Hub v3] Script loaded!")
print("[Egg Hub v3] Game: Steal An Egg")
print("[Egg Hub v3] Place ID: 107778070777162")
print("[Egg Hub v3] Modules:")
print("  Network:", okNet)
print("  EggCmds:", okEgg)
print("  EggState:", EggState_m ~= nil)
print("  AssetCmds:", okAsset)
print("  BaseUpgrade:", okBase)
print("  ToolGuard:", okGuard)
print("  PlotCmds:", okPlot)

-- Auto scan 3 detik setelah load
task.spawn(function()
    task.wait(3)
    scanGame()
end)
