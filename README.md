# Alligator-R — EA MQL5 professionnel (Alligator + W%R + Fractales)

Ce dépôt contient un Expert Advisor MT5 modulaire orienté suivi de tendance:
- **Trend engine H1**: Alligator 5/8/13, EMA macro trend, ATR volatility gate, filtre de dormance.
- **Timing M30**: transition Williams %R (survente/surachat).
- **Mode fractal avancé**: breakout fractal, SL fractal, blocage range si fractales trop proches.
- **Gestion du risque**: risk%, scaling dynamique, peak-equity, drawdown protection.
- **Modules**: `SignalManager`, `TradeManager`, `RiskManager`, `TrailingManager`, `EquityProtection`, `Dashboard`.

## Structure
- `Experts/AlligatorProEA.mq5`
- `Include/AlligatorPro/*.mqh`
- `presets/*.set`
- `docs/*.md`

## Démarrage rapide
1. Copier les dossiers `Experts` et `Include` dans votre terminal MT5 (MQL5).
2. Compiler `Experts/AlligatorProEA.mq5`.
3. Charger un preset depuis `presets/` selon l'actif.
4. Lancer des backtests + optimisation avant passage en réel.

Voir `docs/INSTALLATION_MT5.md` et `docs/OPTIMIZATION.md`.
