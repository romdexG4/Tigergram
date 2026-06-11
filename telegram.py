# TigerGram Gateway - telegram.py
# Version 1.0 by romdex (@romdex on Telegram)
# Handles all Telegram API communication via Telethon

from telethon import TelegramClient, events
from telethon.tl.types import User, Chat, Channel
from telethon.tl.types import MessageMediaPhoto, MessageMediaDocument
from telethon.tl.types import DocumentAttributeSticker, DocumentAttributeVideo
from telethon.tl.types import DocumentAttributeAudio, DocumentAttributeAnimated
import telethon.tl.functions.users as user_functions
import telethon.tl.functions.channels as channel_functions
import telethon.tl.functions.messages as message_functions
import asyncio, os, time

# ─────────────────────────────────────────
# Configuration
# Get your api_id and api_hash from https://my.telegram.org
# ─────────────────────────────────────────
API_ID = 0
API_HASH = "0"
VERSION = "1.0"
AUTHOR = "romdex"

# ─────────────────────────────────────────
# Telethon client setup
# Creates a persistent session file called "session.session"
# ─────────────────────────────────────────
client = TelegramClient("session", API_ID, API_HASH)

# Stores incoming new messages per chat_id for long-polling
new_messages = {}

# Gateway start time - used for uptime calculation
start_time = time.time()

# Counts total messages received since gateway start
message_count = 0

# ─────────────────────────────────────────
# Event handler - fires when a new message arrives
# Stores it in new_messages dict so /poll can detect it
# ─────────────────────────────────────────
@client.on(events.NewMessage)
async def on_new_message(event):
    global message_count
    chat_id = event.chat_id
    if chat_id not in new_messages:
        new_messages[chat_id] = []
    new_messages[chat_id].append(event.message)
    message_count += 1

# ─────────────────────────────────────────
# Get chat list
# Returns up to 50 most recent dialogs with type and unread count
# Unread count is capped at 50+ to avoid bot-like behavior
# ─────────────────────────────────────────
async def get_chats(limit=50):
    await client.connect()
    dialogs = await client.get_dialogs(limit=limit)
    chats = []
    for d in dialogs:
        # Determine chat type: direct message, group or broadcast channel
        if isinstance(d.entity, User):
            chat_type = "user"
            member_count = None
        elif isinstance(d.entity, Channel) and d.entity.broadcast:
            chat_type = "channel"
            member_count = d.entity.participants_count if hasattr(d.entity, 'participants_count') else None
        else:
            chat_type = "group"
            member_count = d.entity.participants_count if hasattr(d.entity, 'participants_count') else None

        # Cap unread at 50+ to keep display clean
        unread = d.unread_count
        unread_str = "50+" if unread > 50 else str(unread)

        chats.append({
            "id": d.id,
            "name": d.name,
            "unread": unread_str,
            "type": chat_type,
            "members": str(member_count) if member_count else ""
        })
    return chats

# ─────────────────────────────────────────
# Get messages for a specific chat
# Returns last 50 messages with sender, date, text and media info
# Also fetches reply-to context if message is a reply
# ─────────────────────────────────────────
async def get_messages(chat_id, limit=50):
    await client.connect()
    me = await client.get_me()
    messages = []
    async for msg in client.iter_messages(chat_id, limit=limit):
        # Determine sender name
        if msg.sender_id == me.id:
            sender = "Me"
        elif msg.sender:
            first = msg.sender.first_name or ""
            last = msg.sender.last_name or ""
            sender = (first + " " + last).strip() or "Unknown"
        else:
            sender = "Unknown"

        # Detect media type: photo, sticker, video, voice, gif or file
        media_type = None
        media_file = None
        if msg.media:
            if isinstance(msg.media, MessageMediaPhoto):
                media_type = "photo"
                media_file = f"photo_{msg.id}.jpg"
            elif isinstance(msg.media, MessageMediaDocument):
                doc = msg.media.document
                is_sticker = any(isinstance(a, DocumentAttributeSticker) for a in doc.attributes)
                is_video = any(isinstance(a, DocumentAttributeVideo) for a in doc.attributes)
                is_audio = any(isinstance(a, DocumentAttributeAudio) for a in doc.attributes)
                is_animated = any(isinstance(a, DocumentAttributeAnimated) for a in doc.attributes)
                if is_sticker:
                    media_type = "sticker"
                    media_file = f"sticker_{msg.id}.webp"
                elif is_video:
                    media_type = "video"
                elif is_audio:
                    media_type = "voice"
                elif is_animated:
                    media_type = "gif"
                else:
                    media_type = "file"

        # Fetch reply-to message context if this is a reply
        reply_to_text = None
        reply_to_sender = None
        reply_to_id = None
        if msg.reply_to_msg_id:
            try:
                reply_msg = await client.get_messages(chat_id, ids=msg.reply_to_msg_id)
                if reply_msg:
                    reply_to_id = msg.reply_to_msg_id
                    reply_to_text = reply_msg.text or "[media]"
                    if reply_msg.sender:
                        reply_to_sender = reply_msg.sender.first_name or "Unknown"
                    else:
                        reply_to_sender = "Unknown"
            except:
                pass

        messages.append({
            "id": msg.id,
            "date": int(msg.date.timestamp()),
            "text": msg.text or "",
            "sender": sender,
            "media_type": media_type,
            "media_file": media_file,
            "reply_to_text": reply_to_text,
            "reply_to_sender": reply_to_sender,
            "reply_to_id": reply_to_id
        })
    return messages

# ─────────────────────────────────────────
# Get bio/about text for a user or channel
# Returns empty string if not available
# ─────────────────────────────────────────
async def get_bio(chat_id):
    await client.connect()
    try:
        entity = await client.get_entity(chat_id)
        if isinstance(entity, User):
            full = await client(user_functions.GetFullUserRequest(entity))
            return full.full_user.about or ""
        else:
            full = await client(channel_functions.GetFullChannelRequest(entity))
            return full.full_chat.about or ""
    except:
        return ""

# ─────────────────────────────────────────
# Get member count for groups and channels
# Returns 0 for direct messages or if unavailable
# ─────────────────────────────────────────
async def get_member_count(chat_id):
    await client.connect()
    try:
        entity = await client.get_entity(chat_id)
        if isinstance(entity, Channel):
            full = await client(channel_functions.GetFullChannelRequest(entity))
            return full.full_chat.participants_count or 0
        elif isinstance(entity, Chat):
            full = await client(message_functions.GetFullChatRequest(chat_id))
            return full.full_chat.participants_count or 0
    except:
        pass
    return 0

# ─────────────────────────────────────────
# Get profile picture for a chat
# Cached locally for 24 hours to avoid unnecessary API calls
# ─────────────────────────────────────────
async def get_avatar(chat_id):
    await client.connect()
    os.makedirs("./avatars", exist_ok=True)
    path = f"./avatars/{chat_id}.jpg"

    # Return cached version if younger than 24 hours
    if os.path.exists(path):
        age = time.time() - os.path.getmtime(path)
        if age < 24 * 3600:
            return path
    try:
        entity = await client.get_entity(chat_id)
        downloaded = await client.download_profile_photo(entity,
            file=path, download_big=False)
        if downloaded:
            return path
    except:
        pass
    return None

# ─────────────────────────────────────────
# Download media for a specific message
# Only supports photos - stickers/video/voice are shown as text only
# Old media files are deleted after 7 days to save disk space
# ─────────────────────────────────────────
async def get_media(chat_id, message_id):
    await client.connect()
    os.makedirs("./media_cache", exist_ok=True)

    # Clean up media files older than 7 days
    for f in os.listdir("./media_cache"):
        fpath = os.path.join("./media_cache", f)
        if time.time() - os.path.getmtime(fpath) > 7 * 24 * 3600:
            os.remove(fpath)

    # Return cached file if already downloaded
    for f in os.listdir("./media_cache"):
        if f.startswith(f"photo_{message_id}"):
            return os.path.join("./media_cache", f)

    # Download from Telegram
    try:
        msg = await client.get_messages(chat_id, ids=message_id)
        if msg and msg.media:
            if isinstance(msg.media, MessageMediaPhoto):
                path = f"./media_cache/photo_{message_id}.jpg"
                downloaded = await client.download_media(msg, file=path)
                if downloaded:
                    return downloaded
    except:
        pass
    return None

# ─────────────────────────────────────────
# Send a message to a chat
# Supports reply_to_id for replying to specific messages
# ─────────────────────────────────────────
async def send_message(chat_id, text, reply_to_id=None):
    await client.connect()
    await client.send_message(chat_id, text, reply_to=reply_to_id)

# ─────────────────────────────────────────
# Long-polling for new messages
# Waits up to 30 seconds for a new message in a specific chat
# Returns True if new message arrived, False on timeout
# ─────────────────────────────────────────
async def wait_for_new_message(chat_id, timeout=30):
    deadline = asyncio.get_event_loop().time() + timeout
    while asyncio.get_event_loop().time() < deadline:
        if chat_id in new_messages and len(new_messages[chat_id]) > 0:
            new_messages[chat_id] = []
            return True
        await asyncio.sleep(0.5)
    return False

# ─────────────────────────────────────────
# Calculate gateway uptime for status page
# ─────────────────────────────────────────
def get_uptime():
    seconds = int(time.time() - start_time)
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours}h {minutes}m {secs}s"