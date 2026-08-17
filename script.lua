-- 1. Game Load Wait
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ContentProvider = game:GetService("ContentProvider")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Plots = workspace:WaitForChild("Plots")
local camera = workspace.CurrentCamera

---------------------------------------------------------
-- Config System (設定の保存・読み込み機能)
---------------------------------------------------------
local CONFIG_FOLDER = "OhaHubConfig"
local CONFIG_FILE = CONFIG_FOLDER .. "/settings.json"

if not isfolder(CONFIG_FOLDER) then
    makefolder(CONFIG_FOLDER)
end

local ConfigData = {
    AntiLag = true,
    InfiniteJump = true,
    AntiRagdoll = true,
    SpeedToggle = true,
    RespawnKey = true,
    KickKeyEnabled = true,
    RejoinKeyEnabled = true,
    PlayerESP = true,
    BlacklistDetector = true,
    NextBaseEnabled = true,
    NextBaseLineEnabled = true,
    PodiumESP = true,
    BeamColor = {255, 0, 0},
    PodiumColor = {255, 60, 60},
    KeySpeedToggle = Enum.KeyCode.Q,
    KeyRespawn = Enum.KeyCode.X,
    KeyKick = Enum.KeyCode.K,
    KeyRejoin = Enum.KeyCode.J
}

local function saveConfig()
    pcall(function()
        local saveData = {}
        for k, v in pairs(ConfigData) do
            if typeof(v) == "EnumItem" then
                saveData[k] = v.Name
            else
                saveData[k] = v
            end
        end
        local encoded = HttpService:JSONEncode(saveData)
        writefile(CONFIG_FILE, encoded)
    end)
end

local function loadConfig()
    pcall(function()
        if isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if decoded.KeySpeedToggle then ConfigData.KeySpeedToggle = Enum.KeyCode[decoded.KeySpeedToggle] or ConfigData.KeySpeedToggle end
            if decoded.KeyRespawn then ConfigData.KeyRespawn = Enum.KeyCode[decoded.KeyRespawn] or ConfigData.KeyRespawn end
            if decoded.KeyKick then ConfigData.KeyKick = Enum.KeyCode[decoded.KeyKick] or ConfigData.KeyKick end
            if decoded.KeyRejoin then ConfigData.KeyRejoin = Enum.KeyCode[decoded.KeyRejoin] or ConfigData.KeyRejoin end
            for k, v in pairs(decoded) do
                if k ~= "KeySpeedToggle" and k ~= "KeyRespawn" and k ~= "KeyKick" and k ~= "KeyRejoin" then
                    ConfigData[k] = v
                end
            end
        end
    end)
end

loadConfig()

-- Global Color Settings
_G.__NextBaseBeamColor = Color3.fromRGB(ConfigData.BeamColor[1], ConfigData.BeamColor[2], ConfigData.BeamColor[3])
_G.__PodiumColor = Color3.fromRGB(ConfigData.PodiumColor[1], ConfigData.PodiumColor[2], ConfigData.PodiumColor[3])

-- 2. Load Maclib
local success, MacLib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
end)

if not success or not MacLib then return end

-- 3. Create Window & Tabs
local Window = MacLib:Window({
    Title = "oha hub",
    Subtitle = "Maclib Template",
    Size = UDim2.fromOffset(550, 420),
    Dragable = true
})

Window:SetKeybind(Enum.KeyCode.LeftControl)

---------------------------------------------------------
-- Color Picker Fix
---------------------------------------------------------
local hui = (gethui and gethui()) or CoreGui
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            for _, root in ipairs({hui, CoreGui, PlayerGui}) do
                for _, obj in ipairs(root:GetDescendants()) do
                    if obj:IsA("Frame") and (obj.Name:find("Color") or obj.Name:find("Picker") or obj.Name:find("Popup") or obj.Name:find("Dropdown")) then
                        obj.ClipsDescendants = false
                        obj.ZIndex = 100
                        if obj.Parent and obj.Parent:IsA("Frame") then
                            obj.Parent.ClipsDescendants = false
                        end
                    end
                end
            end
        end)
    end
end)

local TabGroup = Window:TabGroup()

local MainTab = TabGroup:Tab({ Name = "Main", Image = "rbxassetid://10734950309" })

local UtilitySection = MainTab:Section({ Side = "Left" })
local MovementSection = MainTab:Section({ Side = "Left" })

local PlayerSection = MainTab:Section({ Side = "Right" })
local WorldSection = MainTab:Section({ Side = "Right" })

local ServerTab = TabGroup:Tab({ Name = "Server Control", Image = "rbxassetid://10734950309" })
local ServerSection = ServerTab:Section({ Side = "Left" })

-- Settings Tab
local SettingsTab = TabGroup:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
local KeybindSection = SettingsTab:Section({ Side = "Left" })

---------------------------------------------------------
-- Helper Function for Notification
---------------------------------------------------------
local function notify(title, description, lifetime)
    pcall(function()
        Window:Notify({
            Title = title or "Notification",
            Description = description or "",
            Lifetime = lifetime or 3,
            Scale = 1,
            SizeX = 260,
            Style = "None"
        })
    end)
end

---------------------------------------------------------
-- Server Controls Tab
---------------------------------------------------------
local function doKick()
    LocalPlayer:Kick("Kicked via menu or keybind.")
end

local function doRejoin()
    notify("Rejoin", "Rejoining server...", 3)
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("Rejoining...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

ServerSection:Button({
    Name = "Kick Self",
    Callback = function()
        doKick()
    end
})

ServerSection:Button({
    Name = "Rejoin Server",
    Callback = function()
        doRejoin()
    end
})

ServerSection:Button({
    Name = "Server Hop",
    Callback = function()
        notify("Server Hop", "Searching for a new server...", 3)
        local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Asc&limit=100"
        local function listServers(cursor)
            local raw = game:HttpGet(Api .. (cursor and "&cursor=" .. cursor or ""))
            return HttpService:JSONDecode(raw)
        end
        task.spawn(function()
            local ok, serverList = pcall(listServers)
            if not ok or not serverList or not serverList.data then
                notify("Server Hop", "Failed to fetch server list.", 3)
                return
            end
            local targetServer = nil
            for _, server in ipairs(serverList.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    targetServer = server.id
                    break
                end
            end
            if targetServer then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer, LocalPlayer)
            else
                notify("Server Hop", "No other server found.", 3)
            end
        end)
    end
})

local defaultLightingSettings = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
}

local function applyAntiLag(enable)
    if enable then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 8999999488.0
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    else
        Lighting.GlobalShadows = defaultLightingSettings.GlobalShadows
        Lighting.FogEnd = defaultLightingSettings.FogEnd
        Lighting.Brightness = defaultLightingSettings.Brightness
        Lighting.EnvironmentDiffuseScale = defaultLightingSettings.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = defaultLightingSettings.EnvironmentSpecularScale
    end
end

ServerSection:Toggle({
    Name = "Anti-Lag (Lighting)",
    Default = ConfigData.AntiLag,
    Callback = function(state)
        ConfigData.AntiLag = state
        saveConfig()
        applyAntiLag(state)
    end
})

applyAntiLag(ConfigData.AntiLag)

---------------------------------------------------------
-- SECTION 1: Utility (Left Side)
---------------------------------------------------------
UtilitySection:Button({
    Name = "Copy JobID",
    Callback = function()
        local jobId = game.JobId
        local copied = false
        if setclipboard then
            setclipboard(jobId)
            copied = true
        elseif toclipboard then
            toclipboard(jobId)
            copied = true
        end
        if copied then
            notify("JobID", "Copied to clipboard!", 3)
        else
            notify("Error", "Your executor is not supported", 3)
        end
    end
})

---------------------------------------------------------
-- SECTION 2: Movement & Character (Left Side)
---------------------------------------------------------
local JUMP_POWER = 60
local jumpEnabled = ConfigData.InfiniteJump

MovementSection:Toggle({
    Name = "Infinite Jump",
    Default = ConfigData.InfiniteJump,
    Callback = function(state)
        ConfigData.InfiniteJump = state
        saveConfig()
        jumpEnabled = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if jumpEnabled then
        local character = LocalPlayer.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentVel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, JUMP_POWER, currentVel.Z)
            end
        end
    end
end)

-- Anti-Ragdoll
local antiRagdollEnabled = ConfigData.AntiRagdoll
local antiRagdollConnection = nil
local cached = {}

local function cacheCharacter()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cached = { character = char, humanoid = hum, root = root }
    camera.CameraSubject = hum
    return true
end

local function isRagdolled()
    local hum = cached.humanoid
    if not hum then return false end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
        return true
    end
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime then
        local now = workspace:GetServerTimeNow()
        if (endTime - now) > 0 then return true end
    end
    return false
end

local function removeRagdollConstraints()
    if not cached.character then return end
    for _, v in ipairs(cached.character:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or (v:IsA("Attachment") and v.Name:find("RagdollAttachment")) then
            pcall(function() v:Destroy() end)
        end
    end
end

local function forceExitRagdoll()
    local hum = cached.humanoid
    local root = cached.root
    if not hum or not root then return end
    pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(root.Orientation.Y), 0)
    if camera.CameraSubject ~= hum then camera.CameraSubject = hum end
end

local function startAntiRagdollLoop()
    if antiRagdollConnection then antiRagdollConnection:Disconnect() end
    antiRagdollConnection = RunService.RenderStepped:Connect(function()
        if not antiRagdollEnabled then return end
        if not cached.humanoid or not cached.humanoid.Parent then
            cacheCharacter()
            return
        end
        if isRagdolled() then
            removeRagdollConstraints()
            forceExitRagdoll()
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    if antiRagdollEnabled then
        task.wait(0.5)
        cacheCharacter()
    end
end)

MovementSection:Toggle({
    Name = "Anti-Ragdoll",
    Default = ConfigData.AntiRagdoll,
    Callback = function(state)
        ConfigData.AntiRagdoll = state
        saveConfig()
        antiRagdollEnabled = state
        if antiRagdollEnabled then
            cacheCharacter()
            startAntiRagdollLoop()
        else
            if antiRagdollConnection then
                antiRagdollConnection:Disconnect()
                antiRagdollConnection = nil
            end
        end
    end
})

cacheCharacter()
startAntiRagdollLoop()

-- Speed Boost
local speedToggleEnabled = ConfigData.SpeedToggle
local isSpeedBoosted = false
local originalSpeed = nil
local TARGET_SPEED = 28

RunService.Heartbeat:Connect(function()
    if speedToggleEnabled and isSpeedBoosted then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= TARGET_SPEED then
            hum.WalkSpeed = TARGET_SPEED
        end
    end
end)

MovementSection:Toggle({
    Name = "Speed Boost (Key)",
    Default = ConfigData.SpeedToggle,
    Callback = function(state)
        ConfigData.SpeedToggle = state
        saveConfig()
        speedToggleEnabled = state
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not state then
            isSpeedBoosted = false
            if hum and originalSpeed then
                hum.WalkSpeed = originalSpeed
            end
        end
    end
})

-- Respawn Key
local respawnKeyEnabled = ConfigData.RespawnKey

MovementSection:Toggle({
    Name = "Respawn Key",
    Default = ConfigData.RespawnKey,
    Callback = function(state)
        ConfigData.RespawnKey = state
        saveConfig()
        respawnKeyEnabled = state
    end
})

-- キー入力監視
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Speed Boost Key Execution
    if speedToggleEnabled and ConfigData.KeySpeedToggle and input.KeyCode == ConfigData.KeySpeedToggle then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if not isSpeedBoosted then
                originalSpeed = hum.WalkSpeed
                isSpeedBoosted = true
                hum.WalkSpeed = TARGET_SPEED
                notify("Speed Boost", "ON (Speed: " .. tostring(TARGET_SPEED) .. ")", 2)
            else
                isSpeedBoosted = false
                if originalSpeed then hum.WalkSpeed = originalSpeed end
                notify("Speed Boost", "OFF (Speed: " .. tostring(originalSpeed or 16) .. ")", 2)
            end
        end
    end

    -- Respawn Key Execution
    if respawnKeyEnabled and ConfigData.KeyRespawn and input.KeyCode == ConfigData.KeyRespawn then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            hum.Health = 0
            notify("Respawn", "Respawning...", 2)
        end
    end

    -- Kick Key Execution
    if ConfigData.KickKeyEnabled and ConfigData.KeyKick and input.KeyCode == ConfigData.KeyKick then
        doKick()
    end

    -- Rejoin Key Execution
    if ConfigData.RejoinKeyEnabled and ConfigData.KeyRejoin and input.KeyCode == ConfigData.KeyRejoin then
        doRejoin()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    isSpeedBoosted = false
    originalSpeed = nil
end)

---------------------------------------------------------
-- SETTINGS TAB: Keybind Configurations & Toggles
---------------------------------------------------------
pcall(function()
    -- Speed Boost
    KeybindSection:Toggle({
        Name = "Enable Speed Key",
        Default = true,
        Callback = function(state) end
    })
    KeybindSection:Keybind({
        Name = "Speed Boost Key",
        Default = ConfigData.KeySpeedToggle,
        Callback = function(binded) end,
        onBinded = function(bind)
            if bind and bind.Name then
                ConfigData.KeySpeedToggle = Enum.KeyCode[bind.Name] or bind
                saveConfig()
                notify("Keybind", "Rebound Speed Boost to " .. tostring(bind.Name), 2)
            end
        end
    }, "SpeedBoostKeyBind")

    -- Respawn
    KeybindSection:Toggle({
        Name = "Enable Respawn Key",
        Default = true,
        Callback = function(state) end
    })
    KeybindSection:Keybind({
        Name = "Respawn Key",
        Default = ConfigData.KeyRespawn,
        Callback = function(binded) end,
        onBinded = function(bind)
            if bind and bind.Name then
                ConfigData.KeyRespawn = Enum.KeyCode[bind.Name] or bind
                saveConfig()
                notify("Keybind", "Rebound Respawn to " .. tostring(bind.Name), 2)
            end
        end
    }, "RespawnKeyBind")

    -- Kick
    KeybindSection:Toggle({
        Name = "Enable Kick Key",
        Default = ConfigData.KickKeyEnabled,
        Callback = function(state)
            ConfigData.KickKeyEnabled = state
            saveConfig()
        end
    })
    KeybindSection:Keybind({
        Name = "Kick Key",
        Default = ConfigData.KeyKick,
        Callback = function(binded) end,
        onBinded = function(bind)
            if bind and bind.Name then
                ConfigData.KeyKick = Enum.KeyCode[bind.Name] or bind
                saveConfig()
                notify("Keybind", "Rebound Kick to " .. tostring(bind.Name), 2)
            end
        end
    }, "KickKeyBind")

    -- Rejoin
    KeybindSection:Toggle({
        Name = "Enable Rejoin Key",
        Default = ConfigData.RejoinKeyEnabled,
        Callback = function(state)
            ConfigData.RejoinKeyEnabled = state
            saveConfig()
        end
    })
    KeybindSection:Keybind({
        Name = "Rejoin Key",
        Default = ConfigData.KeyRejoin,
        Callback = function(binded) end,
        onBinded = function(bind)
            if bind and bind.Name then
                ConfigData.KeyRejoin = Enum.KeyCode[bind.Name] or bind
                saveConfig()
                notify("Keybind", "Rebound Rejoin to " .. tostring(bind.Name), 2)
            end
        end
    }, "RejoinKeyBind")
end)

---------------------------------------------------------
-- SECTION 3: Player Visuals & Detection (Right Side)
---------------------------------------------------------
local espEnabled = ConfigData.PlayerESP
local StorageFolder = PlayerGui:FindFirstChild("ESP_Storage")
if not StorageFolder then
    StorageFolder = Instance.new("Folder")
    StorageFolder.Name = "ESP_Storage"
    StorageFolder.Parent = PlayerGui
end

local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupESP(character)
        if not character or not espEnabled then return end
        local existing = StorageFolder:FindFirstChild(player.Name)
        if existing then existing:Destroy() end

        local playerContainer = Instance.new("Model")
        playerContainer.Name = player.Name
        playerContainer.Parent = StorageFolder

        local highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.Adornee = character
        highlight.FillTransparency = 0.5 
        highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = playerContainer

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = playerContainer

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 16
        nameLabel.Parent = billboard

        task.spawn(function()
            local head = character:WaitForChild("Head", 10)
            if head and billboard.Parent then billboard.Adornee = head end
        end)
    end
    if player.Character then task.spawn(setupESP, player.Character) end
    player.CharacterAdded:Connect(setupESP)
end

Players.PlayerAdded:Connect(applyESP)
Players.PlayerRemoving:Connect(function(player)
    local existing = StorageFolder:FindFirstChild(player.Name)
    if existing then existing:Destroy() end
end)

PlayerSection:Toggle({
    Name = "Player ESP",
    Default = ConfigData.PlayerESP,
    Callback = function(state)
        ConfigData.PlayerESP = state
        saveConfig()
        espEnabled = state
        if espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do applyESP(player) end
        else
            StorageFolder:ClearAllChildren()
        end
    end
})

for _, player in ipairs(Players:GetPlayers()) do applyESP(player) end

-- Blacklist Detector
local blacklistEnabled = ConfigData.BlacklistDetector
local TARGET_USERNAMES = {
    "m4guro0722", "mixy_sub5", "eitoo0824", "drika9x8s",
    "xxsonia18xx5", "yisel12_1", "papichulo4kk", "discoduro28", "zahjj77"
}
local SOUND_ID = "rbxassetid://138081509"
local SOUND_VOLUME = 5

local function playWarningSound()
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = SOUND_ID
        sound.Volume = SOUND_VOLUME
        sound.Parent = workspace.CurrentCamera or workspace
        pcall(function() ContentProvider:PreloadAsync({sound}) end)
        if not sound.IsLoaded then sound.Loaded:Wait() end
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
        task.delay(10, function() if sound and sound.Parent then sound:Destroy() end end)
    end)
end

local function isTargetUser(player)
    for _, targetName in ipairs(TARGET_USERNAMES) do
        if player.Name:lower() == targetName:lower() or player.DisplayName:lower() == targetName:lower() then
            return true
        end
    end
    return false
end

local function checkBlacklistPlayer(player)
    if not blacklistEnabled then return end
    if isTargetUser(player) then
        notify("⚠️ Target Detected!", player.Name .. " joined the server", 10)
        playWarningSound()
    end
end

PlayerSection:Toggle({
    Name = "Blacklist Detector",
    Default = ConfigData.BlacklistDetector,
    Callback = function(state)
        ConfigData.BlacklistDetector = state
        saveConfig()
        blacklistEnabled = state
        if blacklistEnabled then
            for _, player in ipairs(Players:GetPlayers()) do checkBlacklistPlayer(player) end
        end
    end
})

Players.PlayerAdded:Connect(checkBlacklistPlayer)
for _, player in ipairs(Players:GetPlayers()) do checkBlacklistPlayer(player) end

---------------------------------------------------------
-- SECTION 4: World & Base Visuals (Right Side)
---------------------------------------------------------
local nextBaseLineEnabled = ConfigData.NextBaseLineEnabled
_G.__NextBaseEnabled = ConfigData.NextBaseEnabled

local function startNextBase()
    if _G.__NextBaseCleanup then pcall(_G.__NextBaseCleanup) end

    local BASE_POSITIONS = {
        Vector3.new(-342.439, 10.399, 113.107),
        Vector3.new(-342.439, 10.465,   6.107),
        Vector3.new(-476.752, 10.465, 114.107),
        Vector3.new(-476.752, 10.465,   7.107),
        Vector3.new(-342.440, 10.464, 220.107),
        Vector3.new(-476.752, 10.465, 221.107),
        Vector3.new(-342.439, 10.465,-100.893),
        Vector3.new(-476.752, 10.465, -99.893),
    }
    local MATCH_TOL = 6
    local EMPTY_TEXT = "Empty Base"
    local ARROW = utf8.char(0x2B07)
    local LINE_WIDTH = 0.4

    local function baseIndexFor(model)
        local ok, cf = pcall(function() return (model:GetBoundingBox()) end)
        if not ok then return nil end
        local p, bestI, bestD = cf.Position
        for i, bp in ipairs(BASE_POSITIONS) do
            local dx, dz = p.X - bp.X, p.Z - bp.Z
            local d = math.sqrt(dx * dx + dz * dz)
            if not bestD or d < bestD then bestI, bestD = i, d end
        end
        return (bestD and bestD <= MATCH_TOL) and bestI or nil
    end

    local bases, connected, conns = {}, {}, {}
    local lastTargetIdx = nil

    local folder = Instance.new("Folder")
    folder.Name = "__NextBaseFolder"
    folder.Parent = workspace

    local anchor = Instance.new("Part")
    anchor.Name = "__NextBaseAnchor"
    anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Parent = folder

    local bb = Instance.new("BillboardGui")
    bb.Name = "NextBaseBillboard"
    bb.Adornee = anchor
    bb.Size = UDim2.fromScale(32, 13)
    bb.StudsOffset = Vector3.new(0, 10, 0)
    bb.MaxDistance = math.huge
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Enabled = false
    bb.Parent = CoreGui

    local top = Instance.new("TextLabel", bb)
    top.BackgroundTransparency = 1
    top.AnchorPoint = Vector2.new(0.5, 0.5)
    top.Position = UDim2.fromScale(0.5, 0.30)
    top.Size = UDim2.fromScale(0.95, 0.50)
    top.Font = Enum.Font.GothamBlack
    top.Text = ARROW .. "  NEXT  " .. ARROW
    top.TextScaled = true
    top.TextColor3 = Color3.fromRGB(255, 60, 60)
    top.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    top.TextStrokeTransparency = 0

    local bottom = Instance.new("TextLabel", bb)
    bottom.BackgroundTransparency = 1
    bottom.AnchorPoint = Vector2.new(0.5, 0.5)
    bottom.Position = UDim2.fromScale(0.5, 0.72)
    bottom.Size = UDim2.fromScale(0.95, 0.42)
    bottom.Font = Enum.Font.GothamBlack
    bottom.Text = "EMPTY BASE"
    bottom.TextScaled = true
    bottom.TextColor3 = Color3.fromRGB(255, 255, 255)
    bottom.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    bottom.TextStrokeTransparency = 0

    local baseAttachment = Instance.new("Attachment")
    baseAttachment.Parent = anchor

    local playerAttachment = Instance.new("Attachment")
    playerAttachment.Name = "ATPPlayerLineAttachment"

    local beam = Instance.new("Beam")
    beam.Attachment0 = playerAttachment
    beam.Attachment1 = baseAttachment
    beam.Width0 = LINE_WIDTH
    beam.Width1 = LINE_WIDTH
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Color = ColorSequence.new(_G.__NextBaseBeamColor or Color3.fromRGB(255, 0, 0))
    beam.Texture = "rbxassetid://1258169528"
    beam.Enabled = false
    beam.Parent = folder

    _G.__UpdateNextBaseColor = function(newColor)
        if beam then beam.Color = ColorSequence.new(newColor) end
    end

    local function setupPlayerAttachment(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        if hrp then playerAttachment.Parent = hrp end
    end

    if LocalPlayer.Character then task.spawn(setupPlayerAttachment, LocalPlayer.Character) end
    table.insert(conns, LocalPlayer.CharacterAdded:Connect(setupPlayerAttachment))

    local function isEmpty(label)
        return (label.Text:gsub("^%s+", ""):gsub("%s+$", "")) == EMPTY_TEXT
    end

    local function recompute()
        local targetIdx = nil
        for i = 1, #BASE_POSITIONS do
            local b = bases[i]
            if b and b.label and isEmpty(b.label) then
                targetIdx = i
                break
            end
        end

        if playerAttachment.Parent == nil and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then playerAttachment.Parent = hrp end
        end

        local shouldBeam = nextBaseLineEnabled and _G.__NextBaseEnabled

        if targetIdx ~= lastTargetIdx then
            if targetIdx and bases[targetIdx] then
                anchor.CFrame = bases[targetIdx].cf
                bb.Enabled = true
                beam.Enabled = shouldBeam
            else
                bb.Enabled = false
                beam.Enabled = false
            end
            lastTargetIdx = targetIdx
        elseif targetIdx and bases[targetIdx] then
            anchor.CFrame = bases[targetIdx].cf
            bb.Enabled = true
            beam.Enabled = shouldBeam
        end
    end

    local function connectLabel(label)
        if connected[label] then return end
        connected[label] = true
        table.insert(conns, label:GetPropertyChangedSignal("Text"):Connect(recompute))
    end

    local function scan()
        for _, plot in ipairs(Plots:GetChildren()) do
            local sign  = plot:FindFirstChild("PlotSign")
            local model = sign and sign:FindFirstChild("Model")
            local gui   = sign and sign:FindFirstChild("SurfaceGui")
            local fr    = gui and gui:FindFirstChild("Frame")
            local label = fr and fr:FindFirstChild("TextLabel")
            if model and label then
                local idx = baseIndexFor(model)
                if idx then
                    bases[idx] = { label = label, cf = (select(1, model:GetBoundingBox())) }
                    connectLabel(label)
                end
            end
        end
        recompute()
    end

    scan()
    table.insert(conns, Plots.DescendantAdded:Connect(function(d)
        if d:IsA("TextLabel") then task.defer(scan) end
    end))
    table.insert(conns, Plots.ChildAdded:Connect(function() task.defer(scan) end))

    _G.__SetNextBaseLine = function(state)
        nextBaseLineEnabled = state
        if beam then
            beam.Enabled = state and _G.__NextBaseEnabled and (lastTargetIdx ~= nil)
        end
    end

    _G.__NextBaseCleanup = function()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if playerAttachment then playerAttachment:Destroy() end
        if folder then folder:Destroy() end
        if bb then bb:Destroy() end
        _G.__NextBaseCleanup = nil
        _G.__SetNextBaseLine = nil
        _G.__UpdateNextBaseColor = nil
    end
end

WorldSection:Toggle({
    Name = "Next Base Indicator",
    Default = ConfigData.NextBaseEnabled,
    Callback = function(state)
        ConfigData.NextBaseEnabled = state
        saveConfig()
        _G.__NextBaseEnabled = state
        if state then
            startNextBase()
        else
            if _G.__NextBaseCleanup then pcall(_G.__NextBaseCleanup) end
        end
    end
})

WorldSection:Toggle({
    Name = " └ Beam Line",
    Default = ConfigData.NextBaseLineEnabled,
    Callback = function(state)
        ConfigData.NextBaseLineEnabled = state
        saveConfig()
        nextBaseLineEnabled = state
        if _G.__SetNextBaseLine then
            _G.__SetNextBaseLine(state)
        end
    end
})

-- Color Picker (Beam Color)
pcall(function()
    local cpFunc = WorldSection.Colorpicker or WorldSection.ColorPicker or WorldSection.AddColorPicker
    if cpFunc then
        cpFunc(WorldSection, {
            Name = "Beam Color",
            Default = _G.__NextBaseBeamColor,
            Callback = function(color)
                ConfigData.BeamColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
                saveConfig()
                _G.__NextBaseBeamColor = color
                if _G.__UpdateNextBaseColor then
                    _G.__UpdateNextBaseColor(color)
                end
            end
        })
    end
end)

if ConfigData.NextBaseEnabled then
    startNextBase()
end

-- Podium ESP
local function startPodiumESP()
    if _G.__PodiumESPCleanup then pcall(_G.__PodiumESPCleanup) end

    local currentPodiumColor = _G.__PodiumColor or Color3.fromRGB(255, 60, 60)
    local CFG = {
        FLOOR_COLOR = { currentPodiumColor, currentPodiumColor, currentPodiumColor },
        COLLIDE     = true,
    }

    local FILL_T, INNER_T, MISS_T, THICK = 0.55, 0.42, 0.10, 0.05
    local PULSE_SPEED, PULSE_AMOUNT = 2, 0.12

    local TEMPLATE = {
        { 18.500,  1.531, -14.476,  90}, { 18.500,  1.531,  -6.976,  90}, { 18.500,  1.531,   0.524,  90},
        { 18.500,  1.531,   8.024,  90}, { 18.500,  1.531,  15.524,  90},
        {-18.536,  1.531,  15.524, -90}, {-18.536,  1.531,   8.024, -90}, {-18.536,  1.531,   0.524, -90},
        {-18.536,  1.531,  -6.976, -90}, {-18.536,  1.531, -14.476, -90},
        { 18.500, 19.531, -14.476,  90}, { 18.500, 19.531,  -6.976,  90}, { 18.500, 19.531,   0.524,  90},
        { 18.500, 19.531,   8.024,  90}, { 18.500, 19.531,  15.524,  90},
        {-18.380, 19.531, -14.452, -90}, {-18.380, 19.531,  -6.952, -90}, {-18.380, 19.531,   0.548, -90},
        { 18.500, 36.531, -12.476,  90}, { 18.500, 36.531,  -4.976,  90}, { 18.500, 36.531,   2.524,  90},
        { 18.500, 36.531,  10.024,  90}, { 18.500, 36.531,  17.524,  90},
        {-18.472, 36.531, -12.501, -90}, {-18.471, 36.531,  -5.001, -90}, {-18.471, 36.531,   2.499, -90},
        {-18.471, 36.531,   9.999, -90}, {-18.471, 36.531,  17.499, -90},
    }

    local OUTER, INNER_SZ, INNER_UP = Vector3.new(6, 0.25, 6), Vector3.new(4, 0.25, 4), 0.25

    for _, where in ipairs({workspace, CoreGui, hui}) do
        for _, n in ipairs({"__PodiumMarkers", "__PodiumTest", "__PodiumCollide"}) do
            local o = where:FindFirstChild(n)
            if o then o:Destroy() end
        end
    end

    local markers, fills, conns = {}, {}, {}
    local alive = true
    local solids

    local function keep(x) markers[#markers + 1] = x x.Parent = hui return x end

    local function clear()
        for _, m in ipairs(markers) do pcall(function() m:Destroy() end) end
        table.clear(markers)
        table.clear(fills)
        if solids then solids:ClearAllChildren() end
    end

    local function box(adornee, cf, size, color, trans, isFill)
        local a = Instance.new("BoxHandleAdornment")
        a.Adornee = adornee
        a.Size = size
        a.CFrame = cf
        a.Color3 = color
        a.Transparency = trans
        a.AlwaysOnTop = false
        a.ZIndex = 0
        keep(a)
        if isFill then fills[#fills + 1] = { a = a, base = trans } end
        return a
    end

    local function outline(part, color)
        local b = Instance.new("SelectionBox")
        b.Adornee = part
        b.Color3 = color
        b.SurfaceColor3 = color
        b.LineThickness = THICK
        b.Transparency = 0
        b.SurfaceTransparency = 1
        return keep(b)
    end

    local function edges(root, cf, size, color)
        local t = THICK * 1.6
        local hx, hz, y = size.X * 0.5, size.Z * 0.5, size.Y * 0.5
        box(root, cf * CFrame.new(0, y,  hz), Vector3.new(size.X, t, t), color, 0)
        box(root, cf * CFrame.new(0, y, -hz), Vector3.new(size.X, t, t), color, 0)
        box(root, cf * CFrame.new( hx, y, 0), Vector3.new(t, t, size.Z), color, 0)
        box(root, cf * CFrame.new(-hx, y, 0), Vector3.new(t, t, size.Z), color, 0)
    end

    local function solid(worldCF)
        if not CFG.COLLIDE then return end
        if not solids then
            solids = Instance.new("Folder")
            solids.Name = "__PodiumCollide"
            solids.Parent = workspace
        end
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = true
        p.CanQuery = false
        p.CanTouch = false
        p.Transparency = 1
        p.Size = OUTER
        p.CFrame = worldCF
        p.Parent = solids
    end

    local function colorFor(i)
        if i <= 10 then return CFG.FLOOR_COLOR[1] elseif i <= 18 then return CFG.FLOOR_COLOR[2] end
        return CFG.FLOOR_COLOR[3]
    end

    local function slabsOf(slot)
        local base = slot:FindFirstChild("Base") or slot
        local decos = base:FindFirstChild("Decorations")
        local parts = {}
        if decos then
            for _, c in ipairs(decos:GetChildren()) do
                if c:IsA("BasePart") and c.Transparency < 1 then parts[#parts + 1] = c end
            end
        end
        table.sort(parts, function(a, b) return a.Size.X * a.Size.Z > b.Size.X * b.Size.Z end)
        return parts
    end

    local function drawReal(parts, color)
        local anchor = parts[1]
        for i, p in ipairs(parts) do
            local rel = anchor.CFrame:Inverse() * p.CFrame
            box(anchor, rel, p.Size + Vector3.new(0.03, 0.03, 0.03), color, i == 1 and FILL_T or INNER_T, true)
            outline(p, color)
        end
    end

    local function drawGhost(root, e, color)
        local cf = CFrame.new(e[1], e[2], e[3]) * CFrame.Angles(0, math.rad(e[4]), 0)
        box(root, cf, OUTER, color, FILL_T + MISS_T, true)
        box(root, cf * CFrame.new(0, INNER_UP, 0), INNER_SZ, color, INNER_T + MISS_T, true)
        edges(root, cf, OUTER, color)
        solid(root.CFrame * cf)
    end

    local function build()
        if not alive then return end
        clear()
        for _, plot in ipairs(Plots:GetChildren()) do
            local root = plot:FindFirstChild("MainRoot")
            local pods = plot:FindFirstChild("AnimalPodiums")
            if root and pods then
                for i = 1, #TEMPLATE do
                    local sl = pods:FindFirstChild(tostring(i))
                    local parts = sl and slabsOf(sl)
                    local c = colorFor(i)
                    if parts and parts[1] then
                        drawReal(parts, c)
                    else
                        drawGhost(root, TEMPLATE[i], c)
                    end
                end
            end
        end
    end

    build()

    _G.__UpdatePodiumColor = function(newColor)
        CFG.FLOOR_COLOR = { newColor, newColor, newColor }
        if alive then build() end
    end

    local pending = false
    local function rebuild()
        if pending or not alive then return end
        pending = true
        task.delay(0.4, function() pending = false build() end)
    end
    local function watch(plot)
        local pods = plot:WaitForChild("AnimalPodiums", 20)
        if pods and alive then
            conns[#conns + 1] = pods.ChildAdded:Connect(rebuild)
            conns[#conns + 1] = pods.ChildRemoved:Connect(rebuild)
        end
    end
    for _, plot in ipairs(Plots:GetChildren()) do task.spawn(watch, plot) end
    conns[#conns + 1] = Plots.ChildAdded:Connect(function(plot)
        task.spawn(watch, plot)
        rebuild()
    end)

    do
        local acc = 0
        conns[#conns + 1] = RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.05 then return end
            acc = 0
            local w = math.sin(os.clock() * PULSE_SPEED) * PULSE_AMOUNT
            for _, f in ipairs(fills) do
                if f.a.Parent then f.a.Transparency = math.clamp(f.base + w, 0, 1) end
            end
        end)
    end

    _G.__PodiumESPCleanup = function()
        alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
        clear()
        if solids then solids:Destroy() solids = nil end
        _G.__PodiumESPCleanup = nil
        _G.__UpdatePodiumColor = nil
    end
end

WorldSection:Toggle({
    Name = "Podium ESP",
    Default = ConfigData.PodiumESP,
    Callback = function(state)
        ConfigData.PodiumESP = state
        saveConfig()
        if state then
            startPodiumESP()
        else
            if _G.__PodiumESPCleanup then pcall(_G.__PodiumESPCleanup) end
        end
    end
})

-- Color Picker (Podium Color)
pcall(function()
    local cpFunc = WorldSection.Colorpicker or WorldSection.ColorPicker or WorldSection.AddColorPicker
    if cpFunc then
        cpFunc(WorldSection, {
            Name = "Podium Color",
            Default = _G.__PodiumColor,
            Callback = function(color)
                ConfigData.PodiumColor = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
                saveConfig()
                _G.__PodiumColor = color
                if _G.__UpdatePodiumColor then
                    _G.__UpdatePodiumColor(color)
                end
            end
        })
    end
end)

if ConfigData.PodiumESP then
    startPodiumESP()
end