# Japanese JavaScript Quest

Campagne locale et autonome de 23 missions pour apprendre JavaScript à un enfant japonais.
Elle utilise les fichiers statiques du dépôt CodeCombat, mais **aucun niveau officiel ou Premium**.

Les règles fonctionnelles complètes sont dans [`docs/PRODUCT_RULES.md`](../../../docs/PRODUCT_RULES.md). Les contraintes générales de contribution sont dans [`docs/DEVELOPMENT_RULES.md`](../../../docs/DEVELOPMENT_RULES.md).

## Lancer le jeu sous Windows

Ouvre PowerShell dans le dépôt, puis exécute :

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Ouvre ensuite :

```text
http://localhost:8000/
```

En mode autonome sur le port 8000, le jeu utilise directement son éditeur texte intégré. Il ne tente pas de charger l'éditeur Ace de l'application CodeCombat complète, dont les fichiers ne sont pas servis par cette commande.

Si `py` n'est pas reconnu :

```powershell
python -m http.server 8000
```

Pour arrêter le serveur, utilise `Ctrl+C`. Aucun script PowerShell du dépôt n'est nécessaire.

## Mode administrateur

```text
http://localhost:8000/?admin=1
```

Ce mode ajoute :

- un bouton permettant de débloquer temporairement toutes les missions sans les marquer comme terminées ;
- un bouton `答えを見る` disponible immédiatement pour afficher la solution finale de la mission sélectionnée ;
- un bouton `ADMIN：正解を選ぶ` dans chaque mini-quiz, qui sélectionne les bonnes réponses sans soumettre ni valider automatiquement la carte.

L'affichage de la réponse administrateur ne demande aucune confirmation et n'enregistre pas cette réponse dans le code sauvegardé du joueur. Le déblocage total disparaît au rechargement de la page.

## Utiliser la branche de renforcement pédagogique

```powershell
cd D:\yuzu-dev\codecombat
git fetch origin
git switch feature/japanese-js-quest-learning-reinforcement
git pull --ff-only origin feature/japanese-js-quest-learning-reinforcement
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Recharge ensuite la page avec `Ctrl+F5`.

La migration de curriculum déplace automatiquement les anciens codes sauvegardés et les identifiants de progression vers la nouvelle numérotation. Un code personnel reste associé à sa leçon d'origine.

## Cartes de concepts et mini-quiz

Les 36 cartes de `新しい考え方` sont chargées depuis la base canonique et cachées au premier affichage. L'enfant peut les retourner dans l'ordre qu'il souhaite, mais une seule carte non validée reste ouverte à la fois.

La mission 01 contient notamment la carte canonique `// はコメント（Comment）`. Elle utilise exactement le même parcours que les autres cartes : face cachée, prévisualisation, mini-quiz, validation et mémorisation. Aucun second bloc HTML indépendant n'est ajouté.

Chaque carte possède un mini-quiz de une à trois questions très simples. Toutes les réponses doivent être correctes en même temps pour valider la carte. En cas d'erreur, la bonne réponse n'est pas révélée : l'enfant est invité à relire la carte et à recommencer.

Les mots difficiles en kanji reçoivent les mêmes infobulles de lecture dans les explications, les cartes, les questions et les choix des mini-quiz.

Une carte validée reste visible avec une coche. Ses identifiants sont sauvegardés séparément dans :

```text
japanese-js-quest-concept-memory-v1
```

Le compteur `カード X / N` montre la progression. L'éditeur et l'exécution restent verrouillés jusqu'à la validation de toutes les cartes de la mission.

## Coloration pédagogique simplifiée

Quand l'éditeur n'a pas le focus, une prévisualisation colorée montre les catégories de concepts :

- bleu : objet et noms de variables ou constantes ;
- violet : méthodes ;
- rouge : valeurs littérales et contenu des chaînes ;
- gris : commentaires ;
- blanc : mots-clés, opérateurs, ponctuation, parenthèses, quotes et autres éléments de syntaxe.

Les quotes des chaînes restent blanches ; seul leur contenu est rouge. Une légende très compacte apparaît sous le code.

Au clic dans la zone de code, la coloration disparaît, l'éditeur retrouve sa couleur uniforme et le curseur est placé à l'endroit correspondant au caractère ou au mot sélectionné. Lorsque l'éditeur perd le focus, la prévisualisation est reconstruite à partir du dernier texte. Les couleurs sont centralisées dans des variables CSS faciles à modifier.

## Interface et défilement

La ligne `Ctrl / ⌘ + Enter で実行` utilise une taille réduite afin de rester secondaire par rapport au titre JavaScript.

Toutes les zones défilables utilisent désormais le même thème bleu que l'éditeur : page, liste des missions, panneaux d'aide, prévisualisation du code et fenêtres de mini-quiz. Les couleurs et la taille sont centralisées dans des variables CSS.

## Progression pédagogique

- Mission 00 : `hero.say("Hello Yuzu")`, objet, méthode, paramètre et chaîne de caractères ;
- missions 01–02 : commentaires, déplacements et ordre des instructions ;
- mission 03 : booléens, `true`, `false`, `const`, affectation et `hero.isTrue(boolean)` ;
- missions 04–10 : `if`, `else`, `else if`, comparaisons, `&&` et `||` ;
- missions 11–13 : boucles `for` et première boucle conditionnelle `while` ;
- mission 14 : démonstration volontaire de `while (true)` et d'une boucle infinie ;
- missions 15–22 : conditions dans les boucles, boucles imbriquées et combinaison des concepts.

L'interface, les consignes, les erreurs et les indices sont en japonais. Les termes techniques japonais sont accompagnés de leur nom anglais et de sa prononciation en katakana. Les kanji difficiles disposent d'infobulles de lecture.

## Mission 03 : booléens

Le code est déjà complet :

```javascript
// true という値に alwaysTrue という名前をつける
const alwaysTrue = true;
hero.isTrue(alwaysTrue);

// false という値に alwaysFalse という名前をつける
const alwaysFalse = false;
hero.isTrue(alwaysFalse);

// 宝石を取って、旗まで進む
hero.move("right");
hero.move("right");
```

Le premier déplacement collecte la gemme et le second place le héros sur le drapeau.

## Mission 14 : boucle infinie volontaire

La mission 14 utilise deux rechargements :

1. l'éditeur est d'abord grisé ;
2. le bouton vert demande de préparer la démonstration ;
3. `Ctrl+F5` active l'éditeur et remet le bouton jaune ;
4. `実行する` enregistre la réussite avant de lancer `while (true)` ;
5. un second `Ctrl+F5` sort de la boucle avec la mission déjà terminée.

## Validation locale

Depuis la racine du dépôt :

```powershell
node scripts/validate-japanese-js-quest.js
node scripts/validate-japanese-js-quest-runtime.js
node scripts/validate-japanese-js-quest-loop-rules.js
node scripts/validate-japanese-js-quest-learning-reinforcement.js
```
