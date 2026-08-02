# Japanese JavaScript Quest

Campagne locale et autonome de 21 missions pour apprendre JavaScript à un enfant japonais.
Elle utilise les fichiers statiques du dépôt CodeCombat, mais **aucun niveau officiel ou Premium**.

## Lancer le jeu sous Windows

Ouvre PowerShell dans le dépôt, puis exécute exactement :

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Ensuite, ouvre dans Chrome :

```text
http://localhost:8000
```

Pour arrêter le serveur, retourne dans PowerShell et appuie sur :

```text
Ctrl+C
```

### Si `py` n'est pas reconnu

Utilise `python` à la place :

```powershell
cd .\app\assets\japanese-js-quest
python -m http.server 8000
```

### Après une mise à jour Git

Depuis la racine du dépôt :

```powershell
git pull --ff-only origin feature/japanese-js-quest-20-missions
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Puis recharge complètement la page avec :

```text
Ctrl+F5
```

Aucun script PowerShell du dépôt n'a besoin d'être exécuté. Cette méthode fonctionne même lorsque l'exécution des fichiers `.ps1` est désactivée par Windows.

## Progression pédagogique

- Mission 0 : première fonction avec `hero.say("Hello Yuzu")`
- Missions 1–2 : appels de fonctions et paramètres (`hero.move("right")`)
- Missions 3–9 : `if`, `else`, `else if`, comparaisons, `&&`, `||`
- Missions 10–14 : boucles `for` et `while`, conditions dans les boucles
- Missions 15–20 : boucles imbriquées et combinaison des concepts

L'interface, les consignes, les erreurs et les indices sont en japonais. Les codes sont sauvegardés dans `localStorage`.
Chaque solution est testée sur toutes les variantes de sa mission avant que la mission soit validée.

## Validation automatique

Depuis la racine du dépôt :

```bash
node scripts/validate-japanese-js-quest.js
```

Le script vérifie :

- qu'il y a exactement 21 missions ;
- que les identifiants sont uniques ;
- que chaque mission possède une carte, un code initial et une solution ;
- que la solution réussit toutes les variantes et respecte les contraintes pédagogiques.

## 日本語

CodeCombat のローカル環境で動く、子ども向け JavaScript 学習キャンペーンです。
PowerShell で次のコマンドを実行してください。

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

そのあと、ブラウザで `http://localhost:8000` を開いてください。
進みぐあいとコードはブラウザ内に保存されます。
