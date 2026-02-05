local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local SKYBOX_ASSET_ID = "rbxassetid://71960376840332"

local CONFIG = {
    lanes = {-6, 0, 6},
    spawnDistance = 90,
    despawnDistance = 20,
    runSpeed = 42,
    attackRange = 9,
    attackCooldown = 0.6,
    pistachioBurst = 3,
    obstacleDetectionRange = 15,
    obstacleChaseSpeed = 12,
    -- SUBWAY SURFERS STYLE: One-hit death with continue system
    reviveCost = 50, -- Cost in pistachios to continue after crash
    maxRevivesPerRun = 2, -- Can only revive twice per run
    speedPenalty = 0.7,
    -- Pistachio economy
    pistachioMagnetRange = 8,
    studyStreakThreshold = 25,
    studyStreakMultipliers = {1.2, 1.5, 2.0, 2.5, 3.0},
    pistachioValues = {
        common = {points = 10, metaCurrency = 1, color = Color3.fromRGB(152, 255, 130), spawnChance = 0.7},
        gold = {points = 50, metaCurrency = 5, color = Color3.fromRGB(255, 215, 0), spawnChance = 0.25},
        rare = {points = 100, metaCurrency = 10, color = Color3.fromRGB(255, 100, 255), spawnChance = 0.05}
    },
    obstacleImageIds = {
        Bostan = "rbxassetid://YOUR_IMAGE_ID",
        Fistic = "rbxassetid://YOUR_IMAGE_ID",
        Cojuhari = "rbxassetid://YOUR_IMAGE_ID",
        Grosu = "rbxassetid://YOUR_IMAGE_ID",
        Braga = "rbxassetid://YOUR_IMAGE_ID",
        Tronciu = "rbxassetid://YOUR_IMAGE_ID",
    },
    pistachioImageId = "rbxassetid://YOUR_PISTACHIO_IMAGE_ID",
}

local levels = {
    {
        name = "Year 1",
        checkpointDistance = 0,
        obstacleInterval = 2.5,  -- Slower start
        pistachioInterval = 1.1,
    },
    {
        name = "Year 2", 
        checkpointDistance = 300,
        obstacleInterval = 2.0,  -- Moderate
        pistachioInterval = 1.0,
    },
    {
        name = "Year 3",
        checkpointDistance = 650,
        obstacleInterval = 1.5,  -- Getting harder
        pistachioInterval = 0.95,
    },
    {
        name = "Year 4",
        checkpointDistance = 1000,
        obstacleInterval = 1.2,  -- Challenging but fair
        pistachioInterval = 0.87,
    },
}

local obstacleDefinitions = {
    -- Person obstacles (attackable)
    {name = "Bostan", type = "person", level = 1, health = 3, points = 60},
    {name = "Fistic", type = "person", level = 1, health = 3, points = 60},
    {name = "Cojuhari", type = "person", level = 2, health = 2, points = 45},
    {name = "Grosu", type = "person", level = 2, health = 2, points = 45},
    {name = "Braga", type = "person", level = 3, health = 2, points = 50},
    {name = "Tronciu", type = "person", level = 4, health = 4, points = 80},
}

local staticObstacleDefinitions = {
    -- Static obstacles (must be avoided)
    {name = "Barrier", type = "static", level = 1, width = 4, height = 8, color = Color3.fromRGB(200, 50, 50)},
    {name = "Pole", type = "static", level = 1, width = 2, height = 12, color = Color3.fromRGB(100, 100, 100)},
    {name = "Wall", type = "static", level = 1, width = 6, height = 10, color = Color3.fromRGB(150, 75, 30)},
    {name = "Spikes", type = "static", level = 1, width = 5, height = 3, color = Color3.fromRGB(80, 80, 80)},
    {name = "Fence", type = "static", level = 1, width = 3, height = 6, color = Color3.fromRGB(120, 60, 20)},
    {name = "Crate", type = "static", level = 1, width = 4, height = 4, color = Color3.fromRGB(160, 100, 40)},
    {name = "Pillar", type = "static", level = 2, width = 2.5, height = 15, color = Color3.fromRGB(180, 180, 180)},
    {name = "Bench", type = "static", level = 2, width = 5, height = 2, color = Color3.fromRGB(90, 50, 30)},
}

local movingObstacleDefinitions = {
    -- Moving obstacles (slide left-right)
    {name = "SwingingHammer", type = "moving", level = 1, width = 3, height = 6, color = Color3.fromRGB(120, 60, 0), speed = 8},
    {name = "SlidingBlock", type = "moving", level = 1, width = 4, height = 4, color = Color3.fromRGB(80, 150, 80), speed = 6},
    {name = "RotatingBlade", type = "moving", level = 2, width = 2, height = 8, color = Color3.fromRGB(200, 200, 50), speed = 10},
    {name = "Pendulum", type = "moving", level = 2, width = 2, height = 10, color = Color3.fromRGB(150, 50, 150), speed = 5},
    {name = "Piston", type = "moving", level = 3, width = 3, height = 5, color = Color3.fromRGB(100, 100, 200), speed = 7},
}

local runnerWorld = workspace:FindFirstChild("RunnerWorld") or Instance.new("Folder")
runnerWorld.Name = "RunnerWorld"
runnerWorld.Parent = workspace

local obstaclesFolder = runnerWorld:FindFirstChild("Obstacles") or Instance.new("Folder")
obstaclesFolder.Name = "Obstacles"
obstaclesFolder.Parent = runnerWorld

local pistachiosFolder = runnerWorld:FindFirstChild("Pistachios") or Instance.new("Folder")
pistachiosFolder.Name = "Pistachios"
pistachiosFolder.Parent = runnerWorld

local distanceTraveled = 0
local currentLevelIndex = 1
local pistachioCount = 0
local totalPistachios = 0  -- Meta currency (persistent across runs)
local score = 0
local canAttack = true
local isAlive = true  -- Subway Surfers style: alive or dead
local isInvulnerable = false
local currentSpeed = CONFIG.runSpeed
local revivesUsedThisRun = 0  -- Track revives used this run
local isGamePaused = false  -- For revive screen

-- Study Streak system
local studyStreak = 0
local studyStreakLevel = 0
local pistachiosCollectedInRun = 0
local lastPistachioTime = 0
local streakMultiplier = 1

-- Year progress system
local yearProgress = 0
local yearMeter = 0
local maxYearMeter = 1000

local hudGui
local pistachioLabel
local scoreLabel
local levelLabel
local healthLabel
local streakLabel
local yearLabel

local function getCharacterRoot()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local function createHud()
    if hudGui then
        hudGui:Destroy()
    end

    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "RunnerHUD"
    hudGui.ResetOnSpawn = false
    hudGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Position = UDim2.fromScale(0.02, 0.04)
    frame.Size = UDim2.fromOffset(260, 100)
    frame.BackgroundTransparency = 0.3
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    frame.BorderSizePixel = 0
    frame.Parent = hudGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame

    local function makeLabel()
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 26)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(240, 240, 240)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        return label
    end

    levelLabel = makeLabel()
    scoreLabel = makeLabel()
    pistachioLabel = makeLabel()
    healthLabel = makeLabel()
    streakLabel = makeLabel()
    yearLabel = makeLabel()
end

local function updateHud()
    local level = levels[currentLevelIndex]
    if not level then
        return
    end

    levelLabel.Text = string.format("📍 %s", level.name)
    scoreLabel.Text = string.format("⭐ Score: %d (x%.1f)", math.floor(score), streakMultiplier)
    pistachioLabel.Text = string.format("🥜 Pistachios: %d | 💰 %d", pistachioCount, totalPistachios)
    
    -- Revives remaining (Subway Surfers style)
    local revivesLeft = CONFIG.maxRevivesPerRun - revivesUsedThisRun
    if revivesLeft > 0 then
        healthLabel.Text = string.format("❤️ Lives: %d | Revive Cost: %d 🥜", revivesLeft, CONFIG.reviveCost)
        healthLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    else
        healthLabel.Text = "❤️ Lives: 0 (No more revives!)"
        healthLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
    end
    
    -- Study Streak display
    if studyStreak > 0 then
        streakLabel.Text = string.format("🔥 Study Streak: %d/25 (Level %d)", studyStreak % CONFIG.studyStreakThreshold, studyStreakLevel + 1)
        streakLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    else
        streakLabel.Text = "🔥 Study Streak: 0/25"
        streakLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    -- Year Progress (like Subway Surfers mission progress)
    local yearPercent = (yearMeter / maxYearMeter) * 100
    yearLabel.Text = string.format("📚 Year Progress: %.0f%%", yearPercent)
    yearLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
end

local function setSkyBackground()
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
    sky.SkyboxBk = SKYBOX_ASSET_ID
    sky.SkyboxDn = SKYBOX_ASSET_ID
    sky.SkyboxFt = SKYBOX_ASSET_ID
    sky.SkyboxLf = SKYBOX_ASSET_ID
    sky.SkyboxRt = SKYBOX_ASSET_ID
    sky.SkyboxUp = SKYBOX_ASSET_ID
    sky.Parent = Lighting
end

local function getLevelForDistance(distance)
    local selectedIndex = 1
    for index, level in ipairs(levels) do
        if distance >= level.checkpointDistance then
            selectedIndex = index
        end
    end
    return selectedIndex
end

local function createPersonObstacle(obstacleDef, position)
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(4, 6, 1)
    hitbox.Transparency = 1
    hitbox.Anchored = true
    hitbox.CanCollide = false
    hitbox.Position = position + Vector3.new(0, 3, 0)
    hitbox.Parent = model

    -- Create detection zone (invisible sphere for proximity detection)
    local detectionZone = Instance.new("Part")
    detectionZone.Name = "DetectionZone"
    detectionZone.Shape = Enum.PartType.Ball
    detectionZone.Size = Vector3.new(CONFIG.obstacleDetectionRange * 2, CONFIG.obstacleDetectionRange * 2, CONFIG.obstacleDetectionRange * 2)
    detectionZone.Transparency = 1
    detectionZone.Anchored = true
    detectionZone.CanCollide = false
    detectionZone.Position = position + Vector3.new(0, 3, 0)
    detectionZone.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CharacterImage"
    billboard.Size = UDim2.fromOffset(220, 320)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hitbox

    local image = Instance.new("ImageLabel")
    image.Name = "Image"
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.Image = CONFIG.obstacleImageIds[obstacleDef.name] or ""
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = billboard

    local humanoid = Instance.new("Humanoid")
    humanoid.Health = obstacleDef.health
    humanoid.MaxHealth = obstacleDef.health
    humanoid.Parent = model

    model.PrimaryPart = hitbox
    model:SetAttribute("Health", obstacleDef.health)
    model:SetAttribute("Points", obstacleDef.points)
    model:SetAttribute("Level", obstacleDef.level)
    model:SetAttribute("Damage", 30) -- Person obstacles deal 30 damage
    model:SetAttribute("Type", "person")
    model:SetAttribute("IsChasing", false)
    model:SetAttribute("OriginalPosition", position)

    return model
end

local function createStaticObstacle(obstacleDef, position)
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(obstacleDef.width, obstacleDef.height, 2)
    hitbox.Color = obstacleDef.color
    hitbox.Anchored = true
    hitbox.CanCollide = false -- Disable CanCollide to prevent physics interference
    hitbox.Position = position + Vector3.new(0, obstacleDef.height/2, 0)
    hitbox.Parent = model

    model.PrimaryPart = hitbox
    model:SetAttribute("Type", "static")
    model:SetAttribute("Damage", 25) -- Static obstacles deal 25 damage

    return model
end

local function createMovingObstacle(obstacleDef, position)
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(obstacleDef.width, obstacleDef.height, 2)
    hitbox.Color = obstacleDef.color
    hitbox.Anchored = true
    hitbox.CanCollide = false -- Disable CanCollide to prevent physics interference
    hitbox.Position = position + Vector3.new(0, obstacleDef.height/2, 0)
    hitbox.Parent = model

    model.PrimaryPart = hitbox
    model:SetAttribute("Type", "moving")
    model:SetAttribute("Damage", 35) -- Moving obstacles deal 35 damage (higher since they're harder)
    model:SetAttribute("Speed", obstacleDef.speed)
    model:SetAttribute("Direction", math.random() > 0.5 and 1 or -1)
    model:SetAttribute("OriginalX", position.X)

    return model
end

-- SUBWAY SURFERS STYLE: One-hit death with revive option
local function crashPlayer()
    if not isAlive or isInvulnerable then 
        print("Player already crashed or invulnerable")
        return 
    end
    
    isAlive = false
    isGamePaused = true
    currentSpeed = 0
    print("💥 CRASH! Player hit an obstacle!")
    
    -- Dramatic crash screen flash
    local crashFlash = Instance.new("Frame")
    crashFlash.Size = UDim2.fromScale(1, 1)
    crashFlash.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    crashFlash.BackgroundTransparency = 0.2
    crashFlash.BorderSizePixel = 0
    crashFlash.ZIndex = 100
    crashFlash.Parent = hudGui
    
    -- Flash effect
    local flashTween = TweenService:Create(
        crashFlash,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.6}
    )
    flashTween:Play()
    
    -- Check if player can revive
    local canRevive = revivesUsedThisRun < CONFIG.maxRevivesPerRun and totalPistachios >= CONFIG.reviveCost
    
    -- Show revive/game over screen
    task.wait(0.3)
    
    if canRevive then
        showReviveScreen(crashFlash)
    else
        crashFlash:Destroy()
        gameOver()
    end
end

local function showReviveScreen(crashFlash)
    local reviveGui = Instance.new("Frame")
    reviveGui.Name = "ReviveScreen"
    reviveGui.AnchorPoint = Vector2.new(0.5, 0.5)
    reviveGui.Position = UDim2.fromScale(0.5, 0.5)
    reviveGui.Size = UDim2.fromOffset(400, 300)
    reviveGui.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    reviveGui.BorderSizePixel = 0
    reviveGui.ZIndex = 101
    reviveGui.Parent = hudGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = reviveGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.25, 0)
    title.BackgroundTransparency = 1
    title.Text = "💀 CRASHED!"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextSize = 36
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 102
    title.Parent = reviveGui
    
    local info = Instance.new("TextLabel")
    info.Position = UDim2.fromScale(0, 0.25)
    info.Size = UDim2.new(1, 0, 0.25, 0)
    info.BackgroundTransparency = 1
    info.Text = string.format("Score: %d | Pistachios: %d", math.floor(score), pistachioCount)
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.TextSize = 18
    info.Font = Enum.Font.Gotham
    info.ZIndex = 102
    info.Parent = reviveGui
    
    -- Revive button
    local reviveButton = Instance.new("TextButton")
    reviveButton.Position = UDim2.fromScale(0.1, 0.55)
    reviveButton.Size = UDim2.new(0.8, 0, 0.18, 0)
    reviveButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    reviveButton.Text = string.format("🔄 CONTINUE (%d 🥜)", CONFIG.reviveCost)
    reviveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    reviveButton.TextSize = 20
    reviveButton.Font = Enum.Font.GothamBold
    reviveButton.BorderSizePixel = 0
    reviveButton.ZIndex = 102
    reviveButton.Parent = reviveGui
    
    local reviveCorner = Instance.new("UICorner")
    reviveCorner.CornerRadius = UDim.new(0, 8)
    reviveCorner.Parent = reviveButton
    
    -- End run button
    local endButton = Instance.new("TextButton")
    endButton.Position = UDim2.fromScale(0.1, 0.78)
    endButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    endButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    endButton.Text = "❌ END RUN"
    endButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    endButton.TextSize = 16
    endButton.Font = Enum.Font.GothamBold
    endButton.BorderSizePixel = 0
    endButton.ZIndex = 102
    endButton.Parent = reviveGui
    
    local endCorner = Instance.new("UICorner")
    endCorner.CornerRadius = UDim.new(0, 8)
    endCorner.Parent = endButton
    
    -- Countdown timer (5 seconds to decide, like Subway Surfers)
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Position = UDim2.fromScale(0, 0.4)
    countdownLabel.Size = UDim2.new(1, 0, 0.15, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "5"
    countdownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    countdownLabel.TextSize = 48
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.ZIndex = 102
    countdownLabel.Parent = reviveGui
    
    local timeLeft = 5
    local countdownActive = true
    
    task.spawn(function()
        while countdownActive and timeLeft > 0 do
            task.wait(1)
            timeLeft -= 1
            if countdownActive then
                countdownLabel.Text = tostring(timeLeft)
            end
        end
        
        if countdownActive then
            -- Time ran out, end run
            countdownActive = false
            reviveGui:Destroy()
            crashFlash:Destroy()
            gameOver()
        end
    end)
    
    reviveButton.Activated:Connect(function()
        if not countdownActive then return end
        countdownActive = false
        
        -- Spend pistachios to revive
        totalPistachios -= CONFIG.reviveCost
        revivesUsedThisRun += 1
        
        reviveGui:Destroy()
        crashFlash:Destroy()
        
        -- Revive with brief invulnerability
        isAlive = true
        isGamePaused = false
        isInvulnerable = true
        currentSpeed = CONFIG.runSpeed
        
        -- Reset streak on revive
        studyStreak = 0
        studyStreakLevel = 0
        streakMultiplier = 1
        
        print("🔄 REVIVED! Pistachios spent:", CONFIG.reviveCost, "Revives used:", revivesUsedThisRun)
        updateHud()
        
        -- Clear nearby obstacles
        for _, obstacle in ipairs(obstaclesFolder:GetChildren()) do
            obstacle:Destroy()
        end
        
        -- Brief invulnerability
        task.spawn(function()
            task.wait(2)
            isInvulnerable = false
            print("Invulnerability ended")
        end)
    end)
    
    endButton.Activated:Connect(function()
        if not countdownActive then return end
        countdownActive = false
        reviveGui:Destroy()
        crashFlash:Destroy()
        gameOver()
    end)
end

local function gameOver()
    -- Create game over screen
    local gameOverGui = Instance.new("ScreenGui")
    gameOverGui.Name = "GameOverGui"
    gameOverGui.ResetOnSpawn = false
    gameOverGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(500, 400)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = gameOverGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.BackgroundTransparency = 1
    title.Text = "SEMESTER FAILED"
    title.TextColor3 = Color3.fromRGB(255, 50, 50)
    title.TextSize = 32
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    local runStats = Instance.new("TextLabel")
    runStats.Position = UDim2.new(0, 0, 0.2, 0)
    runStats.Size = UDim2.new(1, 0, 0.4, 0)
    runStats.BackgroundTransparency = 1
    runStats.Text = string.format(
        "Final Score: %d\n\nPistachios Collected: %d\nDistance Traveled: %.1fm\nMax Study Streak: %d\nYear Progress: %.1f%%\n\nPistachios Earned: +%d",
        score, 
        pistachiosCollectedInRun, 
        distanceTraveled,
        studyStreakLevel * CONFIG.studyStreakThreshold + (studyStreak % CONFIG.studyStreakThreshold),
        (yearMeter / maxYearMeter) * 100,
        pistachioCount
    )
    runStats.TextColor3 = Color3.fromRGB(240, 240, 240)
    runStats.TextSize = 16
    runStats.Font = Enum.Font.Gotham
    runStats.TextXAlignment = Enum.TextXAlignment.Center
    runStats.Parent = frame

    local totalLabel = Instance.new("TextLabel")
    totalLabel.Position = UDim2.new(0, 0, 0.6, 0)
    totalLabel.Size = UDim2.new(1, 0, 0.15, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = string.format("Total Pistachios: %d", totalPistachios)
    totalLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    totalLabel.TextSize = 20
    totalLabel.Font = Enum.Font.GothamBold
    totalLabel.TextXAlignment = Enum.TextXAlignment.Center
    totalLabel.Parent = frame

    local respawnButton = Instance.new("TextButton")
    respawnButton.Position = UDim2.new(0.1, 0, 0.8, 0)
    respawnButton.Size = UDim2.new(0.8, 0, 0.12, 0)
    respawnButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    respawnButton.Text = "RETAKE SEMESTER"
    respawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    respawnButton.TextSize = 18
    respawnButton.Font = Enum.Font.GothamBold
    respawnButton.BorderSizePixel = 0
    respawnButton.Parent = frame

    respawnButton.Activated:Connect(function()
        gameOverGui:Destroy()
        respawnPlayer()
    end)
end

local function respawnPlayer()
    -- Reset run stats (keep totalPistachios persistent)
    isAlive = true
    isGamePaused = false
    score = 0
    pistachioCount = 0
    pistachiosCollectedInRun = 0
    distanceTraveled = 0
    currentLevelIndex = 1
    currentSpeed = CONFIG.runSpeed
    isInvulnerable = false
    revivesUsedThisRun = 0  -- Reset revives for new run
    
    -- Reset timers to ensure spawning continues
    obstacleTimer = 0
    pistachioTimer = 0
    
    -- Reset streak system
    studyStreak = 0
    studyStreakLevel = 0
    streakMultiplier = 1
    lastPistachioTime = 0
    
    -- Reset year progress
    yearProgress = 0
    yearMeter = 0
    
    -- Clear all obstacles
    for _, obstacle in pairs(obstaclesFolder:GetChildren()) do
        obstacle:Destroy()
    end
    
    -- Clear all pistachios
    for _, pistachio in pairs(pistachiosFolder:GetChildren()) do
        pistachio:Destroy()
    end
    
    print("🔄 New run started! Total pistachios:", totalPistachios)
    updateHud()
end

local function createPistachio(position, rarity)
    rarity = rarity or "common"
    local pistachioData = CONFIG.pistachioValues[rarity]
    print("✨ Creating", rarity, "pistachio at", position)
    
    local pistachio = Instance.new("Part")
    pistachio.Name = "Pistachio_" .. rarity
    pistachio.Shape = Enum.PartType.Ball
    pistachio.Size = Vector3.new(2, 2, 2)  -- Slightly larger for visibility
    pistachio.Color = pistachioData.color
    pistachio.Anchored = true
    pistachio.CanCollide = false
    pistachio.Material = Enum.Material.Neon  -- Make it glow/visible
    pistachio.Position = position  -- Use position directly, no offset
    pistachio.Parent = pistachiosFolder
    
    -- Add rarity attributes
    pistachio:SetAttribute("Rarity", rarity)
    pistachio:SetAttribute("Points", pistachioData.points)
    pistachio:SetAttribute("MetaCurrency", pistachioData.metaCurrency)
    
    print("Pistachio color set to:", pistachioData.color)
    
    -- Add glow effect for rare pistachios
    if rarity == "gold" or rarity == "rare" then
        local light = Instance.new("PointLight")
        light.Brightness = rarity == "rare" and 3 or 1.5
        light.Color = pistachioData.color
        light.Range = 20
        light.Parent = pistachio
        print("Added glow to", rarity, "pistachio")
    end
    
    -- Make rare pistachios bigger
    if rarity == "rare" then
        pistachio.Size = Vector3.new(2.2, 2.2, 2.2)
    elseif rarity == "gold" then
        pistachio.Size = Vector3.new(1.8, 1.8, 1.8)
    end

    -- NO Touched event - we handle collection in updateActiveObjects for consistent behavior
    -- This prevents double-collection issues

    return pistachio
end

local function collectPistachio(pistachio, rarity)
    -- Prevent double-collection and nil checks
    if not pistachio or not pistachio.Parent then
        print("⚠️ Pistachio already destroyed or nil")
        return
    end
    
    if pistachio:GetAttribute("Collected") then
        return
    end
    pistachio:SetAttribute("Collected", true)
    
    local pistachioData = CONFIG.pistachioValues[rarity]
    if not pistachioData then
        print("⚠️ Invalid pistachio rarity:", rarity)
        pistachio:Destroy()
        return
    end
    
    print("Collected", rarity, "pistachio! Points:", pistachioData.points, "Meta currency:", pistachioData.metaCurrency)
    
    -- Create collection animation BEFORE destroying pistachio
    local originalPosition = pistachio.Position
    local originalColor = pistachio.Color
    
    -- Scale up and fade effect
    local collectTween = TweenService:Create(
        pistachio,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = pistachio.Size * 2,
            Transparency = 1,
            Position = originalPosition + Vector3.new(0, 5, 0)
        }
    )
    collectTween:Play()
    
    -- Create floating points text in 3D world
    local pointsPart = Instance.new("Part")
    pointsPart.Name = "FloatingPoints"
    pointsPart.Anchored = true
    pointsPart.CanCollide = false
    pointsPart.Transparency = 1
    pointsPart.Size = Vector3.new(1, 1, 1)
    pointsPart.Position = originalPosition + Vector3.new(0, 2, 0)
    pointsPart.Parent = workspace
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.fromOffset(200, 100)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = pointsPart
    
    local pointsLabel = Instance.new("TextLabel")
    pointsLabel.Size = UDim2.fromScale(1, 1)
    pointsLabel.BackgroundTransparency = 1
    pointsLabel.Text = "+" .. (pistachioData.points * streakMultiplier)
    pointsLabel.TextColor3 = originalColor
    pointsLabel.TextSize = 36
    pointsLabel.Font = Enum.Font.GothamBold
    pointsLabel.TextStrokeTransparency = 0
    pointsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    pointsLabel.Parent = billboardGui
    
    -- Animate floating points
    local pointsFloatTween = TweenService:Create(
        pointsPart,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = originalPosition + Vector3.new(0, 8, 0)}
    )
    
    local pointsFadeTween = TweenService:Create(
        pointsLabel,
        TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1, TextStrokeTransparency = 1}
    )
    
    pointsFloatTween:Play()
    pointsFadeTween:Play()
    
    -- Clean up after animations
    pointsFadeTween.Completed:Connect(function()
        pointsPart:Destroy()
    end)
    
    collectTween.Completed:Connect(function()
        pistachio:Destroy()
    end)
    
    -- Update counters
    pistachioCount += 1
    totalPistachios += pistachioData.metaCurrency
    pistachiosCollectedInRun += 1
    
    -- Update study streak
    studyStreak += 1
    lastPistachioTime = tick()
    print("Study streak now:", studyStreak)
    
    -- Check for streak level up
    local newStreakLevel = math.floor(studyStreak / CONFIG.studyStreakThreshold)
    if newStreakLevel > studyStreakLevel then
        studyStreakLevel = newStreakLevel
        streakMultiplier = CONFIG.studyStreakMultipliers[studyStreakLevel + 1] or CONFIG.studyStreakMultipliers[#CONFIG.studyStreakMultipliers]
        print("🔥 STREAK LEVEL UP! New level:", studyStreakLevel, "Multiplier:", streakMultiplier)
        
        -- Create streak level up effect (safe spawn to avoid blocking)
        task.spawn(function()
            if not hudGui then return end
            
            local streakEffect = Instance.new("Frame")
            streakEffect.Name = "StreakEffect"
            streakEffect.Size = UDim2.fromScale(1, 0.15)
            streakEffect.Position = UDim2.fromScale(0, 0.4)
            streakEffect.AnchorPoint = Vector2.new(0, 0)
            streakEffect.BackgroundColor3 = Color3.fromRGB(255, 215, 0)  -- Gold color
            streakEffect.BackgroundTransparency = 0.3
            streakEffect.BorderSizePixel = 0
            streakEffect.ZIndex = 50
            streakEffect.Parent = hudGui
            
            -- Add "STREAK UP!" text
            local streakText = Instance.new("TextLabel")
            streakText.Size = UDim2.fromScale(1, 1)
            streakText.BackgroundTransparency = 1
            streakText.Text = "🔥 STUDY STREAK x" .. streakMultiplier .. "! 🔥"
            streakText.TextColor3 = Color3.fromRGB(255, 255, 255)
            streakText.TextSize = 36
            streakText.Font = Enum.Font.GothamBold
            streakText.TextStrokeTransparency = 0
            streakText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            streakText.ZIndex = 51
            streakText.Parent = streakEffect
            
            task.wait(1.5)
            if streakEffect and streakEffect.Parent then
                streakEffect:Destroy()
            end
        end)
    end
    
    -- Add score with streak multiplier
    local pointsEarned = pistachioData.points * streakMultiplier
    score += pointsEarned
    print("Points earned:", pointsEarned, "(", pistachioData.points, "x", streakMultiplier, ")")
    
    -- Add to year meter
    yearMeter = math.min(maxYearMeter, yearMeter + (5 * streakMultiplier))
    
    updateHud()
end

local function getObstaclesForLevel(levelIndex)
    local results = {}
    for _, obstacle in ipairs(obstacleDefinitions) do
        if obstacle.level <= levelIndex then
            table.insert(results, obstacle)
        end
    end
    return results
end

local function getStaticObstaclesForLevel(levelIndex)
    local results = {}
    for _, obstacle in ipairs(staticObstacleDefinitions) do
        if obstacle.level <= levelIndex then
            table.insert(results, obstacle)
        end
    end
    return results
end

local function getMovingObstaclesForLevel(levelIndex)
    local results = {}
    for _, obstacle in ipairs(movingObstacleDefinitions) do
        if obstacle.level <= levelIndex then
            table.insert(results, obstacle)
        end
    end
    return results
end

local function spawnObstacle(levelIndex)
    local root = getCharacterRoot()
    if not root then return end
    
    local laneX = CONFIG.lanes[math.random(1, #CONFIG.lanes)]
    -- Use player's Y minus offset (to get ground level relative to player)
    local groundY = root.Position.Y - 3  -- Player root is ~3 studs above ground
    local spawnPosition = Vector3.new(laneX, groundY, root.Position.Z - CONFIG.spawnDistance)
    
    -- Randomly choose obstacle type (weighted)
    local obstacleType = math.random(1, 10)
    local obstacleType = math.random(1, 10)
    
    if obstacleType <= 4 then
        -- Person obstacle (40% chance)
        local available = getObstaclesForLevel(levelIndex)
        if #available > 0 then
            local obstacleDef = available[math.random(1, #available)]
            createPersonObstacle(obstacleDef, spawnPosition)
        end
    elseif obstacleType <= 7 then
        -- Static obstacle (30% chance)
        local available = getStaticObstaclesForLevel(levelIndex)
        if #available > 0 then
            local obstacleDef = available[math.random(1, #available)]
            createStaticObstacle(obstacleDef, spawnPosition)
        end
    else
        -- Moving obstacle (30% chance)
        local available = getMovingObstaclesForLevel(levelIndex)
        if #available > 0 then
            local obstacleDef = available[math.random(1, #available)]
            createMovingObstacle(obstacleDef, spawnPosition)
        end
    end
end

local function determinePistachioRarity()
    local roll = math.random()
    if roll <= CONFIG.pistachioValues.rare.spawnChance then
        print("Spawning RARE pistachio!")
        return "rare"
    elseif roll <= CONFIG.pistachioValues.rare.spawnChance + CONFIG.pistachioValues.gold.spawnChance then
        print("Spawning GOLD pistachio!")
        return "gold"
    else
        return "common"
    end
end

local function createGuidingPistachioTrail(startPos, endPos, pattern)
    pattern = pattern or "straight"
    local trailCount = CONFIG.pistachioBurst
    
    for i = 1, trailCount do
        local progress = (i - 1) / (trailCount - 1)
        local position
        local rarity = determinePistachioRarity()
        
        if pattern == "straight" then
            -- Straight line guidance
            position = startPos:lerp(endPos, progress)
        elseif pattern == "zigzag" then
            -- Zigzag pattern for lane switching practice
            local zigzagOffset = math.sin(progress * math.pi * 2) * 3
            position = startPos:lerp(endPos, progress) + Vector3.new(zigzagOffset, 0, 0)
        elseif pattern == "arc_up" then
            -- Arc upward for jump guidance
            local arcHeight = math.sin(progress * math.pi) * 4
            position = startPos:lerp(endPos, progress) + Vector3.new(0, arcHeight, 0)
        elseif pattern == "arc_low" then
            -- Low arc for slide guidance
            position = startPos:lerp(endPos, progress) + Vector3.new(0, -1 * math.sin(progress * math.pi), 0)
        else
            position = startPos:lerp(endPos, progress)
        end
        
        -- Ensure pistachios stay within lane boundaries (keep original Y from lerp)
        position = Vector3.new(
            math.clamp(position.X, CONFIG.lanes[1] + 1.5, CONFIG.lanes[#CONFIG.lanes] - 1.5),
            position.Y, -- Keep the Y from the lerped position
            position.Z
        )
        
        createPistachio(position, rarity)
        task.wait(0.1) -- Small delay for trail effect
    end
end

local function spawnPistachio()
    local root = getCharacterRoot()
    if not root then 
        print("⚠️ No root found, skipping pistachio spawn")
        return 
    end
    
    print("🥜 Spawning pistachios - Player at:", root.Position)
    
    -- Spawn pistachios in front of the player (negative Z is forward)
    for i = 1, CONFIG.pistachioBurst do
        local laneX = CONFIG.lanes[math.random(1, #CONFIG.lanes)]
        -- Spawn in front: subtract from Z (more negative = further ahead)
        local zOffset = -(CONFIG.spawnDistance + (i * 8))
        local spawnPosition = Vector3.new(
            laneX,
            root.Position.Y - 2, -- Slightly below player (player is ~3 studs tall, root is at center)
            root.Position.Z + zOffset
        )
        local rarity = determinePistachioRarity()
        print("  Pistachio", i, "at:", spawnPosition, "Rarity:", rarity)
        createPistachio(spawnPosition, rarity)
    end
end

local function updateActiveObjects(dt)
    local root = getCharacterRoot()
    
    -- Don't update if game is paused
    if isGamePaused or not isAlive then
        return
    end

    -- Update obstacles
    for _, obstacle in ipairs(obstaclesFolder:GetChildren()) do
        if obstacle:IsA("Model") and obstacle.PrimaryPart then
            local hitbox = obstacle.PrimaryPart
            local obstacleType = obstacle:GetAttribute("Type")
            
            -- Check if obstacle should be destroyed (too far away)
            if hitbox.Position.Z > root.Position.Z + CONFIG.despawnDistance then
                obstacle:Destroy()
                continue
            end
            
            -- CHECK FOR COLLISION WITH PLAYER (SUBWAY SURFERS STYLE: ONE-HIT CRASH)
            local distance = (hitbox.Position - root.Position).Magnitude
            if distance <= 4 and not isInvulnerable and isAlive then -- 4 studs collision range
                print("💥 COLLISION DETECTED! Obstacle:", obstacle.Name, "Distance:", distance)
                crashPlayer()  -- One-hit death like Subway Surfers!
                
                -- Destroy obstacle on hit
                obstacle:Destroy()
                continue
            end
            
            if obstacleType == "moving" then
                -- Handle moving obstacles
                local speed = obstacle:GetAttribute("Speed") or 5
                local direction = obstacle:GetAttribute("Direction") or 1
                local originalX = obstacle:GetAttribute("OriginalX") or hitbox.Position.X
                
                -- Move side to side
                local newX = hitbox.Position.X + direction * speed * dt
                
                -- Bounce off boundaries (lane system)
                if newX > CONFIG.lanes[#CONFIG.lanes] + 3 then
                    direction = -1
                    obstacle:SetAttribute("Direction", direction)
                elseif newX < CONFIG.lanes[1] - 3 then
                    direction = 1
                    obstacle:SetAttribute("Direction", direction)
                end
                
                hitbox.Position = Vector3.new(newX, hitbox.Position.Y, hitbox.Position.Z)
                
            elseif obstacleType ~= "static" then
                -- Handle person obstacles (original chase logic)
                local detectionZone = obstacle:FindFirstChild("DetectionZone")
                
                if detectionZone then
                    local distanceToPlayer = (hitbox.Position - root.Position).Magnitude
                    local isChasing = obstacle:GetAttribute("IsChasing") or false
                    
                    if distanceToPlayer <= CONFIG.obstacleDetectionRange and not isChasing then
                        obstacle:SetAttribute("IsChasing", true)
                        print("📍 Obstacle", obstacle.Name, "started chasing player!")
                    elseif isChasing then
                        local direction = (root.Position - hitbox.Position).Unit
                        local newPosition = hitbox.Position + direction * CONFIG.obstacleChaseSpeed * dt
                        newPosition = Vector3.new(newPosition.X, hitbox.Position.Y, newPosition.Z)
                        
                        hitbox.Position = newPosition
                        detectionZone.Position = newPosition
                        
                        if distanceToPlayer > CONFIG.obstacleDetectionRange * 2 then
                            obstacle:SetAttribute("IsChasing", false)
                            print("📍 Obstacle", obstacle.Name, "stopped chasing player")
                        end
                    end
                end
            end
        end
    end

    -- Update pistachios with magnet effect AND collision detection
    for _, pistachio in ipairs(pistachiosFolder:GetChildren()) do
        if pistachio:IsA("BasePart") and not pistachio:GetAttribute("Collected") then
            if pistachio.Position.Z > root.Position.Z + CONFIG.despawnDistance then
                pistachio:Destroy()
            else
                -- Check for pistachio collection
                local distance = (pistachio.Position - root.Position).Magnitude
                if distance <= 3.5 then -- Collection range
                    local rarity = pistachio:GetAttribute("Rarity") or "common"
                    print("🌰 PISTACHIO COLLECTED! Rarity:", rarity, "Distance:", distance)
                    
                    -- Wrap in pcall to prevent errors from stopping the game loop
                    local success, err = pcall(function()
                        collectPistachio(pistachio, rarity)
                    end)
                    
                    if not success then
                        print("⚠️ Error collecting pistachio:", err)
                        pistachio:Destroy() -- Just destroy it if collection fails
                    end
                    continue
                end
                
                -- Magnetic attraction when close
                if distance <= CONFIG.pistachioMagnetRange then
                    local direction = (root.Position - pistachio.Position).Unit
                    local magnetForce = (CONFIG.pistachioMagnetRange - distance) / CONFIG.pistachioMagnetRange
                    local pullSpeed = 15 * magnetForce
                    pistachio.Position = pistachio.Position + direction * pullSpeed * dt
                end
            end
        end
    end
end

local function attackNearestObstacle()
    if not canAttack then
        return
    end

    canAttack = false
    local root = getCharacterRoot()
    local closest
    local closestDistance = CONFIG.attackRange

    -- Check obstacles
    for _, obstacle in ipairs(obstaclesFolder:GetChildren()) do
        if obstacle:IsA("Model") and obstacle.PrimaryPart then
            local distance = (obstacle.PrimaryPart.Position - root.Position).Magnitude
            if distance <= closestDistance then
                closest = obstacle
                closestDistance = distance
            end
        end
    end

    if closest then
        local health = closest:GetAttribute("Health") or 1
        health -= 1
        closest:SetAttribute("Health", health)

        if closest.PrimaryPart then
            closest.PrimaryPart.Color = Color3.fromRGB(255, 110, 110)
            task.delay(0.1, function()
                if closest.PrimaryPart then
                    closest.PrimaryPart.Color = Color3.fromRGB(35, 127, 200)
                end
            end)
        end

        if health <= 0 then
            score += closest:GetAttribute("Points") or 50
            closest:Destroy()
            updateHud()
        end
    end

    task.delay(CONFIG.attackCooldown, function()
        canAttack = true
    end)
end

local function connectAttackInput()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.KeyCode == Enum.KeyCode.F
            or input.KeyCode == Enum.KeyCode.E then
            attackNearestObstacle()
        end
    end)
end

-- Timers as module-level variables to persist properly
local obstacleTimer = 0
local pistachioTimer = 0
local gameLoopConnection = nil  -- Track the connection

local function startRunner()
    print("🎮 FAF RUN — Credite, Cafele, Colocvii!")
    print("🥜 Revive Cost:", CONFIG.reviveCost, "pistachios")
    print("❤️ Max Revives Per Run:", CONFIG.maxRevivesPerRun)
    
    createHud()
    setSkyBackground()
    updateHud()
    
    -- Reset timers
    obstacleTimer = 0
    pistachioTimer = 0

    connectAttackInput()
    
    -- Disconnect old connection if it exists (prevents duplicate loops)
    if gameLoopConnection then
        gameLoopConnection:Disconnect()
    end

    gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
        -- Don't update if game is paused (crash screen showing)
        if isGamePaused or not isAlive then
            return
        end
        
        distanceTraveled += currentSpeed * dt
        local newLevelIndex = getLevelForDistance(distanceTraveled)
        if newLevelIndex ~= currentLevelIndex then
            currentLevelIndex = newLevelIndex
            print("🎓 PROMOTED TO:", levels[currentLevelIndex].name)
            updateHud()
        end

        local currentLevel = levels[currentLevelIndex]
        if not currentLevel then
            print("⚠️ ERROR: No level found for index", currentLevelIndex)
            return
        end
        
        obstacleTimer += dt
        pistachioTimer += dt
        
        -- Debug: Log timer status every 5 seconds
        if math.floor(pistachioTimer * 10) % 50 == 0 and pistachioTimer > 0.1 then
            print("🔍 Timer check - Pistachio:", string.format("%.2f", pistachioTimer), "/", currentLevel.pistachioInterval, "Obstacle:", string.format("%.2f", obstacleTimer))
        end

        -- Make obstacles spawn more frequently as you progress
        local difficultyMultiplier = 1 + (currentLevelIndex - 1) * 0.1
        local adjustedObstacleInterval = currentLevel.obstacleInterval / difficultyMultiplier

        if obstacleTimer >= adjustedObstacleInterval then
            obstacleTimer = 0
            spawnObstacle(currentLevelIndex)
            
            -- Occasional double obstacles only in higher levels
            if currentLevelIndex >= 3 and math.random() > 0.8 then  -- 20% chance in year 3+
                task.wait(0.5)
                spawnObstacle(currentLevelIndex)
            end
        end

        -- INFINITE PISTACHIO SPAWNING - spawns continuously based on interval
        if pistachioTimer >= currentLevel.pistachioInterval then
            pistachioTimer = 0
            print("⏰ Pistachio timer triggered! Spawning batch...")
            spawnPistachio()
        end

        updateActiveObjects(dt)
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(0.2)
    startRunner()
end)

if player.Character then
    startRunner()
end
