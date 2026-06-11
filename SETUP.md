# Tigergram Setup Guide

Setting up Tigergram takes about 15 minutes. You need two computers:

- A **modern computer** (Mac, Linux or Windows) – this runs the gateway
- A **Tiger Mac** (PowerPC or early Intel with Mac OS X 10.4) – this runs the client

Both computers must be on the **same network** (same WiFi/router).

---

## Part 1: Set up the Gateway (Modern Computer)

### Step 1 – Install Python

**On macOS:**

Open **Terminal** (press `⌘ + Space`, type `Terminal`, press Enter), then paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Wait for it to finish, then run:

```bash
brew install python
```

**On Windows:** Download Python from [python.org](https://python.org) and install it.

### Step 2 – Download Tigergram

Download this repository as ZIP (green **Code** button → **Download ZIP**) and unzip it, or run:

```bash
git clone https://github.com/romdexG4/Tigergram.git
```

### Step 3 – Install dependencies

In Terminal, go into the folder and set everything up:

```bash
cd Tigergram
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```

### Step 4 – Get your Telegram API keys

1. Go to [my.telegram.org](https://my.telegram.org)
2. Log in with your Telegram phone number
3. Click **API development tools**
4. Create a new app (any name works)
5. Copy your **api_id** and **api_hash**

### Step 5 – Enter your API keys

Open `telegram.py` and `login.py` in a text editor. In both files, replace:

```python
API_ID = 0
API_HASH = ""
```

with your actual values:

```python
API_ID = 12345678
API_HASH = "abc123yourhashhere"
```

Save both files.

### Step 6 – Log in to Telegram

Run:

```bash
python3 login.py
```

Enter your phone number (with country code, e.g. `+1234567890`) and the code Telegram sends you. You only need to do this once.

### Step 7 – Start the gateway

```bash
uvicorn main:app --host 0.0.0.0 --port 8080
```

The gateway is now running! Check it works by opening **http://localhost:8080/status** in your browser.

### Step 8 – Find your IP address

**On macOS:**
```bash
ipconfig getifaddr en0
```

Write down this IP (e.g. `192.168.1.50`) – you need it for the Tiger Mac.

> **Important:** Keep the Terminal window open. The gateway only runs while this window is open.

---

## Part 2: Set up the Client (Tiger Mac)

### Step 1 – Install Tigergram

Download `Tigergram-1.0.dmg` from the [Releases page](https://github.com/romdexG4/Tigergram/releases), open it, and drag **Tigergram** to your Applications folder.

### Step 2 – Launch and connect

1. Open **Tigergram**
2. A setup window appears
3. Enter the **IP address** from Part 1, Step 8 (e.g. `192.168.1.50`)
4. Port stays at `8080`
5. Click **Connect**

### Step 3 – Done!

Your chats will load. Click any chat to open it. Type a message and press Enter to send.

---

## Troubleshooting

**"Gateway not reachable"**
- Is the gateway still running on the modern computer?
- Are both computers on the same WiFi/network?
- Did you type the IP address correctly?

**Chats won't load**
- Restart the gateway (press `Ctrl + C` in Terminal, then run the start command again)

**Gateway stopped working after restart**
- You need to activate the environment again first:

```bash
cd Tigergram
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8080
```

---

That's it! Enjoy Telegram on your vintage Mac.

*Tigergram v1.0 by romdex (@romdex on Telegram)*
