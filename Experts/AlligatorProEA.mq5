#property strict
#property version "1.00"
#property description "EA multi-symbol Alligator + WPR + Fractals + ATR + EMA"

#include "..\Include\AlligatorPro\Types.mqh"
#include "..\Include\AlligatorPro\Logger.mqh"
#include "..\Include\AlligatorPro\SignalManager.mqh"
#include "..\Include\AlligatorPro\TradeManager.mqh"
#include "..\Include\AlligatorPro\RiskManager.mqh"
#include "..\Include\AlligatorPro\TrailingManager.mqh"
#include "..\Include\AlligatorPro\EquityProtection.mqh"
#include "..\Include\AlligatorPro\Dashboard.mqh"

input group "Universe"
input string InpSymbols="XAUUSD,BTCUSD";

input group "Trend Filters (H1)"
input int InpAlligatorJaw=13;
input int InpAlligatorTeeth=8;
input int InpAlligatorLips=5;
input int InpEMAPeriod=200;
input int InpATRPeriod=14;
input double InpATRVolatilityMultiplier=1.0;
input double InpDormancyATRFactor=0.20;

input group "Entry (M30)"
input int InpWPRPeriod=14;
input bool InpUseFractalFilter=true;
input int InpFractalRangePoints=250;

input group "Risk"
input double InpRiskPercent=1.0;
input double InpRR=2.0;
input double InpATRSLMultiplier=1.5;
input double InpTrailingATRMultiplier=1.2;
input double InpSoftDD=8.0;
input double InpHardDD=18.0;

input group "Execution"
input long InpMagic=56012026;
input int InpMaxPositions=4;
input int InpDeviationPoints=10;
input int InpMinSecondsBetweenTrades=120;

string g_symbols[];
SignalManager g_signal[];
TradeManager g_trade;
RiskManager g_risk;
TrailingManager g_trailing;
EquityProtection g_equity;
Dashboard g_dashboard;
datetime g_last_trade_time=0;

int OnInit()
  {
   int count=StringSplit(InpSymbols,',',g_symbols);
   if(count<=0)
      return(INIT_PARAMETERS_INCORRECT);

   ArrayResize(g_signal,count);
   for(int i=0;i<count;i++)
     {
      string s=StringTrim(g_symbols[i]);
      g_symbols[i]=s;
      SymbolSelect(s,true);
      if(!g_signal[i].Init(s,InpAlligatorJaw,InpAlligatorTeeth,InpAlligatorLips,InpEMAPeriod,InpATRPeriod,InpWPRPeriod,InpATRVolatilityMultiplier,InpDormancyATRFactor))
         return(INIT_FAILED);
     }

   g_trade.Init(InpMagic,InpDeviationPoints);
   g_risk.Init(InpRiskPercent);
   g_trailing.Init(InpMagic);
   g_equity.Init(InpSoftDD,InpHardDD);
   Logger::Info("EA","Initialization complete");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   for(int i=0;i<ArraySize(g_signal);i++)
      g_signal[i].Release();
   Comment("");
  }

void OnTick()
  {
   g_trailing.Update(InpTrailingATRMultiplier);

   bool trading_ok=g_equity.TradingAllowed();
   double drawdown=g_equity.CurrentDrawdownPct();
   double eq_scaler=g_equity.RiskScaler();
   g_risk.UpdatePerformanceScaler(HistoryDealsTotal(),0);
   double eff_risk=g_risk.EffectiveRiskPct(eq_scaler);

   RuntimeState st;
   st.equity=AccountInfoDouble(ACCOUNT_EQUITY);
   st.balance=AccountInfoDouble(ACCOUNT_BALANCE);
   st.drawdown_pct=drawdown;
   st.risk_pct=eff_risk;
   st.open_positions=g_trade.CountOpenPositions();
   st.trading_enabled=trading_ok;
   g_dashboard.Render(st);

   if(!trading_ok)
      return;
   if(st.open_positions>=InpMaxPositions)
      return;
   if((TimeCurrent()-g_last_trade_time)<InpMinSecondsBetweenTrades)
      return;

   for(int i=0;i<ArraySize(g_symbols);i++)
     {
      string symbol=g_symbols[i];
      if(g_trade.HasOpenPosition(symbol))
         continue;

      StrategySignal signal=g_signal[i].Evaluate(symbol,InpUseFractalFilter,InpATRSLMultiplier,InpRR,InpFractalRangePoints);
      if(!signal.valid)
         continue;

      double entry=(signal.direction==DIR_BUY)?SymbolInfoDouble(symbol,SYMBOL_ASK):SymbolInfoDouble(symbol,SYMBOL_BID);
      double sl_points=MathAbs(entry-signal.stop_loss)/SymbolInfoDouble(symbol,SYMBOL_POINT);
      double lots=g_risk.ComputeLots(symbol,eff_risk,sl_points);
      if(lots<=0.0)
         continue;

      if(g_trade.ExecuteSignal(signal,lots))
        {
         g_last_trade_time=TimeCurrent();
         Logger::Info("TradeManager",StringFormat("Order sent %s lots=%.2f",symbol,lots));
        }
      else
         Logger::Warn("TradeManager",StringFormat("Order rejected %s",symbol));
     }
  }
