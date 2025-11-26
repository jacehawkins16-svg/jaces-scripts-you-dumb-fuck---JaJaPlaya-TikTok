loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 
local LocalPlayer = Players.LocalPlayer 
local task = task
local RunService = game:GetService("RunService")

-- Cooldown Configuration (Common for both systems)
local COOLDOWN_DURATION = 5.0 -- 5 seconds cooldown between toggles

-- UI References (Common for both systems)
local CooldownTextLabel = nil

--------------------------------------------------------------------------------
-- SHARED STATE (Global Cooldown Lock)
--------------------------------------------------------------------------------
local isAnyTeleportActive = {value = false} 
local activeTeleportKey = "" 

-- GLOBAL COOLDOWN STATE: Controls activation delay for *both* T and Y
local isGlobalCooldown = {value = false} 
local lastGlobalToggleTime = {value = 0}

--------------------------------------------------------------------------------
-- UI Functions (Shared by both T and Y systems)
--------------------------------------------------------------------------------

local function updateCooldownUI(remainingTime, isInitial, key)
    if not CooldownTextLabel then return end

    if isInitial then
         CooldownTextLabel.Text = string.format("[%s] INITIALIZING: Please wait %.1fs", key, remainingTime)
    else
         -- Red Banner: Cooldown status with accurate remaining time at the bottom of the screen.
        CooldownTextLabel.Text = string.format("[%s] COOLDOWN: %.1f remaining", key, remainingTime)
    end
end

local function displayErrorMessage(message)
    if not CooldownTextLabel then return end

    local originalBgColor = CooldownTextLabel.BackgroundColor3
    local originalBgTrans = CooldownTextLabel.BackgroundTransparency

    CooldownTextLabel.BackgroundColor3 = Color3.fromRGB(192, 57, 43) -- Darker Red
    CooldownTextLabel.Text = message
    CooldownTextLabel.Visible = true
    
    local fadeInTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bgFade = TweenService:Create(CooldownTextLabel, fadeInTweenInfo, { 
        BackgroundTransparency = 0,
        TextTransparency = 0,
    })
    bgFade:Play()
    
    task.wait(2.0) -- Display time
    
    local fadeOutTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local bgFadeOut = TweenService:Create(CooldownTextLabel, fadeOutTweenInfo, { 
        BackgroundTransparency = 1,
        TextTransparency = 1,
    })
    bgFadeOut:Play()
    bgFadeOut.Completed:Wait()
    
    CooldownTextLabel.Visible = false 
    
    CooldownTextLabel.BackgroundColor3 = originalBgColor
    CooldownTextLabel.BackgroundTransparency = originalBgTrans
end

local function setupCooldownUI()
    if not LocalPlayer:FindFirstChild("PlayerGui") then return end

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    if PlayerGui:FindFirstChild("CooldownScreenGui") then return end

    local CooldownGui = Instance.new("ScreenGui")
    CooldownGui.Name = "CooldownScreenGui"
    CooldownGui.DisplayOrder = 10 
    CooldownGui.Parent = PlayerGui

    local Label = Instance.new("TextLabel")
    Label.Name = "CooldownTimer"
    Label.Size = UDim2.new(0, 350, 0, 50) 
    Label.Position = UDim2.new(0.5, 0, 1, -150) 
    Label.AnchorPoint = Vector2.new(0.5, 0)
    
    Label.BackgroundTransparency = 1 
    Label.BackgroundColor3 = Color3.fromRGB(231, 76, 60) 
    Label.TextColor3 = Color3.fromRGB(255, 255, 255) 
    Label.TextTransparency = 1 
    
    Label.Font = Enum.Font.SourceSansBold
    Label.TextSize = 18
    Label.Text = "COOLDOWN: 5.0 remaining"
    Label.Visible = false
    Label.Parent = CooldownGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Label
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(192, 57, 43) 
    Stroke.Parent = Label
    
    CooldownTextLabel = Label 
end

-- Function to handle the actual cooldown lock (Now Global)
local function startCooldownLock(duration)
    isGlobalCooldown.value = true
    lastGlobalToggleTime.value = tick()
    
    task.wait(duration)
    
    if tick() >= lastGlobalToggleTime.value + duration - 0.1 then 
        isGlobalCooldown.value = false
    end
end

-- Function to show the cooldown UI, handle fade-in, and run the countdown (Now uses Global Time)
local function showCooldownTimer(duration, isInitial, key)
    if not CooldownTextLabel then return end
    
    -- Prevent multiple countdowns from running simultaneously
    if CooldownTextLabel.Visible and CooldownTextLabel.TextTransparency < 1 then
        return 
    end

    CooldownTextLabel.Visible = true
    
    local fadeInTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bgFade = TweenService:Create(CooldownTextLabel, fadeInTweenInfo, { 
        BackgroundTransparency = 0,
        TextTransparency = 0,
    })
    bgFade:Play()
    bgFade.Completed:Wait() 
    
    local endTime = lastGlobalToggleTime.value + duration
    
    while tick() < endTime do 
        local timeRemaining = math.max(0, endTime - tick())
        local displayTime = math.ceil(timeRemaining * 10) / 10 
        
        updateCooldownUI(displayTime, isInitial, key)
        task.wait(0.1)
    end
    
    updateCooldownUI(0.0, isInitial, key)
    
    task.wait(0.3)
    local fadeOutTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    local bgFadeOut = TweenService:Create(CooldownTextLabel, fadeOutTweenInfo, { 
        BackgroundTransparency = 1,
        TextTransparency = 1,
    })
    bgFadeOut:Play()
    bgFadeOut.Completed:Wait()
    
    CooldownTextLabel.Visible = false 
end

-- Function to display a custom GUI notification at the top of the screen (Green Banner)
local function displayNotification(message)
    if not LocalPlayer:FindFirstChild("PlayerGui") then return end

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    if PlayerGui:FindFirstChild("InjectionNotification") then
        PlayerGui.InjectionNotification:Destroy() 
    end

    local NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "InjectionNotification"
    NotificationGui.DisplayOrder = 99
    
    local frameColor = Color3.fromRGB(46, 204, 113) 
    
    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Position = UDim2.new(0.5, 0, 0, -50) 
    NotificationFrame.AnchorPoint = Vector2.new(0.5, 0)
    NotificationFrame.Size = UDim2.new(0, 350, 0, 50) 
    NotificationFrame.BackgroundColor3 = frameColor
    NotificationFrame.Parent = NotificationGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8) 
    Corner.Parent = NotificationFrame

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Text = message
    MessageLabel.Size = UDim2.new(1, -20, 1, 0)
    MessageLabel.Position = UDim2.new(0, 10, 0, 0)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.TextColor3 = Color3.new(1, 1, 1) 
    MessageLabel.TextScaled = true
    MessageLabel.Font = Enum.Font.SourceSansBold
    MessageLabel.Parent = NotificationFrame

    NotificationGui.Parent = PlayerGui

    -- Animation (Slide In, Hold, Fade Out)
    task.spawn(function()
        local SLIDE_DURATION = 0.5 
        local HOLD_DURATION = 4.0  
        
        local targetPosition = UDim2.new(0.5, 0, 0, 10)
        local slideInTweenInfo = TweenInfo.new(SLIDE_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local slideInTween = TweenService:Create(NotificationFrame, slideInTweenInfo, { Position = targetPosition })
        slideInTween:Play()
        slideInTween.Completed:Wait()
        
        task.wait(HOLD_DURATION)
        
        local fadeOutTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        local frameExitTween = TweenService:Create(NotificationFrame, fadeOutTweenInfo, {
            Position = UDim2.new(0.5, 0, 0, -50),
            BackgroundTransparency = 1,
        })
        
        local textTween = TweenService:Create(MessageLabel, fadeOutTweenInfo, {
            TextTransparency = 1
        })
      
        frameExitTween:Play()
        textTween:Play()
        frameExitTween.Completed:Wait()
        NotificationGui:Destroy()
    end)
end

--------------------------------------------------------------------------------
-- T Key System (Auto Win TP)
--------------------------------------------------------------------------------

local TELEPORT_KEY_T = Enum.KeyCode.T
local TARGET_DISTANCE_T = 20000
local TELEPORT_DELAY_T = 0.01   
local TARGET_POSITION_T = Vector3.new(TARGET_DISTANCE_T, 500, 0)

-- State variables for 'T'
local isTeleporting_T = false
local teleportLoopTask_T = nil 

local function TeleportCharacter_T()
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

    if HumanoidRootPart and isTeleporting_T then
        HumanoidRootPart.CFrame = CFrame.new(TARGET_POSITION_T)
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function startTeleportLoop_T()
    while isTeleporting_T do
        if LocalPlayer.Character then
            TeleportCharacter_T()
        end
        task.wait(TELEPORT_DELAY_T)
    end
end

local function onInputBegan_T(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == TELEPORT_KEY_T then
        
        -- 1. Check for Mutual Exclusion Lock (Prevents Toggling T if Y is currently active)
        if isAnyTeleportActive.value and not isTeleporting_T then
            local errorMessage = string.format("ERROR: Deactivate [%s] first!", activeTeleportKey)
            task.spawn(function() displayErrorMessage(errorMessage) end)
            return
        end
        
        -- 2. CHECK GLOBAL COOLDOWN (APPLIES ONLY WHEN TRYING TO ACTIVATE)
        -- If Global Cooldown is active AND T is currently OFF, block activation.
        if isGlobalCooldown.value and not isTeleporting_T then
            task.spawn(function() showCooldownTimer(COOLDOWN_DURATION, false, "T") end)
            return 
        end
        
        -- 3. --- Toggling Logic ---
        local message
        local Character = LocalPlayer.Character
        
        if not Character then
            message = "ERROR: Character not found! Please wait to respawn."
            displayNotification(message)
            return
        end
        
        if not isTeleporting_T then
            -- Toggled ON: Start Global Cooldown Lock immediately.
            isTeleporting_T = true
            isAnyTeleportActive.value = true 
            activeTeleportKey = "T" 
            teleportLoopTask_T = task.spawn(startTeleportLoop_T)
            message = "AUTO WIN TP ENABLED (T). Press 'T' to stop."

            -- 4. Start the GLOBAL Cooldown Lock AND the UI countdown (Only when turning ON)
            task.spawn(function() startCooldownLock(COOLDOWN_DURATION) end)
            task.spawn(function() showCooldownTimer(COOLDOWN_DURATION, false, "T") end)
        else
            -- Toggled OFF: Stop the Teleport and Reset state.
            isTeleporting_T = false
            isAnyTeleportActive.value = false 
            activeTeleportKey = "" 
            
            if teleportLoopTask_T then
                task.cancel(teleportLoopTask_T)
                teleportLoopTask_T = nil
            end
            
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if HumanoidRootPart then
                local fixedStopPosition = Vector3.new(-4, 5, 23) 
                local lookAtPosition = fixedStopPosition - Vector3.new(1, 0, 0) 
                
                HumanoidRootPart.CFrame = CFrame.new(fixedStopPosition, lookAtPosition)
                HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                local customMessage = "Teleported Back To Elevator"
                message = "AUTO WIN TP DISABLED!\n" .. customMessage .. ". Press 'T' to start."
            else
                LocalPlayer:LoadCharacter() 
                message = "AUTO WIN TP DISABLED! Character is resetting. Press 'T' to start."
            end
            -- Note: Cooldown does *not* start on Toggled OFF, only on Toggled ON.
        end
        
        -- 5. Display the toggle notification (top banner)
        displayNotification(message)
    end
end

-- Initialization function that runs once for 'T'
local function initialize_T()
    -- Only prints; Global Initialization handles the lock/UI start.
    print("Teleport Toggle Script (T) initialized and ready for input.")
end

--------------------------------------------------------------------------------
-- Y Key System (Specific TP)
--------------------------------------------------------------------------------

local TELEPORT_KEY_Y = Enum.KeyCode.Y 
local TELEPORT_DELAY_Y = 1   
local TARGET_POSITION_Y = Vector3.new(-307, 17, 26) 

-- State variables for 'Y'
local isTeleporting_Y = false
local teleportLoopTask_Y = nil 

local function TeleportCharacter_Y()
    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

    if HumanoidRootPart and isTeleporting_Y then
        HumanoidRootPart.CFrame = CFrame.new(TARGET_POSITION_Y)
        HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function startTeleportLoop_Y()
    while isTeleporting_Y do
        if LocalPlayer.Character then
            TeleportCharacter_Y()
        end
        task.wait(TELEPORT_DELAY_Y)
    end
end

local function onInputBegan_Y(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == TELEPORT_KEY_Y then
        
        -- 1. Check for Mutual Exclusion Lock (Prevents Toggling Y if T is currently active)
        if isAnyTeleportActive.value and not isTeleporting_Y then
            local errorMessage = string.format("ERROR: Deactivate [%s] first!", activeTeleportKey)
            task.spawn(function() displayErrorMessage(errorMessage) end)
            return
        end
        
        -- 2. CHECK GLOBAL COOLDOWN (APPLIES ONLY WHEN TRYING TO ACTIVATE)
        -- If Global Cooldown is active AND Y is currently OFF, block activation.
        if isGlobalCooldown.value and not isTeleporting_Y then
            task.spawn(function() showCooldownTimer(COOLDOWN_DURATION, false, "Y") end)
            return 
        end

        -- 3. --- Toggling Logic ---
        local message
        local Character = LocalPlayer.Character
        
        if not Character then
            message = "ERROR: Character not found! Please wait to respawn."
            displayNotification(message)
            return
        end
        
        if not isTeleporting_Y then
            -- Toggled ON: Start Global Cooldown Lock immediately.
            isTeleporting_Y = true
            isAnyTeleportActive.value = true 
            activeTeleportKey = "Y" 
            teleportLoopTask_Y = task.spawn(startTeleportLoop_Y)
            message = string.format("SPECIFIC TP ENABLED (Y) to (%d, %d, %d). Press 'Y' to stop.", TARGET_POSITION_Y.X, TARGET_POSITION_Y.Y, TARGET_POSITION_Y.Z)
            
            -- 4. Start the GLOBAL Cooldown Lock AND the UI countdown (Only when turning ON)
            task.spawn(function() startCooldownLock(COOLDOWN_DURATION) end)
            task.spawn(function() showCooldownTimer(COOLDOWN_DURATION, false, "Y") end)
        else
            -- Toggled OFF: Stop the Teleport and Reset state.
            isTeleporting_Y = false
            isAnyTeleportActive.value = false 
            activeTeleportKey = "" 
            
            if teleportLoopTask_Y then
                task.cancel(teleportLoopTask_Y)
                teleportLoopTask_Y = nil
            end
            
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if HumanoidRootPart then
                local fixedStopPosition = Vector3.new(-4, 5, 23)
                local lookAtPosition = fixedStopPosition - Vector3.new(1, 0, 0) 
                
                HumanoidRootPart.CFrame = CFrame.new(fixedStopPosition, lookAtPosition)
                HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                local customMessage = "Teleported Back To Elevator"
                message = "SPECIFIC TP DISABLED!\n" .. customMessage .. ". Press 'Y' to start."
            else
                LocalPlayer:LoadCharacter() 
                message = "SPECIFIC TP DISABLED!\n" .. "Character is resetting. Press 'Y' to start."
            end
            -- Note: Cooldown does *not* start on Toggled OFF, only on Toggled ON.
        end
        
        -- 5. Display the toggle notification (top banner)
        displayNotification(message)
    end
end

-- Initialization function that runs once for 'Y' (handles combined welcome message)
local function initialize_Y()
    -- Only prints; Global Initialization handles the lock/UI start.
    local message = "Script Loaded! Press 'Y' for Specific TP or 'T' for Auto Win TP."
    displayNotification(message)
    print("Teleport Toggle Script (Y) initialized and ready for input.")
end

--------------------------------------------------------------------------------
-- Combined Startup Logic
--------------------------------------------------------------------------------

local function initializeGlobalCooldown()
    -- 1. Start Initial Global Cooldown Lock (Prevents immediate use on load)
    task.spawn(function() startCooldownLock(COOLDOWN_DURATION) end)
    
    -- 2. Show Initial Cooldown UI (tells player to wait)
    -- Using "TP" to indicate the global cooldown on startup
    task.spawn(function() showCooldownTimer(COOLDOWN_DURATION, true, "TP") end)
end

-- 1. Connect input handlers immediately
UserInputService.InputBegan:Connect(onInputBegan_T)
UserInputService.InputBegan:Connect(onInputBegan_Y)

if RunService:IsClient() then
    -- Wait for player services and character before initializing the game logic
    repeat task.wait() until LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    
    -- 2. Setup the shared UI structure first
    setupCooldownUI() 
    
    -- 3. Initialize the Global Cooldown lock and UI
    initializeGlobalCooldown()
    
    -- 4. Run individual initializations (mainly for welcome messages)
    task.spawn(initialize_T)
    task.spawn(initialize_Y)
end
