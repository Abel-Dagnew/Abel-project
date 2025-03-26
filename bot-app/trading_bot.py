import MetaTrader5 as mt5
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import time
from dotenv import load_dotenv
import os
from strategies.base_strategy import BaseStrategy
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

class ForexTradingBot:
    def __init__(self, strategy: BaseStrategy):
        """
        Initialize the trading bot.
        
        Args:
            strategy (BaseStrategy): Trading strategy to use
        """
        self.strategy = strategy
        self.connected = False
        self.load_credentials()

    def load_credentials(self):
        """Load MT5 credentials from Azure Key Vault or .env file."""
        try:
            # Try to load from Azure Key Vault first
            key_vault_url = os.getenv('KEY_VAULT_URL')
            if key_vault_url:
                credential = DefaultAzureCredential()
                secret_client = SecretClient(vault_url=key_vault_url, credential=credential)
                
                self.login = int(secret_client.get_secret("MT5-LOGIN").value)
                self.password = secret_client.get_secret("MT5-PASSWORD").value
                self.server = secret_client.get_secret("MT5-SERVER").value
            else:
                # Fallback to .env file
                load_dotenv()
                self.login = int(os.getenv('MT5_LOGIN'))
                self.password = os.getenv('MT5_PASSWORD')
                self.server = os.getenv('MT5_SERVER')
        except Exception as e:
            print(f"Error loading credentials: {e}")
            raise

    def connect(self) -> bool:
        """
        Connect to MetaTrader5 terminal.
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        if not mt5.initialize():
            print(f"Failed to initialize MT5: {mt5.last_error()}")
            return False

        if not mt5.login(self.login, password=self.password, server=self.server):
            print(f"Failed to login: {mt5.last_error()}")
            mt5.shutdown()
            return False

        self.connected = True
        return True

    def disconnect(self):
        """Disconnect from MetaTrader5 terminal."""
        if self.connected:
            mt5.shutdown()
            self.connected = False

    def get_historical_data(self, symbol: str, timeframe: int, bars: int = 100) -> pd.DataFrame:
        """
        Get historical price data from MT5.
        
        Args:
            symbol (str): Trading symbol
            timeframe (int): Timeframe in minutes
            bars (int): Number of bars to retrieve
            
        Returns:
            pd.DataFrame: Historical price data
        """
        if not self.connected:
            return None

        # Convert timeframe to MT5 timeframe
        tf_map = {
            1: mt5.TIMEFRAME_M1,
            5: mt5.TIMEFRAME_M5,
            15: mt5.TIMEFRAME_M15,
            30: mt5.TIMEFRAME_M30,
            60: mt5.TIMEFRAME_H1,
            240: mt5.TIMEFRAME_H4,
            1440: mt5.TIMEFRAME_D1
        }
        
        mt5_timeframe = tf_map.get(timeframe, mt5.TIMEFRAME_M1)
        
        # Get historical data
        rates = mt5.copy_rates_from_pos(symbol, mt5_timeframe, 0, bars)
        
        if rates is None:
            print(f"Failed to get historical data: {mt5.last_error()}")
            return None
            
        # Convert to DataFrame
        df = pd.DataFrame(rates)
        df['time'] = pd.to_datetime(df['time'], unit='s')
        return df

    def execute_trade(self, signal: dict):
        """
        Execute a trade based on the signal.
        
        Args:
            signal (dict): Trading signal information
        """
        if not self.connected or not signal['action']:
            return

        # Get current account balance
        account_info = mt5.account_info()
        if account_info is None:
            print(f"Failed to get account info: {mt5.last_error()}")
            return

        # Calculate position size
        position_size = self.strategy.calculate_position_size(
            account_info.balance,
            signal['stop_loss']
        )

        # Prepare order request
        request = {
            "action": mt5.TRADE_ACTION_DEAL,
            "symbol": self.strategy.symbol,
            "volume": position_size,
            "type": mt5.ORDER_TYPE_BUY if signal['action'] == 'buy' else mt5.ORDER_TYPE_SELL,
            "price": signal['price'],
            "sl": signal['stop_loss'],
            "tp": signal['take_profit'],
            "deviation": 20,
            "magic": 234000,
            "comment": signal['reason'],
            "type_time": mt5.ORDER_TIME_GTC,
            "type_filling": mt5.ORDER_FILLING_IOC,
        }

        # Send order
        result = mt5.order_send(request)
        if result.retcode != mt5.TRADE_RETCODE_DONE:
            print(f"Order failed: {result.comment}")
            return

        # Update strategy position
        self.strategy.position = {
            'ticket': result.order,
            'type': signal['action'],
            'price': signal['price'],
            'stop_loss': signal['stop_loss'],
            'take_profit': signal['take_profit']
        }

    def run(self):
        """Main trading loop."""
        if not self.connect():
            return

        try:
            while True:
                # Get historical data
                data = self.get_historical_data(
                    self.strategy.symbol,
                    self.strategy.timeframe
                )
                
                if data is None:
                    print("Failed to get historical data, retrying in 60 seconds...")
                    time.sleep(60)
                    continue

                # Generate signals
                signal = self.strategy.generate_signals(data)
                
                # Update current position
                if self.strategy.position:
                    current_price = data.iloc[-1]['close']
                    self.strategy.update_position(current_price)
                
                # Execute trade if we have a signal and no current position
                if signal['action'] and not self.strategy.position:
                    self.execute_trade(signal)
                
                # Wait for next iteration
                time.sleep(60)  # Check every minute
                
        except KeyboardInterrupt:
            print("Stopping trading bot...")
        finally:
            self.disconnect() 