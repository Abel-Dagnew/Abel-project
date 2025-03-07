from abc import ABC, abstractmethod
import pandas as pd
import numpy as np

class BaseStrategy(ABC):
    def __init__(self, symbol, timeframe, risk_percentage=1.0):
        self.symbol = symbol
        self.timeframe = timeframe
        self.risk_percentage = risk_percentage
        self.position = None
        self.last_signal = None

    @abstractmethod
    def generate_signals(self, data: pd.DataFrame) -> dict:
        """
        Generate trading signals based on the strategy's logic.
        
        Args:
            data (pd.DataFrame): Historical price data
            
        Returns:
            dict: Dictionary containing signal information
                {
                    'action': 'buy', 'sell', or None,
                    'price': float,
                    'stop_loss': float,
                    'take_profit': float,
                    'reason': str
                }
        """
        pass

    @abstractmethod
    def calculate_position_size(self, account_balance: float, stop_loss: float) -> float:
        """
        Calculate the position size based on risk management rules.
        
        Args:
            account_balance (float): Current account balance
            stop_loss (float): Stop loss price
            
        Returns:
            float: Position size in lots
        """
        pass

    def update_position(self, current_price: float):
        """
        Update the current position status.
        
        Args:
            current_price (float): Current market price
        """
        if self.position:
            if current_price >= self.position['take_profit']:
                self.position = None
                self.last_signal = 'close_tp'
            elif current_price <= self.position['stop_loss']:
                self.position = None
                self.last_signal = 'close_sl'

    def get_position(self) -> dict:
        """
        Get the current position information.
        
        Returns:
            dict: Current position information or None if no position
        """
        return self.position

    def get_last_signal(self) -> str:
        """
        Get the last trading signal.
        
        Returns:
            str: Last signal information
        """
        return self.last_signal 