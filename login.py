from telethon.sync import TelegramClient

API_ID = 0 		# Get your api_id from https://my.telegram.org
API_HASH = "0"		# Get your api_hash from https://my.telegram.org

client = TelegramClient("session", API_ID, API_HASH)
client.start()

print("\n✅ Login erfolgreich!")
print("Teste Verbindung...")

me = client.get_me()
print(f"Eingeloggt als: {me.first_name} (@{me.username})")

client.disconnect()
