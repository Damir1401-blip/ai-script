-- Simple API Test Script for Roblox
-- Run this first to test if NVIDIA API works in your Roblox environment

print("🧪 Testing NVIDIA API connection...")

local HttpService = game:GetService("HttpService")
local API_KEY = "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"
local API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"

-- Test HTTP requests enabled
if not HttpService.HttpEnabled then
    warn("❌ HTTP requests are disabled! Enable them in Studio or your executor.")
    return
else
    print("✅ HTTP requests are enabled")
end

-- Test API call
local success, result = pcall(function()
    local requestData = {
        model = "nvidia/llama-3.1-nemotron-70b-instruct",
        messages = {
            {
                role = "user",
                content = "Hello, this is a test from Roblox"
            }
        },
        max_tokens = 30,
        temperature = 0.7
    }
    
    local headers = {
        ["Authorization"] = "Bearer " .. API_KEY,
        ["Content-Type"] = "application/json"
    }
    
    local jsonData = HttpService:JSONEncode(requestData)
    print("📤 Sending request...")
    
    local response = HttpService:PostAsync(API_URL, jsonData, Enum.HttpContentType.ApplicationJson, false, headers)
    return HttpService:JSONDecode(response)
end)

if success then
    print("✅ API Test Successful!")
    if result and result.choices and result.choices[1] then
        print("🤖 AI Response:", result.choices[1].message.content)
        print("💰 Token Usage:", result.usage.total_tokens, "tokens")
        print("🎯 The API is working perfectly in Roblox!")
    else
        print("❌ Unexpected response format:", result)
    end
else
    print("❌ API Test Failed:", result)
    print("🔍 This could be due to:")
    print("   - HTTP requests disabled")
    print("   - Firewall blocking the request") 
    print("   - Game/executor restrictions")
    print("   - Network connectivity issues")
end

print("🧪 API Test Complete!")
