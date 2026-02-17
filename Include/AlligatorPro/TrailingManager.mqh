#pragma once
#include <Trade/Trade.mqh>

class TrailingManager
  {
private:
   CTrade m_trade;
   long   m_magic;
public:
   void Init(const long magic)
     {
      m_magic=magic;
      m_trade.SetExpertMagicNumber(magic);
     }

   void Update(const double atr_mult)
     {
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket))
            continue;
         if(PositionGetInteger(POSITION_MAGIC)!=m_magic)
            continue;

         string symbol=PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
         double sl=PositionGetDouble(POSITION_SL);
         double tp=PositionGetDouble(POSITION_TP);

         int h=iATR(symbol,PERIOD_M30,14);
         if(h==INVALID_HANDLE)
            continue;
         double atr[1];
         if(CopyBuffer(h,0,1,1,atr)<1)
           {
            IndicatorRelease(h);
            continue;
           }
         IndicatorRelease(h);

         double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
         double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
         double new_sl=sl;

         if(type==POSITION_TYPE_BUY)
           {
            double candidate=bid-atr[0]*atr_mult;
            if(candidate>sl && candidate>open_price)
               new_sl=candidate;
           }
         else if(type==POSITION_TYPE_SELL)
           {
            double candidate=ask+atr[0]*atr_mult;
            if((sl==0.0 || candidate<sl) && candidate<open_price)
               new_sl=candidate;
           }

         if(new_sl!=sl)
            m_trade.PositionModify(symbol,new_sl,tp);
        }
     }
  };
