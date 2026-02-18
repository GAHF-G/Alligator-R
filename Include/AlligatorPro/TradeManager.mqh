#pragma once
#include <Trade/Trade.mqh>
#include "Types.mqh"
#include "Logger.mqh"

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

      bool sent=false;
      if(sig.direction==DIR_BUY)
         sent=m_trade.Buy(lots,sig.symbol,0.0,sig.stop_loss,sig.take_profit,"AlligatorPro BUY");
      else
         sent=m_trade.Sell(lots,sig.symbol,0.0,sig.stop_loss,sig.take_profit,"AlligatorPro SELL");

      if(!sent)
         Logger::Warn("TradeManager",StringFormat("Send failed %s retcode=%d desc=%s",sig.symbol,m_trade.ResultRetcode(),m_trade.ResultRetcodeDescription()));

      return(sent);
     }

   bool ClosePosition(const string symbol)
     {
      if(!PositionSelect(symbol))
         return(false);

      if(PositionGetInteger(POSITION_MAGIC)!=m_magic)
         return(false);

      if(!m_trade.PositionClose(symbol))
        {
         Logger::Warn("TradeManager",StringFormat("Close failed %s retcode=%d desc=%s",symbol,m_trade.ResultRetcode(),m_trade.ResultRetcodeDescription()));
         return(false);
        }

      Logger::Info("TradeManager",StringFormat("Position closed %s",symbol));
      return(true);
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
