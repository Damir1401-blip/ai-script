-- KRNL AI Script with NVIDIA API Integration
print("🤖 KRNL AI SCRIPT LOADED!")
print("📡 Connecting to NVIDIA API...")
print("💬 Ready to respond to chat messages!")

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

print("✨ Setup complete! AI is ready to respond to chat messages.")
