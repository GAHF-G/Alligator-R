#pragma once
#include <Trade/Trade.mqh>
#include "Types.mqh"
#include "Logger.mqh"

class TradeManager
  {
private:
   CTrade m_trade;
   long   m_magic;

   bool NormalizeAndValidateStops(const StrategySignal &sig,double &sl,double &tp,string &reason)
     {
      int digits=(int)SymbolInfoInteger(sig.symbol,SYMBOL_DIGITS);
      double point=SymbolInfoDouble(sig.symbol,SYMBOL_POINT);
      int stops_level=(int)SymbolInfoInteger(sig.symbol,SYMBOL_TRADE_STOPS_LEVEL);
      double min_stop_distance=stops_level*point;

      double bid=SymbolInfoDouble(sig.symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(sig.symbol,SYMBOL_ASK);
      if(point<=0 || bid<=0 || ask<=0)
        {
         reason="Invalid symbol quotes";
         return(false);
        }

      sl=NormalizeDouble(sig.stop_loss,digits);
      tp=NormalizeDouble(sig.take_profit,digits);
      if(!MathIsValidNumber(sl) || !MathIsValidNumber(tp) || sl<=0.0 || tp<=0.0 || sl==EMPTY_VALUE || tp==EMPTY_VALUE)
        {
         reason="SL/TP are not finite";
         return(false);
        }

      if(sig.direction==DIR_BUY)
        {
         if(sl>=ask-min_stop_distance)
           {
            reason="BUY SL too close/invalid";
            return(false);
           }
         if(tp<=ask+min_stop_distance)
           {
            reason="BUY TP too close/invalid";
            return(false);
           }
        }
      else if(sig.direction==DIR_SELL)
        {
         if(sl<=bid+min_stop_distance)
           {
            reason="SELL SL too close/invalid";
            return(false);
           }
         if(tp>=bid-min_stop_distance)
           {
            reason="SELL TP too close/invalid";
            return(false);
           }
        }

      return(true);
     }

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

      double sl=0.0,tp=0.0;
      string reason="";
      if(!NormalizeAndValidateStops(sig,sl,tp,reason))
        {
         Logger::Warn("TradeManager",StringFormat("%s (%s)",reason,sig.symbol));
         return(false);
        }

      bool sent=false;
      if(sig.direction==DIR_BUY)
         sent=m_trade.Buy(lots,sig.symbol,0.0,sl,tp,"AlligatorPro BUY");
      else
         sent=m_trade.Sell(lots,sig.symbol,0.0,sl,tp,"AlligatorPro SELL");

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
