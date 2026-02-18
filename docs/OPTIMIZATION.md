# Méthodologie d'optimisation

## Paramètres optimisables (suggestions)
- Alligator: Jaw `[10..18]`, Teeth `[6..12]`, Lips `[4..8]`
- W%R seuils:
  - BUY cross: `< -90..-80` vers `>-85..-70`
  - SELL cross: `> -10..-20` vers `<-15..-30`
- ATR:
  - période `[10..24]`
  - multiplicateur vol `[0.8..1.5]`
  - ATR SL multiplier `[1.0..3.0]`
- EMA période `[100..300]`
- Fractal mode: `true/false`
- FractalRangePoints `[80..500]`

## Process robuste
1. Optimisation coarse grid.
2. Affinage local des zones robustes (pas des pics isolés).
3. Walk-forward optimization.
4. Monte-Carlo perturbé (spread/slippage/latence).
5. Stress test événements de volatilité.

## Critères de sélection
- Profit Factor > 1.4
- DD max < 18%
- Recovery factor cohérent
- Sensibilité paramétrique faible (plateau de performance)
