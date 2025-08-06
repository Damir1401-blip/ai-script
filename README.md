# 🤖 Roblox AI Chat Bot Script

A powerful AI-powered chat bot for Roblox that uses NVIDIA's API to intelligently respond to player messages in real-time.

## ✨ Features

- 🧠 **AI-Powered Responses** - Uses NVIDIA's Llama 3.1 Nemotron 70B model
- 💬 **Smart Chat Detection** - Responds to trigger words and mentions
- 🎮 **Easy Commands** - Simple `/ai` commands to control the bot
- 🛡️ **Built-in Safety** - Rate limiting and duplicate message prevention
- 🔄 **Auto-Cleanup** - Prevents memory issues with periodic cache clearing
- ⚡ **Multiple Chat Systems** - Works with both modern and legacy Roblox chat

## 🚀 Quick Start

### Method 1: Direct Load (Recommended)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/ai-script/main/main.lua"))()
```

### Method 2: Manual Execution
1. Copy the contents of `main.lua`
2. Paste into your executor (KRNL, Synapse X, etc.)
3. Execute the script

## 🎯 Trigger Words

The AI bot will respond to messages containing:
- `ai`, `bot`, `help`, `question`
- `what`, `how`, `why`, `when`, `where`
- Your Roblox username
- And more contextual triggers!

## 🎮 Commands

- `/ai status` - Check if the bot is enabled
- `/ai on` - Enable AI responses
- `/ai off` - Disable AI responses

## 📋 Requirements

- ✅ HTTP requests enabled in your executor
- ✅ Game with active chat system
- ✅ NVIDIA API access (built-in)

## 🔧 Configuration

The script comes pre-configured with:
- **Model:** NVIDIA Llama 3.1 Nemotron 70B Instruct
- **Max Tokens:** 100 (short, concise responses)
- **Temperature:** 0.7 (balanced creativity)
- **Response Delay:** 2 seconds (rate limiting)

## 🛠️ How It Works

1. **Chat Monitoring** - Listens to all player messages
2. **Smart Filtering** - Only responds to relevant messages
3. **API Processing** - Sends context to NVIDIA AI
4. **Response Generation** - Gets AI response and sends to chat
5. **Rate Limiting** - Prevents spam with built-in delays

## 🔒 Privacy & Safety

- ✅ Kid-friendly responses only
- ✅ No data stored permanently
- ✅ Rate limiting prevents spam
- ✅ Can be disabled instantly

## 📖 Example Usage

**Player says:** "How do I get better at this game?"
**AI responds:** "🤖 Practice regularly, watch tutorials, and learn from other players! Focus on one skill at a time."

**Player says:** "What's the best strategy?"
**AI responds:** "🤖 It depends on the game mode, but teamwork and communication are usually key to success!"

## 🐛 Troubleshooting

**Bot not responding?**
- Check if HTTP requests are enabled
- Verify the game has active chat
- Use `/ai status` to check bot status

**Getting errors?**
- Make sure you're using a compatible executor
- Check your internet connection
- Try reloading the script

## 📜 License

This project is open source. Feel free to modify and share!

## ⭐ Support

If you found this helpful, please give it a star! 🌟

---
*Made with ❤️ for the Roblox scripting community*
