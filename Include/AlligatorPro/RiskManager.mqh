#pragma once

class RiskManager
  {
private:
   double m_base_risk_pct;
   double m_perf_multiplier;

   int VolumeDigits(const double step)
     {
      int digits=0;
      double s=step;
      while(digits<8 && MathAbs(s-MathRound(s))>1e-8)
        {
         s*=10.0;
         digits++;
        }
      return(digits);
     }

public:
   void Init(const double risk_pct)
     {
      m_base_risk_pct=risk_pct;
      m_perf_multiplier=1.0;
     }

   void UpdatePerformanceScaler(const int wins,const int losses)
     {
      int trades=wins+losses;
      if(trades<10)
        {
         m_perf_multiplier=1.0;
         return;
        }
      double wr=(double)wins/(double)trades;
      m_perf_multiplier=MathMin(1.5,MathMax(0.7,0.8+wr));
     }

   double EffectiveRiskPct(const double equity_scaler)
     {
      return(m_base_risk_pct*m_perf_multiplier*equity_scaler);
     }

   double ComputeLots(const string symbol,const double risk_pct,const double sl_points)
     {
      if(sl_points<=0)
         return(0.0);

      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amount=balance*(risk_pct/100.0);
      double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
      double tick_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double lot_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      double min_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double max_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      if(tick_value<=0 || tick_size<=0 || point<=0 || lot_step<=0)
         return(0.0);

      double sl_value_per_lot=(sl_points*tick_value)/(tick_size/point);
      if(sl_value_per_lot<=0)
         return(0.0);

      double lots=risk_amount/sl_value_per_lot;
      lots=MathFloor(lots/lot_step)*lot_step;
      lots=MathMax(min_lot,MathMin(max_lot,lots));

      return(NormalizeDouble(lots,VolumeDigits(lot_step)));
     }
  };
