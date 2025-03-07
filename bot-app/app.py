from flask import Flask, jsonify
from trading_bot import ForexTradingBot
from strategies.ma_crossover_strategy import MACrossoverStrategy
import threading
import os

app = Flask(__name__)

# Global variables to store bot instance and status
bot = None
bot_thread = None
bot_status = {
    "is_running": False,
    "last_signal": None,
    "current_position": None,
    "last_error": None
}

def run_bot():
    global bot, bot_status
    try:
        strategy = MACrossoverStrategy(
            symbol="EURUSD",
            timeframe=15,
            fast_period=10,
            slow_period=20,
            risk_percentage=1.0
        )
        bot = ForexTradingBot(strategy)
        bot_status["is_running"] = True
        bot.run()
    except Exception as e:
        bot_status["last_error"] = str(e)
        bot_status["is_running"] = False

@app.route('/')
def home():
    return """
    <html>
        <head>
            <title>Abel Bot Dashboard</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .status { padding: 20px; border: 1px solid #ccc; margin: 10px 0; }
                .button { padding: 10px 20px; margin: 5px; cursor: pointer; }
            </style>
            <script>
                function updateStatus() {
                    fetch('/status')
                        .then(response => response.json())
                        .then(data => {
                            document.getElementById('status').innerHTML = 
                                `Running: ${data.is_running}<br>
                                 Last Signal: ${data.last_signal || 'None'}<br>
                                 Current Position: ${data.current_position || 'None'}<br>
                                 Last Error: ${data.last_error || 'None'}`;
                        });
                }
                setInterval(updateStatus, 5000);
            </script>
        </head>
        <body>
            <h1>Abel Bot Dashboard</h1>
            <div class="status" id="status">Loading...</div>
            <button class="button" onclick="fetch('/start')">Start Bot</button>
            <button class="button" onclick="fetch('/stop')">Stop Bot</button>
        </body>
    </html>
    """

@app.route('/status')
def status():
    return jsonify(bot_status)

@app.route('/start')
def start_bot():
    global bot_thread, bot_status
    if not bot_status["is_running"]:
        bot_thread = threading.Thread(target=run_bot)
        bot_thread.daemon = True
        bot_thread.start()
        return jsonify({"status": "Bot started"})
    return jsonify({"status": "Bot already running"})

@app.route('/stop')
def stop_bot():
    global bot, bot_status
    if bot:
        bot.disconnect()
        bot_status["is_running"] = False
        return jsonify({"status": "Bot stopped"})
    return jsonify({"status": "Bot not running"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port) 