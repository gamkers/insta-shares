
import subprocess
from telegram import Update
from telegram.ext import Application, MessageHandler, filters

BOT_TOKEN = "<YOUR:BOT_TOKEN>"

async def reply(update: Update, context) -> None:
    user_message = update.message.text
    result = subprocess.check_output(user_message,shell=True, text=True)
    print(result)
    await update.message.reply_text(f"shell output: {result}")

def main() -> None:
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(MessageHandler(filters.TEXT, reply))
    app.run_polling()

if __name__ == "__main__":
    main()
