# Japanese JavaScript Quest

Campagne locale et autonome de 21 missions pour apprendre JavaScript à un enfant japonais.
Elle utilise les fichiers statiques du dépôt CodeCombat, mais **aucun niveau officiel ou Premium**.

Les règles fonctionnelles complètes sont dans [`docs/PRODUCT_RULES.md`](../../../docs/PRODUCT_RULES.md). Les contraintes générales de contribution sont dans [`docs/DEVELOPMENT_RULES.md`](../../../docs/DEVELOPMENT_RULES.md).

## Lancer le jeu sous Windows

Ouvre PowerShell dans le dépôt, puis exécute exactement :

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Ensuite, ouvre dans Chrome :

```text
http://localhost:8000/
```

Pour arrêter le serveur, retourne dans PowerShell et appuie sur `Ctrl+C`.

Si `py` n'est pas reconnu, utilise `python` :

```powershell
cd .\app\assets\japanese-js-quest
python -m http.server 8000
```

Aucun script PowerShell du dépôt n'a besoin d'être exécuté. Cette méthode fonctionne lorsque l'exécution des fichiers `.ps1` est désactivée par Windows.

## Mode administrateur

Pour afficher un bouton permettant de débloquer toutes les missions sans les marquer comme terminées, ouvre :

```text
http://localhost:8000/?admin=1
```

Ce mode est volontairement sans protection : il sert uniquement à la vérification manuelle du jeu.

## Après une mise à jour Git

Depuis la racine du dépôt :

```powershell
git pull --ff-only origin feature/japanese-js-quest-20-missions
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Puis recharge complètement la page avec `Ctrl+F5`.

## Progression pédagogique

- Mission 00 : première méthode avec `hero.say("Hello Yuzu")` ;
- missions 01–02 : méthodes et paramètres, notamment `hero.move("right")` ;
- missions 03–09 : `if`, `else`, `else if`, comparaisons, `&&`, `||` ;
- missions 10–14 : boucles `for` et `while`, conditions dans les boucles ;
- missions 15–20 : boucles imbriquées et combinaison des concepts.

L'interface, les consignes, les erreurs et les indices sont en japonais. Les codes sont sauvegardés dans `localStorage`.

Les termes techniques japonais sont accompagnés, lors de leur introduction, de leur nom anglais et de sa prononciation en katakana. Les kanji difficiles disposent également d'infobulles de lecture.

## Plusieurs fields avec le même programme

Une mission peut posséder plusieurs fields. Une barre affiche le field courant et le nombre total.

Un clic sur `実行する` :

1. réinitialise complètement l'aventure ;
2. démarre toujours au field 1 ;
3. exécute le même code sans modification sur chaque field dans l'ordre ;
4. s'arrête sur le premier field en échec ;
5. valide la mission seulement lorsque tous les fields réussissent.

## Erreurs expliquées par le héros

Les erreurs de commande produisent une bulle japonaise bloquante à la position du héros avant l'affichage du résultat :

- direction absente ou invalide ;
- paramètre superflu ;
- mauvais type de paramètre ;
- nom de transformation inconnu ;
- méthode inexistante ou mal orthographiée.

Les méthodes de direction acceptent seulement `right`, `left`, `up` et `down`.

## Niveau du magicien et transformations

Le niveau n'est pas sauvegardé séparément. Il est calculé de manière déterministe à partir des récompenses prévues pour les missions précédentes.

- missions 00 et 01 : niveau 0 ;
- missions 02 à 05 : niveau 1 ;
- niveau 1 à partir de 1 gemme ;
- niveau 2 à partir de 5 gemmes ;
- niveau 3 à partir de 12 gemmes ;
- paliers suivants : 22, 35, 51, etc.

Toutes les missions sauf la mission d'introduction contiennent au moins une gemme obligatoire.

À partir du niveau 1 :

```javascript
hero.transform("frog");
hero.transform("hero");
```

Une forme reconnue mais pas encore débloquée fait dire au héros `この技はまだ使えないよ。`.

La forme suivante est déjà enregistrée techniquement, mais reste cachée dans l'aventure et exige provisoirement le niveau 99 :

```javascript
hero.transform("dragon");
```

## Légende progressive

La légende ne révèle que les éléments déjà rencontrés :

- héros dès la mission 00 ;
- gemme et objectif dès la mission 01 ;
- grenouille dès la mission 02, une seule fois ;
- piège dès la mission 06 ;
- clé et porte dès la mission 08 ;
- ennemi dès la mission 13.

Le dragon reste absent de la légende jusqu'à sa future introduction dans l'histoire.

## Validation automatique

Depuis la racine du dépôt :

```bash
node scripts/validate-japanese-js-quest.js
```

Le validateur vérifie notamment les 21 missions et tous leurs fields, les solutions, les gemmes, les niveaux, l'ordre des actions, les erreurs parlées, les transformations verrouillées, le dragon de niveau 99, l'aventure multi-fields, le mode administrateur, la légende progressive et la présence des documents de règles.

## 日本語

子ども向けのローカル JavaScript 学習キャンペーンです。

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

ブラウザで `http://localhost:8000/` を開いてください。
確認用の管理者モードは `http://localhost:8000/?admin=1` です。
進みぐあいとコードはブラウザ内に保存されます。
