##### Atividade

# Introdução à Refatoração
Atividade de Inquérito

### Objetivos de Aprendizagem
- [LO 2.2.1] Desenvolver uma abstração ao escrever um programa ou criar outros artefatos computacionais. [P2]
- [LO 2.2.3] Identificar vários níveis de abstrações que são usados ao escrever programas. [P3]

## Código de Refatoração

**Atividade:**

Peça aos alunos que joguem [Defesa Agripa](https://codecombat.com/play/level/the-agrippa-defense), que pode ser encontrado em Ciência da Computação 2.

A solução óbvia para este nível usa um algoritmo que consiste em três níveis de instruções IF / ELSE aninhadas:

```
while True:
    enemy = hero.findNearestEnemy()
    if enemy:
        distance = hero.distanceTo(enemy)
        if distance < 5:
            if hero.isReady("cleave"):
                hero.cleave(enemy)
            else:
                hero.attack(enemy)
```

Usando vários níveis de abstração, os alunos podem eventualmente simplificar a lógica central do nível para apenas três linhas:

```
while True:
    enemy = hero.findNearestEnemy()
    cleaveOrAttack(enemy)
```


Este código é muito mais fácil de entender, porque é um nível mais alto de abstração!

Instrua os alunos a identificar as partes da lógica que podem ser abstraídas para passar do primeiro programa para o segundo. Se eles precisarem de ajuda, você poderá guiá-los para duas abstrações principais:

1. Determinar se existe um inimigo apropriado para o alvo.
2. Determinar o ataque apropriado a ser usado.

### Abstração 1: Determinar se existe um inimigo apropriado para o alvo.


A chave para essa abstração é criar uma função que aceite o 'inimigo' como parâmetro e retorne falso se o inimigo for nulo (não há inimigo) ou se o inimigo estiver a 5 ou mais metros de distância. Deve retornar true se o inimigo existir e estiver a menos de 5 metros.

O código deve ser algo como isto:

```
def enemyInRange(enemy):
	if not enemy:
		return False
	if hero.distanceTo(enemy) < 5:
		return True
	else:
		return False
```

### Abstração 2: Determinando o ataque apropriado a ser usado.

A chave para essa abstração é criar uma função que aceite o 'inimigo' como um parâmetro e, em seguida, use a função da abstração 1 em uma instrução `if` para garantir que o inimigo seja apropriado para atacar. Se sim, então use o ataque `cleave` se estiver pronto, caso contrário use um` attack` normal. O código deve ser algo como isto:

```
def cleaveOrAttack(enemy):
    if enemyInRange(enemy):
        if hero.isReady('cleave'):
            hero.cleave(enemy)
        else:
            hero.attack(enemy)
```

Para finalizar, guie a discussão em direção a como essas funções poderiam ser usadas em outros contextos. Como geralmente é usado `enemyInRange` ou` cleaveOrAttack`, por exemplo? Podem estes ser usados em outros contextos de outros níveis? Guie os alunos na direção da percepção de que a abstração geralmente ocorre quando você faz as perguntas “qual é a lógica desse código eu poderia usar em outro lugar?” E depois descobre como estruturar o código para que ele possa ser usado em várias circunstâncias.


### Questões de discussão:

- Como  eu  uso abstração para dividir um problema em problemas menores e separados ajuda a melhorar os programas?
- Como eu uso abstrações torna os programas mais fáceis de entender?
- Quais outras abstrações são usadas na programação de computadores?

### Questões de Avaliação:

Para cada um dos seguintes pedaços de pseudocódigo:
- Circule uma peça que pode ser abstraída
- Dê um nome de função descritivo e quaisquer parâmetros necessários
- Descreva como ele poderia ser usado em outra função em outro lugar.
```
def userSignsUp(email, password):
  emailIsLongEnough = email length is greater than 5
  emailHasAtSymbol = email contains “@”
  if emailIsLongEnough and emailHasAtSymbol
    userExists = lookup user by email
    if userExists
      Tell user they have already signed up
    else
      Sign user up
  else
    Tell user email is invalid
```

```
def driveCarInCircles():
  if sensor 1 says something is in front of us
    stop
  else if sensor 2 says something is in front of us
    stop
  else if sensor 3 says something is in front of us
    stop
  else if at intersection
    Turn right
  else 
    if closest object is over 100 feet away
      Drive forward fast
    else
      Drive forward slow
```
