#pragma once

enum TradeDirection
  {
   DIR_NONE = 0,
   DIR_BUY,
   DIR_SELL
  };

struct StrategySignal
  {
   string         symbol;
   TradeDirection direction;
   double         stop_loss;
   double         take_profit;
   bool           valid;
   string         reason;
  };

struct RuntimeState
  {
   double equity;
   double balance;
   double drawdown_pct;
   double risk_pct;
   int    open_positions;
   bool   trading_enabled;
  };
