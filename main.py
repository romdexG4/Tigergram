# TigerGram Gateway - main.py
# Version 1.0 by romdex (@romdex on Telegram)
# FastAPI server that bridges the Tiger PPC client with Telegram

from fastapi import FastAPI
from fastapi.responses import Response, FileResponse, HTMLResponse
from contextlib import asynccontextmanager
import xml.etree.ElementTree as ET
import asyncio, os
import telegram

# ─────────────────────────────────────────
# App startup and shutdown
# Connects Telethon client on start, disconnects on shutdown
# run_until_disconnected runs as background task so
# event handlers (new messages) keep firing
# ─────────────────────────────────────────
@asynccontextmanager
async def lifespan(app):
    await telegram.client.connect()
    asyncio.create_task(telegram.client.run_until_disconnected())
    yield
    await telegram.client.disconnect()

app = FastAPI(lifespan=lifespan)

# ─────────────────────────────────────────
# Helper - returns XML response
# All endpoints return XML so the Tiger client
# can parse it with NSXMLParser
# ─────────────────────────────────────────
def xml(root):
    return Response(
        content=ET.tostring(root, encoding="unicode"),
        media_type="application/xml"
    )

# ─────────────────────────────────────────
# GET /test
# Simple connectivity test endpoint
# Used by Tiger client setup screen to verify gateway is reachable
# ─────────────────────────────────────────
@app.get("/test")
async def test():
    return {"status": "Gateway running!", "version": telegram.VERSION}

# ─────────────────────────────────────────
# GET /status
# Human-readable web interface showing gateway status
# Open in any browser: http://YOUR_IP:8080/status
# ─────────────────────────────────────────
@app.get("/status", response_class=HTMLResponse)
async def status():
    me = await telegram.client.get_me()
    uptime = telegram.get_uptime()
    name = f"{me.first_name or ''} {me.last_name or ''}".strip()
    username = f"@{me.username}" if me.username else "no username"
    pending = sum(len(v) for v in telegram.new_messages.values())

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>TigerGram Gateway</title>
        <meta http-equiv="refresh" content="30">
        <style>
            body {{
                font-family: monospace;
                background: #1a1a1a;
                color: #00ff00;
                padding: 40px;
                max-width: 600px;
                margin: 0 auto;
            }}
            h1 {{ color: #00ff88; border-bottom: 1px solid #00ff00; padding-bottom: 10px; }}
            h2 {{ color: #00cc66; margin-top: 30px; }}
            .label {{ color: #888; }}
            .value {{ color: #00ff00; }}
            .ok {{ color: #00ff00; }}
            .info {{ color: #ffff00; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
            td {{ padding: 6px; border-bottom: 1px solid #333; }}
            td:first-child {{ color: #888; width: 40%; }}
            footer {{ margin-top: 40px; color: #444; font-size: 11px; }}
        </style>
    </head>
    <body>
        <h1>TigerGram Gateway v{telegram.VERSION}</h1>

        <h2>Status</h2>
        <table>
            <tr><td>Connection</td><td class="ok">Connected</td></tr>
            <tr><td>Account</td><td class="value">{name} ({username})</td></tr>
            <tr><td>Uptime</td><td class="value">{uptime}</td></tr>
            <tr><td>Messages received</td><td class="value">{telegram.message_count}</td></tr>
            <tr><td>Pending updates</td><td class="value">{pending}</td></tr>
        </table>

        <h2>API Endpoints</h2>
        <table>
            <tr><td>GET /test</td><td>Connectivity test</td></tr>
            <tr><td>GET /chats</td><td>Chat list (XML)</td></tr>
            <tr><td>GET /messages?chat_id=ID</td><td>Messages (XML)</td></tr>
            <tr><td>GET /send?chat_id=ID&text=TEXT</td><td>Send message</td></tr>
            <tr><td>GET /poll?chat_id=ID</td><td>Long-poll for new messages</td></tr>
            <tr><td>GET /avatar?chat_id=ID</td><td>Profile picture (JPEG)</td></tr>
            <tr><td>GET /media?chat_id=ID&message_id=ID</td><td>Download photo</td></tr>
            <tr><td>GET /bio?chat_id=ID</td><td>Bio/about text (XML)</td></tr>
            <tr><td>GET /members?chat_id=ID</td><td>Member count (XML)</td></tr>
            <tr><td>GET /status</td><td>This page</td></tr>
        </table>

        <h2>Cache</h2>
        <table>
            <tr><td>Avatars</td><td class="value">{len(os.listdir('./avatars')) if os.path.exists('./avatars') else 0} files</td></tr>
            <tr><td>Media cache</td><td class="value">{len(os.listdir('./media_cache')) if os.path.exists('./media_cache') else 0} files</td></tr>
        </table>

        <footer>
            TigerGram v{telegram.VERSION} by {telegram.AUTHOR} (@{telegram.AUTHOR} on Telegram)<br>
            Page auto-refreshes every 30 seconds
        </footer>
    </body>
    </html>
    """
    return HTMLResponse(content=html)

# ─────────────────────────────────────────
# GET /chats
# Returns list of chats as XML
# Includes chat id, name, unread count, type and member count
# ─────────────────────────────────────────
@app.get("/chats")
async def chats():
    result = await telegram.get_chats()
    root = ET.Element("chats")
    for chat in result:
        c = ET.SubElement(root, "chat")
        c.set("id", str(chat["id"]))
        c.set("name", str(chat["name"]))
        c.set("unread", str(chat["unread"]))
        c.set("type", str(chat["type"]))
        c.set("members", str(chat["members"]))
    return xml(root)

# ─────────────────────────────────────────
# GET /messages?chat_id=ID
# Returns last 50 messages as XML
# Includes sender, date, text, media info and reply context
# ─────────────────────────────────────────
@app.get("/messages")
async def messages(chat_id: int):
    result = await telegram.get_messages(chat_id)
    root = ET.Element("messages")
    for msg in reversed(result):
        if msg is None:
            continue
        m = ET.SubElement(root, "message")
        m.set("id", str(msg["id"]))
        m.set("date", str(msg["date"]))
        m.set("sender", msg["sender"])
        if msg["media_type"]:
            m.set("media_type", msg["media_type"])
        if msg["media_file"]:
            m.set("media_file", msg["media_file"])
        if msg["reply_to_text"]:
            m.set("reply_to_text", msg["reply_to_text"])
        if msg["reply_to_sender"]:
            m.set("reply_to_sender", msg["reply_to_sender"])
        if msg["reply_to_id"]:
            m.set("reply_to_id", str(msg["reply_to_id"]))
        ET.SubElement(m, "text").text = msg["text"]
    return xml(root)

# ─────────────────────────────────────────
# GET /send?chat_id=ID&text=TEXT&reply_to_id=ID
# Sends a message to a chat
# reply_to_id is optional - used for reply functionality
# ─────────────────────────────────────────
@app.get("/send")
async def send(chat_id: int, text: str, reply_to_id: int = 0):
    reply = reply_to_id if reply_to_id > 0 else None
    await telegram.send_message(chat_id, text, reply_to_id=reply)
    root = ET.Element("result")
    root.set("ok", "true")
    return xml(root)

# ─────────────────────────────────────────
# GET /poll?chat_id=ID
# Long-polling endpoint - waits up to 30 seconds for new message
# Returns has_new="true" immediately when message arrives
# Returns has_new="false" after 30 second timeout
# ─────────────────────────────────────────
@app.get("/poll")
async def poll(chat_id: int):
    has_new = await telegram.wait_for_new_message(chat_id, timeout=30)
    root = ET.Element("update")
    root.set("has_new", "true" if has_new else "false")
    return xml(root)

# ─────────────────────────────────────────
# GET /avatar?chat_id=ID
# Returns profile picture as JPEG
# Cached on gateway for 24 hours
# Returns 404 if no profile picture available
# ─────────────────────────────────────────
@app.get("/avatar")
async def avatar(chat_id: int):
    path = await telegram.get_avatar(chat_id)
    if path and os.path.exists(path):
        return FileResponse(path, media_type="image/jpeg")
    return Response(status_code=404)

# ─────────────────────────────────────────
# GET /media?chat_id=ID&message_id=ID
# Downloads a photo from a specific message
# Cached on gateway for 7 days
# Only supports photos - stickers/video shown as text in client
# ─────────────────────────────────────────
@app.get("/media")
async def media(chat_id: int, message_id: int):
    path = await telegram.get_media(chat_id, message_id)
    if path and os.path.exists(path):
        return FileResponse(path, media_type="image/jpeg")
    return Response(status_code=404)

# ─────────────────────────────────────────
# GET /bio?chat_id=ID
# Returns bio/about text as XML
# Works for users, groups and channels
# ─────────────────────────────────────────
@app.get("/bio")
async def bio(chat_id: int):
    result = await telegram.get_bio(chat_id)
    root = ET.Element("bio")
    root.set("text", result)
    return xml(root)

# ─────────────────────────────────────────
# GET /members?chat_id=ID
# Returns member count for groups and channels as XML
# Returns 0 for direct messages
# ─────────────────────────────────────────
@app.get("/members")
async def members(chat_id: int):
    count = await telegram.get_member_count(chat_id)
    root = ET.Element("members")
    root.set("count", str(count))
    return xml(root)