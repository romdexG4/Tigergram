# Tigergram
Tigergram and its companion gateway brings the Telegram messenger to Mac OS X 10.4 Tiger (PPC&amp;Intel)


# Tigergram

Tigergram is an independent and unofficial Telegram client for Mac OS X 10.4 Tiger, designed to bring modern messaging to classic PowerPC and early Intel Macintosh systems.

The client itself is written in Objective-C and runs natively on Mac OS X Tiger. Because modern Telegram infrastructure relies on technologies that are difficult or impossible to support directly on Mac OS X 10.4, including modern TLS versions, cryptographic libraries, and the MTProto protocol—Tigergram uses a companion Python gateway server running on a modern machine. The gateway communicates with Telegram and relays data to the Tiger client.

Tigergram is currently experimental but already capable of basic day-to-day messaging.

---

## Features

### Currently Working

- Chat list with chat type indicators (Direct, Group, Channel)
- Unread message count (capped at 50+)
- Automatic refresh every 30 seconds
- View messages with sender and timestamp
- Send messages
- Press Enter to send
- Reply to messages
- Near real-time updates through long polling
- Profile pictures
- User bio/status displayed below chat names
- Download photos directly to the Desktop
- First-run setup window with gateway IP configuration
- Connection error handling
- Application closes cleanly when the main window is closed
- Gateway status page (`/status`)
- Partially documented and commented source code

### Current Limitations

- Maximum of 50 chats displayed
- Maximum of 50 messages loaded per chat
- No voice or video calls
- Only image downloads are currently supported
- Other media types appear as informational text only
- Messages are not yet marked as read
- No online/offline presence indicator
- No notification sound or message alerts

---

## Compatibility

- Mac OS X 10.4 Tiger
- PowerPC Macs (G4, G5)
- Early Intel Macs running Tiger

---

## Requirements

### Tiger Mac (Client)
- Mac OS X 10.4 Tiger
- A local network connection to the gateway machine

### Gateway Machine (Modern Computer)
- macOS, Linux or Windows
- Python 3.10 or newer
- A Telegram account
- A Telegram API ID and API Hash (free, from [my.telegram.org](https://my.telegram.org))
- Network connectivity between the gateway and the Tiger Mac
- Homebrew (macOS only, recommended)

---

## Installation

### Part 1 – Gateway Setup (Modern Mac)

**Step 1: Install Homebrew** (if not already installed)

Open Terminal and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Step 2: Install Python**
```bash
brew install python
```

**Step 3: Download the gateway files**

Either clone this repository:
```bash
git clone https://github.com/romdexG4/Tigergram.git
cd Tigergram
```

Or download the ZIP from GitHub and extract it.

**Step 4: Create a virtual environment and install dependencies**
```bash
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

**Step 5: Get your Telegram API credentials**

1. Go to [https://my.telegram.org](https://my.telegram.org)
2. Log in with your Telegram phone number
3. Click **API development tools**
4. Create a new application (name and platform do not matter)
5. Copy your **App api_id** and **App api_hash**

**Step 6: Enter your credentials**

Open `telegram.py` in a text editor and replace:
```python
API_ID = 0        # Get your api_id from https://my.telegram.org
API_HASH = ""     # Get your api_hash from https://my.telegram.org
```
with your actual values:
```python
API_ID = 12345678
API_HASH = "yourhashhere"
```

**Step 7: Log in to Telegram**

Run the login script once to authenticate:
```bash
python3 login.py
```

You will be prompted for your phone number and a verification code sent to your Telegram app.

**Step 8: Start the gateway**
```bash
uvicorn main:app --host 0.0.0.0 --port 8080
```

The gateway is now running. You can verify it by opening:
http://localhost:8080/status

**Step 9: Find your gateway IP address**

On macOS:
```bash
ipconfig getifaddr en0
```

Note this IP address – you will need it when setting up the Tiger client.

---

### Part 2 – Tiger Client Setup

**Step 1: Install Tigergram**

Download the latest release from the [Releases](https://github.com/romdexG4/Tigergram/releases) page and copy `Tigergram.app` to your Applications folder.

**Step 2: Launch Tigergram**

Double-click `Tigergram.app`. A setup window will appear asking for the gateway IP address and port.

**Step 3: Enter gateway details**

- **IP Address:** The IP address of your modern Mac running the gateway (e.g. `192.168.1.50`)
- **Port:** `8080` (default)

Click **Connect**. If the gateway is reachable, the chat list will load automatically.

---

### Part 3 – Building from Source (Optional)

Developers wishing to build the Tiger client from source will need:

- Xcode 2.5
- Mac OS X 10.4 SDK
- The source files from the `tigergram-client/` directory

Open `Tigergram.xcodeproj` in Xcode 2.5, select **Release** as the build configuration and click **Build**.

---

## Architecture

Tigergram consists of two components:

### Tigergram Client

The native Mac OS X 10.4 application written in Objective-C. This is responsible for the user interface, chat display, message composition, image downloading, and communication with the gateway server.

### Tigergram Gateway

A Python-based gateway server that runs on a modern computer. The gateway connects to Telegram using the Telethon library and a regular Telegram user account.

The gateway handles:

- Telegram authentication
- Communication with Telegram servers
- Modern TLS and cryptographic requirements
- Message synchronization
- Long-polling updates
- Data translation between Telegram and the Tiger client

To use the gateway, users must obtain their own Telegram API ID and API Hash from Telegram and configure them in the gateway.

### Why a Gateway?

Mac OS X 10.4 predates many technologies required by modern Telegram clients, including:

- Modern TLS versions
- Current cryptographic libraries
- Telegram's MTProto ecosystem
- Contemporary Python and networking stacks

Using a gateway allows Tigergram to remain compatible with original Tiger-era hardware while still accessing the modern Telegram network.

---

## Project Status

Tigergram Version 1 should be considered experimental software. While the client is already usable for basic messaging, many Telegram features are not yet implemented.

---

## Credits

Created and developed by Romdex ([@romdex](https://t.me/romdex) on Telegram).

AI-assisted development tools, including Claude AI, were used during development. Much of the Python gateway server was generated, refined, or accelerated through AI-assisted coding.

---

## Contributing

Feel free to modify, improve, fork, or build upon this project. The goal of Tigergram is to provide a foundation for Telegram access on legacy Macintosh systems and to encourage experimentation and preservation of classic computing platforms.

I will only distribute my own official builds through Macintosh Garden http://macintoshgarden.org/ or here on this GitHub page. Any third-party builds, modifications, or redistributions are the responsibility of their respective authors.

---

## Disclaimer

Tigergram is an unofficial client and is not affiliated with, endorsed by, or supported by Telegram Messenger LLP.

Use at your own risk. No warranty is provided regarding security, reliability, compatibility, or future functionality.

---

## License

MIT License
