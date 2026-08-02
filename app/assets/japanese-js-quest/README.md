# Japanese JavaScript Quest

Campagne locale et autonome de 20 missions pour apprendre JavaScript à un enfant japonais.
Elle utilise le serveur statique déjà fourni par CodeCombat, mais **aucun niveau officiel ou Premium**.

## Ouvrir la campagne

Après avoir lancé CodeCombat localement :

```text
http://localhost:7777/japanese-js-quest/
```

Le build Webpack copie `app/assets` dans le dossier public, donc aucune configuration serveur supplémentaire n’est nécessaire.

## Progression pédagogique

- Missions 1–2 : appels de fonctions et paramètres (`hero.move("right")`)
- Missions 3–9 : `if`, `else`, `else if`, comparaisons, `&&`, `||`
- Missions 10–14 : boucles `for` et `while`, conditions dans les boucles
- Missions 15–20 : boucles imbriquées et combinaison des trois concepts

L’interface, les consignes, les erreurs et les indices sont en japonais. Les codes sont sauvegardés dans `localStorage`.
Chaque solution est testée sur toutes les variantes de sa mission avant que la mission soit validée.

## Validation automatique

Depuis la racine du dépôt :

```bash
node scripts/validate-japanese-js-quest.js
```

Le script vérifie :

- qu’il y a exactement 20 missions ;
- que les identifiants sont uniques ;
- que chaque mission possède une carte, un code initial et une solution ;
- que la solution réussit toutes les variantes et respecte les contraintes pédagogiques.

## 日本語

CodeCombat のローカル環境で動く、子ども向け JavaScript 学習キャンペーンです。
ブラウザで `/japanese-js-quest/` を開いてください。進みぐあいとコードはブラウザ内に保存されます。
