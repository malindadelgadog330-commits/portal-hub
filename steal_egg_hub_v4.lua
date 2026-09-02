-- ╔══════════════════════════════════════════════════╗
-- ║   STEAL AN EGG HUB v4.0                          ║
-- ║   Game: Steal An Egg (107778070777162)           ║
-- ║   Rarity Targeting + Auto Steal Secret + Anti Guard ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local oldGui = CoreGui:FindFirstChild("EggHubV4")
if oldGui then oldGui:Destroy() end

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local State = {
    autoSteal = false,
    autoHatch = false,
    autoSell = false,
    autoTreadmill = false,
    autoUpgradeBase = false,
    godmode = false,
    antiBat = false,
    antiTrap = false,
    antiGuard = false,
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
    -- Rarity targeting
    targetRarity = "All",
    stealMethod = "Instant",
    stealDelay = 0.35,
    -- Runtime
    stolen = 0,
    failed = 0,
}

-- ══════════════════════════════════════
-- RARITY DATA (dari source code asli game)
-- ══════════════════════════════════════
local Rarities = {
    "All", "BrainrotGod", "Secret", "Divine", "Cosmic", "Eternal",
    "Mythic", "Legendary", "Epic", "Rare", "Superior", "Uncommon", "Common", "Basic"
}

local RarityColors = {
    BrainrotGod = Color3.fromRGB(255, 0, 128),
    Secret      = Color3.fromRGB(0, 255, 255),
    Divine      = Color3.fromRGB(255, 215, 0),
    Cosmic      = Color3.fromRGB(168, 85, 247),
    Eternal     = Color3.fromRGB(255, 75, 75),
    Mythic      = Color3.fromRGB(244, 63, 94),
    Legendary   = Color3.fromRGB(245, 158, 11),
    Epic        = Color3.fromRGB(139, 92, 246),
    Rare        = Color3.fromRGB(59, 130, 246),
    Superior    = Color3.fromRGB(16, 185, 129),
    Uncommon    = Color3.fromRGB(34, 197, 94),
    Common      = Color3.fromRGB(200, 200, 200),
    Basic       = Color3.fromRGB(160, 160, 160),
}

local EggTypes = {
    "Starter Egg", "Forest Egg", "Desert Egg", "Ocean Egg",
    "Volcano Egg", "Cyber Egg", "Mythic Egg", "Void Egg", "Limited Egg"
}

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
-- NETWORK REMOTE RESOLVER
-- ══════════════════════════════════════
local function getNetwork()
    return ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage
end

local function getRemote(name)
    local net = getNetwork()
    local item = net:FindFirstChild(name)
    if not item then
        item = ReplicatedStorage:FindFirstChild(name, true)
    end
    return item
end

local function fireRemote(name, ...)
    local r = getRemote(name)
    if r and r:IsA("RemoteEvent") then
        pcall(function(...) r:FireServer(...) end, ...)
        return true
    end
    return false
end

local function invokeRemote(name, ...)
    local rf = getRemote(name)
    if rf and rf:IsA("RemoteFunction") then
        local res = nil
        local ok = pcall(function(...) res = rf:InvokeServer(...) end, ...)
        if ok then return res end
    end
    return nil
end

-- ══════════════════════════════════════
-- TELEPORT
-- ══════════════════════════════════════
local function teleportTo(targetCFrame, useTween, speed)
    local root = getRoot()
    if not root then return end
    if useTween then
        local distance = (root.Position - targetCFrame.Position).Magnitude
        local duration = math.clamp(distance / (speed or 45), 0.15, 4)
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        tween:Play()
        tween.Completed:Wait()
    else
        root.CFrame = targetCFrame
    end
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
    pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 0)
        elseif typeof(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end)
    return true
end

-- ══════════════════════════════════════
-- PLOT DETECTION
-- ══════════════════════════════════════
local function getLocalPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
    if not plotsFolder then return nil end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local owner = plot:GetAttribute("Owner") or plot:GetAttribute("PlayerId")
        if owner == LocalPlayer.UserId or owner == LocalPlayer.Name then
            return plot
        end
        -- Cek sign
        local sign = plot:FindFirstChild("Sign") or plot:FindFirstChild("OwnerSign")
        if sign then
            local text = sign:GetAttribute("Text") or ""
            if text:find(LocalPlayer.Name) then return plot end
        end
    end
    return nil
end

local function getEnemyPlots()
    local results = {}
    local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
    if not plotsFolder then return results end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local owner = plot:GetAttribute("Owner") or plot:GetAttribute("PlayerId")
        if owner ~= LocalPlayer.UserId and owner ~= LocalPlayer.Name then
            table.insert(results, {
                Model = plot,
                Owner = owner
            })
        end
    end
    return results
end

local function getDepositZone()
    local plot = getLocalPlot()
    if plot then
        for _, obj in ipairs(plot:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("deposit") or n:find("drop") or n:find("claim") or n:find("collection") then
                if obj:IsA("BasePart") then
                    return obj.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end
    -- Fallback: TP ke spawn
    local spawn = Workspace:FindFirstChild("SpawnLocation")
    if spawn then return spawn.CFrame + Vector3.new(0, 5, 0) end
    return nil
end

-- ══════════════════════════════════════
-- SCAN STEAL TARGETS (dari source code asli)
-- ══════════════════════════════════════
local function scanStealTargets(filterRarity)
    local results = {}
    local root = getRoot()
    if not root then return results end
    
    -- 1. Scan enemy plots (egg/pet di base player lain)
    local enemyPlots = getEnemyPlots()
    for _, pData in ipairs(enemyPlots) do
        local plot = pData.Model
        for _, obj in ipairs(plot:GetDescendants()) do
            local isTarget = false
            local rarity = obj:GetAttribute("Rarity") or obj:GetAttribute("AssetRarity") or "Common"
            local name = obj.Name
            
            if obj:GetAttribute("IsEgg") or obj:GetAttribute("IsAnimal") or obj:GetAttribute("AssetId")
            or name:lower():find("egg") or name:lower():find("animal") or obj:FindFirstChild("ProximityPrompt") then
                isTarget = true
            end
            
            if isTarget then
                if not filterRarity or filterRarity == "All" 
                or rarity:lower() == filterRarity:lower() 
                or name:lower():find(filterRarity:lower()) then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if part then
                        table.insert(results, {
                            Model = obj,
                            Part = part,
                            Prompt = prompt,
                            Rarity = rarity,
                            Name = name,
                            Owner = pData.Owner,
                            IsAreaEgg = false,
                        })
                    end
                end
            end
        end
    end
    
    -- 2. Scan AreaEggs (egg di map, bisa di-steal langsung)
    local areaEggsFolder = Workspace:FindFirstChild("AreaEggs") 
        or Workspace:FindFirstChild("SpawnedEggs") 
        or Workspace:FindFirstChild("Eggs")
    if areaEggsFolder then
        for _, egg in ipairs(areaEggsFolder:GetChildren()) do
            local rarity = egg:GetAttribute("Rarity") or "Common"
            if not filterRarity or filterRarity == "All" or rarity:lower() == filterRarity:lower() then
                local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart", true)
                local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                if part then
                    table.insert(results, {
                        Model = egg,
                        Part = part,
                        Prompt = prompt,
                        Rarity = rarity,
                        Name = egg.Name,
                        IsAreaEgg = true,
                    })
                end
            end
        end
    end
    
    return results
end

-- ══════════════════════════════════════
-- AUTO STEAL (targeting + steal + bawa ke base)
-- ══════════════════════════════════════
local stealThread = nil
local stealActive = false

local function startStealLoop()
    if stealActive then return end
    stealActive = true
    
    stealThread = task.spawn(function()
        notify("Auto Steal", "Engine started! Target: " .. State.targetRarity, 3)
        
        while stealActive do
            local root = getRoot()
            if not root then task.wait(2) continue end
            
            local targets = scanStealTargets(State.targetRarity)
            
            if #targets > 0 then
                -- Sort by distance (terdekat dulu)
                table.sort(targets, function(a, b)
                    if a.Part and b.Part then
                        return (root.Position - a.Part.Position).Magnitude < (root.Position - b.Part.Position).Magnitude
                    end
                    return false
                end)
                
                local target = targets[1]
                if target and target.Part then
                    -- A. Remote Steal Request (instant steal via remote)
                    invokeRemote("ActiveAssets: RequestStealTarget", target.Model or target.Part)
                    fireRemote("ActiveAssets: StealTargetEvent", target.Model or target.Part)
                    
                    -- B. Skip steal animation
                    invokeRemote("ActiveAssets: RequestDnaStealAnimationComplete", target.Model or target.Part)
                    
                    -- C. Kalau area egg → carry + drop ke base
                    if target.IsAreaEgg or (target.Model and target.Model:GetAttribute("IsAreaEgg")) then
                        invokeRemote("Eggs: RequestAreaEggCarry", target.Model)
                        task.wait(0.1)
                        
                        -- TP ke deposit zone (base kita)
                        local depositCF = getDepositZone()
                        if depositCF then
                            teleportTo(depositCF, State.stealMethod == "Tween", State.stealSpeed)
                            task.wait(0.15)
                            -- Drop egg di base
                            invokeRemote("Eggs: RequestAreaEggDrop")
                            fireRemote("Guards: ForestDeposit")
                            State.stolen = State.stolen + 1
                            notify("Steal Success", target.Rarity .. " egg stolen! Total: " .. State.stolen, 2)
                        end
                    else
                        -- D. Steal dari enemy plot → TP ke egg → trigger prompt
                        if target.Prompt then
                            teleportTo(target.Part.CFrame + Vector3.new(0, 2, 0), State.stealMethod == "Tween", State.stealSpeed)
                            task.wait(0.15)
                            triggerPrompt(target.Prompt)
                        end
                        
                        -- E. Bawa ke base
                        local depositCF = getDepositZone()
                        if depositCF then
                            teleportTo(depositCF, State.stealMethod == "Tween", State.stealSpeed)
                            task.wait(0.15)
                            invokeRemote("Eggs: RequestAreaEggDrop")
                            fireRemote("Guards: ForestDeposit")
                            State.stolen = State.stolen + 1
                            notify("Steal Success", target.Rarity .. " stolen! Total: " .. State.stolen, 2)
                        end
                    end
                end
            else
                -- Ga ada target, tunggu
                task.wait(1.5)
            end
            
            task.wait(State.stealDelay)
        end
    end)
end

local function stopStealLoop()
    stealActive = false
    if stealThread then pcall(task.cancel, stealThread) end
    notify("Auto Steal", "Stopped", 2)
end

-- ══════════════════════════════════════
-- AUTO HATCH (instant)
-- ══════════════════════════════════════
local hatchThread = nil
local function toggleAutoHatch(en)
    State.autoHatch = en
    if en then
        hatchThread = task.spawn(function()
            while State.autoHatch do
                invokeRemote("Eggs: RequestSkipGrowth")
                invokeRemote("Eggs: RequestHatchEgg", "Starter Egg", 1)
                invokeRemote("Eggs: RequestCompleteHatchEgg", "Starter Egg")
                invokeRemote("Eggs: RequestPlaceEgg")
                task.wait(0.5)
            end
        end)
        notify("Egg Hub", "Auto Hatch: ON", 3)
    else
        if hatchThread then pcall(task.cancel, hatchThread) end
        notify("Egg Hub", "Auto Hatch: OFF", 2)
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
                fireRemote("AssetInventory: SellAllAssets")
                task.wait(2)
            end
        end)
        notify("Egg Hub", "Auto Sell: ON", 3)
    else
        if sellThread then pcall(task.cancel, sellThread) end
        notify("Egg Hub", "Auto Sell: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO TREADMILL
-- ══════════════════════════════════════
local treadmillThread = nil
local function toggleAutoTreadmill(en)
    State.autoTreadmill = en
    if en then
        treadmillThread = task.spawn(function()
            while State.autoTreadmill do
                fireRemote("Treadmills: SpeedGain", 1)
                invokeRemote("Treadmills: RequestUpgrade")
                invokeRemote("Treadmills: RequestEquipStatic")
                task.wait(0.15)
            end
        end)
        notify("Egg Hub", "Auto Treadmill: ON", 3)
    else
        if treadmillThread then pcall(task.cancel, treadmillThread) end
        notify("Egg Hub", "Auto Treadmill: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- AUTO UPGRADE BASE
-- ══════════════════════════════════════
local upgradeThread = nil
local function toggleAutoUpgradeBase(en)
    State.autoUpgradeBase = en
    if en then
        upgradeThread = task.spawn(function()
            while State.autoUpgradeBase do
                fireRemote("Plots: RequestBaseUpgrade", "All")
                invokeRemote("Backpack: EquipBest")
                task.wait(2)
            end
        end)
        notify("Egg Hub", "Auto Upgrade Base: ON", 3)
    else
        if upgradeThread then pcall(task.cancel, upgradeThread) end
        notify("Egg Hub", "Auto Upgrade Base: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- GODMODE
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
                    if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                    pcall(function()
                        if h.MaxHealth < 9999 then h.MaxHealth = 9999 h.Health = 9999 end
                    end)
                end
            end
        end)
        notify("Egg Hub", "Godmode: ON - Kebal!", 3)
    else
        if godConn then godConn:Disconnect() end
        local h = getHum()
        if h then pcall(function() h.MaxHealth = 100 h.Health = 100 end) end
        notify("Egg Hub", "Godmode: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ANTI BAT (anti dipukul player)
-- ══════════════════════════════════════
local antiBatConn = nil
local function toggleAntiBat(en)
    State.antiBat = en
    if en then
        antiBatConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local h = getHum()
            if not root or not h then return end
            if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local tool = p.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local ph = p.Character:FindFirstChild("HumanoidRootPart")
                        if ph then
                            local d = (ph.Position - root.Position).Magnitude
                            if d < 15 then
                                root.CFrame = root.CFrame + Vector3.new(0, 30, 0)
                            end
                        end
                    end
                end
            end
            for _, obj in ipairs(getChar():GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") then
                    local n = obj.Name:lower()
                    if not n:match("egg") and not n:match("fly") then obj:Destroy() end
                end
            end
        end)
        notify("Egg Hub", "Anti Bat: ON", 3)
    else
        if antiBatConn then antiBatConn:Disconnect() end
        notify("Egg Hub", "Anti Bat: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ANTI TRAP
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
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude < 0.1 and h.MoveDirection.Magnitude > 0.1 then
                pcall(function() h.PlatformStand = false h.Sit = false root.Anchored = false end)
                for _, obj in ipairs(c:GetDescendants()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") then
                        local n = obj.Name:lower()
                        if not n:match("egg") and not n:match("fly") then obj:Destroy() end
                    end
                end
                root.CFrame = root.CFrame * CFrame.new(0, 5, 0)
            end
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("Weld") or obj:IsA("WeldConstraint") then
                    local n = obj.Name:lower()
                    if n:match("trap") or n:match("grab") or n:match("lock") or n:match("freeze") then obj:Destroy() end
                end
            end
        end)
        notify("Egg Hub", "Anti Trap: ON", 3)
    else
        if antiTrapConn then antiTrapConn:Disconnect() end
        notify("Egg Hub", "Anti Trap: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- ANTI GUARD (anti penjaga/npc yang usir lo)
-- ══════════════════════════════════════
local antiGuardConn = nil
local function toggleAntiGuard(en)
    State.antiGuard = en
    if en then
        antiGuardConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local h = getHum()
            if not root or not h then return end
            
            -- Cari NPC/Guard di dekat lo
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= getChar() then
                    local n = obj.Name:lower()
                    if n:match("guard") or n:match("npc") or n:match("keeper") or n:match("warden") or n:match("protector") then
                        local gp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        if gp then
                            local d = (gp.Position - root.Position).Magnitude
                            if d < 25 then
                                -- Guard dekat! TP pergi
                                root.CFrame = root.CFrame + Vector3.new(0, 50, 0)
                                -- Reset health kalau kena
                                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                            end
                        end
                    end
                end
            end
        end)
        notify("Egg Hub", "Anti Guard: ON - Anti penjaga!", 3)
    else
        if antiGuardConn then antiGuardConn:Disconnect() end
        notify("Egg Hub", "Anti Guard: OFF", 2)
    end
end

-- ══════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════
local function toggleSpeed(en)
    State.speedEnabled = en
    local h = getHum()
    if h then if en then h.WalkSpeed = State.walkSpeed else h.WalkSpeed = 16 end end
end

local noclipConn = nil
local function toggleNoclip(en)
    State.noclip = en
    if en then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
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
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
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
        Lighting.Brightness = 3 Lighting.ClockTime = 12 Lighting.FogEnd = 100000 Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1 Lighting.ClockTime = 14 Lighting.GlobalShadows = true
    end
end

-- ══════════════════════════════════════
-- ESP EGGS (dengan rarity color)
-- ══════════════════════════════════════
local function toggleESPeggs(en)
    State.espEggs = en
    if en then
        -- Scan area eggs
        local areaEggsFolder = Workspace:FindFirstChild("AreaEggs") or Workspace:FindFirstChild("SpawnedEggs") or Workspace:FindFirstChild("Eggs")
        if areaEggsFolder then
            for _, egg in ipairs(areaEggsFolder:GetChildren()) do
                local rarity = egg:GetAttribute("Rarity") or "Common"
                local color = RarityColors[rarity] or Color3.new(1, 1, 1)
                if not egg:FindFirstChild("EESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "EESP"
                    hl.FillColor = color
                    hl.FillTransparency = 0.3
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.Parent = egg
                    
                    local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "EESP"
                        bb.Size = UDim2.new(0, 200, 0, 40)
                        bb.AlwaysOnTop = true
                        bb.MaxDistance = 1000
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1, 0, 1, 0)
                        l.BackgroundTransparency = 1
                        l.Text = rarity .. " | " .. egg.Name
                        l.TextColor3 = color
                        l.TextScaled = true
                        l.Font = Enum.Font.GothamBold
                        l.Parent = bb
                        bb.Parent = part
                    end
                end
            end
        end
        -- Scan enemy plots
        for _, pData in ipairs(getEnemyPlots()) do
            for _, obj in ipairs(pData.Model:GetDescendants()) do
                if obj:GetAttribute("IsEgg") or obj:GetAttribute("IsAnimal") then
                    local rarity = obj:GetAttribute("Rarity") or obj:GetAttribute("AssetRarity") or "Common"
                    local color = RarityColors[rarity] or Color3.new(1, 1, 1)
                    if not obj:FindFirstChild("EESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EESP"
                        hl.FillColor = color
                        hl.FillTransparency = 0.3
                        hl.Parent = obj
                    end
                end
            end
        end
        notify("Egg Hub", "ESP Eggs: ON (with rarity colors!)", 3)
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local e = obj:FindFirstChild("EESP")
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
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("PESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "PESP"
                    hl.FillColor = Color3.new(1, 0, 0)
                    hl.FillTransparency = 0.5
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

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggHubV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 580)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -290)
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
Title.Text = "🥚 STEAL AN EGG HUB v4.0"
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
CloseBtn.MouseButton1Click:Connect(function() stopStealLoop() ScreenGui:Destroy() end)

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
    local st = false
    btn.MouseButton1Click:Connect(function()
        st = not st
        btn.BackgroundColor3 = st and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(50, 50, 65)
        callback(st)
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
    l.Size = UDim2.new(0.6, 0, 0, 20) l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.Font = Enum.Font.Gotham l.TextSize = 13 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.35, 0, 0, 20) v.Position = UDim2.new(0.63, 0, 0, 2)
    v.BackgroundTransparency = 1 v.Text = tostring(default) v.TextColor3 = Color3.fromRGB(100, 200, 255)
    v.Font = Enum.Font.GothamBold v.TextSize = 13 v.TextXAlignment = Enum.TextXAlignment.Right v.Parent = f
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.88, 0, 0, 6) bar.Position = UDim2.new(0.06, 0, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60) bar.BorderSizePixel = 0 bar.Parent = f
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255) fill.BorderSizePixel = 0 fill.Parent = bar
    local dragging = false local val = default
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            local x = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * x)
            fill.Size = UDim2.new(x, 0, 1, 0) v.Text = tostring(val) callback(val)
        end
    end)
end

local function createDropdown(name, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 35)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    f.BorderSizePixel = 0
    f.Parent = Scroll
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = f
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.4, 0, 1, 0) l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.Font = Enum.Font.Gotham l.TextSize = 13 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.55, 0, 0, 25) btn.Position = UDim2.new(0.42, 0, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65) btn.Text = default or options[1]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.Font = Enum.Font.GothamBold btn.TextSize = 12 btn.Parent = f
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn
    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)
end

-- ══════════════════════════════════════
-- GUI CONTENT
-- ══════════════════════════════════════

createSection("🥚 AUTO STEAL (RARITY TARGETING)")
createDropdown("🎯 Target Rarity", Rarities, "All", function(v)
    State.targetRarity = v
    notify("Target", "Rarity: " .. v, 2)
end)
createDropdown("🚀 Steal Method", {"Instant", "Tween"}, "Instant", function(v)
    State.stealMethod = v
end)
createToggle("🥚 Auto Steal (scan → steal → bawa ke base)", function(s)
    if s then startStealLoop() else stopStealLoop() end
end)
createSlider("Steal Speed", 10, 300, 100, function(v) State.stealSpeed = v end)
createSlider("Steal Delay", 0.1, 5, 0.35, function(v) State.stealDelay = v end)

createSection("🛡️ KEBAL / ANTI")
createToggle("🛡️ Godmode (Kebal Total)", function(s) toggleGodmode(s) end)
createToggle("🏏 Anti Bat (Anti dipukul player)", function(s) toggleAntiBat(s) end)
createToggle("🔒 Anti Trap (Anti di-kunci)", function(s) toggleAntiTrap(s) end)
createToggle("👮 Anti Guard (Anti penjaga NPC)", function(s) toggleAntiGuard(s) end)
createToggle("💤 Anti AFK", function(s)
    State.antiAFK = s
    if s then
        task.spawn(function()
            while State.antiAFK do
                local root = getRoot()
                if root then root.CFrame = root.CFrame * CFrame.new(0.001, 0, 0.001) end
                task.wait(30)
            end
        end)
    end
end)

createSection("🐣 EGG AUTO")
createToggle("Auto Hatch + Place", function(s) toggleAutoHatch(s) end)
createToggle("Auto Sell (Sell All)", function(s) toggleAutoSell(s) end)

createSection("🏃 TRAINING & BASE")
createToggle("Auto Treadmill (Speed + Upgrade)", function(s) toggleAutoTreadmill(s) end)
createToggle("Auto Upgrade Base + Equip Best", function(s) toggleAutoUpgradeBase(s) end)

createSection("⚡ MOVEMENT")
createSlider("Walk Speed", 16, 500, 100, function(v)
    State.walkSpeed = v
    if State.speedEnabled then local h = getHum() if h then h.WalkSpeed = v end end
end)
createToggle("Speed Boost", function(s) toggleSpeed(s) end)
createToggle("Noclip", function(s) toggleNoclip(s) end)
createToggle("Infinite Jump", function(s) toggleInfJump(s) end)
createToggle("Fly (WASD+Space/Shift)", function(s) toggleFly(s) end)
createSlider("Fly Speed", 10, 300, 50, function(v) State.flySpeed = v end)

createSection("👁️ VISUAL")
createToggle("ESP Eggs (with rarity colors)", function(s) toggleESPeggs(s) end)
createToggle("ESP Players", function(s) toggleESPplayers(s) end)
createToggle("Fullbright", function(s) toggleFullbright(s) end)

createSection("🔧 TOOLS")
createButton("📋 SCAN TARGETS", Color3.fromRGB(200, 100, 50), function()
    local targets = scanStealTargets(State.targetRarity)
    notify("Scan", "Found " .. #targets .. " targets (" .. State.targetRarity .. ")", 5)
    for i, t in ipairs(targets) do
        if i > 10 then break end
        print(string.format("[EggHub] %d: %s | Rarity: %s | AreaEgg: %s", i, t.Name, t.Rarity, tostring(t.IsAreaEgg)))
    end
end)
createButton("🏠 TP to Base", Color3.fromRGB(100, 150, 200), function()
    local cf = getDepositZone()
    if cf then teleportTo(cf, false) end
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
        if h then pcall(function() h.MaxHealth = 9999 h.Health = 9999 end) end
    end
end)

-- Init
notify("🥚 Egg Hub v4", "Loaded! RightCtrl to toggle", 5)
print("[Egg Hub v4] Loaded! Game: Steal An Egg")
print("[Egg Hub v4] Rarities: " .. table.concat(Rarities, ", "))
print("[Egg Hub v4] Target: " .. State.targetRarity)
