#pragma once
#include "SignalManager.mqh"
#include "Logger.mqh"

class CExitEngine
  {
private:
   string       *m_symbols;
   SignalManager *m_signals;
   int           m_count;

   bool m_use_contraction;
   bool m_use_alignment;
   bool m_use_wpr;
   bool m_use_atr;
   int  m_threshold;
   ExitMode m_mode;

   int SymbolIndex(const string symbol) const
     {
      for(int i=0;i<m_count;i++)
        {
         if(m_symbols[i]==symbol)
            return(i);
        }
      return(-1);
     }

   // Alligator contraction: both lips-teeth and teeth-jaw distances shrink vs previous bar.
   bool IsAlligatorContraction(const string symbol)
     {
      int idx=SymbolIndex(symbol);
      if(idx<0)
         return(false);

      double jaw_now=0,jaw_prev=0,teeth_now=0,teeth_prev=0,lips_now=0,lips_prev=0;
      if(!m_signals[idx].ReadAlligator(jaw_now,jaw_prev,teeth_now,teeth_prev,lips_now,lips_prev))
         return(false);

      double dist_lt_now=MathAbs(lips_now-teeth_now);
      double dist_tj_now=MathAbs(teeth_now-jaw_now);
      double dist_lt_prev=MathAbs(lips_prev-teeth_prev);
      double dist_tj_prev=MathAbs(teeth_prev-jaw_prev);

      return(dist_lt_now<dist_lt_prev && dist_tj_now<dist_tj_prev);
     }

   // Alignment loss signals trend fatigue: long needs Lips>Teeth>Jaw, short inverse.
   bool IsAlignmentLost(const string symbol,const bool is_long)
     {
      int idx=SymbolIndex(symbol);
      if(idx<0)
         return(false);

      double jaw_now=0,jaw_prev=0,teeth_now=0,teeth_prev=0,lips_now=0,lips_prev=0;
      if(!m_signals[idx].ReadAlligator(jaw_now,jaw_prev,teeth_now,teeth_prev,lips_now,lips_prev))
         return(false);

      if(is_long)
         return(lips_now<=teeth_now || teeth_now<=jaw_now);
      return(lips_now>=teeth_now || teeth_now>=jaw_now);
     }

   // WPR reversal confirms momentum fading after an extreme zone.
   bool IsWPRReversal(const string symbol,const bool is_long)
     {
      int idx=SymbolIndex(symbol);
      if(idx<0)
         return(false);

      double wpr_now=0,wpr_prev=0;
      if(!m_signals[idx].ReadWPR(wpr_now,wpr_prev))
         return(false);

      if(is_long)
         return(wpr_prev>-20.0 && wpr_now<-20.0);
      return(wpr_prev<-80.0 && wpr_now>-80.0);
     }

   bool IsATRDeclining(const string symbol)
     {
      int idx=SymbolIndex(symbol);
      if(idx<0)
         return(false);

      double atr_now=0,atr_prev=0;
      if(!m_signals[idx].ReadATR(atr_now,atr_prev))
         return(false);

      return(atr_now<atr_prev);
     }

   bool ReachedThreshold(const int score) const
     {
      if(m_mode==EXIT_STRICT)
         return(score>=MathMax(1,m_threshold+1));
      if(m_mode==EXIT_SIMPLE)
         return(score>=1);
      return(score>=MathMax(1,m_threshold));
     }

   // Score-based decision engine (can behave simple/strict via ExitMode).
   bool ShouldExit(const string symbol,const bool is_long)
     {
      int exitScore=0;

      if(m_use_contraction && IsAlligatorContraction(symbol))
         exitScore++;
      if(m_use_alignment && IsAlignmentLost(symbol,is_long))
         exitScore++;
      if(m_use_wpr && IsWPRReversal(symbol,is_long))
         exitScore++;
      if(m_use_atr && IsATRDeclining(symbol))
         exitScore++;

      return(ReachedThreshold(exitScore));
     }

public:
   void Init(string &symbols[],SignalManager &signals[],const int count,
             const bool use_contraction,const bool use_alignment,
             const bool use_wpr,const bool use_atr,
             const int threshold,const ExitMode mode)
     {
      m_symbols=symbols;
      m_signals=signals;
      m_count=count;
      m_use_contraction=use_contraction;
      m_use_alignment=use_alignment;
      m_use_wpr=use_wpr;
      m_use_atr=use_atr;
      m_threshold=threshold;
      m_mode=mode;
     }

   bool ShouldExitLong(string symbol)
     {
      return(ShouldExit(symbol,true));
     }

   bool ShouldExitShort(string symbol)
     {
      return(ShouldExit(symbol,false));
     }
  };
