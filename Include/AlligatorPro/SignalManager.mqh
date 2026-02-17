#pragma once
#include "Types.mqh"
#include "Logger.mqh"

class SignalManager
  {
private:
   int m_alligator;
   int m_ema;
   int m_atr;
   int m_wpr;
   int m_fractals;

   int m_jaw_period;
   int m_teeth_period;
   int m_lips_period;
   int m_ema_period;
   int m_atr_period;
   int m_wpr_period;
   double m_atr_volatility_multiplier;
   double m_dormancy_atr_factor;

public:
   bool Init(const string symbol,
             const int jaw_period,const int teeth_period,const int lips_period,
             const int ema_period,const int atr_period,const int wpr_period,
             const double atr_vol_multiplier,const double dormancy_atr_factor)
     {
      m_jaw_period=jaw_period;
      m_teeth_period=teeth_period;
      m_lips_period=lips_period;
      m_ema_period=ema_period;
      m_atr_period=atr_period;
      m_wpr_period=wpr_period;
      m_atr_volatility_multiplier=atr_vol_multiplier;
      m_dormancy_atr_factor=dormancy_atr_factor;

      m_alligator=iAlligator(symbol,PERIOD_H1,m_jaw_period,8,m_teeth_period,5,m_lips_period,3,MODE_SMMA,PRICE_MEDIAN);
      m_ema=iMA(symbol,PERIOD_H1,m_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_atr=iATR(symbol,PERIOD_H1,m_atr_period);
      m_wpr=iWPR(symbol,PERIOD_M30,m_wpr_period);
      m_fractals=iFractals(symbol,PERIOD_M30);
      bool ok=(m_alligator!=INVALID_HANDLE && m_ema!=INVALID_HANDLE && m_atr!=INVALID_HANDLE && m_wpr!=INVALID_HANDLE && m_fractals!=INVALID_HANDLE);
      if(!ok)
         Logger::Error("SignalManager","Indicator init failed");
      return(ok);
     }

   StrategySignal Evaluate(const string symbol,const bool use_fractal_filter,const double atr_sl_mult,const double rr_ratio,const int lookback_fractals)
     {
      StrategySignal sig;
      sig.symbol=symbol;
      sig.direction=DIR_NONE;
      sig.stop_loss=0;
      sig.take_profit=0;
      sig.valid=false;
      sig.reason="No setup";

      double jaw[3],teeth[3],lips[3],ema[3],atr[30],wpr[3];
      if(CopyBuffer(m_alligator,0,1,3,jaw)<3 ||
         CopyBuffer(m_alligator,1,1,3,teeth)<3 ||
         CopyBuffer(m_alligator,2,1,3,lips)<3 ||
         CopyBuffer(m_ema,0,1,3,ema)<3 ||
         CopyBuffer(m_atr,0,1,30,atr)<30 ||
         CopyBuffer(m_wpr,0,1,3,wpr)<3)
        {
         sig.reason="Not enough data";
         return(sig);
        }

      MqlRates r_h1[3],r_m30[3];
      if(CopyRates(symbol,PERIOD_H1,1,3,r_h1)<3 || CopyRates(symbol,PERIOD_M30,1,3,r_m30)<3)
        {
         sig.reason="Rates unavailable";
         return(sig);
        }

      double atr_avg=0.0;
      for(int i=0;i<30;i++) atr_avg+=atr[i];
      atr_avg/=30.0;

      bool trend_buy=(lips[0]>teeth[0] && teeth[0]>jaw[0] && r_h1[0].close>ema[0]);
      bool trend_sell=(lips[0]<teeth[0] && teeth[0]<jaw[0] && r_h1[0].close<ema[0]);
      bool volatility_ok=(atr[0]>(atr_avg*m_atr_volatility_multiplier));
      bool dormant=(MathAbs(lips[0]-teeth[0])<atr[0]*m_dormancy_atr_factor && MathAbs(teeth[0]-jaw[0])<atr[0]*m_dormancy_atr_factor);

      bool wpr_buy=(wpr[1]<-85.0 && wpr[0]>-80.0);
      bool wpr_sell=(wpr[1]>-15.0 && wpr[0]<-20.0);

      if(!volatility_ok || dormant)
        {
         sig.reason="Volatility/dormancy filter";
         return(sig);
        }

      sig.direction=DIR_NONE;
      if(trend_buy && wpr_buy) sig.direction=DIR_BUY;
      if(trend_sell && wpr_sell) sig.direction=DIR_SELL;
      if(sig.direction==DIR_NONE)
         return(sig);

      double fract_up[200],fract_dn[200];
      if(CopyBuffer(m_fractals,0,1,200,fract_up)<200 || CopyBuffer(m_fractals,1,1,200,fract_dn)<200)
        {
         sig.reason="Fractal data unavailable";
         return(sig);
        }

      double last_up=0,last_dn=0;
      for(int i=0;i<200;i++)
        {
         if(last_up==0 && fract_up[i]!=0.0) last_up=fract_up[i];
         if(last_dn==0 && fract_dn[i]!=0.0) last_dn=fract_dn[i];
         if(last_up>0 && last_dn>0) break;
        }

      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double current=r_m30[0].close;
      if(use_fractal_filter)
        {
         bool breakout=(sig.direction==DIR_BUY && current>last_up) || (sig.direction==DIR_SELL && current<last_dn);
         if(!breakout)
           {
            sig.reason="No fractal breakout";
            sig.direction=DIR_NONE;
            return(sig);
           }
         if(last_up>0 && last_dn>0 && MathAbs(last_up-last_dn)<lookback_fractals*point)
           {
            sig.reason="Fractals too close (range)";
            sig.direction=DIR_NONE;
            return(sig);
           }
      }

      double sl=(sig.direction==DIR_BUY)?(last_dn>0?last_dn:(current-atr[0]*atr_sl_mult)):(last_up>0?last_up:(current+atr[0]*atr_sl_mult));
      double risk=MathAbs(current-sl);
      double tp=(sig.direction==DIR_BUY)?current+risk*rr_ratio:current-risk*rr_ratio;

      sig.stop_loss=sl;
      sig.take_profit=tp;
      sig.valid=true;
      sig.reason="Signal validated";
      return(sig);
     }

   void Release()
     {
      if(m_alligator!=INVALID_HANDLE) IndicatorRelease(m_alligator);
      if(m_ema!=INVALID_HANDLE) IndicatorRelease(m_ema);
      if(m_atr!=INVALID_HANDLE) IndicatorRelease(m_atr);
      if(m_wpr!=INVALID_HANDLE) IndicatorRelease(m_wpr);
      if(m_fractals!=INVALID_HANDLE) IndicatorRelease(m_fractals);
     }
  };
