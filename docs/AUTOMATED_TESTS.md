# Guide automatisation des tests

## Backtests batch
- Créer des configurations `.ini` Strategy Tester pour chaque symbole.
- Exécuter des campagnes par période (in-sample / out-of-sample).

## Workflow recommandé
1. Baseline preset XAUUSD + BTCUSD.
2. Sweep paramètres clés.
3. Walk-forward (rolling windows).
4. Monte-Carlo (slippage, spread, latence, ordre des trades).
5. Validation forward démo 4 à 8 semaines.

## KPIs robustesse
- Profit Factor > 1.4
- Max DD < 18%
- Stabilité annuelle et multi-régime marché
- Dégradation OOS contrôlée
