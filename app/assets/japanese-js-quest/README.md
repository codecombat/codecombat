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
- un bouton `答えを見る` disponible immédiatement pour afficher la solution finale de la mission sélectionnée.

L'affichage de la réponse administrateur ne demande aucune confirmation et n'enregistre pas cette réponse dans le code sauvegardé du joueur. Le déblocage total disparaît au rechargement de la page.

## Après une mise à jour Git

```powershell
cd D:\yuzu-dev\codecombat
git pull --ff-only origin feature/japanese-js-quest-20-missions
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

Recharge ensuite la page avec `Ctrl+F5`.

La migration de curriculum déplace automatiquement les anciens codes sauvegardés et les identifiants de progression vers la nouvelle numérotation. Un code personnel reste associé à sa leçon d'origine.

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

`hero.isTrue(boolean)` accepte strictement une valeur booléenne :

- `true` → `正しいです。` ;
- `false` → `違いますよ。` ;
- autre valeur, paramètre absent ou paramètres multiples → explication japonaise dans une bulle bloquante.

La mission n'est validée qu'après avoir contrôlé les deux booléens, récupéré la gemme et terminé sur le drapeau.

Les cartes pédagogiques de cette mission présentent séparément le booléen, `const`, l'affectation `=`, le choix d'un nom de constante en romaji et `hero.isTrue(boolean)`. La carte de nommage rappelle que les programmeurs japonais utilisent souvent des noms anglais significatifs, par exemple `alwaysTrue` pour « toujours true ».

## Mission 04 : premier `if`

Les notions de constante et d'affectation ne sont pas répétées. La section `新しい考え方` contient uniquement les nouveaux concepts de cette mission :

- la valeur de retour de `hero.readSign()` ;
- la branche `if` ;
- la comparaison `===`.

## Aide après des échecs

En mode joueur normal, la solution finale n'est jamais affichée.

Après trois exécutions réellement échouées sur une même mission, le bouton `ほぼ完成コードを見る` devient disponible. Après confirmation, il remplace le code par une version presque complète contenant plusieurs commentaires, des indices et un `TODO`. Au moins une instruction indispensable reste à écrire par le joueur.

Une exécution réussie ne compte pas comme un échec.

## Mission 14 : boucle infinie volontaire

La mission explique pourquoi `while (true)` ne peut pas s'arrêter seule. Lorsque l'utilisateur clique sur `実行する` :

1. la réussite et le déblocage de la mission suivante sont sauvegardés immédiatement ;
2. le héros récupère la gemme ;
3. il répète son message à chaque tour ;
4. fermer la bulle déclenche l'itération suivante ;
5. il faut recharger la page avec l'icône circulaire du navigateur ou `Ctrl+F5` pour sortir de la démonstration.

## Plusieurs fields avec le même programme

Une barre affiche le field courant et le nombre total. Un clic sur `実行する` réinitialise toujours l'aventure, démarre au field 1 et exécute le même code sur tous les fields dans l'ordre. La mission s'arrête sur le premier field en échec et n'est validée que lorsque tous réussissent.

## Erreurs expliquées par le héros

Les erreurs de commande produisent une bulle japonaise bloquante avant l'affichage du résultat :

- direction absente, multiple ou invalide ;
- paramètre superflu ;
- mauvais type de paramètre ;
- booléen invalide pour `hero.isTrue(...)` ;
- nom de transformation inconnu ;
- méthode inexistante ou mal orthographiée.

Les méthodes de direction acceptent seulement `right`, `left`, `up` et `down`.

## Niveau du magicien et transformations

Le niveau est calculé à partir des récompenses prévues pour les missions précédentes. Les seuils commencent à 1, 5, 12, 22, 35 et 51 gemmes.

À partir du niveau 1 :

```javascript
hero.transform("frog");
hero.transform("hero");
```

Une forme reconnue mais verrouillée fait dire `この技はまだ使えないよ。`.

La forme suivante est préparée techniquement au niveau 99, mais reste cachée dans l'aventure :

```javascript
hero.transform("dragon");
```

## Légende progressive

- héros : mission 00 ;
- gemme et objectif : mission 01 ;
- grenouille : mission 02, une seule fois ;
- piège : mission 07 ;
- clé et porte : mission 09 ;
- ennemi : mission 15.

Le dragon reste absent jusqu'à une future introduction narrative.

## Validation automatique

Depuis la racine du dépôt :

```bash
node scripts/validate-japanese-js-quest.js
```

Le validateur vérifie les 23 missions et tous leurs fields, les solutions finies, les solutions partielles incomplètes, les gemmes, les niveaux, l'ordre des actions, les erreurs parlées, `hero.isTrue(...)`, le drapeau de la mission 03, le dragon de niveau 99, la mission infinie spéciale, la migration des identifiants, l'aventure multi-fields, le mode administrateur, la légende progressive, l'absence de requête Ace en mode autonome et les documents de règles.

## 日本語

子ども向けのローカル JavaScript 学習キャンペーンです。

```powershell
cd .\app\assets\japanese-js-quest
py -m http.server 8000
```

ブラウザで `http://localhost:8000/` を開いてください。管理者モードは `http://localhost:8000/?admin=1` です。
