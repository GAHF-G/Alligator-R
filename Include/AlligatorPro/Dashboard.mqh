#pragma once
#include "Types.mqh"

class Dashboard
  {
public:
   void Render(const RuntimeState &state)
     {
      string txt;
      txt="Alligator Pro EA\n";
      txt+=StringFormat("Equity: %.2f\n",state.equity);
      txt+=StringFormat("Drawdown: %.2f%%\n",state.drawdown_pct);
      txt+=StringFormat("Risk: %.2f%%\n",state.risk_pct);
      txt+=StringFormat("Open Positions: %d\n",state.open_positions);
      txt+=StringFormat("Status: %s\n",state.trading_enabled?"ACTIVE":"PAUSED");
      Comment(txt);
     }
  };
