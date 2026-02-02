local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local SKYBOX_ASSET_ID = "rbxassetid://71960376840332"

local CONFIG = {
    lanes = {-6, 0, 6},
    spawnDistance = 90,
    despawnDistance = 20,
    runSpeed = 42,
    attackRange = 9,
    attackCooldown = 0.6,
    pistachioBurst = 4,
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
        obstacleInterval = 1.4,
        pistachioInterval = 0.45,
    },
    {
        name = "Year 2",
        checkpointDistance = 300,
        obstacleInterval = 2.2,
        pistachioInterval = 0.4,
    },
    {
        name = "Year 3",
        checkpointDistance = 650,
        obstacleInterval = 2.3,
        pistachioInterval = 0.38,
    },
    {
        name = "Year 4",
        checkpointDistance = 1000,
        obstacleInterval = 1.3,
        pistachioInterval = 0.35,
    },
}

local obstacleDefinitions = {
    {name = "Bostan", level = 1, health = 3, points = 60},
    {name = "Fistic", level = 1, health = 3, points = 60},
    {name = "Cojuhari", level = 2, health = 2, points = 45},
    {name = "Grosu", level = 2, health = 2, points = 45},
    {name = "Braga", level = 3, health = 2, points = 50},
    {name = "Tronciu", level = 4, health = 4, points = 80},
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
local score = 0
local canAttack = true

local hudGui
local pistachioLabel
local scoreLabel
local levelLabel

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
end

local function updateHud()
    local level = levels[currentLevelIndex]
    if not level then
        return
    end

    levelLabel.Text = string.format("Checkpoint: %s", level.name)
    scoreLabel.Text = string.format("Score: %d", score)
    pistachioLabel.Text = string.format("Pistachios: %d", pistachioCount)
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
    hitbox.CanCollide = true
    hitbox.Position = position + Vector3.new(0, 3, 0)
    hitbox.Parent = model

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

    return model
end

local function createPistachio(position)
    local pistachio = Instance.new("Part")
    pistachio.Name = "Pistachio"
    pistachio.Shape = Enum.PartType.Ball
    pistachio.Size = Vector3.new(0.8, 0.8, 0.8)
    pistachio.Color = Color3.fromRGB(152, 255, 130)
    pistachio.Anchored = true
    pistachio.CanCollide = false
    pistachio.Position = position + Vector3.new(0, 2, 0)
    pistachio.Parent = pistachiosFolder

    if CONFIG.pistachioImageId ~= "" then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PistachioImage"
        billboard.Size = UDim2.fromOffset(80, 80)
        billboard.AlwaysOnTop = true
        billboard.Parent = pistachio

        local image = Instance.new("ImageLabel")
        image.Name = "Image"
        image.BackgroundTransparency = 1
        image.Size = UDim2.fromScale(1, 1)
        image.Image = CONFIG.pistachioImageId
        image.ScaleType = Enum.ScaleType.Fit
        image.Parent = billboard
    end

    pistachio.Touched:Connect(function(hit)
        local character = player.Character
        if not character then
            return
        end
        if hit:IsDescendantOf(character) then
            pistachioCount += 1
            updateHud()
            pistachio:Destroy()
        end
    end)

    return pistachio
end

local function getObstaclesForLevel(levelIndex)
    local results = {}
    for _, obstacle in ipairs(obstacleDefinitions) do
        if obstacle.level == levelIndex then
            table.insert(results, obstacle)
        end
    end
    return results
end

local function spawnObstacle(levelIndex)
    local available = getObstaclesForLevel(levelIndex)
    if #available == 0 then
        return
    end

    local root = getCharacterRoot()
    local laneX = CONFIG.lanes[math.random(1, #CONFIG.lanes)]
    local spawnPosition = root.Position + Vector3.new(laneX, 0, -CONFIG.spawnDistance)
    local obstacleDef = available[math.random(1, #available)]
    createPersonObstacle(obstacleDef, spawnPosition)
end

local function spawnPistachio()
    local root = getCharacterRoot()
    for i = 1, CONFIG.pistachioBurst do
        local laneX = CONFIG.lanes[math.random(1, #CONFIG.lanes)]
        local zOffset = -CONFIG.spawnDistance + 8 - (i - 1) * 4
        local spawnPosition = root.Position + Vector3.new(laneX, 0, zOffset)
        createPistachio(spawnPosition)
    end
end

local function updateActiveObjects(dt)
    local root = getCharacterRoot()

    for _, obstacle in ipairs(obstaclesFolder:GetChildren()) do
        if obstacle:IsA("Model") and obstacle.PrimaryPart then
            if obstacle.PrimaryPart.Position.Z > root.Position.Z + CONFIG.despawnDistance then
                obstacle:Destroy()
            end
        end
    end

    for _, pistachio in ipairs(pistachiosFolder:GetChildren()) do
        if pistachio:IsA("BasePart") then
            if pistachio.Position.Z > root.Position.Z + CONFIG.despawnDistance then
                pistachio:Destroy()
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

local function startRunner()
    createHud()
    setSkyBackground()
    updateHud()

    local obstacleTimer = 0
    local pistachioTimer = 0

    connectAttackInput()

    RunService.Heartbeat:Connect(function(dt)
        distanceTraveled += CONFIG.runSpeed * dt
        local newLevelIndex = getLevelForDistance(distanceTraveled)
        if newLevelIndex ~= currentLevelIndex then
            currentLevelIndex = newLevelIndex
            updateHud()
        end

        local currentLevel = levels[currentLevelIndex]
        obstacleTimer += dt
        pistachioTimer += dt

        if obstacleTimer >= currentLevel.obstacleInterval then
            obstacleTimer = 0
            spawnObstacle(currentLevelIndex)
        end

        if pistachioTimer >= currentLevel.pistachioInterval then
            pistachioTimer = 0
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
