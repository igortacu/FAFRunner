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
    reviveCost = 5, -- Cost in pistachios to continue after crash
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
        Braga = "rbxassetid://YOUR_IMAGE_ID",
        Tronciu = "rbxassetid://YOUR_IMAGE_ID",
    },
    pistachioImageId = "rbxassetid://YOUR_PISTACHIO_IMAGE_ID",
    -- Speed pad system
    speedPads = {
        slowdown = {
            color = Color3.fromRGB(255, 50, 50),
            speedMultiplier = 0.6,
            particleColor = Color3.fromRGB(255, 100, 100),
            trailDuration = 3,
            width = 6,           -- FIXED: Increased from 5
            height = 0.3,        -- FIXED: Reduced from 0.5 to sit flush
            spawnChance = 0.15,
            effectDuration = 3,  -- NEW: Explicit duration
        },
        speedup = {
            color = Color3.fromRGB(50, 255, 50),
            speedMultiplier = 1.5,
            particleColor = Color3.fromRGB(100, 255, 100),
            trailDuration = 3,
            width = 6,           -- FIXED: Increased from 5
            height = 0.3,        -- FIXED: Reduced from 0.5
            spawnChance = 0.15,
            effectDuration = 3,
        },
    },

    powerUps = {
        shield = {
            color = Color3.fromRGB(100, 200, 255),
            duration = 5,
            icon = "🛡️",
            spawnChance = 0.25,
        },
        doublePoints = {
            color = Color3.fromRGB(255, 215, 0),
            duration = 8,
            icon = "⭐",
            spawnChance = 0.3,
        },
        magnetBoost = {
            color = Color3.fromRGB(255, 100, 255),
            duration = 6,
            icon = "🧲",
            spawnChance = 0.35,
        },
    }
}

local levels = {
    {
        name = "Year 1",
        checkpointDistance = 0,
        obstacleInterval = 3.0,  -- Calmer start (fewer obstacles)
        pistachioInterval = 1.1,
    },
    {
        name = "Year 2", 
        checkpointDistance = 300,
        obstacleInterval = 2.4,  -- Moderate
        pistachioInterval = 1.0,
    },
    {
        name = "Year 3",
        checkpointDistance = 650,
        obstacleInterval = 1.8,  -- Getting harder
        pistachioInterval = 0.95,
    },
    {
        name = "Year 4",
        checkpointDistance = 1000,
        obstacleInterval = 1.4,  -- Challenging but fair
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

local platformsFolder = runnerWorld:FindFirstChild("Platforms") or Instance.new("Folder")
platformsFolder.Name = "Platforms"
platformsFolder.Parent = runnerWorld

local speedPadsFolder = runnerWorld:FindFirstChild("SpeedPads") or Instance.new("Folder")
speedPadsFolder.Name = "SpeedPads"
speedPadsFolder.Parent = runnerWorld

local powerUpsFolder = runnerWorld:FindFirstChild("PowerUps") or Instance.new("Folder")
powerUpsFolder.Name = "PowerUps"
powerUpsFolder.Parent = runnerWorld

local activePowerUps = {}
local hasShield = false
local doublePointsActive = false
local magnetBoostActive = false
local powerUpTimer = 0
local powerUpLabel  -- Add to HUD variables

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
local gameLoopConnection = nil  -- Track the Heartbeat connection

-- Speed modifier system
local speedModifier = 1.0  -- Multiplier for current speed (1.0 = normal, 1.5 = 50% faster, 0.6 = 40% slower)
local speedModifierEndTime = 0  -- When the current speed modifier expires
local activeSpeedPadType = nil  -- Track what type of pad is active for particle effects
local currentTrailColor = nil  -- Color of current trail

-- Timers as module-level variables to persist properly
local obstacleTimer = 0
local pistachioTimer = 0
local speedPadTimer = 0
local hudUpdateTimer = 0
local pinkRefreshTimer = 0

-- Study Streak system
local studyStreak = 0
local studyStreakLevel = 0
local pistachiosCollectedInRun = 0
local lastPistachioTime = 0
local streakMultiplier = 1
local totalMultiplier = 1  -- Calculate based on streak and double points

-- Year progress system
local yearProgress = 0
local yearMeter = 0
local maxYearMeter = 5000

-- Checkpoint system variables
local lastCheckpointReached = 0
local savedCheckpointPosition = Vector3.new(0, 55, 0)  -- Start position (GROUND_Y + 5)

local hudGui
local pistachioLabel
local scoreLabel
local levelLabel
local healthLabel
local streakLabel
local yearLabel
local checkpointLabel  -- New label for checkpoints
local speedEffectLabel  -- Add speed effect label

local function getCharacterRoot()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local platformWidth = 18  -- Width across all lanes
local platformHeight = 1  -- Thickness
local gapMinLength = 5    -- Minimum gap size (smaller for easier early jumps)
local gapMaxLength = 9    -- Maximum gap size (tighter gaps overall)
local platformColor = Color3.fromRGB(40, 40, 45)  -- Dark subtle ground
local lastPlatformZ = 0   -- Track where we last spawned a platform
local GROUND_Y = 50       -- Fixed ground level HIGH above base
local platformSegmentLength = 20  -- Length of each solid segment (reduced for more gaps)
local distanceBeforeGaps = 0 -- Gaps can start immediately

-- Helper to style platform parts (dark, subtle ground)
local function paintPlatform(part)
    part.Material = Enum.Material.SmoothPlastic
    part.Color = Color3.fromRGB(40, 40, 45)
end

-- Checkpoint System
local checkpoints = {}
local lastCheckpointDistance = 0
local checkpointInterval = 50  -- Checkpoint every 150 studs
local currentCheckpoint = 0
local checkpointColor = Color3.fromRGB(100, 255, 100)  -- Green checkpoints

local function createPlatformSegment(zPosition, length)
    local platform = Instance.new("Part")
    platform.Name = "RunnerPlatform"
    platform.Size = Vector3.new(platformWidth, platformHeight, length)
    platform.Position = Vector3.new(0, GROUND_Y, zPosition)
    platform.Anchored = true
    platform.CanCollide = true
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.CastShadow = false
    paintPlatform(platform)
    
    platform.Parent = platformsFolder
    
    return platform
end

local function createCheckpoint(zPosition)
    local checkpoint = Instance.new("Part")
    checkpoint.Name = "Checkpoint"
    checkpoint.Size = Vector3.new(platformWidth - 2, 1, 3)
    checkpoint.Position = Vector3.new(0, GROUND_Y + 2, zPosition)  -- Float above platform
    checkpoint.Anchored = true
    checkpoint.Color = checkpointColor
    checkpoint.Material = Enum.Material.Neon
    checkpoint.Transparency = 0.5  -- More transparent
    checkpoint.CanCollide = false
    checkpoint.Parent = platformsFolder
    
    -- Add checkpoint number
    checkpoint:SetAttribute("CheckpointNumber", currentCheckpoint + 1)
    
    -- Add glow effect
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = checkpointColor
    light.Range = 25
    light.Parent = checkpoint
    
    print("✅ Created checkpoint #", currentCheckpoint + 1, "at Z:", zPosition)
    return checkpoint
end

local function spawnPlatformAhead()
    local root = getCharacterRoot()
    if not root then return end
    
    -- Only spawn platforms if we're getting close to the end of existing ones
    if lastPlatformZ < root.Position.Z - CONFIG.spawnDistance - 50 then
        return  -- Already have enough platforms ahead
    end
    
    -- Check if we should spawn a checkpoint
    local currentDistance = math.abs(lastPlatformZ)
    if currentDistance - lastCheckpointDistance >= checkpointInterval then
        createCheckpoint(lastPlatformZ - 10)  -- Place checkpoint ahead
        lastCheckpointDistance = currentDistance
        currentCheckpoint = currentCheckpoint + 1
    end
    
    -- Determine if this section will have a gap (obby-style)
    -- NO GAPS until player has traveled distanceBeforeGaps
    local hasGap = false
    if distanceTraveled > distanceBeforeGaps then
        -- Ramp gap frequency gently with progress/level so early game is calmer
        local baseGapChance = 0.4
        local distanceBump = math.clamp(distanceTraveled / 600, 0, 1) * 0.25  -- up to +25%
        local levelBump = (currentLevelIndex - 1) * 0.05
        local gapChance = math.clamp(baseGapChance + distanceBump + levelBump, 0, 0.75)
        hasGap = math.random() < gapChance
    end
    
    if hasGap then
        -- Create ACTUAL GAP by not spawning platform (player will fall through)
        local gapLength = math.random(gapMinLength, gapMaxLength)
        lastPlatformZ = lastPlatformZ - gapLength
        print("🕳️ Created ACTUAL GAP (no platform) of", gapLength, "studs at Z:", lastPlatformZ)
    end
    
    -- Create solid platform segment (shorter segments for more frequent gaps)
    local segmentLength = math.random(platformSegmentLength - 3, platformSegmentLength + 8)  -- 17-28 studs
    local zPos = lastPlatformZ - segmentLength / 2
    createPlatformSegment(zPos, segmentLength)
    lastPlatformZ = lastPlatformZ - segmentLength
end

local function cleanupOldPlatforms()
    local root = getCharacterRoot()
    if not root then return end
    
    -- Remove platforms that are far behind the player
    for _, platform in ipairs(platformsFolder:GetChildren()) do
        if platform:IsA("Part") and platform.Position.Z > root.Position.Z + 40 then
            platform:Destroy()
        end
    end
end

local function initializePlatforms()
    -- Clear old platforms
    for _, platform in ipairs(platformsFolder:GetChildren()) do
        platform:Destroy()
    end
    
    -- Remove any default Baseplate that might be grey
    local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("Base")
    if baseplate then
        baseplate:Destroy()
        print("🗑️ Removed default baseplate")
    end
    
    -- Reset checkpoint system
    lastCheckpointDistance = 0
    currentCheckpoint = 0
    
    local root = getCharacterRoot()
    if not root then 
        print("⚠️ No root found during platform initialization")
        return 
    end
    
    -- GROUND_Y is now a constant (50) - keep platforms high!
    
    -- Start creating platforms from ahead of the player
    lastPlatformZ = root.Position.Z + 20  -- Start a bit behind
    
    -- Create initial stretch with gaps allowed immediately (but gentler)
    for i = 1, 14 do
        local createGap = (i > 3) and (math.random() < 0.4)
        if createGap then
            local gapLength = math.random(gapMinLength, gapMaxLength)
            lastPlatformZ = lastPlatformZ - gapLength
            print("🕳️ Initial gap of", gapLength, "studs at Z:", lastPlatformZ)
        end
        local segmentLength = math.random(platformSegmentLength - 3, platformSegmentLength + 8)
        local zPos = lastPlatformZ - segmentLength / 2
        createPlatformSegment(zPos, segmentLength)
        lastPlatformZ = lastPlatformZ - segmentLength
    end

    -- Ensure all platforms are styled (safety)
    for _, part in ipairs(platformsFolder:GetChildren()) do
        if part:IsA("BasePart") then
            paintPlatform(part)
        end
    end
    
    print("🎨 Initialized platform system at Y:", GROUND_Y)
end

-- Periodically repaint platforms to enforce the style (catches any leftover defaults)
local function refreshPlatformStyle()
    for _, part in ipairs(platformsFolder:GetChildren()) do
        if part:IsA("BasePart") then
            paintPlatform(part)
        end
    end
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
    frame.Size = UDim2.fromOffset(320, 230)  -- Room for all 7 labels
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
    checkpointLabel = makeLabel()  -- Add checkpoint label
    speedEffectLabel = makeLabel()  -- Add speed effect label
    
    speedEffectLabel.Text = "⚡ Speed: Normal"
    speedEffectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

    powerUpLabel = makeLabel()
    powerUpLabel.Text = "💎 Power-ups: None"
    powerUpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

    -- Update frame size:
    frame.Size = UDim2.fromOffset(320, 260)  -- Was 230
end

local function updateHud()
    if not levelLabel or not scoreLabel or not pistachioLabel then
        return  -- HUD not created yet
    end
    
    -- Calculate total multiplier from active power-ups
    totalMultiplier = streakMultiplier * (doublePointsActive and 2 or 1)
    
    local level = levels[currentLevelIndex]
    if not level then
        return
    end

    levelLabel.Text = string.format("📍 %s", level.name)
    
    -- Enhance score display to highlight active multiplier
    if doublePointsActive then
        scoreLabel.Text = string.format("⭐ Score: %d (x%.1f) ⚡ 2x ACTIVE!", math.floor(score), totalMultiplier)
        scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 100)  -- Gold highlight when 2x active
    else
        scoreLabel.Text = string.format("⭐ Score: %d (x%.1f)", math.floor(score), totalMultiplier)
        scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Normal white
    end
    
    pistachioLabel.Text = string.format("🥜 Pistachios: %d | 💰 %d", pistachiosCollectedInRun, totalPistachios)
    
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
    
    -- Checkpoint display
    checkpointLabel.Text = string.format("✅ Checkpoint: #%d", lastCheckpointReached)
    checkpointLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    -- Speed effect display
    if speedModifier ~= 1.0 then
        if speedModifier > 1.0 then
            speedEffectLabel.Text = string.format("⚡ SPEEDUP: %.1fx (%.1fs)", speedModifier, math.max(0, speedModifierEndTime - tick()))
            speedEffectLabel.TextColor3 = CONFIG.speedPads.speedup.color
        else
            speedEffectLabel.Text = string.format("🐌 SLOWDOWN: %.1fx (%.1fs)", speedModifier, math.max(0, speedModifierEndTime - tick()))
            speedEffectLabel.TextColor3 = CONFIG.speedPads.slowdown.color
        end
    else
        speedEffectLabel.Text = "⚡ Speed: Normal"
        speedEffectLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    -- Power-up display with active effects highlighted
    local activePowerUpTexts = {}
    if hasShield then
        table.insert(activePowerUpTexts, "🛡️ SHIELD ACTIVE")
    end
    if doublePointsActive then
        table.insert(activePowerUpTexts, "⭐ 2x POINTS!")
    end
    if magnetBoostActive then
        table.insert(activePowerUpTexts, "🧲 MAGNET BOOST")
    end

    if #activePowerUpTexts > 0 then
        powerUpLabel.Text = "💎 " .. table.concat(activePowerUpTexts, " | ")
        powerUpLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        powerUpLabel.Text = "💎 Power-ups: None"
        powerUpLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end

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

-- Forward declarations
local connectLethalTouch
local connectModelLethal
local crashPlayer
local showReviveScreen
local gameOver
local collectPistachio
local checkForCheckpointTouch
local startRunner
local respawnPlayer

-- ========== FIX: ADD MISSING OBSTACLE CREATION FUNCTIONS ==========
local function createPersonObstacle(obstacleDef, position)
    print("🛠️ Creating person obstacle:", obstacleDef.name)
    
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(4, 6, 2)
    hitbox.Transparency = 0
    hitbox.Anchored = true
    hitbox.CanCollide = true
    hitbox.Material = Enum.Material.Metal
    hitbox.Color = Color3.fromRGB(200, 80, 80)
    hitbox.Position = position + Vector3.new(0, 3, 0)
    hitbox.Parent = model
    
    -- Add a simple humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.Health = obstacleDef.health or 3
    humanoid.MaxHealth = obstacleDef.health or 3
    humanoid.Parent = model
    
    model.PrimaryPart = hitbox
    model:SetAttribute("Health", obstacleDef.health or 3)
    model:SetAttribute("Points", obstacleDef.points or 50)
    model:SetAttribute("Type", "person")
    
    -- Make it lethal
    hitbox.Touched:Connect(function(hit)
        local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Parent == player.Character and isAlive and not isInvulnerable then
            if hasShield then
                -- Shield absorbs hit
                hasShield = false
                print("🛡️ Shield absorbed hit!")
                updateHud()
                
                -- Shield break effect
                local shieldBreak = Instance.new("Part")
                shieldBreak.Shape = Enum.PartType.Ball
                shieldBreak.Size = Vector3.new(8, 8, 8)
                shieldBreak.Position = hit.Parent.HumanoidRootPart.Position
                shieldBreak.Anchored = true
                shieldBreak.CanCollide = false
                shieldBreak.Color = CONFIG.powerUps.shield.color
                shieldBreak.Material = Enum.Material.Neon
                shieldBreak.Transparency = 0.3
                shieldBreak.Parent = workspace
                
                local tween = TweenService:Create(
                    shieldBreak,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = Vector3.new(15, 15, 15), Transparency = 1}
                )
                tween:Play()
                task.delay(0.5, function()
                    shieldBreak:Destroy()
                end)
            else
                crashPlayer()
            end
        end
    end)
    
    return model
end

local function createStaticObstacle(obstacleDef, position)
    print("🛠️ Creating static obstacle:", obstacleDef.name)
    
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    
    -- Different shapes for variety
    if obstacleDef.name == "Pole" or obstacleDef.name == "Pillar" then
        hitbox.Shape = Enum.PartType.Cylinder
        hitbox.Size = Vector3.new(obstacleDef.height, obstacleDef.width, obstacleDef.width)
        hitbox.Orientation = Vector3.new(0, 0, 90)
    elseif obstacleDef.name == "Spikes" then
        hitbox.Shape = Enum.PartType.Wedge
        hitbox.Size = Vector3.new(obstacleDef.width, obstacleDef.height, 3)
    else
        hitbox.Size = Vector3.new(obstacleDef.width, obstacleDef.height, 3)
    end
    
    hitbox.Color = obstacleDef.color
    hitbox.Material = Enum.Material.SmoothPlastic
    hitbox.Anchored = true
    hitbox.CanCollide = true
    hitbox.Position = position + Vector3.new(0, obstacleDef.height/2, 0)
    hitbox.Parent = model
    
    -- Make it lethal
    hitbox.Touched:Connect(function(hit)
        local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Parent == player.Character and isAlive and not isInvulnerable then
            if hasShield then
                -- Shield absorbs hit
                hasShield = false
                print("🛡️ Shield absorbed hit!")
                updateHud()
                
                -- Shield break effect
                local shieldBreak = Instance.new("Part")
                shieldBreak.Shape = Enum.PartType.Ball
                shieldBreak.Size = Vector3.new(8, 8, 8)
                shieldBreak.Position = hit.Parent.HumanoidRootPart.Position
                shieldBreak.Anchored = true
                shieldBreak.CanCollide = false
                shieldBreak.Color = CONFIG.powerUps.shield.color
                shieldBreak.Material = Enum.Material.Neon
                shieldBreak.Transparency = 0.3
                shieldBreak.Parent = workspace
                
                local tween = TweenService:Create(
                    shieldBreak,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = Vector3.new(15, 15, 15), Transparency = 1}
                )
                tween:Play()
                task.delay(0.5, function()
                    shieldBreak:Destroy()
                end)
            else
                crashPlayer()
            end
        end
    end)
    
    model.PrimaryPart = hitbox
    model:SetAttribute("Type", "static")
    
    return model
end

local function createMovingObstacle(obstacleDef, position)
    print("🛠️ Creating moving obstacle:", obstacleDef.name)
    
    local model = Instance.new("Model")
    model.Name = obstacleDef.name
    model.Parent = obstaclesFolder

    local hitbox = Instance.new("Part")
    hitbox.Name = "Hitbox"
    hitbox.Size = Vector3.new(obstacleDef.width, obstacleDef.height, 3)
    hitbox.Color = obstacleDef.color
    hitbox.Material = Enum.Material.Metal
    hitbox.Anchored = true
    hitbox.CanCollide = true
    hitbox.Position = position + Vector3.new(0, obstacleDef.height/2, 0)
    hitbox.Parent = model
    
    -- Make it lethal
    hitbox.Touched:Connect(function(hit)
        local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Parent == player.Character and isAlive and not isInvulnerable then
            crashPlayer()
        end
    end)
    
    model.PrimaryPart = hitbox
    model:SetAttribute("Type", "moving")
    model:SetAttribute("Speed", obstacleDef.speed)
    model:SetAttribute("Direction", math.random() > 0.5 and 1 or -1)
    model:SetAttribute("OriginalX", position.X)
    
    return model
end

-- ========== ACTIVATION FUNCTIONS (Must be before create* functions) ==========
-- Reusable activation for power-ups (so proximity + touch both work)
local function activatePowerUpInstance(powerUp)
    if not powerUp or not powerUp.Parent then return end
    if powerUp:GetAttribute("Collected") then return end

    powerUp:SetAttribute("Collected", true)
    local powerUpType = powerUp:GetAttribute("Type") or "shield"
    local powerUpConfig = CONFIG.powerUps[powerUpType]
    print("💎 Activated power-up:", powerUpType)

    if powerUpType == "shield" then
        hasShield = true
        print("🛡️ Shield activated for", powerUpConfig.duration, "seconds")
        task.delay(powerUpConfig.duration, function()
            hasShield = false
            print("🛡️ Shield expired")
            updateHud()
        end)
    elseif powerUpType == "doublePoints" then
        doublePointsActive = true
        print("⭐ Double Points activated for", powerUpConfig.duration, "seconds")
        task.delay(powerUpConfig.duration, function()
            doublePointsActive = false
            print("⭐ Double Points expired")
            updateHud()
        end)
    elseif powerUpType == "magnetBoost" then
        magnetBoostActive = true
        print("🧲 Magnet Boost activated for", powerUpConfig.duration, "seconds")
        task.delay(powerUpConfig.duration, function()
            magnetBoostActive = false
            print("🧲 Magnet Boost expired")
            updateHud()
        end)
    end

    -- Collection animation + cleanup
    local tween = TweenService:Create(
        powerUp,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = Vector3.new(0,0,0), Transparency = 1}
    )
    tween:Play()
    tween.Completed:Connect(function()
        if powerUp and powerUp.Parent then
            powerUp:Destroy()
        end
    end)

    updateHud()  -- Update immediately so player sees power-up is active
end

-- Reusable activation for speed pads (so proximity + touch both work)
local function activateSpeedPad(pad)
    if not pad or not pad.Parent then return end
    if pad:GetAttribute("Collected") then return end

    pad:SetAttribute("Collected", true)
    local padType = pad:GetAttribute("Type") or "speedup"
    local padConfig = CONFIG.speedPads[padType]
    if not padConfig then return end

    speedModifier = padConfig.speedMultiplier
    speedModifierEndTime = tick() + (padConfig.effectDuration or 3)
    activeSpeedPadType = padType
    currentTrailColor = padConfig.particleColor

    -- Collection animation
    local tween = TweenService:Create(
        pad,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Size = Vector3.new(0,0,0), Transparency = 1}
    )
    tween:Play()
    tween.Completed:Connect(function()
        if pad and pad.Parent then
            pad:Destroy()
        end
    end)

    print("✅ Speed modifier applied: " .. tostring(padConfig.speedMultiplier) .. "x for " .. tostring(padConfig.effectDuration) .. " seconds")
    updateHud()
end

-- ========== FIX: ENHANCED SPEED PAD SYSTEM ==========
local function createSpeedPad(position, padType)
    padType = padType or (math.random() > 0.5 and "speedup" or "slowdown")
    local padConfig = CONFIG.speedPads[padType]
    
    print("⚡ Creating", padType, "pad at", position)
    
    -- FIXED: Main pad part - sits FLUSH on platform
    local pad = Instance.new("Part")
    pad.Name = "SpeedPad_" .. padType
    pad.Size = Vector3.new(padConfig.width, padConfig.height, padConfig.width)
    pad.Color = padConfig.color
    pad.Anchored = true
    pad.CanCollide = false  -- FIXED: Changed from true to false
    pad.Material = Enum.Material.Neon
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad.Transparency = 0.2  -- FIXED: Was not set, now 0.2 for visibility
    pad.Position = position
    pad.Parent = speedPadsFolder
    
    pad:SetAttribute("Type", padType)
    pad:SetAttribute("Collected", false)
    pad:SetAttribute("SpawnTime", tick())  -- Track spawn time to delay proximity activation
    
    -- FIXED: Much brighter glow
    local light = Instance.new("PointLight")
    light.Brightness = 5  -- FIXED: Increased from 2
    light.Color = padConfig.color
    light.Range = 30      -- FIXED: Increased from 25
    light.Parent = pad
    
    -- Icon billboard positioned in 3D space (not overlay)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(120, 120)
    billboard.StudsOffset = Vector3.new(0, 3, 0)  -- Adjusted for ground-level positioning
    billboard.Adornee = pad
    billboard.AlwaysOnTop = false  -- Respect 3D depth - appears behind obstacles
    billboard.Parent = pad
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.Text = padType == "speedup" and "⚡" or "🐌"
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.TextSize = 50  -- FIXED: Increased from 40
    icon.Font = Enum.Font.GothamBold
    icon.TextStrokeTransparency = 0      -- NEW: Added outline
    icon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    icon.Parent = billboard
    
    -- STATIC on platform - no floating animation
    -- Speed pads stay fixed at spawn position on the running platform
    task.spawn(function()
        while pad and pad.Parent and not pad:GetAttribute("Collected") do
            if pad and pad.Parent then
                pad.CFrame = pad.CFrame * CFrame.Angles(0, math.rad(1.5), 0)
            end
            task.wait(0.016)
        end
    end)
    
    -- Touch detection for collection (delegates to reusable activation function)
    pad.Touched:Connect(function(hit)
        if hit and hit.Parent then
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent == player.Character and not pad:GetAttribute("Collected") and isAlive then
                local success, err = pcall(function()
                    activateSpeedPad(pad)
                end)
                if not success then
                    warn("⚠️ Error activating speed pad:", err)
                end
            end
        end
    end)
    
    return pad
end

-- Create particle trail effect when player is under speed pad effect
local function createParticleTrail()
    if not activeSpeedPadType or not currentTrailColor then
        return
    end
    
    local root = getCharacterRoot()
    if not root then return end
    
    local padConfig = CONFIG.speedPads[activeSpeedPadType]
    if not padConfig then return end
    
    -- Create multiple particles for better trail effect
    for i = 1, 3 do
        local particle = Instance.new("Part")
        particle.Name = "SpeedTrail"
        particle.Shape = Enum.PartType.Ball
        particle.Size = Vector3.new(0.8, 0.8, 0.8)
        particle.Color = currentTrailColor
        particle.Anchored = true
        particle.CanCollide = false
        particle.Material = Enum.Material.Neon
        particle.Position = root.Position - Vector3.new(0, 2, 0) + Vector3.new(
            (math.random() - 0.5) * 3,
            math.random() * 1.5,
            (math.random() - 0.5) * 2 - 2
        )
        particle.Parent = workspace
        
        -- Animate particle - scale down and fade out
        local tween = TweenService:Create(
            particle,
            TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1,
                Position = particle.Position + Vector3.new(0, 0, -4)
            }
        )
        tween:Play()
        
        -- Destroy after animation
        tween.Completed:Connect(function()
            particle:Destroy()
        end)
    end
end

-- Power-up creation function
local function createPowerUp(position, powerUpType)
    powerUpType = powerUpType or "shield"
    local powerUpConfig = CONFIG.powerUps[powerUpType]
    
    print("💎 Creating", powerUpType, "power-up at", position)
    
    local powerUp = Instance.new("Part")
    powerUp.Name = "PowerUp_" .. powerUpType
    powerUp.Shape = Enum.PartType.Ball
    powerUp.Size = Vector3.new(3, 3, 3)
    powerUp.Color = powerUpConfig.color
    powerUp.Anchored = true
    powerUp.CanCollide = false
    powerUp.Material = Enum.Material.Neon
    powerUp.Position = position
    powerUp.Parent = powerUpsFolder
    
    powerUp:SetAttribute("Type", powerUpType)
    powerUp:SetAttribute("Collected", false)
    powerUp:SetAttribute("SpawnTime", tick())  -- Track when created to delay proximity activation
    
    -- Bright glow
    local light = Instance.new("PointLight")
    light.Brightness = 4
    light.Color = powerUpConfig.color
    light.Range = 25
    light.Parent = powerUp
    
    -- Floating icon (rendered in 3D space, not as overlay)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(100, 100)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Adornee = powerUp
    billboard.AlwaysOnTop = false  -- Respect depth so it appears behind obstacles like pistachios
    billboard.Parent = powerUp
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.Text = powerUpConfig.icon
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.TextSize = 45
    icon.Font = Enum.Font.GothamBold
    icon.TextStrokeTransparency = 0
    icon.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    icon.Parent = billboard
    
    -- Smooth floating animation (Subway Surfers style: gentle bob + rotation)
    task.spawn(function()
        local bobAmount = 0.6
        local bobSpeed = 1.8
        local baseY = position.Y
        local time = 0
        
        while powerUp and powerUp.Parent and not powerUp:GetAttribute("Collected") do
            time += task.wait(0.016)  -- ~60 FPS for smooth motion
            if powerUp and powerUp.Parent then
                -- Smooth floating up and down
                local newY = baseY + math.sin(time * bobSpeed * math.pi) * bobAmount
                powerUp.Position = Vector3.new(position.X, newY, position.Z)
            end
        end
    end)
    
    -- Gentle continuous rotation
    task.spawn(function()
        while powerUp and powerUp.Parent and not powerUp:GetAttribute("Collected") do
            if powerUp and powerUp.Parent then
                powerUp.CFrame = powerUp.CFrame * CFrame.Angles(
                    math.rad(0.8),  -- Slow roll on X
                    math.rad(2),     -- Spin on Y
                    math.rad(0.3)    -- Tilt on Z
                )
            end
            task.wait(0.016)  -- ~60 FPS
        end
    end)
    
    -- Collection (delegates to reusable activation so proximity + touch work)
    powerUp.Touched:Connect(function(hit)
        if hit and hit.Parent then
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent == player.Character and not powerUp:GetAttribute("Collected") and isAlive then
                local success, err = pcall(function()
                    activatePowerUpInstance(powerUp)
                end)
                if not success then
                    warn("⚠️ Error activating power-up:", err)
                end
            end
        end
    end)
    
    return powerUp
end

-- Power-up spawning function (modeled after pistachio spawning)
local function spawnPowerUp()
    local root = getCharacterRoot()
    if not root then return end
    
    local powerUpTypes = {"shield", "doublePoints", "magnetBoost"}
    local powerUpType = powerUpTypes[math.random(1, #powerUpTypes)]
    
    local laneChoice = math.random(1, #CONFIG.lanes)
    local laneX = CONFIG.lanes[laneChoice]
    
    -- Add horizontal variation like pistachios do
    local horizontalVariation = (math.random() - 0.5) * 3
    laneX = laneX + horizontalVariation
    
    -- Spawn further ahead with more natural spacing
    local zOffset = -(CONFIG.spawnDistance + math.random(20, 40))
    
    -- Position at ground level like pistachios (GROUND_Y + 4)
    local spawnPosition = Vector3.new(
        laneX,
        GROUND_Y + 4,  -- Match pistachio height
        root.Position.Z + zOffset
    )
    
    print("💎 Spawning", powerUpType, "power-up at:", spawnPosition)
    createPowerUp(spawnPosition, powerUpType)
end

-- SUBWAY SURFERS STYLE: One-hit death with revive option
crashPlayer = function()
    if not isAlive or isInvulnerable then 
        print("Player already crashed or invulnerable")
        return 
    end
    
    isAlive = false
    isGamePaused = true
    currentSpeed = 0
    print("💥 CRASH! Player hit an obstacle!")
    
    -- Freeze the character so they stop running
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Anchored = true  -- Completely freeze in place
        end
    end
    
    -- Play funny crash sound
    local crashSound = Instance.new("Sound")
    crashSound.SoundId = "rbxasset://sounds/electrodes_hit1.ogg"  -- Built-in funny bonk sound
    crashSound.Volume = 0.7
    crashSound.PlaybackSpeed = 0.8  -- Slightly slower for comedic effect
    crashSound.Parent = workspace
    crashSound:Play()
    task.delay(2, function()
        crashSound:Destroy()
    end)
    
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

showReviveScreen = function(crashFlash)
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
    info.Text = string.format("Score: %d | Pistachios: %d", math.floor(score), pistachiosCollectedInRun)
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
        
        -- Unfreeze the character
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = false
            end
        end
        
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

gameOver = function()
    -- Stop the game loop completely
    if gameLoopConnection then
        gameLoopConnection:Disconnect()
        gameLoopConnection = nil
    end
    
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
        pistachiosCollectedInRun
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

respawnPlayer = function()
    -- Reset run stats (keep totalPistachios AND checkpoints persistent)
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
    
    -- Reset speed modifier system
    speedModifier = 1.0
    speedModifierEndTime = 0
    activeSpeedPadType = nil
    currentTrailColor = nil
    
    -- Reset timers to ensure spawning continues
    obstacleTimer = 0
    pistachioTimer = 0
    speedPadTimer = 0
    
    -- Reset streak system
    studyStreak = 0
    studyStreakLevel = 0
    streakMultiplier = 1
    lastPistachioTime = 0
    
    -- Reset year progress
    yearProgress = 0
    yearMeter = 0

    -- Reset power-ups
    hasShield = false
    doublePointsActive = false
    magnetBoostActive = false
    activePowerUps = {}

    -- Clear all power-ups
    for _, powerUp in pairs(powerUpsFolder:GetChildren()) do
        powerUp:Destroy()
    end

    -- Reset power-up timer
    powerUpTimer = 0
    
    -- Clear all obstacles
    for _, obstacle in pairs(obstaclesFolder:GetChildren()) do
        obstacle:Destroy()
    end
    
    -- Clear all pistachios
    for _, pistachio in pairs(pistachiosFolder:GetChildren()) do
        pistachio:Destroy()
    end
    
    -- Clear all speed pads
    for _, speedPad in pairs(speedPadsFolder:GetChildren()) do
        speedPad:Destroy()
    end
    
    -- Clear and reinitialize platforms (checkpoints persist)
    initializePlatforms()
    
    -- Unfreeze and reposition character
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Anchored = false
            root.CFrame = CFrame.new(savedCheckpointPosition)
            print("🔄 Character repositioned at checkpoint #" .. lastCheckpointReached)
        end
    end
    
    print("🔄 New run started! Total pistachios:", totalPistachios, "| Checkpoint:", lastCheckpointReached)
    
    -- Fully restart the game loop
    startRunner()
end

local function createPistachio(position, rarity)
    rarity = rarity or "common"
    local pistachioData = CONFIG.pistachioValues[rarity]
    print("✨ Creating", rarity, "pistachio at", position)
    
    local pistachio = Instance.new("Part")
    pistachio.Name = "Pistachio_" .. rarity
    pistachio.Shape = Enum.PartType.Ball
    pistachio.Size = Vector3.new(2.5, 2.5, 2.5)  -- Larger for better visibility and collection
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
        pistachio.Size = Vector3.new(3.5, 3.5, 3.5)
    elseif rarity == "gold" then
        pistachio.Size = Vector3.new(3, 3, 3)
    end

    -- Add Touched event as backup collection method
    pistachio.Touched:Connect(function(hit)
        if hit and hit.Parent then
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and not pistachio:GetAttribute("Collected") then
                print("🎯 Coin touched by player!")
                pistachio:SetAttribute("Collected", true)
                local success, err = pcall(function()
                    collectPistachio(pistachio, rarity)
                end)
                if not success then
                    print("⚠️ Error in touch collection:", err)
                    pistachio:Destroy()
                end
            end
        end
    end)

    return pistachio
end

collectPistachio = function(pistachio, rarity)
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
    local totalMultiplier = streakMultiplier * (doublePointsActive and 2 or 1)
    local pointsEarned = pistachioData.points * totalMultiplier
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
    -- Spawn obstacles on the platform
    local spawnPosition = Vector3.new(laneX, GROUND_Y + 3, root.Position.Z - CONFIG.spawnDistance)
    
    -- Randomly choose obstacle type (weighted)
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
    
    -- Spawn FEW coins (halved: 1-2 per batch)
    local coinCount = math.random(1, 2)
    for i = 1, coinCount do
        -- Randomly place in lanes
        local laneChoice = math.random(1, #CONFIG.lanes)
        local laneX = CONFIG.lanes[laneChoice]
        
        -- Add some horizontal variation
        local horizontalVariation = (math.random() - 0.5) * 2
        laneX = laneX + horizontalVariation
        
        -- Spawn in front: subtract from Z (more negative = further ahead)
        local zOffset = -(CONFIG.spawnDistance + (i * 8))  -- Slightly more spacing
        
        -- Place coins at player running height for easy collection
        local spawnPosition = Vector3.new(
            laneX,
            GROUND_Y + 4, -- Player height (was +2, now +4 for better alignment)
            root.Position.Z + zOffset
        )
        
        local rarity = determinePistachioRarity()
        print("  Coin", i, "at:", spawnPosition, "Rarity:", rarity)
        createPistachio(spawnPosition, rarity)
    end
end

local function spawnSpeedPad()
    local root = getCharacterRoot()
    if not root then 
        print("⚠️ No root found, skipping speed pad spawn")
        return 
    end
    
    local padType = math.random() > 0.5 and "speedup" or "slowdown"
    local padConfig = CONFIG.speedPads[padType]
    
    local laneChoice = math.random(1, #CONFIG.lanes)
    local laneX = CONFIG.lanes[laneChoice]
    
    -- Add horizontal variation like pistachios
    local horizontalVariation = (math.random() - 0.5) * 2.5
    laneX = laneX + horizontalVariation
    
    -- Spawn with natural spacing
    local zOffset = -(CONFIG.spawnDistance + math.random(15, 35))
    
    -- Position on platform surface (not floating high)
    local spawnPosition = Vector3.new(
        laneX,
        GROUND_Y + 0.8,  -- Sit on platform surface (platform top ~50.5, pad height 0.3 means center at 50.65)
        root.Position.Z + zOffset
    )
    
    print("⚡ Spawning", padType, "speed pad at:", spawnPosition)
    createSpeedPad(spawnPosition, padType)
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
            local collisionRange = 3.5  -- Tight collision — must actually hit the obstacle
            
            if distance <= collisionRange and not isInvulnerable and isAlive then
                print("💥 COLLISION DETECTED! Obstacle:", obstacle.Name, "Distance:", distance)
                
                -- CHECK FOR SHIELD FIRST
                if hasShield then
                    hasShield = false
                    print("🛡️ Shield absorbed hit!")
                    updateHud()
                    
                    -- Shield break effect
                    local shieldBreak = Instance.new("Part")
                    shieldBreak.Shape = Enum.PartType.Ball
                    shieldBreak.Size = Vector3.new(8, 8, 8)
                    shieldBreak.Position = root.Position
                    shieldBreak.Anchored = true
                    shieldBreak.CanCollide = false
                    shieldBreak.Color = CONFIG.powerUps.shield.color
                    shieldBreak.Material = Enum.Material.Neon
                    shieldBreak.Transparency = 0.3
                    shieldBreak.Parent = workspace
                    
                    local tween = TweenService:Create(
                        shieldBreak,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = Vector3.new(15, 15, 15), Transparency = 1}
                    )
                    tween:Play()
                    task.delay(0.5, function()
                        shieldBreak:Destroy()
                    end)
                else
                    -- No shield, crash
                    crashPlayer()
                end
                
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
            end
            -- Person and static obstacles just stay in place (no chasing)
        end
    end

    -- Update pistachios with magnet effect AND collision detection
    for _, pistachio in ipairs(pistachiosFolder:GetChildren()) do
        if pistachio:IsA("BasePart") and not pistachio:GetAttribute("Collected") then
            if pistachio.Position.Z > root.Position.Z + CONFIG.despawnDistance then
                pistachio:Destroy()
            else
                -- Check for pistachio collection (increased range)
                local distance = (pistachio.Position - root.Position).Magnitude
                if distance <= 7 then -- Increased collection range to 7 studs
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
                
                -- Magnetic attraction (extended range when magnet boost is active)
                local baseMagnetRange = CONFIG.pistachioMagnetRange
                local activeMagnetRange = baseMagnetRange + (magnetBoostActive and 8 or 0)
                
                if distance <= activeMagnetRange then
                    local direction = (root.Position - pistachio.Position).Unit
                    local magnetForce = (activeMagnetRange - distance) / activeMagnetRange
                    local pullSpeed = 45 * magnetForce
                    pistachio.Position = pistachio.Position + direction * pullSpeed * dt
                    
                    if distance <= 2 then
                        local rarity = pistachio:GetAttribute("Rarity") or "common"
                        local success, err = pcall(function()
                            collectPistachio(pistachio, rarity)
                        end)
                        if not success then
                            pistachio:Destroy()
                        end
                        continue
                    end
                    
                    if magnetBoostActive and distance < 5 then
                        print("🧲 Magnet boost active! Pulling pistachio at distance:", distance)
                    end
                end
            end
        end
    end
    
    -- Update speed pads: proximity collection + despawn old ones
    for _, speedPad in ipairs(speedPadsFolder:GetChildren()) do
        if not speedPad:IsA("BasePart") then continue end

        -- Despawn pads far behind the player
        if speedPad.Position.Z > root.Position.Z + CONFIG.despawnDistance then
            speedPad:Destroy()
            continue
        end

        -- Proximity collection (so pads are collectible even if Touch fails)
        if not speedPad:GetAttribute("Collected") then
            local spawnTime = speedPad:GetAttribute("SpawnTime") or tick()
            local ageInSeconds = tick() - spawnTime
            
            -- Only activate by proximity after 0.5s to let it render
            if ageInSeconds > 0.5 then
                local dist = (speedPad.Position - root.Position).Magnitude
                if dist <= 5 and isAlive then
                    local success, err = pcall(function()
                        activateSpeedPad(speedPad)
                    end)
                    if not success then
                        warn("⚠️ Error activating speed pad (proximity):", err)
                    end
                end
            end
        end
    end

    -- Update power-ups: proximity collection + despawn
    for _, powerUp in ipairs(powerUpsFolder:GetChildren()) do
        if not powerUp:IsA("BasePart") then continue end

        if powerUp.Position.Z > root.Position.Z + CONFIG.despawnDistance then
            powerUp:Destroy()
            continue
        end

        if not powerUp:GetAttribute("Collected") then
            local spawnTime = powerUp:GetAttribute("SpawnTime") or tick()
            local ageInSeconds = tick() - spawnTime
            
            -- Only activate by proximity after 0.5s to let it render
            if ageInSeconds > 0.5 then
                local dist = (powerUp.Position - root.Position).Magnitude
                if dist <= 6 and isAlive then
                    local success, err = pcall(function()
                        activatePowerUpInstance(powerUp)
                    end)
                    if not success then
                        warn("⚠️ Error activating power-up (proximity):", err)
                    end
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
            local basePoints = closest:GetAttribute("Points") or 50
            local totalMultiplier = streakMultiplier * (doublePointsActive and 2 or 1)
            score += basePoints * totalMultiplier
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

-- (Timer variables declared near top of file with other state variables)

startRunner = function()
    print("🎮 FAF RUN — Credite, Cafele, Colocvii!")
    print("🥜 Revive Cost:", CONFIG.reviveCost, "pistachios")
    print("❤️ Max Revives Per Run:", CONFIG.maxRevivesPerRun)
    print("⚡ Speed Pad System: ACTIVE")
    print("   - Speed Up Pads: Green (1.5x speed)")
    print("   - Slow Down Pads: Red (0.6x speed)")
    
    -- Clean any leftovers so first spawn shows new visuals immediately
    for _, folder in ipairs({obstaclesFolder, pistachiosFolder, platformsFolder, speedPadsFolder}) do
        for _, child in ipairs(folder:GetChildren()) do
            child:Destroy()
        end
    end

    createHud()
    setSkyBackground()
    updateHud()
    initializePlatforms()  -- Create initial platforms
    
    -- Reset timers
    obstacleTimer = 0
    pistachioTimer = 0
    speedPadTimer = 0
    hudUpdateTimer = 0

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
        
        -- Update speed modifier expiration
        if tick() >= speedModifierEndTime then
            if speedModifier ~= 1.0 then
                print("⏱️ Speed modifier expired, returning to normal speed")
            end
            speedModifier = 1.0
            activeSpeedPadType = nil
            currentTrailColor = nil
        end
        
        -- Apply speed modifier to current speed
        local effectiveSpeed = CONFIG.runSpeed * speedModifier
        distanceTraveled += effectiveSpeed * dt
        -- Advance year progress with distance traveled (slow fill)
        yearMeter = math.min(maxYearMeter, yearMeter + effectiveSpeed * dt * 0.15)
        local newLevelIndex = getLevelForDistance(distanceTraveled)
        if newLevelIndex ~= currentLevelIndex then
            currentLevelIndex = newLevelIndex
            print("🎓 PROMOTED TO:", levels[currentLevelIndex].name)
            updateHud()
        end

        -- Periodic HUD refresh so stats/progress stay live
        hudUpdateTimer += dt
        if hudUpdateTimer >= 0.25 then
            hudUpdateTimer = 0
            updateHud()
        end

        -- Periodic refresh to keep platform styling consistent
        pinkRefreshTimer += dt
        if pinkRefreshTimer >= 3 then
            pinkRefreshTimer = 0
            refreshPlatformStyle()
        end

        local currentLevel = levels[currentLevelIndex]
        if not currentLevel then
            print("⚠️ ERROR: No level found for index", currentLevelIndex)
            return
        end
        
        obstacleTimer += dt
        pistachioTimer += dt
        
        -- Debug: Log timer status every 5 seconds
            powerUpTimer += dt
        if math.floor(pistachioTimer * 10) % 50 == 0 and pistachioTimer > 0.1 then
            print("🔍 Timer check - Pistachio:", string.format("%.2f", pistachioTimer), "/", currentLevel.pistachioInterval, "Obstacle:", string.format("%.2f", obstacleTimer))
        end

        -- Make obstacles spawn more frequently as you progress
        -- Difficulty ramps with level and distance, but starts gentle
        local distanceRamp = 1 + math.clamp(distanceTraveled / 800, 0, 1) * 0.4
        local difficultyMultiplier = distanceRamp + (currentLevelIndex - 1) * 0.1
        local adjustedObstacleInterval = currentLevel.obstacleInterval / difficultyMultiplier

        if obstacleTimer >= adjustedObstacleInterval then
            obstacleTimer = 0
            spawnObstacle(currentLevelIndex)
            
            -- Occasional double obstacles only in higher levels
            if currentLevelIndex >= 4 and distanceTraveled > 700 and math.random() > 0.9 then  -- Rare doubles, only late
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
        
        -- SPEED PAD SPAWNING - distribute pads along the path
        speedPadTimer += dt
        local speedPadInterval = 4.5  -- Speed pads spawn every 4.5 seconds
        if speedPadTimer >= speedPadInterval then
            speedPadTimer = 0
            -- Random chance to spawn a speed pad (prevents overcrowding)
            if math.random() < 0.6 then  -- 60% chance each spawn window
                spawnSpeedPad()
            end
        end

        -- POWER-UP SPAWNING - special items that provide temporary boosts (now more frequent!)
        local powerUpInterval = 3.5
        if powerUpTimer >= powerUpInterval then
            powerUpTimer = 0
            if math.random() < 0.8 then
                spawnPowerUp()
            end
        end
        
        -- Continuously spawn platforms and structures throughout the runner
        spawnPlatformAhead()
        cleanupOldPlatforms()
        checkForCheckpointTouch()  -- Check for checkpoint touches

        updateActiveObjects(dt)
        
        -- Create particle trail effect if player has active speed modifier
        if speedModifier ~= 1.0 and math.random() < 0.3 then  -- 30% chance each frame for particle generation
            createParticleTrail()
        end
        
        -- Synchronize character animation speed with movement speed
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent == character then
                -- Get all animations in character - FIXED: proper animator access
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _, anim in pairs(animator:GetPlayingAnimationTracks() or {}) do
                        if anim then
                            -- Adjust animation playback speed based on movement modifier
                            anim:AdjustSpeed(speedModifier)
                        end
                    end
                end
            end
        end
        -- Check if player fell through a gap (fall detection)
        local root = getCharacterRoot()
        if root and root.Position.Y < GROUND_Y - 10 then  -- Fell 10 studs below platform
            print("💀 Player fell through a gap!")
            crashPlayer()
        end
    end)
end

checkForCheckpointTouch = function()
    local root = getCharacterRoot()
    if not root then return end
    
    -- Check if player is touching any checkpoint
    for _, checkpoint in ipairs(platformsFolder:GetChildren()) do
        if checkpoint.Name == "Checkpoint" and checkpoint:IsA("BasePart") then
            local checkpointNum = checkpoint:GetAttribute("CheckpointNumber") or 0
            if checkpointNum > lastCheckpointReached then
                local distance = (checkpoint.Position - root.Position).Magnitude
                if distance <= 8 then  -- Touch range
                    lastCheckpointReached = checkpointNum
                    savedCheckpointPosition = checkpoint.Position + Vector3.new(0, 5, 0)
                    
                    -- Visual feedback
                    checkpoint.Transparency = 0.7
                    print("✅ CHECKPOINT #" .. checkpointNum .. " REACHED! Progress saved.")
                    
                    -- Create checkpoint effect
                    task.spawn(function()
                        local effect = Instance.new("Part")
                        effect.Shape = Enum.PartType.Ball
                        effect.Size = Vector3.new(1, 1, 1)
                        effect.Position = checkpoint.Position
                        effect.Anchored = true
                        effect.CanCollide = false
                        effect.Color = checkpointColor
                        effect.Material = Enum.Material.Neon
                        effect.Transparency = 0.3
                        effect.Parent = workspace
                        
                        local tween = TweenService:Create(
                            effect,
                            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {Size = Vector3.new(15, 15, 15), Transparency = 1}
                        )
                        tween:Play()
                        task.wait(1)
                        effect:Destroy()
                    end)
                end
            end
        end
    end
end

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)  -- Wait a bit longer for character to fully load
    
    -- Position character on the platform (at last checkpoint)
    local humanoidRoot = character:WaitForChild("HumanoidRootPart", 5)
    if humanoidRoot then
        -- Set character position to be standing on the platform
        humanoidRoot.CFrame = CFrame.new(savedCheckpointPosition)
        print("🎮 Character positioned on platform at:", savedCheckpointPosition)
    else
        warn("⚠️ Could not find HumanoidRootPart")
    end
    
    startRunner()
end)

if player.Character then
    task.wait(0.5)
    local humanoidRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRoot then
        humanoidRoot.CFrame = CFrame.new(savedCheckpointPosition)
        print("🎮 Initial character positioned")
    end
    startRunner()
else
    print("⚠️ Waiting for character to spawn...")
end