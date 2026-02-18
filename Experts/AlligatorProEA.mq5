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
#include "..\Include\AlligatorPro\ExitEngine.mqh"

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


input group "Exit Engine"
input bool InpUseContractionExit=true;
input bool InpUseAlignmentExit=true;
input bool InpUseWPRExit=true;
input bool InpUseATRExit=false;
input int InpExitScoreThreshold=2;
input ExitMode InpExitMode=EXIT_SCORE;
input int InpExitTimerSeconds=5;

input group "Execution"
input long InpMagic=56012026;
input int InpMaxPositions=4;
input int InpDeviationPoints=10;
input int InpMinSecondsBetweenTrades=120;
input int InpMaxSpreadPoints=0; // 0=disabled

input group "Diagnostics"
input bool InpDebugMode=false;

string g_symbols[];
SignalManager g_signal[];
TradeManager g_trade;
RiskManager g_risk;
TrailingManager g_trailing;
EquityProtection g_equity;
Dashboard g_dashboard;
CExitEngine g_exit;
datetime g_last_trade_time=0;
long g_signal_checks=0;
long g_signal_valid=0;
long g_block_counts[10];
datetime g_last_perf_update=0;
int g_perf_wins=0;
int g_perf_losses=0;

string BlockReasonToString(const BlockReason reason)
  {
   switch(reason)
     {
      case BLOCK_SPREAD: return("BLOCK_SPREAD");
      case BLOCK_VOLATILITY: return("BLOCK_VOLATILITY");
      case BLOCK_ALIGNMENT: return("BLOCK_ALIGNMENT");
      case BLOCK_WPR: return("BLOCK_WPR");
      case BLOCK_DD: return("BLOCK_DD");
      case BLOCK_SESSION: return("BLOCK_SESSION");
      case BLOCK_MARGIN: return("BLOCK_MARGIN");
      case BLOCK_FRACTAL: return("BLOCK_FRACTAL");
      case BLOCK_SIGNAL_MISC: return("BLOCK_SIGNAL_MISC");
      default: return("BLOCK_NONE");
     }
  }

BlockReason DetectBlockReason(const string reason)
  {
   if(StringFind(reason,"Volatility",0)>=0 || StringFind(reason,"dormancy",0)>=0)
      return(BLOCK_VOLATILITY);
   if(StringFind(reason,"fractal",0)>=0 || StringFind(reason,"Fractal",0)>=0)
      return(BLOCK_FRACTAL);
   if(StringFind(reason,"WPR",0)>=0)
      return(BLOCK_WPR);
   if(StringFind(reason,"align",0)>=0)
      return(BLOCK_ALIGNMENT);
   if(StringFind(reason,"margin",0)>=0)
      return(BLOCK_MARGIN);
   if(StringFind(reason,"drawdown",0)>=0 || StringFind(reason,"Trading disabled",0)>=0)
      return(BLOCK_DD);
   return(BLOCK_SIGNAL_MISC);
  }

void RegisterBlock(const BlockReason reason,const string symbol,const string details)
  {
   int idx=(int)reason;
   if(idx>=0 && idx<ArraySize(g_block_counts))
      g_block_counts[idx]++;

   if(InpDebugMode)
      Logger::Info("BlockStats",StringFormat("%s %s - %s",symbol,BlockReasonToString(reason),details));
  }


string TrimText(string value)
  {
   StringTrimLeft(value);
   StringTrimRight(value);
   return(value);
  }

void UpdatePerformanceStats()
  {
   datetime now=TimeCurrent();
   if(g_last_perf_update!=0 && (now-g_last_perf_update)<60)
      return;

   g_perf_wins=0;
   g_perf_losses=0;

   if(!HistorySelect(0,now))
      return;

   int deals=HistoryDealsTotal();
   for(int i=0;i<deals;i++)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0)
         continue;

      if((long)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=InpMagic)
         continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY)!=DEAL_ENTRY_OUT)
         continue;

      double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_SWAP)+HistoryDealGetDouble(ticket,DEAL_COMMISSION);
      if(profit>0.0)
         g_perf_wins++;
      else if(profit<0.0)
         g_perf_losses++;
     }

   g_last_perf_update=now;
  }

int OnInit()
  {
   ArrayInitialize(g_block_counts,0);
   int count=StringSplit(InpSymbols,',',g_symbols);
   if(count<=0)
      return(INIT_PARAMETERS_INCORRECT);

   ArrayResize(g_signal,count);
   for(int i=0;i<count;i++)
     {
      string s=TrimText(g_symbols[i]);
      g_symbols[i]=s;
      SymbolSelect(s,true);
      if(!g_signal[i].Init(s,InpAlligatorJaw,InpAlligatorTeeth,InpAlligatorLips,InpEMAPeriod,InpATRPeriod,InpWPRPeriod,InpATRVolatilityMultiplier,InpDormancyATRFactor))
         return(INIT_FAILED);
     }

   g_trade.Init(InpMagic,InpDeviationPoints);
   g_risk.Init(InpRiskPercent);
   g_trailing.Init(InpMagic);
   g_equity.Init(InpSoftDD,InpHardDD);
   g_exit.Init(g_symbols,g_signal,count,InpUseContractionExit,InpUseAlignmentExit,InpUseWPRExit,InpUseATRExit,InpExitScoreThreshold,InpExitMode);

   if(InpExitTimerSeconds>0)
      EventSetTimer(InpExitTimerSeconds);

   Logger::Info("EA","Initialization complete");
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Logger::Info("Stats",StringFormat("Signal stats checks=%I64d valid=%I64d",g_signal_checks,g_signal_valid));
   for(int i=0;i<ArraySize(g_block_counts);i++)
     {
      if(g_block_counts[i]>0)
         Logger::Info("Stats",StringFormat("%s=%I64d",BlockReasonToString((BlockReason)i),g_block_counts[i]));
     }
   for(int i=0;i<ArraySize(g_signal);i++)
      g_signal[i].Release();
   Comment("");
  }


void OnTimer()
  {
   for(int i=0;i<ArraySize(g_symbols);i++)
     {
      string symbol=g_symbols[i];
      if(!PositionSelect(symbol))
         continue;

      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic)
         continue;

      ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      bool should_close=false;

      if(position_type==POSITION_TYPE_BUY)
         should_close=g_exit.ShouldExitLong(symbol);
      else if(position_type==POSITION_TYPE_SELL)
         should_close=g_exit.ShouldExitShort(symbol);

      if(!should_close)
         continue;

      if(g_trade.ClosePosition(symbol))
         Logger::Info("ExitEngine",StringFormat("Exit signal executed for %s",symbol));
      else
         Logger::Warn("ExitEngine",StringFormat("Exit signal failed for %s",symbol));
     }
  }

void OnTick()
  {
   g_trailing.Update(InpTrailingATRMultiplier);

   bool trading_ok=g_equity.TradingAllowed();
   double drawdown=g_equity.CurrentDrawdownPct();
   double eq_scaler=g_equity.RiskScaler();
   UpdatePerformanceStats();
   g_risk.UpdatePerformanceScaler(g_perf_wins,g_perf_losses);
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
     {
      RegisterBlock(BLOCK_DD,"*","Trading disabled by equity protection");
      return;
     }
   if(st.open_positions>=InpMaxPositions)
      return;
   if((TimeCurrent()-g_last_trade_time)<InpMinSecondsBetweenTrades)
      return;

   for(int i=0;i<ArraySize(g_symbols);i++)
     {
      string symbol=g_symbols[i];
      if(g_trade.HasOpenPosition(symbol))
         continue;

      g_signal_checks++;

      if(InpMaxSpreadPoints>0)
        {
         double spread_points=(SymbolInfoDouble(symbol,SYMBOL_ASK)-SymbolInfoDouble(symbol,SYMBOL_BID))/SymbolInfoDouble(symbol,SYMBOL_POINT);
         if(spread_points>InpMaxSpreadPoints)
           {
            RegisterBlock(BLOCK_SPREAD,symbol,StringFormat("Spread too high %.1f > %d",spread_points,InpMaxSpreadPoints));
            continue;
           }
        }

      StrategySignal signal=g_signal[i].Evaluate(symbol,InpUseFractalFilter,InpATRSLMultiplier,InpRR,InpFractalRangePoints);
      if(!signal.valid)
        {
         RegisterBlock(DetectBlockReason(signal.reason),symbol,signal.reason);
         continue;
        }

      g_signal_valid++;

      int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(point<=0.0)
        {
         RegisterBlock(BLOCK_SIGNAL_MISC,symbol,"Invalid point size");
         continue;
        }

      double entry_raw=(signal.direction==DIR_BUY)?SymbolInfoDouble(symbol,SYMBOL_ASK):SymbolInfoDouble(symbol,SYMBOL_BID);
      double entry=NormalizeDouble(entry_raw,digits);
      signal.stop_loss=NormalizeDouble(signal.stop_loss,digits);
      signal.take_profit=NormalizeDouble(signal.take_profit,digits);
      double sl_points=MathAbs(entry-signal.stop_loss)/point;
      double lots=g_risk.ComputeLots(symbol,eff_risk,sl_points);
      if(lots<=0.0)
        {
         RegisterBlock(BLOCK_MARGIN,symbol,"Lot computation <= 0");
         continue;
        }

      if(g_trade.ExecuteSignal(signal,lots))
        {
         g_last_trade_time=TimeCurrent();
         Logger::Info("TradeManager",StringFormat("Order sent %s lots=%.2f",symbol,lots));
        }
      else
        {
         RegisterBlock(BLOCK_SIGNAL_MISC,symbol,"Order rejected by trade manager");
         Logger::Warn("TradeManager",StringFormat("Order rejected %s",symbol));
        }
     }
  }
