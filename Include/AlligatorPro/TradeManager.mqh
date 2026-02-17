#pragma once
#include <Trade/Trade.mqh>
#include "Types.mqh"

class TradeManager
  {
private:
   CTrade m_trade;
   long   m_magic;
public:
   void Init(const long magic,const int deviation)
     {
      m_magic=magic;
      m_trade.SetExpertMagicNumber(magic);
      m_trade.SetDeviationInPoints(deviation);
     }

   bool HasOpenPosition(const string symbol)
     {
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket))
            continue;
         if(PositionGetInteger(POSITION_MAGIC)==m_magic && PositionGetString(POSITION_SYMBOL)==symbol)
            return(true);
        }
      return(false);
     }

   bool ExecuteSignal(const StrategySignal &sig,const double lots)
     {
      if(!sig.valid || sig.direction==DIR_NONE || lots<=0)
         return(false);
      if(sig.direction==DIR_BUY)
         return(m_trade.Buy(lots,sig.symbol,0.0,sig.stop_loss,sig.take_profit,"AlligatorPro BUY"));
      return(m_trade.Sell(lots,sig.symbol,0.0,sig.stop_loss,sig.take_profit,"AlligatorPro SELL"));
     }

   int CountOpenPositions()
     {
      int c=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket))
            continue;
         if(PositionGetInteger(POSITION_MAGIC)==m_magic)
            c++;
        }
      return(c);
     }
  };
