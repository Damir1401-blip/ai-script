-- KRNL AI Script with NVIDIA API Integration & GUI
print("🤖 KRNL AI SCRIPT WITH GUI LOADED!")
print("📡 Connecting to NVIDIA API...")
print("💬 Ready to respond to chat messages!")
print("🎨 Creating GUI interface...")

-- Configuration
local API_KEY = "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"
local API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
local MODEL = "nvidia/llama-3.1-nemotron-70b-instruct"
local MAX_TOKENS = 100
local TEMPERATURE = 0.7
local RESPONSE_DELAY = 2

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local isEnabled = true
local lastMessageTime = 0
local processedMessages = {}

-- Function to make API request to NVIDIA
local function callNVIDIAAPI(prompt)
    local success, response = pcall(function()
        local requestData = {
            model = MODEL,
            messages = {
                {
                    role = "system",
                    content = "You are a helpful AI assistant in a Roblox game. Keep responses short, friendly, and appropriate for all ages. Maximum 50 words."
                },
                {
                    role = "user",
                    content = prompt
                }
            },
            max_tokens = MAX_TOKENS,
            temperature = TEMPERATURE,
            stream = false
        }
        
        local headers = {
            ["Authorization"] = "Bearer " .. API_KEY,
            ["Content-Type"] = "application/json"
        }
        
        local jsonData = HttpService:JSONEncode(requestData)
        local result = HttpService:PostAsync(API_URL, jsonData, Enum.HttpContentType.ApplicationJson, false, headers)
        
        return HttpService:JSONDecode(result)
    end)
    
    if success and response and response.choices and response.choices[1] then
        return response.choices[1].message.content
    else
        print("❌ API Error:", response)
        return "Sorry, I couldn't process that request."
    end
end

-- Function to send chat message
local function sendChatMessage(message)
    local success, error = pcall(function()
        -- Method 1: Try ReplicatedStorage SayMessageRequest
        if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
            local chatEvents = ReplicatedStorage.DefaultChatSystemChatEvents
            if chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(message, "All")
                return
            end
        end
        
        -- Method 2: Try direct chat service
        game:GetService("Chat"):Chat(LocalPlayer.Character.Head, message, Enum.ChatColor.White)
    end)
    
    if not success then
        print("❌ Failed to send message:", error)
    end
end

-- Function to check if message should trigger AI response
local function shouldRespond(message, playerName)
    local lowerMessage = string.lower(message)
    
    -- Don't respond to own messages
    if playerName == LocalPlayer.Name then
        return false
    end
    
    -- Check for AI triggers
    local triggers = {"ai", "bot", "help", "question", "what", "how", "why", "when", "where"}
    for _, trigger in pairs(triggers) do
        if string.find(lowerMessage, trigger) then
            return true
        end
    end
    
    -- Respond to messages mentioning the player
    if string.find(lowerMessage, string.lower(LocalPlayer.Name)) then
        return true
    end
    
    return false
end

-- Function to process chat message
local function processMessage(message, playerName)
    local currentTime = tick()
    local messageKey = playerName .. ":" .. message
    
    -- Prevent duplicate processing
    if processedMessages[messageKey] then
        return
    end
    processedMessages[messageKey] = true
    
    -- Rate limiting
    if currentTime - lastMessageTime < RESPONSE_DELAY then
        return
    end
    
    if not isEnabled or not shouldRespond(message, playerName) then
        return
    end
    
    print("🎯 Processing message from", playerName .. ":", message)
    
    -- Add context to the prompt
    local contextPrompt = string.format("In a Roblox game, %s said: '%s'. Please respond helpfully.", playerName, message)
    
    spawn(function()
        local aiResponse = callNVIDIAAPI(contextPrompt)
        if aiResponse then
            wait(1) -- Small delay before responding
            sendChatMessage("🤖 " .. aiResponse)
            lastMessageTime = tick()
            print("✅ Sent AI response:", aiResponse)
        end
    end)
end

-- Connect to chat events
local function connectToChat()
    local success = pcall(function()
        -- Method 1: Connect to ReplicatedStorage chat events
        if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
            local chatEvents = ReplicatedStorage.DefaultChatSystemChatEvents
            if chatEvents:FindFirstChild("OnMessageDoneFiltering") then
                chatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
                    if messageData and messageData.Message and messageData.FromSpeaker then
                        processMessage(messageData.Message, messageData.FromSpeaker)
                    end
                end)
                print("✅ Connected to chat via ReplicatedStorage")
                return true
            end
        end
        
        -- Method 2: Connect to player chatted events
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Head") then
                player.Chatted:Connect(function(message)
                    processMessage(message, player.Name)
                end)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(message)
                processMessage(message, player.Name)
            end)
        end)
        
        print("✅ Connected to player chat events")
        return true
    end)
    
    if not success then
        print("❌ Failed to connect to chat")
    end
end

-- Commands system
local function handleCommand(message)
    local args = string.split(string.lower(message), " ")
    local command = args[1]
    
    if command == "/ai" then
        if args[2] == "on" then
            isEnabled = true
            print("✅ AI responses enabled")
        elseif args[2] == "off" then
            isEnabled = false
            print("❌ AI responses disabled")
        elseif args[2] == "status" then
            print("📊 AI Status:", isEnabled and "Enabled" or "Disabled")
        else
            print("💡 AI Commands: /ai on, /ai off, /ai status")
        end
        return true
    end
    
    return false
end

-- Connect to local player chat for commands
if LocalPlayer then
    LocalPlayer.Chatted:Connect(function(message)
        if not handleCommand(message) and string.sub(message, 1, 1) ~= "/" then
            -- Process own messages for AI if not a command
            processMessage(message, LocalPlayer.Name)
        end
    end)
end

-- Initialize
spawn(function()
    wait(2) -- Wait for game to load
    connectToChat()
    print("🚀 AI Script fully initialized!")
    print("💬 Type '/ai status' to check status")
    print("🎮 Type '/ai on' or '/ai off' to toggle")
end)

-- Cleanup processed messages periodically
spawn(function()
    while true do
        wait(300) -- Every 5 minutes
        processedMessages = {}
        print("🧹 Cleaned up message cache")
    end
end)

-- ==================== GUI SYSTEM ====================

-- GUI Variables
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local screenGui = nil
local mainFrame = nil
local statusLabel = nil
local responseCount = 0
local lastResponseTime = ""
local guiVisible = true

-- Statistics tracking
local stats = {
    totalResponses = 0,
    sessionsActive = 0,
    lastActive = tick()
}

-- Create GUI
local function createGUI()
    -- Main ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AIBotGUI"
    screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 400)
    mainFrame.Position = UDim2.new(0, 20, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Corner Radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Shadow Effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/Controls/DropShadow.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(12, 12, 256-12, 256-12)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🤖 AI Chat Bot"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -45, 0, 15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    -- Status Section
    local statusSection = Instance.new("Frame")
    statusSection.Name = "StatusSection"
    statusSection.Size = UDim2.new(1, -20, 0, 80)
    statusSection.Position = UDim2.new(0, 10, 0, 70)
    statusSection.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    statusSection.BorderSizePixel = 0
    statusSection.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusSection
    
    -- Status Indicator
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 12, 0, 12)
    statusIndicator.Position = UDim2.new(0, 15, 0, 15)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = statusSection
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 6)
    indicatorCorner.Parent = statusIndicator
    
    -- Status Text
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -40, 0, 25)
    statusLabel.Position = UDim2.new(0, 35, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "AI Bot: Active"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusSection
    
    -- Response Counter
    local responseCounter = Instance.new("TextLabel")
    responseCounter.Name = "ResponseCounter"
    responseCounter.Size = UDim2.new(1, -40, 0, 20)
    responseCounter.Position = UDim2.new(0, 35, 0, 40)
    responseCounter.BackgroundTransparency = 1
    responseCounter.Text = "Responses: 0"
    responseCounter.TextColor3 = Color3.fromRGB(200, 200, 200)
    responseCounter.TextScaled = true
    responseCounter.Font = Enum.Font.Gotham
    responseCounter.TextXAlignment = Enum.TextXAlignment.Left
    responseCounter.Parent = statusSection
    
    -- Control Buttons Section
    local controlSection = Instance.new("Frame")
    controlSection.Name = "ControlSection"
    controlSection.Size = UDim2.new(1, -20, 0, 100)
    controlSection.Position = UDim2.new(0, 10, 0, 160)
    controlSection.BackgroundTransparency = 1
    controlSection.Parent = mainFrame
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(1, 0, 0, 35)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🔄 Toggle AI (ON)"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = controlSection
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn
    
    -- Settings Button
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0.48, 0, 0, 35)
    settingsBtn.Position = UDim2.new(0, 0, 0, 45)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Text = "⚙️ Settings"
    settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsBtn.TextScaled = true
    settingsBtn.Font = Enum.Font.Gotham
    settingsBtn.Parent = controlSection
    
    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsBtn
    
    -- Info Button
    local infoBtn = Instance.new("TextButton")
    infoBtn.Name = "InfoButton"
    infoBtn.Size = UDim2.new(0.48, 0, 0, 35)
    infoBtn.Position = UDim2.new(0.52, 0, 0, 45)
    infoBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    infoBtn.BorderSizePixel = 0
    infoBtn.Text = "ℹ️ Info"
    infoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoBtn.TextScaled = true
    infoBtn.Font = Enum.Font.Gotham
    infoBtn.Parent = controlSection
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoBtn
    
    -- Log Section
    local logSection = Instance.new("Frame")
    logSection.Name = "LogSection"
    logSection.Size = UDim2.new(1, -20, 0, 120)
    logSection.Position = UDim2.new(0, 10, 0, 270)
    logSection.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    logSection.BorderSizePixel = 0
    logSection.Parent = mainFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logSection
    
    -- Log Title
    local logTitle = Instance.new("TextLabel")
    logTitle.Name = "LogTitle"
    logTitle.Size = UDim2.new(1, -10, 0, 25)
    logTitle.Position = UDim2.new(0, 5, 0, 5)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "📜 Activity Log"
    logTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    logTitle.TextScaled = true
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = logSection
    
    -- Log Content
    local logContent = Instance.new("ScrollingFrame")
    logContent.Name = "LogContent"
    logContent.Size = UDim2.new(1, -10, 1, -35)
    logContent.Position = UDim2.new(0, 5, 0, 30)
    logContent.BackgroundTransparency = 1
    logContent.BorderSizePixel = 0
    logContent.ScrollBarThickness = 4
    logContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    logContent.Parent = logSection
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 2)
    logLayout.Parent = logContent
    
    -- Button Functions
    local function updateGUI()
        if statusLabel then
            statusLabel.Text = isEnabled and "AI Bot: Active ✓" or "AI Bot: Disabled ❌"
            statusIndicator.BackgroundColor3 = isEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            toggleBtn.Text = isEnabled and "🔄 Disable AI" or "🔄 Enable AI"
            toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 150, 250)
            responseCounter.Text = "Responses: " .. stats.totalResponses
        end
    end
    
    local function addLog(message)
        local logEntry = Instance.new("TextLabel")
        logEntry.Size = UDim2.new(1, -10, 0, 15)
        logEntry.BackgroundTransparency = 1
        logEntry.Text = os.date("[%H:%M:%S] ") .. message
        logEntry.TextColor3 = Color3.fromRGB(200, 200, 200)
        logEntry.TextScaled = true
        logEntry.Font = Enum.Font.Code
        logEntry.TextXAlignment = Enum.TextXAlignment.Left
        logEntry.LayoutOrder = tick()
        logEntry.Parent = logContent
        
        -- Auto-scroll
        logContent.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y)
        logContent.CanvasPosition = Vector2.new(0, logContent.CanvasSize.Y.Offset)
        
        -- Remove old entries (keep last 20)
        local children = logContent:GetChildren()
        if #children > 21 then -- 20 + UIListLayout
            children[2]:Destroy() -- First log entry (after UIListLayout)
        end
    end
    
    -- Button Events
    toggleBtn.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        updateGUI()
        addLog(isEnabled and "AI Bot enabled" or "AI Bot disabled")
        
        -- Button animation
        local tween = TweenService:Create(toggleBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, -5, 0, 30)})
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(toggleBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play()
        end)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        guiVisible = false
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
            Position = UDim2.new(0, -370, 0.5, -200),
            Size = UDim2.new(0, 350, 0, 50)
        })
        tween:Play()
        tween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
    
    infoBtn.MouseButton1Click:Connect(function()
        addLog("AI Script by Damir - NVIDIA API Integration")
        addLog("Model: Llama 3.1 Nemotron 70B")
        addLog("Trigger words: ai, bot, help, what, how, why...")
    end)
    
    settingsBtn.MouseButton1Click:Connect(function()
        addLog("Settings: Max tokens: " .. MAX_TOKENS)
        addLog("Temperature: " .. TEMPERATURE)
        addLog("Response delay: " .. RESPONSE_DELAY .. "s")
    end)
    
    -- Initial setup
    updateGUI()
    addLog("AI Bot GUI initialized")
    addLog("Ready to respond to chat messages")
    
    return screenGui, addLog, updateGUI
end

-- Override the processMessage function to include GUI updates
local originalProcessMessage = processMessage
local addLog, updateGUI

processMessage = function(message, playerName)
    originalProcessMessage(message, playerName)
    
    if shouldRespond(message, playerName) and isEnabled then
        stats.totalResponses = stats.totalResponses + 1
        if addLog then
            addLog("💬 Response to: " .. playerName)
        end
        if updateGUI then
            updateGUI()
        end
    end
end

-- Hotkey to toggle GUI (Right Ctrl)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        if not guiVisible then
            local _, logFunc, updateFunc = createGUI()
            addLog = logFunc
            updateGUI = updateFunc
            guiVisible = true
        end
    end
end)

-- Create initial GUI
spawn(function()
    wait(3) -- Wait for everything to load
    local _, logFunc, updateFunc = createGUI()
    addLog = logFunc
    updateGUI = updateFunc
    
    if addLog then
        addLog("GUI System loaded successfully")
        addLog("Press Right Ctrl to reopen if closed")
    end
end)

print("✨ Setup complete! AI is ready with GUI interface!")
print("🎨 GUI will appear in 3 seconds...")
print("⌨️ Press Right Ctrl to reopen GUI if closed")
