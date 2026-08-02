# Japanese JavaScript Quest

Campagne locale et autonome de 21 missions pour apprendre JavaScript à un enfant japonais.
Elle utilise le serveur statique déjà fourni par CodeCombat, mais **aucun niveau officiel ou Premium**.

## Démarrage rapide sous Windows

Depuis la racine du dépôt :

```powershell
.\start-japanese-js-quest.ps1
```

Puis ouvrir :

```text
http://localhost:8000/
```

Le script se place automatiquement dans `app/assets/japanese-js-quest` et lance `py -m http.server 8000` (avec `python` comme solution de secours).

## Avec le serveur CodeCombat

Après avoir lancé CodeCombat localement :

```text
http://localhost:7777/japanese-js-quest/
```

Le build Webpack copie `app/assets` dans le dossier public, donc aucune configuration serveur supplémentaire n’est nécessaire.

## Progression pédagogique

- Mission 0 : première fonction avec `hero.say("Hello Yuzu")` et bulle de dialogue à fermer
- Missions 1–2 : appels de fonctions et paramètres (`hero.move("right")`)
- Missions 3–9 : `if`, `else`, `else if`, comparaisons, `&&`, `||`
- Missions 10–14 : boucles `for` et `while`, conditions dans les boucles
- Missions 15–20 : boucles imbriquées et combinaison des trois concepts

L’interface, les consignes, les erreurs et les indices sont en japonais. Les codes sont sauvegardés dans `localStorage`.
Chaque solution est testée sur toutes les variantes de sa mission avant que la mission soit validée.
L’éditeur rappelle aussi les raccourcis `Ctrl+C`, `Ctrl+V` et `Ctrl+Z`.

## Validation automatique

Depuis la racine du dépôt :

```bash
node scripts/validate-japanese-js-quest.js
```

Le script vérifie :

- qu’il y a exactement 21 missions ;
- que les identifiants sont uniques ;
- que chaque mission possède une carte, un code initial et une solution ;
- que la solution réussit toutes les variantes et respecte les contraintes pédagogiques.

## 日本語

CodeCombat のローカル環境で動く、子ども向け JavaScript 学習キャンペーンです。
ブラウザで `/japanese-js-quest/` を開いてください。進みぐあいとコードはブラウザ内に保存されます。
