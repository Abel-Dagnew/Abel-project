FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    wine \
    && rm -rf /var/lib/apt/lists/*

# Install MetaTrader 5
RUN wget -qO - https://www.mql5.com/en/trading-platform/start | grep -o 'https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe' | xargs wget -O mt5setup.exe
RUN wine mt5setup.exe /auto

# Set working directory
WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create a non-root user
RUN useradd -m -r -s /bin/bash tradingbot
USER tradingbot

# Expose port for Azure Web App
EXPOSE 8000

# Run the bot with gunicorn
CMD ["python", "run_bot.py"] 