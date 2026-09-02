-- ╔══════════════════════════════════════════════════╗
-- ║   STEAL AN EGG HUB v5.0 - PRO UI                 ║
-- ║   Tab: Steal | Config | Prediction | Visual     ║
-- ║   Multi-rarity | Speed 1-1000 | Egg Predictor  ║
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

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local State = {
    -- Steal
    autoSteal = false,
    stealSpeed = 100,
    stealDelay = 0.3,
    stealMethod = "Instant",
    selectedRarities = {["All"] = true},
    selectedMutations = {},
    -- Config
    godmode = false,
    antiBat = false,
    antiTrap = false,
    antiGuard = false,
    antiAFK = false,
    walkSpeed = 100,
    speedEnabled = false,
    noclip = false,
    infJump = false,
    flyEnabled = false,
    flySpeed = 50,
    -- Visual
    espEggs = false,
    espPlayers = false,
    fullbright = false,
    -- Auto
    autoHatch = false,
    autoSell = false,
    autoTreadmill = false,
    autoUpgradeBase = false,
    -- Runtime
    stolen = 0,
    failed = 0,
    predictedEgg = nil,
}

-- ══════════════════════════════════════
-- RARITY DATA
-- ══════════════════════════════════════
local Rarities = {
    "All", "BrainrotGod", "Secret", "Divine", "Cosmic", "Eternal",
    "Mythic", "Legendary", "Epic", "Rare", "Superior", "Uncommon", "Common", "Basic"
}

local Mutations = {
    "Normal", "Shiny", "Giant", "Tiny", "Golden", "Rainbow", "Frozen", "Inferno", "Void", "Cyber"
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
-- NETWORK
-- ══════════════════════════════════════
local function getRemote(name)
    local net = ReplicatedStorage:FindFirstChild("Network") or ReplicatedStorage
    local item = net:FindFirstChild(name)
    if not item then item = ReplicatedStorage:FindFirstChild(name, true) end
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
        local duration = math.clamp(distance / (speed or 100), 0.05, 5)
        local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
        tween:Play()
        tween.Completed:Wait()
    else
        root.CFrame = targetCFrame
    end
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 0)
        else
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
        if owner == LocalPlayer.UserId or owner == LocalPlayer.Name then return plot end
        local sign = plot:FindFirstChild("Sign") or plot:FindFirstChild("OwnerSign")
        if sign then
            local text = sign:GetAttribute("Text") or ""
            if text:find(LocalPlayer.Name) then return plot end
        end
    end
    return nil
end

local function getDepositZone()
    local plot = getLocalPlot()
    if plot then
        for _, obj in ipairs(plot:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("deposit") or n:find("drop") or n:find("claim") or n:find("collection")) and obj:IsA("BasePart") then
                return obj.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
    local spawn = Workspace:FindFirstChild("SpawnLocation")
    if spawn then return spawn.CFrame + Vector3.new(0, 5, 0) end
    return nil
end

-- ══════════════════════════════════════
-- SCAN AREA EGGS
-- ══════════════════════════════════════
local function getAreaEggsFolder()
    return Workspace:FindFirstChild("AreaEggs") 
        or Workspace:FindFirstChild("SpawnedEggs") 
        or Workspace:FindFirstChild("Eggs")
end

local function scanAreaEggs()
    local results = {}
    local root = getRoot()
    if not root then return results end
    local found = {} -- track model yang sudah ditambah
    
    local function tryAddEgg(obj)
        if not obj or found[obj] then return end
        found[obj] = true
        
        local rarity = obj:GetAttribute("Rarity") or obj:GetAttribute("AssetRarity") or "Common"
        local mutation = obj:GetAttribute("Mutation") or obj:GetAttribute("Variant") or "Normal"
        local name = obj.Name or "Unknown"
        local nameLower = name:lower()
        
        -- Cek apakah ini egg: by attribute, by name, or by ProximityPrompt
        local isEgg = obj:GetAttribute("IsEgg") 
            or obj:GetAttribute("IsAreaEgg")
            or obj:GetAttribute("IsAnimal")
            or obj:GetAttribute("AssetId")
            or nameLower:find("egg")
            or nameLower:find("area")
            or nameLower:find("nest")
            or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        
        if not isEgg then return end
        
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
        if not part then 
            -- Coba cari part lain
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    part = child
                    break
                end
            end
        end
        if not part then return end
        
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        
        table.insert(results, {
            Model = obj,
            Part = part,
            Prompt = prompt,
            Rarity = rarity,
            Mutation = mutation,
            Name = name,
            Position = part.Position,
            Distance = (root.Position - part.Position).Magnitude,
            IsAreaEgg = obj:GetAttribute("IsAreaEgg") == true,
        })
    end
    
    -- 1. Scan folder AreaEggs/SpawnedEggs/Eggs
    for _, folderName in ipairs({"AreaEggs", "SpawnedEggs", "Eggs", "Egg", "SpawnedEggs", "WorldEggs"}) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                tryAddEgg(child)
                -- Juga scan grandchildren
                for _, grandchild in ipairs(child:GetDescendants()) do
                    tryAddEgg(grandchild)
                end
            end
        end
    end
    
    -- 2. Scan SEMUA descendants workspace (aggressive)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("MeshPart") then
            tryAddEgg(obj)
        end
    end
    
    -- 3. Scan ReplicatedStorage juga (kadang egg ada di sana)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") and (obj:GetAttribute("IsEgg") or obj.Name:lower():find("egg")) then
            tryAddEgg(obj)
        end
    end
    
    return results
end

-- Filter berdasarkan selected rarities + mutations
local function filterEggs(eggs)
    local filtered = {}
    local allRarity = State.selectedRarities["All"] == true
    
    for _, egg in ipairs(eggs) do
        local rarityOk = allRarity
        if not rarityOk and State.selectedRarities[egg.Rarity] then
            rarityOk = true
        end
        
        local mutationOk = true
        if next(State.selectedMutations) then
            mutationOk = State.selectedMutations[egg.Mutation] == true or egg.Mutation == "Normal" and not State.selectedMutations["Normal"]
        end
        
        if rarityOk and mutationOk then
            table.insert(filtered, egg)
        end
    end
    
    return filtered
end

-- ══════════════════════════════════════
-- AUTO STEAL ENGINE
-- ══════════════════════════════════════
local stealThread = nil
local stealActive = false

local function startStealLoop()
    if stealActive then return end
    stealActive = true
    
    stealThread = task.spawn(function()
        local selectedList = {}
        for k, v in pairs(State.selectedRarities) do if v then table.insert(selectedList, k) end end
        notify("Auto Steal", "Started! Target: " .. table.concat(selectedList, ", "), 3)
        
        while stealActive do
            local root = getRoot()
            if not root then task.wait(2) continue end
            
            local allEggs = scanAreaEggs()
            local targets = filterEggs(allEggs)
            
            if #targets > 0 then
                -- Sort by distance
                table.sort(targets, function(a, b) return a.Distance < b.Distance end)
                
                local target = targets[1]
                if target and target.Part then
                    -- Hop/tween ke egg dengan kecepatan user (bukan instant TP)
                    local root = getRoot()
                    if root and target.Part then
                        local eggPos = target.Part.Position
                        local dist = (root.Position - eggPos).Magnitude
                        local speed = math.clamp(State.stealSpeed, 1, 1000)
                        local duration = math.clamp(dist / speed, 0.01, 10)
                        local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(root, info, {CFrame = CFrame.new(eggPos + Vector3.new(0, 3, 0))})
                        tween:Play()
                        local t0 = os.clock()
                        while tween.PlaybackState == Enum.PlaybackState.Playing and os.clock() - t0 < duration + 2 do
                            task.wait(0.03)
                        end
                    end
                    
                    -- Carry egg
                    invokeRemote("Eggs: RequestAreaEggCarry", target.Model)
                    fireRemote("ActiveAssets: RequestStealTarget", target.Model)
                    invokeRemote("ActiveAssets: RequestDnaStealAnimationComplete", target.Model)
                    
                    -- Trigger prompt kalau ada
                    if target.Prompt then
                        triggerPrompt(target.Prompt)
                    end
                    
                    task.wait(0.1)
                    
                    -- TP ke base deposit zone
                    local depositCF = getDepositZone()
                    if depositCF then
                        teleportTo(depositCF, State.stealMethod == "Tween", State.stealSpeed)
                        task.wait(0.1)
                        -- Drop & deposit
                        invokeRemote("Eggs: RequestAreaEggDrop")
                        fireRemote("Guards: ForestDeposit")
                        
                        State.stolen = State.stolen + 1
                        -- silent steal, no notif
                    end
                end
            else
                -- Ga ada target, tunggu
                task.wait(0.5)
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
-- EGG PREDICTION ENGINE
-- ══════════════════════════════════════
local predictionThread = nil
local predictionActive = false
local eggHistory = {}
local spawnPattern = { lastSpawn = 0, avgInterval = 0, spawnCount = 0 }
local predictedSpawn = nil

local function startPrediction()
    if predictionActive then return end
    predictionActive = true
    
    predictionThread = task.spawn(function()
        local lastEggCount = 0
        
        while predictionActive do
            local eggs = scanAreaEggs()
            local currentCount = #eggs
            
            -- Deteksi egg baru spawn
            if currentCount > lastEggCount and lastEggCount > 0 then
                local now = os.clock()
                if spawnPattern.lastSpawn > 0 then
                    local interval = now - spawnPattern.lastSpawn
                    if spawnPattern.spawnCount > 0 then
                        spawnPattern.avgInterval = (spawnPattern.avgInterval * spawnPattern.spawnCount + interval) / (spawnPattern.spawnCount + 1)
                    else
                        spawnPattern.avgInterval = interval
                    end
                    spawnPattern.spawnCount = spawnPattern.spawnCount + 1
                    
                    -- Prediksi spawn berikutnya
                    predictedSpawn = now + spawnPattern.avgInterval
                    State.predictedEgg = predictedSpawn
                    
                    -- Cari egg baru
                    for _, egg in ipairs(eggs) do
                        local found = false
                        for _, old in ipairs(eggHistory) do
                            if old.Model == egg.Model then found = true break end
                        end
                        if not found then
                            table.insert(eggHistory, egg)
                            if #eggHistory > 20 then table.remove(eggHistory, 1) end
                            notify("Egg Spawned!", egg.Rarity .. " " .. (egg.Mutation or "") .. " egg appeared!", 3)
                        end
                    end
                end
                spawnPattern.lastSpawn = now
            end
            
            lastEggCount = currentCount
            eggHistory = eggs
            task.wait(0.5)
        end
    end)
end

local function stopPrediction()
    predictionActive = false
    if predictionThread then pcall(task.cancel, predictionThread) end
end

-- ══════════════════════════════════════
-- CONFIG: GODMODE / ANTI BAT / ANTI TRAP / ANTI GUARD
-- ══════════════════════════════════════
local godConn, antiBatConn, antiTrapConn, antiGuardConn, afkThread = nil, nil, nil, nil, nil

local function toggleGodmode(en)
    State.godmode = en
    if en then
        godConn = RunService.Heartbeat:Connect(function()
            local c = getChar()
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                    pcall(function() if h.MaxHealth < 9999 then h.MaxHealth = 9999 h.Health = 9999 end end)
                end
            end
        end)
    else
        if godConn then godConn:Disconnect() godConn = nil end
        local h = getHum() if h then pcall(function() h.MaxHealth = 100 h.Health = 100 end) end
    end
end

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
                        if ph and (ph.Position - root.Position).Magnitude < 15 then
                            root.CFrame = root.CFrame + Vector3.new(0, 30, 0)
                        end
                    end
                end
            end
            for _, obj in ipairs(getChar():GetDescendants()) do
                if (obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity")) and not obj.Name:lower():match("egg") and not obj.Name:lower():match("fly") then
                    obj:Destroy()
                end
            end
        end)
    else
        if antiBatConn then antiBatConn:Disconnect() antiBatConn = nil end
    end
end

local function toggleAntiTrap(en)
    State.antiTrap = en
    if en then
        antiTrapConn = RunService.Heartbeat:Connect(function()
            local c = getChar() if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not root or not h then return end
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude < 0.1 and h.MoveDirection.Magnitude > 0.1 then
                pcall(function() h.PlatformStand = false h.Sit = false root.Anchored = false end)
                for _, obj in ipairs(c:GetDescendants()) do
                    if (obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro")) and not obj.Name:lower():match("egg") and not obj.Name:lower():match("fly") then
                        obj:Destroy()
                    end
                end
                root.CFrame = root.CFrame * CFrame.new(0, 5, 0)
            end
            for _, obj in ipairs(c:GetDescendants()) do
                if (obj:IsA("Weld") or obj:IsA("WeldConstraint")) then
                    local n = obj.Name:lower()
                    if n:match("trap") or n:match("grab") or n:match("lock") or n:match("freeze") then obj:Destroy() end
                end
            end
        end)
    else
        if antiTrapConn then antiTrapConn:Disconnect() antiTrapConn = nil end
    end
end

local function toggleAntiGuard(en)
    State.antiGuard = en
    if en then
        antiGuardConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local h = getHum()
            if not root or not h then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= getChar() then
                    local n = obj.Name:lower()
                    if n:match("guard") or n:match("npc") or n:match("keeper") or n:match("warden") or n:match("protector") then
                        local gp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                        if gp and (gp.Position - root.Position).Magnitude < 25 then
                            root.CFrame = root.CFrame + Vector3.new(0, 50, 0)
                            if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                        end
                    end
                end
            end
        end)
    else
        if antiGuardConn then antiGuardConn:Disconnect() antiGuardConn = nil end
    end
end

local function toggleAntiAFK(en)
    State.antiAFK = en
    if en then
        afkThread = task.spawn(function()
            while State.antiAFK do
                local root = getRoot()
                if root then root.CFrame = root.CFrame * CFrame.new(0.001, 0, 0.001) end
                task.wait(30)
            end
        end)
    else
        if afkThread then pcall(task.cancel, afkThread) afkThread = nil end
    end
end

-- ══════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════
local noclipConn, infJumpConn, flyConn = nil, nil, nil

local function toggleSpeed(en)
    State.speedEnabled = en
    local h = getHum()
    if h then if en then h.WalkSpeed = State.walkSpeed else h.WalkSpeed = 16 end end
end

local function toggleNoclip(en)
    State.noclip = en
    if en then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    end
end

local function toggleInfJump(en)
    State.infJump = en
    if en then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local c = getChar()
            if c then local h = c:FindFirstChildOfClass("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    end
end

local function toggleFly(en)
    State.flyEnabled = en
    local root = getRoot() if not root then return end
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
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local g = root:FindFirstChild("EggFly") if g then g:Destroy() end
        local v = root:FindFirstChild("EggFlyVel") if v then v:Destroy() end
    end
end

-- ══════════════════════════════════════
-- AUTO HATCH / SELL / TREADMILL / UPGRADE
-- ══════════════════════════════════════
local function toggleAutoHatch(en)
    State.autoHatch = en
    if en then
        task.spawn(function()
            while State.autoHatch do
                invokeRemote("Eggs: RequestSkipGrowth")
                invokeRemote("Eggs: RequestHatchEgg", "Starter Egg", 1)
                invokeRemote("Eggs: RequestCompleteHatchEgg", "Starter Egg")
                invokeRemote("Eggs: RequestPlaceEgg")
                task.wait(0.5)
            end
        end)
    end
end

local function toggleAutoSell(en)
    State.autoSell = en
    if en then
        task.spawn(function()
            while State.autoSell do
                fireRemote("AssetInventory: SellAllAssets")
                task.wait(2)
            end
        end)
    end
end

local function toggleAutoTreadmill(en)
    State.autoTreadmill = en
    if en then
        task.spawn(function()
            while State.autoTreadmill do
                fireRemote("Treadmills: SpeedGain", 1)
                invokeRemote("Treadmills: RequestUpgrade")
                invokeRemote("Treadmills: RequestEquipStatic")
                task.wait(0.15)
            end
        end)
    end
end

local function toggleAutoUpgradeBase(en)
    State.autoUpgradeBase = en
    if en then
        task.spawn(function()
            while State.autoUpgradeBase do
                fireRemote("Plots: RequestBaseUpgrade", "All")
                invokeRemote("Backpack: EquipBest")
                task.wait(2)
            end
        end)
    end
end

-- ══════════════════════════════════════
-- VISUAL
-- ══════════════════════════════════════
local function toggleESPeggs(en)
    State.espEggs = en
    if en then
        local folder = getAreaEggsFolder()
        if folder then
            for _, egg in ipairs(folder:GetChildren()) do
                local rarity = egg:GetAttribute("Rarity") or "Common"
                local color = RarityColors[rarity] or Color3.new(1,1,1)
                if not egg:FindFirstChild("EESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "EESP" hl.FillColor = color hl.FillTransparency = 0.3
                    hl.OutlineColor = Color3.new(1,1,1) hl.Parent = egg
                    local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "EESP" bb.Size = UDim2.new(0, 200, 0, 40) bb.AlwaysOnTop = true bb.MaxDistance = 1000
                        local l = Instance.new("TextLabel")
                        l.Size = UDim2.new(1,0,1,0) l.BackgroundTransparency = 1 l.Text = rarity .. " | " .. egg.Name
                        l.TextColor3 = color l.TextScaled = true l.Font = Enum.Font.GothamBold l.Parent = bb
                        bb.Parent = part
                    end
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local e = obj:FindFirstChild("EESP") if e then e:Destroy() end
        end
    end
end

local function toggleESPplayers(en)
    State.espPlayers = en
    if en then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("PESP") then
                local hl = Instance.new("Highlight")
                hl.Name = "PESP" hl.FillColor = Color3.new(1,0,0) hl.FillTransparency = 0.5 hl.Parent = p.Character
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then local e = p.Character:FindFirstChild("PESP") if e then e:Destroy() end end
        end
    end
end

local function toggleFullbright(en)
    State.fullbright = en
    if en then
        Lighting.Brightness = 3 Lighting.ClockTime = 12 Lighting.FogEnd = 100000 Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1 Lighting.ClockTime = 14 Lighting.GlobalShadows = true
    end
end

-- ══════════════════════════════════════
-- PRO UI (custom, no dependency)
-- ══════════════════════════════════════
local oldGui = CoreGui:FindFirstChild("EggHubV5")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggHubV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (typeof(gethui) == "function" and gethui()) or CoreGui

-- Main Window
local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, 500, 0, 600)
MainWindow.Position = UDim2.new(0.5, -250, 0.5, -300)
MainWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.Draggable = true
MainWindow.Parent = ScreenGui

local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = MainWindow
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(60, 100, 200) stroke.Thickness = 2 stroke.Parent = MainWindow

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow
local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 12) tc.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥚 STEAL AN EGG HUB v5.0"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar
local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() stopStealLoop() stopPrediction() ScreenGui:Destroy() end)

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 40)
TabBar.Position = UDim2.new(0, 10, 0, 50)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainWindow
local tabLayout = Instance.new("UIListLayout") tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5) tabLayout.Parent = TabBar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -20, 1, -105)
ContentArea.Position = UDim2.new(0, 10, 0, 95)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainWindow

-- Tab System
local Tabs = {}
local currentTab = nil

local function createTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 115, 1, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    tabBtn.Text = (icon or "") .. " " .. name
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.Parent = TabBar
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = tabBtn
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = ContentArea
    local pl = Instance.new("UIListLayout") pl.Padding = UDim.new(0, 5) pl.Parent = page
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.page.Visible = false t.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55) end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
        currentTab = name
    end)
    
    Tabs[name] = { btn = tabBtn, page = page }
    return page
end

-- UI Components
local function addSection(page, name)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 25)
    l.BackgroundTransparency = 1
    l.Text = "━━ " .. name .. " ━━"
    l.TextColor3 = Color3.fromRGB(100, 150, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.Parent = page
end

local function addToggle(page, name, desc, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    f.BorderSizePixel = 0
    f.Parent = page
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = f
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.7, 0, 0, 20) l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(230, 230, 240)
    l.Font = Enum.Font.GothamBold l.TextSize = 13 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(0.85, 0, 0, 14) d.Position = UDim2.new(0, 10, 0, 22)
    d.BackgroundTransparency = 1 d.Text = desc or "" d.TextColor3 = Color3.fromRGB(130, 130, 150)
    d.Font = Enum.Font.Gotham d.TextSize = 10 d.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 24) btn.Position = UDim2.new(1, -60, 0, 8)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65) btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200) btn.Font = Enum.Font.GothamBold btn.TextSize = 11 btn.Parent = f
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 6) bc.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 65)
        callback(state)
    end)
    return btn
end

local function addButton(page, name, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 100, 200)
    btn.Text = name btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold btn.TextSize = 13 btn.Parent = page
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addSlider(page, name, min, max, default, suffix, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 45)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    f.BorderSizePixel = 0 f.Parent = page
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = f
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.5, 0, 0, 18) l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(230, 230, 240)
    l.Font = Enum.Font.GothamBold l.TextSize = 12 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.3, 0, 0, 18) v.Position = UDim2.new(0.65, 0, 0, 2)
    v.BackgroundTransparency = 1 v.Text = tostring(default) .. (suffix or "")
    v.TextColor3 = Color3.fromRGB(100, 200, 255) v.Font = Enum.Font.GothamBold v.TextSize = 12
    v.TextXAlignment = Enum.TextXAlignment.Right v.Parent = f
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0.9, 0, 0, 8) bar.Position = UDim2.new(0.05, 0, 0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 60) bar.BorderSizePixel = 0 bar.Parent = f
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = bar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 150, 255) fill.BorderSizePixel = 0 fill.Parent = bar
    local fc2 = Instance.new("UICorner") fc2.CornerRadius = UDim.new(0, 4) fc2.Parent = fill
    
    local dragging = false local val = default
    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            local x = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * x)
            fill.Size = UDim2.new(x, 0, 1, 0)
            v.Text = tostring(val) .. (suffix or "")
            callback(val)
        end
    end)
end

local function addMultiSelect(page, name, options, selectedTable, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 30 + math.ceil(#options / 3) * 25)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    f.BorderSizePixel = 0 f.Parent = page
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = f
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 20) l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1 l.Text = name l.TextColor3 = Color3.fromRGB(230, 230, 240)
    l.Font = Enum.Font.GothamBold l.TextSize = 12 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -10, 1, -25) grid.Position = UDim2.new(0, 5, 0, 22)
    grid.BackgroundTransparency = 1 grid.Parent = f
    local gl = Instance.new("UIGridLayout") gl.CellSize = UDim2.new(0.3, 0, 0, 22)
    gl.CellPadding = UDim2.new(0, 3, 0, 3) gl.Parent = grid
    
    for _, opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = selectedTable[opt] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(45, 45, 60)
        btn.Text = opt btn.TextColor3 = Color3.fromRGB(230, 230, 240)
        btn.Font = Enum.Font.GothamBold btn.TextSize = 10 btn.Parent = grid
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            selectedTable[opt] = not selectedTable[opt]
            btn.BackgroundColor3 = selectedTable[opt] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(45, 45, 60)
            callback(selectedTable)
        end)
    end
end

-- ══════════════════════════════════════
-- TAB: STEAL
-- ══════════════════════════════════════
local stealPage = createTab("Steal", "🥚")

addSection(stealPage, "RARITY TARGET (Multi-Select)")
addMultiSelect(stealPage, "Pilih Rarity Target", Rarities, State.selectedRarities, function(sel)
    State.selectedRarities = sel
    local count = 0 for _ in pairs(sel) do if sel[_] then count = count + 1 end end
    notify("Rarity", count .. " rarities selected", 2)
end)

addSection(stealPage, "MUTATION TARGET (Multi-Select)")
addMultiSelect(stealPage, "Pilih Mutation Target", Mutations, State.selectedMutations, function(sel)
    State.selectedMutations = sel
end)

addSection(stealPage, "STEAL SETTINGS")
addSlider(stealPage, "Steal Speed", 1, 1000, 100, " studs/s", function(v) State.stealSpeed = v end)
addSlider(stealPage, "Steal Delay (antara steal)", 0.05, 5, 0.3, "s", function(v) State.stealDelay = v end)

addSection(stealPage, "STEAL ENGINE")
addToggle(stealPage, "🥚 Auto Steal", "Scan → TP → Carry → Bawa ke Base → Deposit", function(s)
    if s then startStealLoop() else stopStealLoop() end
end)

addButton(stealPage, "📋 SCAN AREA EGGS", Color3.fromRGB(200, 130, 50), function()
    local eggs = scanAreaEggs()
    local filtered = filterEggs(eggs)
    notify("Scan", #eggs .. " total | " .. #filtered .. " matching", 5)
    for i, e in ipairs(filtered) do
        if i > 15 then break end
        print(string.format("[EggHub] %d: %s | Rarity: %s | Mutation: %s | Dist: %.0f", i, e.Name, e.Rarity, e.Mutation, e.Distance))
    end
end)

addButton(stealPage, "🏠 TP to Base", Color3.fromRGB(80, 130, 200), function()
    local cf = getDepositZone()
    if cf then teleportTo(cf, false) end
end)

-- ══════════════════════════════════════
-- TAB: CONFIG (Player Settings)
-- ══════════════════════════════════════
local configPage = createTab("Config", "⚙️")

addSection(configPage, "KEBAL / PROTECTION")
addToggle(configPage, "🛡️ Godmode", "Health selalu max, kebal segala damage", function(s) toggleGodmode(s) end)
addToggle(configPage, "🏏 Anti Bat", "Anti dipukul, auto TP dari player pegang weapon", function(s) toggleAntiBat(s) end)
addToggle(configPage, "🔒 Anti Trap", "Anti di-freeze/lock, auto unfreeze + escape", function(s) toggleAntiTrap(s) end)
addToggle(configPage, "👮 Anti Guard", "Anti penjaga NPC, auto TP dari guard", function(s) toggleAntiGuard(s) end)
addToggle(configPage, "💤 Anti AFK", "Anti idle kick", function(s) toggleAntiAFK(s) end)

addSection(configPage, "MOVEMENT")
addSlider(configPage, "Walk Speed", 16, 500, 100, "", function(v)
    State.walkSpeed = v
    if State.speedEnabled then local h = getHum() if h then h.WalkSpeed = v end end
end)
addToggle(configPage, "⚡ Speed Boost", "Aktifkan WalkSpeed custom", function(s) toggleSpeed(s) end)
addToggle(configPage, "👻 Noclip", "Tembus tembok", function(s) toggleNoclip(s) end)
addToggle(configPage, "🦘 Infinite Jump", "Lompat tanpa henti", function(s) toggleInfJump(s) end)
addToggle(configPage, "🕊️ Fly", "WASD + Space/Shift", function(s) toggleFly(s) end)
addSlider(configPage, "Fly Speed", 10, 500, 50, "", function(v) State.flySpeed = v end)

addSection(configPage, "AUTO EGG MANAGEMENT")
addToggle(configPage, "🐣 Auto Hatch + Place", "Auto hatch + skip growth + place egg", function(s) toggleAutoHatch(s) end)
addToggle(configPage, "💰 Auto Sell", "Auto sell all assets", function(s) toggleAutoSell(s) end)
addToggle(configPage, "🏃 Auto Treadmill", "Auto speed gain + upgrade + equip", function(s) toggleAutoTreadmill(s) end)
addToggle(configPage, "🏗️ Auto Upgrade Base", "Auto upgrade + equip best pet", function(s) toggleAutoUpgradeBase(s) end)

-- ══════════════════════════════════════
-- TAB: PREDICTION
-- ══════════════════════════════════════
local predPage = createTab("Prediction", "🔮")

addSection(predPage, "EGG PREDICTION ENGINE")
addToggle(predPage, "🔮 Enable Prediction", "Monitor spawn pattern + prediksi egg berikutnya", function(s)
    if s then startPrediction() else stopPrediction() end
end)

addSection(predPage, "SPAWN STATISTICS")
local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.new(1, -10, 0, 80)
statLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
statLabel.BorderSizePixel = 0
statLabel.Text = "Spawn Count: 0\nAvg Interval: 0s\nPredicted Next: --\nLast Rarity: --"
statLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statLabel.Font = Enum.Font.Code
statLabel.TextSize = 12
statLabel.TextXAlignment = Enum.TextXAlignment.Left
statLabel.Parent = predPage
local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 6) sc.Parent = statLabel

-- Update stats
task.spawn(function()
    while true do
        if predictionActive then
            local nextSpawn = predictedSpawn and (math.max(0, predictedSpawn - os.clock())) or 0
            statLabel.Text = string.format(
                "Spawn Count: %d\nAvg Interval: %.1fs\nPredicted Next: %.1fs\nLast Rarity: %s",
                spawnPattern.spawnCount,
                spawnPattern.avgInterval,
                nextSpawn,
                (eggHistory[#eggHistory] and eggHistory[#eggHistory].Rarity) or "--"
            )
        end
        task.wait(0.5)
    end
end)

addButton(predPage, "📊 DETAILED SPAWN LOG", Color3.fromRGB(120, 80, 200), function()
    print("=== SPAWN LOG ===")
    print("Total spawns detected:", spawnPattern.spawnCount)
    print("Average interval:", spawnPattern.avgInterval, "s")
    print("Recent eggs:")
    for i, e in ipairs(eggHistory) do
        if i > 20 then break end
        print(string.format("  %d: %s | %s | %s", i, e.Name, e.Rarity, e.Mutation))
    end
    notify("Spawn Log", "Check F9 console!", 3)
end)

-- ══════════════════════════════════════
-- TAB: VISUAL
-- ══════════════════════════════════════
local visPage = createTab("Visual", "👁️")

addSection(visPage, "ESP")
addToggle(visPage, "🥚 ESP Eggs", "Highlight egg dengan warna rarity", function(s) toggleESPeggs(s) end)
addToggle(visPage, "👤 ESP Players", "Highlight player lain (merah)", function(s) toggleESPplayers(s) end)
addToggle(visPage, "💡 Fullbright", "Hapus bayangan + gelap", function(s) toggleFullbright(s) end)

addSection(visPage, "STATS")
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -10, 0, 60)
statsLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
statsLabel.BorderSizePixel = 0
statsLabel.Text = "Stolen: 0 | Failed: 0"
statsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = 14
statsLabel.Parent = visPage
local stc = Instance.new("UICorner") stc.CornerRadius = UDim.new(0, 6) stc.Parent = statsLabel

task.spawn(function()
    while true do
        statsLabel.Text = string.format("Stolen: %d | Failed: %d | Active: %s", State.stolen, State.failed, stealActive and "YES" or "NO")
        task.wait(1)
    end
end)

addButton(visPage, "🔄 Rejoin Server", Color3.fromRGB(180, 60, 60), function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- ══════════════════════════════════════
-- KEYBIND
-- ══════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightControl then
        MainWindow.Visible = not MainWindow.Visible
    end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if State.speedEnabled then
        local h = char:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = State.walkSpeed end
    end
    if State.godmode then
        local h = char:FindFirstChildOfClass("Humanoid") if h then pcall(function() h.MaxHealth = 9999 h.Health = 9999 end) end
    end
end)

-- Open first tab
Tabs["Steal"].btn.MouseButton1Click:fire()

-- Init
notify("🥚 Egg Hub v5", "Loaded! RightCtrl to toggle", 5)
print("[Egg Hub v5] Loaded! Tabs: Steal | Config | Prediction | Visual")
