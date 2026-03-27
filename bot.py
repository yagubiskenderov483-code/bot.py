import os, re, asyncio, aiohttp
from telethon import TelegramClient, events, Button
from bs4 import BeautifulSoup

# --- ТВОИ ДАННЫЕ (ПОЛНОСТЬЮ ЗАПОЛНЕНО И ПРОВЕРЕНО) ---
API_ID = 27798369
API_HASH = '47e0988636b0d97036a2824368142719'
ADMIN_ID = 174415647
BOT_TOKEN = '8611748903:AAGxBTXL74UfjsO26s5ZT4h6mts2VwCBpU0'
# --------------------------------------------------

# Инициализация бота
bot = TelegramClient('bot_session', API_ID, API_HASH).start(bot_token=BOT_TOKEN)
state = {}

@bot.on(events.NewMessage(pattern='/start'))
async def start(event):
    if event.sender_id == ADMIN_ID:
        await event.respond("⚡️ **Ликвидатор готов к работе.**\n\nПришли номер телефона аккаунта в формате: +79991234567")

@bot.on(events.NewMessage(func=lambda e: e.is_private and e.sender_id == ADMIN_ID))
async def manager(event):
    chat_id = event.chat_id
    text = event.text.strip()

    # Шаг 1: Получение номера телефона
    if text.startswith('+'):
        phone = text
        await event.respond(f"⏳ Подключаюсь к {phone}...")
        
        # Создаем временную сессию для целевого аккаунта
        client = TelegramClient(f"u_{phone.replace('+', '')}", API_ID, API_HASH)
        await client.connect()
        
        try:
            sent = await client.send_code_request(phone)
            state[chat_id] = {
                'client': client, 
                'phone': phone, 
                'hash': sent.phone_code_hash
            }
            await event.respond("📩 **Код входа в Telegram отправлен.**\n\nВведи его цифрами в ответ на это сообщение:")
        except Exception as e:
            await event.respond(f"❌ Ошибка при запросе кода: {e}")

    # Шаг 2: Получение кода подтверждения (цифры)
    elif text.isdigit() and chat_id in state:
        data = state[chat_id]
        client = data['client']
        
        try:
            # Вход в аккаунт через Telethon
            await client.sign_in(data['phone'], text, phone_code_hash=data['hash'])
            await event.respond("✅ **Вход выполнен успешно!**\n\nЗапрашиваю код подтверждения для удаления с сайта my.telegram.org...")

            # Инициируем запрос на удаление через HTTP
            http_session = aiohttp.ClientSession()
            state[chat_id]['http_session'] = http_session

            async with http_session.post('https://my.telegram.org', data={'phone': data['phone']}) as r:
                res = await r.json()
                r_hash = res['random_hash']
                state[chat_id]['r_hash'] = r_hash

            # Слушаем код от сервисного аккаунта 777000 внутри аккаунта
            @client.on(events.NewMessage(from_users=777000))
            async def catch_web_code(web_e):
                if "web login code" in web_e.raw_text.lower():
                    # Извлекаем буквенно-цифровой код для сайта
                    web_code = re.search(r'code:\s*([A-Za-z0-9]+)', web_e.raw_text).group(1)
                    
                    # Авторизация на сайте my.telegram.org
                    await http_session.post('https://my.telegram.org', 
                                            data={'phone': data['phone'], 'random_hash': r_hash, 'password': web_code})
                    
                    # Переходим на страницу удаления для получения финального токена (hash)
                    async with http_session.get('https://my.telegram.org') as p:
                        soup = BeautifulSoup(await p.text(), 'html.parser')
                        f_hash = soup.find('input', {'name': 'hash'})['value']

                    # Генерируем кнопку для окончательного подтверждения
                    btn = [Button.inline("💀 ПОДТВЕРДИТЬ УДАЛЕНИЕ", data=f"kill_{data['phone']}_{f_hash}")]
                    await bot.send_message(ADMIN_ID, f"⚠️ Все готово для удаления {data['phone']}.\n\nНажми кнопку ниже для завершения:", buttons=btn)

        except Exception as e:
            await event.respond(f"❌ Ошибка при входе: {e}")

@bot.on(events.CallbackQuery(pattern=r'kill_'))
async def final_kill(event):
    data_parts = event.data.decode().split('_')
    phone = data_parts[1]
    f_hash = data_parts[2]
    
    # Отправляем финальный запрос на удаление аккаунта
    for sid, data in state.items():
        if data.get('phone') == phone:
            h_session = data.get('http_session')
            if h_session:
                await h_session.post('https://my.telegram.org/do_delete', 
                                    data={'hash': f_hash, 'message': 'Account deletion via API'})
                await h_session.close()
            break
            
    await event.edit(f"🚀 **Аккаунт {phone} успешно ликвидирован!**")

print("Бот успешно запущен и ожидает команд...")
bot.run_until_disconnected()
