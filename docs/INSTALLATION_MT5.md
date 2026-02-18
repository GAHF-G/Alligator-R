# Guide d'installation MT5

1. Ouvrir MT5 → `Fichier > Ouvrir le dossier des données`.
2. Copier:
   - `Experts/AlligatorProEA.mq5` vers `MQL5/Experts/`
   - `Include/AlligatorPro/*` vers `MQL5/Include/AlligatorPro/`
   - `presets/*.set` vers `MQL5/Profiles/Tester/`
3. Redémarrer MT5 puis compiler l'EA dans MetaEditor.
4. Dans Strategy Tester:
   - Mode: Every tick based on real ticks.
   - Timeframes: logique MTF H1 + M30.
   - Charger un preset `.set`.
5. Vérifier les logs structurés dans l'onglet Journal.
