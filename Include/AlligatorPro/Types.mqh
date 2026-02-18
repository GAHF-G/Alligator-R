#pragma once

enum TradeDirection
  {
   DIR_NONE = 0,
   DIR_BUY,
   DIR_SELL
  };

enum ExitMode
  {
   EXIT_SIMPLE = 0,
   EXIT_SCORE  = 1,
   EXIT_STRICT = 2
  };

enum BlockReason
  {
   BLOCK_NONE = 0,
   BLOCK_SPREAD,
   BLOCK_VOLATILITY,
   BLOCK_ALIGNMENT,
   BLOCK_WPR,
   BLOCK_DD,
   BLOCK_SESSION,
   BLOCK_MARGIN,
   BLOCK_FRACTAL,
   BLOCK_SIGNAL_MISC
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
