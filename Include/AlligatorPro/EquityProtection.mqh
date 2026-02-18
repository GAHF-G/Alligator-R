#pragma once

class EquityProtection
  {
private:
   double m_peak_equity;
   double m_soft_dd;
   double m_hard_dd;
public:
   void Init(const double soft_dd,const double hard_dd)
     {
      m_peak_equity=AccountInfoDouble(ACCOUNT_EQUITY);
      m_soft_dd=soft_dd;
      m_hard_dd=hard_dd;
     }

   double CurrentDrawdownPct()
     {
      double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity>m_peak_equity)
         m_peak_equity=equity;
      if(m_peak_equity<=0.0)
         return(0.0);
      return((m_peak_equity-equity)/m_peak_equity*100.0);
     }

   bool TradingAllowed()
     {
      return(CurrentDrawdownPct()<m_hard_dd);
     }

   double RiskScaler()
     {
      double dd=CurrentDrawdownPct();
      if(dd>=m_hard_dd)
         return(0.0);
      if(dd<=m_soft_dd)
         return(1.0);
      double zone=m_hard_dd-m_soft_dd;
      if(zone<=0.0)
         return(1.0);
      return(MathMax(0.2,1.0-(dd-m_soft_dd)/zone));
     }
  };
