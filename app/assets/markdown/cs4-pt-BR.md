###### último : 10/24/2016

##### Planos de Aula
# Ciências da Computação 4

### Sumário
- Recommended Prerequisite: Computer Science 3
- 6 x 45-60 minute coding sessions

#### Visão Geral
<!-- [MISSING] -->

_Este guia foi escrito com as salas de aula em linguagem Python em mente. Com exceção do módulo For Loops, todos os módulos podem ser facilmente adaptados para JavaScript. Existe um módulo para Loops específico para JavaScript disponível._

### Escopo e Sequência


| Módulo                                                 |                      | Metas                                            |
| -----------------------------------------------------  | :-----------------   | :-----------------                                        |
| [21.Condicionais While](#condicionais-while)           |                      | Crie um loop `while` com uma condicional                  |
| [22. Arrays/Matriz](#arraysmatrizes)                   |                      | Acessar um elemento em uma matriz usando um índice              |
| [23. Loops While Aninhados ](#loops-while-aninhados)   |                      | Construa um loop`while` aninhado                            |
| [24. Otimização](#otimizacao)                          |                      | Use a otimização na resolução de problemas                       |
| [25. Objetos](#objetos)                                |                      | Use um objeto literal como um argumento                      |
| [26a. Loops For (Python)](#loops-for-python)           |                      | PYTHON: Use um loop for para percorrer os elementos em uma matriz   |
| [26b. Loops For (JavaScript)](#loops-for-javascript)   |                      | JAVASCRIPT: Use um loop for para percorrer os elementos em uma matriz   |



### Vocabulário Básico
**Condicionais While**  - Um loop `while` é executado até que a condição não seja mais verdadeira.
**Arrays**  - uma lista ordenada de itens. 
**Loops While Aninhados**  - dois ou mais loops while que estão aninhados uns dentro dos outros - os alunos precisarão checar para ter certeza de que ambos se tornarão 'false' para que eles não criem múltiplos loops infinitos! 
**Otimização**  - writing code that can choose the best strategy to execute.  
**Objetos**  - Objetos literais contêm propriedades e valores que outros métodos podem acessar e modificar.  
**Loops For**  - Um loop `for` permite que você dê um loop em elementos de pensamento em uma matriz sem precisar incrementar um valor de índice.

#### Atividades extras para os alunos que concluírem o Curso 4 mais rápido:

- Ajude outra pessoa
- Escreva um passo a passo
- Escreva uma resenha do jogo
- Escreva um guia para o seu nível favorito
- Projete um novo nível

##### Módulo 21
## Condicionais While

### Sumário

Até este ponto, os alunos usaram apenas loops `while` que estão definidos como True para que se repitam para sempre. Nesses níveis, os alunos serão expostos a loops `while` que usam condicionais para fazer coisas como atacar inimigos por um determinado período de tempo.

Os loops `while` são similares aos comandos` if`, mas adicionam complexidade ao introduzir a possibilidade de criar um loop que irá rodar involuntariamente para sempre. Incentive os alunos a ler atentamente as instruções e colaborar enquanto trabalham nos níveis.

### Metas

* Crie um loop `while` com um condicional
* Escolha expressões apropriadas
* Incrementar uma condição de ciclo while
* Entenda o que faz um loop rodar infinitamente

### Atividade Instrutiva: passagem condicional (10 mins)

#### Explique (3 mins)


Semelhante aos comandos `if`, os loops `while` podem incluir condicionais. As condicionais devem ser avaliadas como `True` ou `False`, e o código dentro do loop será executado continuamente, desde que a condição seja encontrada como `True`.

Note que a sintaxe é idêntica aos loops `while` vistos anteriormente no jogo, mas em vez de ser configurado como` True`, o loop `while` é executado em uma expressão condicional.

```
bounces = 0
while bounces < 5:
	ball.bounce()
```
O loop acima é executado repetidas vezes enquanto o número de rejeições for menor que 5. Como o valor de `bounces` não é atualizado toda vez que a bola é devolvida, o loop continuará a rodar para sempre.

```
attacks = 0
while attacks < 10:
	hero.attack(enemy)
	attacks += 1
```
Esse loop é executado repetidas vezes enquanto o número de ataques for menor que 10. Observe que dentro do loop, o valor de `attacks` aumenta, ou **incrementa**, em 1 cada vez que o loop é executado. Isso garante que, na próxima vez que a condição no loop for verificada, esteja verificando o valor correto e atualizado dos ataques. Observe a sintaxe usada para incrementar ataques:

`attacks += 1`

Isso é equivalente ao seguinte:

`attacks = attacks + 1`

Da mesma forma, o valor de uma variável pode **decrementar** ou diminuir em 1 usando a seguinte sintaxe:

`attacks -= 1`

#### Interaja (5 mins)

Apresente uma bola na frente da classe e avise os alunos que este será o objeto que será tratado. Se você não tiver uma bola, pode substituir um lápis, uma borracha ou qualquer outro objeto que possa ser facilmente passado de estudante para aluno. Escreva o seguinte loop no quadro:

```
while True:
	ball.pass( )
```

Aponte para a linha superior e pergunte aos alunos se a condição é verdadeira (todos devem dizer sim). Passe a bola para um aluno e pergunte novamente se a condição é verdadeira. Mais uma vez, todos deveriam dizer sim.

Permita que a bola seja passada de estudante para estudante através da sala, desde que a condição seja verdadeira. Neste caso, é sempre verdade, então deixe a bola passar por cerca de um minuto ou até que os alunos possam ver que isso duraria para sempre. Então escreva este segundo loop no quadro:

```
passes = 0
while passes < 3:
	ball.pass( )
```

Mais uma vez, aponte para a condição `(passes <3)` e pergunte aos alunos se a condição é verdadeira. Permita 3 turnos de passagem, perguntando primeiro se a condição é verdadeira.

Na 4ª vez, quando você pergunta aos alunos se a condição é verdadeira, muitos deles provavelmente dirão não. Continue perguntando quantas vezes a bola foi passada (3). Então pergunte, qual é o valor da variável `passes`? Leve-os a ver que, como o valor de `passes` nunca foi alterado, o valor ainda é 0 e, portanto, a condição é verdadeira e o loop será executado para sempre.

Por fim, escreva este terceiro loop no quadro:
```
passes = 0
while passes < 5:
	ball.pass( )
	passes += 1
```

Seguindo os mesmos passos acima, pergunte aos alunos se a condição é verdadeira e permita que a bola seja passada por (5 vezes). Na sexta vez, quando você perguntar aos alunos se a condição é verdadeira, alguns deles podem dizer sim. Continue perguntando quantas vezes a bola foi passada (5) e pergunte qual é o valor de `passes` (também 5).

Se necessário, percorra novamente o último loop, registrando o valor de 'passes' no tabuleiro com marcas de contagem enquanto os alunos passam a bola.



#### Reflita (2 mins)


**O que é similar entre um laço condicional `while` e uma declaração` if`?** (Ambos confiam em condicionais para serem executados).

**Qual é a diferença entre um loop `while`condicional e uma declaração `if`?** (Uma declaração if é executada apenas uma vez se a condição for verdadeira. Um loop while é executado continuamente desde que a condição seja verdadeira.)

**O que é importante saber sobre a condicional em um loop `while`?** (Deve ser avaliado como True ou False).


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas, especialmente para evitar e corrigir laços infinitos. Se o herói deles passar pelo último aliado e entrar nas rochas na parte inferior, isso indica que eles têm um loop infinito em seu código. Os alunos terão que incrementar `ordersGiven` por 1 dentro do loop` while` para corrigir isso.

### Reflexão Escrita (5 mins)


**O que há de diferente nos loops `while` com os quais você trabalhou hoje do que os que você viu no jogo até agora?**
(Os que eu trabalhei hoje usavam instruções condicionais para determinar quando e por quanto tempo correr. Os outros que vimos até agora apenas usaram o True.)

**Quando você usaria um loop `while` condicional?**
(Quando você deseja que algo seja executado repetidamente, desde que uma certa condicional seja verdadeira.)

**Por que é importante incrementar sua condição de loop `while`?**
(Se você não fizer isso, então você vai ficar preso em um loop infinito - um que nunca termina.)
##### Módulo 22
## Arrays/Matrizes

### Sumário

**Arrays** 277/5000

são listas ordenadas de itens.  Na verdade, em Python, o nome usado para uma matriz é `list`.  Os arrays podem conter qualquer tipo de sequência de itens, números inteiros e até mesmo outros arrays - e podem ser de qualquer tamanho.  Um elemento em uma matriz pode ser acessado pelo seu ** índice/index ** ou por sua posição na lista.

O array é uma estrutura de dados fundamental e aparece com bastante frequência na programação. Ele também aparece frequentemente no CodeCombat, de várias maneiras. Às vezes, os alunos encontrarão os dados armazenados em uma determinada posição em uma matriz ou usarão um loop para acessar todos os itens de uma lista. Outras vezes, um método (como `findEnemies ()`) retornará uma matriz que pode ser usada junto com loops e condicionais para executar ações com mais eficiência.

### Metas

- Reconhecer a estrutura de dados do array
- Acessar um elemento em uma matriz usando um índice
- Determinar o tamanho de uma lista em Python
- Iterar um array com um loop


### Atividade Instrutiva: Caixas Secretas (15 mins)

#### Explique (6 mins)

Atualmente, os alunos sabem como armazenar dados com o uso de **variáveis**. Por exemplo, o seguinte código pode ser usado para declarar um herói chamado Ida:

`hero = "Ida"`


As variáveis são extremamente úteis, mas permitem que apenas um elemento seja armazenado por vez. **Arrays**, ou listas, no entanto, permitem que vários elementos sejam armazenados de cada vez.

A sintaxe usada para criar uma matriz é colchetes (`[]`) ao redor de toda a lista e vírgulas (`,`) entre cada item da lista.

Por exemplo, o código a seguir declara uma matriz dos itens do herói:
`heroItems = ['boots', 'sword', 'shield']`


Observe que a matriz acima tem um nome, "heroItems". Uma vez que a matriz é declarada, ela pode ser usada referenciando seu nome, assim como outras variáveis usadas ao longo do jogo. Dentro dos colchetes estão os itens da matriz, que neste exemplo são os itens de inventário do herói. Boots é o primeiro item, sword é o segundo e shield é o terceiro.

Arrays armazenam itens em ordem. Assim, cada item da matriz pode ser recuperado usando seu ** índice ** ou posição na matriz. Índices em matrizes começam em 0 em vez de 1, portanto, o índice do primeiro item é 0, o índice do segundo item é 1 e assim por diante.

A sintaxe para recuperar um elemento de uma matriz é a seguinte:

```
# returns the item at index 0, which is 'boots'
heroItems[0]

# returns the item at index 1, which is 'sword'
heroItems[1]
```

Observe que o nome da matriz é seguido por colchetes e, em seguida, pelo índice do item a ser recuperado.

Muitas vezes, é útil saber o número de itens que estão em uma matriz. Isto pode ser feito usando a função `len ()`, como mostrado abaixo:

```
# this returns 3 since there are 3 items in the array
len(heroItems)  
```

A função `len ()` é particularmente útil para fazer um loop através de um array para executar uma ação em cada item nele. Por exemplo, veja o seguinte segmento de código:

```
itemsIndex = 0
while itemsIndex < len(heroItems):
	hero.say("I have " + heroItems[itemsIndex])
	itemsIndex += 1
```
Isso pode ser traduzido em pseudocódigo da seguinte forma:

```
declare a variable itemsIndex and initialize it to 0
while the value of itemsIndex is less than the amount of items in the heroItems array:
	the hero says "I have " + the current item in the array
	increment itemsIndex by 1
	(loop again from while the value...)
```

O resultado desse código é que o herói diz as seguintes declarações:

```
I have boots.
I have sword.
I have shield.
```


Usando a variável `itemsIndex` e incrementando-a a cada iteração do loop, desde que seja menor que o comprimento do array, os elementos `heroItems [0] `,` heroItems [1]` e `heroItems [2 ]`são todos chamados. Isso faz com que a matriz seja totalmente conectada e resulta no herói dizendo cada um dos itens em voz alta.

Durante todo o jogo, além de criar seus próprios arrays para uso, os alunos também usarão arrays retornados de métodos. Por exemplo, o método `findEnemies ()` retorna uma matriz que os alunos podem chamar ou acessar os elementos conforme descrito acima.


#### Interaja (7 mins)


Para esta atividade, reúna algumas caixas de papelão e um item a ser colocado em cada caixa. Configure as caixas seguidas de frente para os alunos e coloque um item em cada caixa. Esse conjunto de caixas funcionará como a implementação física de uma matriz. Sacos de papel podem ser substituídos pelas caixas, se desejado. Essa atividade pode ser especialmente divertida e interessante, escolhendo itens engraçados ou inesperados para serem colocados dentro das caixas.

Escolha um nome para o array, como `ourItems`. Registre esse nome no quadro e diga aos alunos que o array `ourItems` consiste nas caixas na frente deles.


Peça aos alunos que verifiquem os índices da matriz começando na primeira caixa (aquela à esquerda dos alunos), apontando para ela e perguntando qual é o índice. Certifique-se de que os alunos lembrem que o índice deste item é 0.

Mover a linha, repetidamente pedindo o índice da caixa. Em seguida, mova-se aleatoriamente apontando para caixas diferentes, pedindo o índice de cada caixa até que os alunos pareçam ter um bom entendimento do conceito de contagem de 0.

Em seguida, peça aos alunos para ajudá-lo a recuperar o primeiro item da matriz. Lembre-os, se necessário, de que a sintaxe é a seguinte:

`ourItems[0]`


Se desejar, você pode pedir a um aluno que vá até o quadro para escrever o código. Depois que o código é escrito corretamente, o item na primeira caixa pode ser retirado e colocado na frente da caixa para a classe ver. Mais uma vez, um aluno pode ajudar com isso, se desejar.

Quando o item estiver visível para a classe, estenda a linha de código acima para incluir a atribuição ao item real, conforme mostrado abaixo:

`ourItems[0] = 'teddy bear'`


Repita o processo de pedir aos alunos para ajudá-lo a recuperar um item específico, escreva o código correspondente no quadro, mostre o item para a turma e conclua a linha de código conforme descrito acima. Em vez de seguir de forma linear, talvez seja melhor escolher itens aleatórios a cada vez para garantir que os alunos lembrem o índice correto a ser usado para cada posição (por exemplo, peça o primeiro item, depois o quarto e depois o segundo).

Você também pode pedir aos alunos para ajudá-lo a recuperar um item que não esteja no array (ou seja, se o array tiver quatro itens solicitados pelo quinto) para garantir que eles entendam que ele retornaria um erro.

Depois que todos os itens estiverem visíveis para a turma, peça aos alunos que escrevam a linha de código que criaria essa matriz. Certifique-se de que os itens sejam adicionados na ordem correta e que as vírgulas sejam colocadas entre cada item.

Por exemplo, se seus itens forem um ursinho de pelúcia, um lápis e uma caixa de suco, seu código deverá ser escrito da seguinte forma:
`ourItems = ['teddy bear', 'pencil', 'juice box']`

Agora pergunte aos alunos como encontrar o número de itens na matriz. Lembre-os, se necessário, sobre o método `len ()`. Com a ajuda deles, escreva o seguinte segmento de código no quadro:

`len(ourItems)`

Pergunte aos alunos qual valor seria retornado dessa linha de código e verifique se ele corresponde ao número de itens que você tem em sua matriz. Para o exemplo mostrado acima, `len (ourItems)` retornaria 3. Acrescente à linha que você acabou de escrever no quadro adicionando = e o valor, da seguinte forma:

`len(ourItems) = 3`

Finalmente, com todos os itens ainda visíveis, escreva o seguinte segmento de código no quadro:

```
itemIndex = 0
while itemIndex < len(ourItems):
	students.say("We have " + ourItems[itemIndex])
	itemIndex += 1
```

Peça aos alunos que percorram o código com você e digam o item correto ao apontar para cada linha de código. Pode ser útil registrar o valor de itemIndex no tabuleiro enquanto você percorre o loop `while`.

#### Reflita (2 mins)

**Como os arrays são usados? Como eles se diferem das variáveis** Arrays são usados para armazenar uma lista de itens em ordem. Eles diferem das variáveis porque as variáveis podem armazenar apenas um item e as matrizes podem armazenar muitas.

**Como os índices de arrays são usados?** Os índices são usados para encontrar um elemento específico em uma matriz, com base em sua posição.

**Para o array `heroes`, como você pode descobrir quantos itens estão no array? Como você obtém o primeiro item da matriz?** `len (heroes)` fornece o número de itens na matriz. `heroes [0]` fornece o primeiro item.


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Use as perguntas principais para lembrar os alunos sobre a função 'len ()' a ser usada em seus loops while para níveis posteriores. Lembrá-los da maneira como um loop `while` foi usado em conjunto com uma matriz enquanto fazia a atividade interativa com caixas. Incentive os alunos a escrever suas respostas em inglês e a trabalhar juntos para resolver alguns dos níveis mais difíceis.



##### Módulo 23
## Loops While Aninhados

### Sumário


Os próximos níveis combinam habilidades dos dois módulos anteriores para introduzir loops `while` aninhados. Os alunos usarão aninhamentos `while` para percorrer todos os inimigos e atacar apenas alguns, ou passar por todos os aliados e comandar certos.

Conceitualmente, loops `while` aninhados são semelhantes a condicionais aninhados, mas a inclusão de arrays e a possibilidade de múltiplos loops infinitos adicionam dificuldade. Se os alunos estiverem com problemas, incentive-os a ler atentamente as dicas, colaborar uns com os outros e a escrever soluções em inglês antes de tentar codificá-las.

### Metas

* Construa um loop aninhado `while`
* Leia e compreenda um laço `while` aninhado

### Atividade Instrutiva: Pulando Enquanto (10 mins)


#### Explique (2 mins)

Neste ponto, os alunos sabem como usar um loop `while` para percorrer e executar os itens em uma matriz. Além disso, eles podem escrever um loop `while` que é executado com base em uma determinada condição. Agora eles aprenderão como fazer um loop através de um array e apenas executar uma ação nos itens que atendem a uma determinada condição com loops `while` aninhados.

Por exemplo, talvez eles queiram encontrar todos os inimigos próximos e atacar cada um deles enquanto sua saúde for maior que 0. Isso pode ser expresso em inglês usando declarações `while` -" Enquanto houver um inimigo por perto e enquanto isso a saúde do inimigo é maior que 0, ataque-o. " O código a seguir representa isso:

```
enemies = hero.findEnemies()
enemyIndex = 0

while enemyIndex < len(enemies):
	enemy = enemies[enemyIndex]
	while enemy.health > 0:
		hero.attack(enemy)
	enemyIndex += 1
```
O primeiro loop `while` faz um loop em cada inimigo encontrado. O segundo loop while é um loop condicional que roda enquanto a vida do inimigo for maior que 0. Observe que o valor de enemyIndex deve ser incrementado para evitar a execução infinita do loop externo.


#### Interaja (5 mins)

Peça aos alunos que se alinhem ao longo de uma parede (use duas paredes, se necessário) de frente para o quadro. No quadro, escreva o seguinte código:

```
students = class.findStudents()
studentIndex = 0

while studentIndex < len(students):
	student = students[studentIndex]
	jumps = 0
	while jumps <= 3:
		student.jump()
		jumps += 1
	studentIndex += 1
```


Diga aos alunos que cada um deles é um elemento na matriz `students`. À medida que você percorre cada elemento da matriz, você se moverá pela linha dos alunos. Quando você chegar a um aluno, será sua vez de pular enquanto o número de saltos para esse aluno for menor ou igual a três. Peça aos alunos que percorram o código com você enquanto você aponta para cada linha.

Aponte para a primeira linha e pergunte aos alunos o que eles acham que faz. Certifique-se de que eles entendem que cria uma matriz de estudantes, semelhante à função `findEnemies ()` no jogo.

Em seguida, aponte para a segunda linha e certifique-se de que eles entendem que inicializa uma variável pela qual você pode percorrer o array, como fizeram nos níveis mais recentes do jogo.

Aponte para as próximas duas linhas de código e pergunte aos alunos o que eles fazem. Os alunos devem reconhecer que essas duas linhas trabalham juntas para percorrer cada aluno da matriz de alunos. Explique que inicializamos a variável `jumps` como 0 sempre que percorremos esse loop para garantir que o valor de `jumps` de cada aluno comece em 0.


Aponte para o segundo loop while e pergunte aos alunos o que ele faz. Eles devem reconhecer que é um loop que executa em um condicional com base no valor de saltos e o efeito é fazer com que cada aluno salte três vezes.

Percorra a fila de alunos, um de cada vez, fazendo com que cada aluno pule três vezes. À medida que você se move de aluno para aluno, certifique-se de apontar para o código correspondente para mostrar a variável "studentIndex" incrementando e o loop externo "while" executando novamente.

Certifique-se de que os alunos saltem devagar para que você possa apontar para o código correspondente que faz com que eles pulem. Pode ser útil obter um voluntário para registrar os valores de `studentIndex` e` jumps` enquanto você passa por este exercício.

Depois que todos na classe pularem, aponte novamente para o código e pergunte aos alunos o que aconteceria se você removesse a linha `saltos + = 1`. Pergunte a eles então o que aconteceria se você removesse a linha `studentIndex + = 1`. Para ambas as perguntas, elas devem responder que o loop `while` dependente desse valor seria executado infinitamente.

Nota: Se você precisar modificar essa atividade devido a restrições de tempo ou espaço, poderá fazer com que um subconjunto da classe realize a atividade de salto enquanto outros alunos acompanham as variáveis e acompanham apontando para as linhas de código correspondentes.



#### Explique (1 min)
Loops aninhados `while` permitem executar instruções, contanto que duas instruções condicionais separadas sejam verdadeiras. Devemos ter cuidado ao usá-los, pois a cada novo loop introduzimos outra possibilidade de executar um comando infinitamente.


#### Reflita (2 mins)

**Por que usamos loops aninhados `while`?** (Para executar comandos contanto que dois condicionais separados sejam verdadeiros.)
**O que é diferente sobre o uso de loops aninhados versus apenas um loop `while`?** (Você pode ser mais específico sobre suas ações, já que você pode especificar duas condicionais, mas você também tem a possibilidade de mais loops infinitos)
**Como é o recuo paraloops `while` aninhados e por quê?** (O loop interno é indentado por 4 espaços adicionais para mostrar que é parte do loop externo).


### Hora da Programação (30-45 mins)



Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Chame a atenção dos alunos para as instruções e dicas. Também certifique-se de que eles leiam todos os comentários no código inicial e estejam cientes dos objetivos de cada nível.

Lembre os alunos de verificar cuidadosamente cada loop `while` para recuo correto e loops infinitos antes de executar seu código. Eles terão que alterar o recuo de grande parte do código inicial para que ele funcione corretamente.




##### Módulo 24
## Otimização

### Sumário


Otimização descreve o ato de resolver um problema selecionando o "melhor" elemento de um conjunto baseado em um determinado critério. Os alunos usarão a otimização para criar estratégias atacando primeiro os inimigos mais distantes e menores.

Esses níveis oferecem aos alunos uma introdução ao conceito de solução de problemas por meio da otimização. Os conceitos de sintaxe e codificação nesses níveis são familiares aos alunos, mas essa abordagem para resolver problemas pode não ser. Assim, esses níveis podem se mostrar difíceis para alguns alunos.

### Metas

* Compare os valores entre si
* Defina um valor inicial para comparar
* Use otimização na resolução de problemas


### Atividade Instrutiva: Item mais longo (10 mins)


#### Explique (3 mins)

Os alunos agora têm as habilidades para atacar um inimigo aleatoriamente e atacar inimigos de um certo tipo. Hoje eles aprenderão como atacar inimigos diferentes, como os maiores, menores ou mais distantes, através de um processo chamado **otimização**.

A otimização envolve a seleção de um item que é determinado como "melhor" com base em determinados critérios. Geralmente, ele é selecionado como o "melhor", comparando-o a outros itens e encontrando o mínimo ou o máximo.

Por exemplo, para encontrar o inimigo que está mais distante, os alunos poderiam comparar as distâncias de cada inimigo. Uma maneira de fazer isso seria armazenar os valores de todas as distâncias e percorrê-los para tentar encontrar os menores.

Outra maneira de fazer isso, porém, é usar uma única variável que armazena a distância máxima conhecida no momento e comparar a distância de cada inimigo a esse valor. Isso pode ser implementado usando o seguinte código:

```
farthest = None
maxDistance = 0
enemyIndex = 0
enemies = hero.findEnemies()

while enemyIndex < len(enemies):
	target = enemies[enemyIndex]
	distance = hero.distanceTo(target)

	if distance > maxDistance:
		maxDistance = distance
		farthest = target

	enemyIndex += 1
```

As partes importantes do código a serem observadas aqui são as duas primeiras linhas e o condicional aninhado ('if distance ...'). `farthest` é inicializado como` None` porque não se sabe quem é o inimigo mais distante, ou se existe um inimigo mais distante (talvez não haja nenhum inimigo). `maxDistance` é inicializado como 0 porque não se sabe qual será a distância máxima. É importante começar com o menor valor possível `maxDistance` para garantir que cada item seja comparado.

A instrução if no final compara a distância do alvo atual com a distância máxima conhecida. Se a distância do alvo é maior, então o `maxDistance` é atualizado para ter o valor da distância do alvo e o `mais distante` é atualizado para ser o alvo. Se a distância do alvo não for maior, os valores das variáveis não serão alterados.

A parte do loop `while` do código acima pode ser lida da seguinte forma:

"Enquanto houver 'inimigos' na matriz, defina a variável `alvo` para o inimigo no índice atual. Agora defina a variável 'distância' para a distância entre o meu herói e este inimigo. Se a distância a este inimigo for maior do que a distância máxima que eu encontrei até agora, atualize minha variável `maxDistance` e defina a variável `farthest` para este inimigo. Agora incremente o índice e verifique se o laço `while` deve rodar novamente."

#### Interaja (5 mins)

Para esta atividade, você precisará de:

* Uma fita métrica (de preferência uma com um interruptor para permitir que a fita fique de fora)
* Uma caixa cheia de itens de vários comprimentos.


Explique aos alunos que você deseja a ajuda deles e que encontrem o item mais longo da caixa, mas com algumas regras:

* Você só pode ter um item fora da caixa de cada vez.
* Você pode usar a fita métrica para medir cada item depois de tirá-lo, mas não pode registrar o comprimento de nenhum item.

Pergunte aos alunos como eles acham que você poderia fazer isso. Certifique-se de levar a discussão a usar comparações e otimização.

Antes de retirar qualquer item da caixa, pergunte aos alunos qual é o tamanho máximo inicial. Certifique-se de que eles entendem que o comprimento máximo inicial é 0, pois nenhum item foi medido. Você pode ajudá-los a visualizar isso exibindo a fita métrica e perguntando o que sua medida atual diz.


Além disso, pergunte a eles qual é o item mais longo atual. Eles devem responder que é `None`, já que nenhum item foi medido ainda. Registre esses valores no quadro usando os nomes das variáveis ​​`maxLength` e` longestItem`. Sinta-se à vontade para pedir a um aluno que o ajude a atualizar esses valores durante toda a atividade.

Selecione aleatoriamente um item da caixa e segure-o ao lado da fita métrica fechada. Pergunte aos alunos se o comprimento é maior do que o atual `maxLength` (ao qual todos devem dizer sim). Meça o seu comprimento com a fita métrica e use o interruptor para deixar a fita nessa medida. Pergunte à classe o que o `maxLength` e` longestItem` são agora (eles devem dizer que é a medida atual e aquele item). Certifique-se de atualizar os valores no quadro apropriadamente.

Continue retirando itens da caixa um de cada vez e comparando-os com a quantidade de fita visível. Você também pode pedir aos alunos que ajudem você nesse processo, se desejar. Pergunte à turma toda vez se o tamanho do item atual for maior que o valor de `maxLength`. Se estiver, então meça o item e atualize os dois valores no quadro de acordo. Lembre-se de manter a fita fora após cada nova medição, para que os alunos possam ver visualmente o `maxLength` com cada comparação.


Depois de examinar todos os itens da caixa, peça aos alunos que identifiquem o comprimento do item mais longo. Todos devem reconhecer que as informações no quadro e na fita métrica mostram esse valor.

Nota: Se necessário, você pode usar uma régua ou uma jarda em vez de uma fita métrica, mas a atividade funcionará melhor se você conseguir mostrar apenas o comprimento máximo atual em seu dispositivo de medição.


#### Reflita (2 mins)

**Por que a otimização é útil?** (Compare os valores entre si para poder executar uma ação no elemento "melhor" com base em seus critérios.)
**Para encontrar o valor máximo ou maior de um conjunto, qual é o valor inicial que você deve definir para comparar?** (Você deve definir o valor inicial como 0, ou um número muito pequeno para avaliar todos os itens. sempre comparando com o maior valor conhecido)
**Para encontrar o valor mínimo ou menor de um conjunto, qual é o valor inicial que você deve definir para comparar?** (Você deve definir o valor inicial como um número muito grande para que você avalie cada item e esteja sempre comparando para o menor valor conhecido.)



### Hora da Programação (30-45 mins)



Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Certifique-se de que eles leiam todos os comentários incluídos no código inicial e entendam por que os valores iniciais estão definidos como estão. Incentive-os a colaborar e a escrever ou verbalizar o valor que estão procurando e como devem encontrá-lo através de comparações.

Lembre os alunos da atividade interativa e faça paralelos com ela, fazendo perguntas como: "O que você poderia comparar com a fita métrica aqui?" ou "Qual variável é semelhante ao` maxLength` da nossa atividade? ".

 

##### Módulo 25
## Objetos

### Sumário


Os estudantes têm usado a função `moveXY ()` para mover seu herói, mas nestes próximos níveis eles aprenderão sobre uma nova função chamada `move ()`. A função `move ()` difere de `moveXY ()` porque faz uso de objetos.

Objetos, também chamados de dicionários em Python, consistem em propriedades e valores. Os alunos aprenderão como criar objetos e usá-los para a nova função `move ()` para mover seus heróis durante todo o jogo.

### Metas

* Construa um objeto literal
* Use um objeto literal como argumento
 
### Atividade Instrutiva: Objetos de sala de aula (10 mins)


#### Explique (3 mins)

A função `moveXY ()` aceita uma coordenada X e Y, que são passadas como dois argumentos separados. A coordenada X é um argumento e a coordenada Y é outra.

A função `move ()` aceita apenas um argumento. O argumento ainda é uma posição com uma coordenada X e Y, mas as coordenadas são passadas como um conjunto de propriedades em um único argumento chamado **objeto literal**.

Os objetos literais são estruturas que consistem em **chaves ** para definir objetos. Cada chave é composta de uma propriedade que o objeto possui e um valor para essa propriedade.

Por exemplo, um objeto para cabelo pode ter as propriedades "cor" e "comprimento" e os valores "marrom" e "longo", respectivamente. Um objeto para uma pessoa pode ter a propriedade 'aniversário' e o valor 1/1/2000.

A sintaxe de um objeto literal é a seguinte:

`object = { 'property1':value1, 'property2':value2 }`


Observe que os nomes das propriedades estão sempre entre aspas e são separados de seus valores por dois pontos. Um objeto literal pode ter qualquer número de propriedades que sejam relevantes ou necessárias para o objeto. Se várias propriedades forem incluídas, elas serão separadas por uma vírgula.

Como mencionado acima, `move ()` aceita um objeto com uma propriedade X e uma propriedade Y para especificar as coordenadas para onde mover. Os alunos usarão objeto literal para criar um único objeto de posição que consiste nas chaves para X e Y. Isso permitirá que eles passem a posição como um único argumento que contém dois valores separados, um para a coordenada X e um para a coordenada Y . Um exemplo disso é mostrado na seguinte linha de código:

`move({ 'x':10, 'y':20 })`  

Além disso, o objeto de posição pode ser criado primeiro e, em seguida, passado como um argumento:

```
position = { 'x':10, 'y':20 }
move(position)
```

#### Interaja (5 mins)

Com a ajuda dos alunos, faça uma lista de itens ao redor da sala de aula. Conforme você escreve cada item no quadro, também registra pelo menos uma propriedade e seu valor para aquele item.

Será útil:

* Obtenha propriedades que tenham diferentes tipos de valor (por exemplo, inteiros e sequências)
* Tenha uma lista de pelo menos dez itens
* Obtenha mais de uma propriedade e valor para a maioria, se não todos, dos itens

Se os alunos sugerirem valores para um objeto, mas não para uma propriedade, incentive-os a pensar sobre qual propriedade é esse valor antes de registrar o valor no quadro.

Alguns itens sugeridos que você pode usar são:

* **borda**
	* cor preta
	* forma: retângulo
* **escrivaninha**
	* cor marrom
	* quantia: 20
* **relógio**
	* forma: redonda
	* hora: 10
* **porta**
	* cor marrom
	* polegadas: 80


Você também pode usar objetos não físicos, como:
* **almoço**
	* hora: 12
* **Recreio**
	* localização: fora
	* hora: 12,5



Depois de ter uma lista de pelo menos dez itens com propriedades e valores correspondentes, formule-os em literais de objeto usando a sintaxe do Python, por exemplo:

```
board = { 'color': 'black', 'shape': 'rectangle' }
desk = { 'color': 'brown', 'amount': 20 }
recess = { 'location': 'outside', 'hour': 12.5 }
```

Certifique-se de colocar aspas em torno de cada nome de propriedade e em torno dos valores que são sequências (em vez de números inteiros ou decimais).

Escolha alguns dos objetos literais que você criou e peça ajuda aos alunos para pensar em funções nas quais você poderia usá-los. Escreva as diferentes maneiras pelas quais você poderia passar o objeto para a função. Por exemplo:

```
recess = { 'location': 'outside', 'hour': 12.5 }
go(recess)
```
Observe que isso também pode ser escrito como:
```
go({ 'location': 'outside', 'hour': 12.5 })

```

Depois de ter dois ou três exemplos de objetos literais como argumentos de função escritos no quadro, sublinhe as propriedades e os valores em cores diferentes. Em seguida, circule a pontuação diferente usada na sintaxe, incluindo as chaves, vírgulas, vírgulas e citações em cores diferentes.

#### Reflita (2 mins)

**O que consiste um objeto literal?** (Chaves ou propriedades e valores que compõem o objeto.)<br>
**Qual é a sintaxe de um objeto literal?**(`{ 'property1':value1, 'property2':value2 }`)




### Hora da Programação (30-45 mins)



Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Lembre-os de que `move ()` funciona de maneira diferente de `moveXY ()`. Incentive os alunos a pensar sobre os objetos literais que foram criados juntos na classe e para lembrar a sintaxe usada para eles.

 


##### Módulo 26a
## Loops For (Python)
_Certifique-se de que você está usando o módulo apropriado para a linguagem de programação de sala de aula_

### Sumário
Loops `for` são semelhantes aos loops` while`, mas com sintaxe e configuração diferentes. Nesses níveis, os alunos aprenderão como usar loops `for` para fazer um loop através de matrizes e executar uma ação um certo número de vezes. Embora a curva de aprendizado inicial possa ser íngreme para alguns alunos, o fato de que o loop em si lida com o incremento deve facilitar para os alunos evitar armadilhas comuns, como loops infinitos.

### Metas

* Construa um loop `for`
* Use um laço `for` para percorrer os elementos em um array
* Use um laço `for` para executar uma ação um certo número de vezes
 

### Atividade Instrutiva: Saltar Para (10 mins)


#### Explique (3 mins)
Os loops `for` são similares aos loops` while` e podem ser usados para realizar as mesmas coisas. Loops `for` podem ser usados para percorrer os elementos em uma matriz e executar uma ação um certo número de vezes. Como loops `while`, eles podem ser aninhados também. A diferença entre os loops está na sintaxe e na configuração.


A sintaxe geral para um loop `for` é ` para X em Y`. `Y` é a matriz ou conjunto de itens a serem executados e` X` é o nome da variável que é escolhida pelo codificador para cada item para ter como ação.

O código a seguir mostra um loop for loop através de uma matriz:

```
for friend in hero.friends():
    if friend.type == 'soldier':
    enemy = friend.findNearestEnemy()
```
Este bloco de código pode ser traduzido em pseudocódigo da seguinte forma:
```
for each friend in the friends array:
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
```

Compare isso com o código de um loop while que faz a mesma coisa:

```
friendIndex = 0
while friendIndex < len(friends):
    friend = friends[friendIndex]
    if friend.type == 'soldier':
        enemy = friend.findNearestEnemy()
    friendIndex += 1
```

Este segundo bloco de código pode ser traduzido em pseudocódigo da seguinte forma:
```
create a variable friendIndex and assign it the value 0
while friendIndex is less than the amount of friends in the array:
	assign the variable friend to the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	add one to friendIndex (and run the while loop again)
```


Ao comparar o código e o pseudocódigo para ambos os loops, observe que no código de loop `for`, não há variável` friendIndex`. Ao usar um loop `for`, não há necessidade de criar uma variável para rastrear o índice e incrementá-lo, pois o Python faz isso automaticamente a cada iteração do loop. Além disso, não há necessidade de atribuir a variável `friend`, pois isso é feito na primeira linha do loop quando é inicializado.

Loops `for` também podem ser usados para executar uma instrução ou bloco de código um certo número de vezes, usando` range () `como mostrado abaixo:

```
for i in range(4):
	hero.summon("soldier")
```

O argumento para `range ()` deve ser um inteiro, e especifica quantas vezes o loop será executado. Assim, no exemplo mostrado acima, 4 soldados seriam convocados.

Note que `range ()` cria uma matriz de inteiros que começa em 0 e tem o número de elementos especificados entre parênteses. Então, 'range (4) `cria uma matriz com os inteiros 0, 1, 2 e 3. Embora a contagem não comece em 1, ela ainda garante que o loop seja executado 4 vezes.

#### Interaja (5 mins)

Para mostrar as semelhanças e diferenças entre loops `while` e` for`, a mesma atividade que foi usada para loops aninhados `while` será usada para demonstrar loops` for`. Se desejar modificá-lo, você pode optar por fazer com que os alunos executem uma ação diferente do que pular, como rir, bater palmas ou dizer uma palavra ou frase idiota.

Peça aos alunos que se enfoquem de frente para o quadro. Escreva o seguinte código no quadro:

```
for student in class.findStudents():
	for i in range(3):
		student.jump()
```


Diga aos alunos que cada um deles é um elemento na matriz de alunos que é gerado a partir da função `findStudents ()`. À medida que você percorre cada elemento da matriz, você se moverá pela linha dos alunos. Quando você chegar a um aluno, será sua vez de pular enquanto o valor de `i` estiver dentro do alcance.  
  
Peça aos alunos que percorram o código com você enquanto você aponta para cada linha. Aponte para a primeira linha e pergunte aos alunos o que eles acham que faz.Certifique-se de que eles entendam tudo o que acontece nessa linha de código:  
  
* Uma matriz de estudantes é criada usando a função `findStudents ()`  
* A variável `estudante` é dada para cada item no array conforme é executado em  
* O array inteiro é passado por um item de cada vez  
  
Aponte para a segunda linha de código e pergunte aos alunos o que ela faz.Certifique-se de que eles estejam cientes de tudo o que acontece nesta linha de código:  
  
* Uma matriz de inteiros é criada usando a função `range ()`. A matriz começa em 0 e tem 3 inteiros, 0, 1 e 2.  
* A variável `i` é dada para cada item no array à medida que é executado  
* `i` é incrementado com cada execução do loop  
* O array inteiro é passado por um item de cada vez  
  
Percorra a linha de alunos, um de cada vez, fazendo com que cada aluno pule três vezes. É muito importante avançar lentamente com isso e apontar a linha de código correspondente a cada salto e a cada mudança de aluno.  
  
Pode ser útil registrar o valor de `i` no quadro à medida que você se move pelos loops.Note que com cada novo aluno, `i` irá iniciar novamente em 0 e será incrementado toda vez que o loop` for` interno for executado.  
  
Assegure-se de que os alunos entendam que, como nos loops `while` aninhados, o loop` for` interno irá rodar durante o tempo que for possível, então o código no loop externo será executado novamente.

#### Reflita (2 mins)


**Como um loop 'for' é semelhante a um loop `while`?** (Um loop for e um loop while podem ser usados para percorrer um array e executar uma ação um certo número de vezes.)

**Como um loop `for` é diferente de um loop `while`?** (Você não precisa criar e incrementar uma variável para o índice porque o Python faz isso automaticamente para você).




### Hora da Programação (30-45 mins)



Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

 Chame a atenção dos alunos para as instruções e dicas. Lembre-os de que, depois de configurar o loop for, não é necessário incrementar variáveis ou configurá-las como um elemento na matriz. Incentive os alunos a trabalhar juntos e escreva as respostas em inglês, se estiverem presos.

 


##### Módulo 26b
## Loops For (JavaScript)
_Certifique-se de que você está usando o módulo apropriado para a linguagem de programação de sala de aula_


### Sumário
Loops `for` são semelhantes aos loops` while`, mas com sintaxe e configuração diferentes. Nesses níveis, os alunos aprenderão como usar loops `for` para fazer um loop através de matrizes e executar uma ação um certo número de vezes. Embora a curva de aprendizado inicial possa ser íngreme para alguns alunos, o fato de que o loop em si lida com o incremento deve facilitar para os alunos evitar armadilhas comuns, como loops infinitos.

### Metas

* Construa um loop `for`
* Use um laço `for` para percorrer os elementos em um array
* Use um laço `for` para executar uma ação um certo número de vezes
 

### Atividade Instrutiva: Saltar Para (10 mins)


#### Explique (3 mins)
Os loops `for` são similares aos loops` while` e podem ser usados para realizar as mesmas coisas. Loops `for` podem ser usados para percorrer os elementos em uma matriz e executar uma ação um certo número de vezes. Como loops `while`, eles podem ser aninhados também. A diferença entre os loops está na sintaxe e na configuração.


A sintaxe geral para um loop `for` é ` for (inicialização; condição; expressão) `. `initialization` é executado apenas uma vez no início da primeira iteração do loop. Inicializa uma variável a ser usada no loop.

`condition` define a condição para o loop ser executado. É frequentemente usado para avaliar a variável que é criada no segmento `initialization` para ver se ela atende a uma determinada condição. O loop continuará a ser executado enquanto a condição for `true`. Após cada vez que o loop é concluído, ele verifica se a condição é `true` e, em seguida, executa se for. Se a condição for `false`, o corpo do loop será pulado e o código abaixo da chave de fechamento do loop for for executado.

`expression` é uma expressão que atua na variável inicializada em`initialization`. Geralmente é usado para incrementar ou decrementar a variável. `expression` é executado no final de cada iteração de loop, após o corpo do loop ter sido executado.

O fluxo de controle para loops `for` é o seguinte:

1. `intialization` é executado para inicializar uma variável.
2. A condição é avaliada. Se é verdade, vá para o próximo passo. Se for `false`, move para o código após o loop.
3. O código no corpo do loop é executado.
4. `expressão/expression` é executada.
5. Repetir a partir do passo 2.


Observe que `initialization` ocorre apenas uma vez, logo no início da execução do loop. Além disso, embora a expressão seja escrita antes do corpo do loop, ela é executada após o corpo do loop.

O código a seguir mostra um loop de loop `for` através de uma matriz:

```
for(var friendIndex = 0; friendIndex < friends.length; friendIndex++) {
    var friend = friends[friendIndex];
    if(friend.type == "soldier") {
        var enemy = friend.findNearestEnemy();
    }
}
```
Este bloco de código pode ser traduzido em pseudocódigo da seguinte forma:
```
create a variable friendIndex and initialize it to be 0

if friendIndex is less than the number of friends in the array {
	initialize a variable friend to be the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	increment friendIndex by 1
	repeat the loop (from if friendIndex...)
```

Compare isso com o código de um loop while que faz a mesma coisa:
```
var friendIndex = 0;
while (friendIndex < len(friends) {
    var friend = friends[friendIndex];
    if (friend.type == "soldier") {
        enemy = friend.findNearestEnemy();
    friendIndex += 1;
```

Este segundo bloco de código pode ser traduzido em pseudocódigo da seguinte forma:

```
create a variable friendIndex and assign it the value 0
while friendIndex is less than the amount of friends in the array:
	assign the variable friend to the current element in the array
	if the friend is a soldier:
		assign the variable enemy to the friend's nearest enemy
	add one to friendIndex (and run the while loop again)
```


Ao comparar o código e o pseudocódigo para os dois loops, observe que no código do loop for, a variável friendIndex é inicializada e incrementada dentro da primeira linha do loop for. Assim, não há linhas separadas para essas ações, como existem no loop `while`.

Loops `for` também podem ser usados para executar uma instrução ou bloco de código um determinado número de vezes, conforme mostrado abaixo:

```
for (var i = 0; i < 4; i++) {
	hero.summon("soldier");
```
No exemplo mostrado acima, a variável `i` é inicializada como 0. Ela é incrementada em 1 a cada vez que o loop é executado, enquanto o` i` for menor que 4. O loop será executado 4 vezes, uma vez cada quando `i` é igual a 0, 1, 2 e 3. Assim, 4 soldados serão convocados.


#### Interaja (5 mins)

Para mostrar as semelhanças e diferenças entre loops `while` e` for`, a mesma atividade que foi usada para loops aninhados `while` será usada para demonstrar loops` for`. Se desejar modificá-lo, você pode optar por fazer com que os alunos executem uma ação diferente do que pular, como rir, bater palmas ou dizer uma palavra ou frase idiota.

Peça aos alunos que se enfoquem de frente para o quadro. Escreva o seguinte código no quadro:


```
var students = class.findStudents();

for(var studentIndex = 0; studentIndex < students.length; studentIndex++) {
    var student = students[studentIndex];
    for (var i = 0; i < 3; i++) {
        student.jump();
    }
}
```

Diga aos alunos que cada um deles é um elemento na matriz `students` que é gerado a partir da função` findStudents () `. À medida que você percorre cada elemento da matriz, você se moverá pela linha dos alunos. Quando você chegar a um aluno, será sua vez de pular enquanto o valor de 'i' for menor que 3.

Peça aos alunos que percorram o código com você enquanto você aponta para cada linha. Aponte para a primeira linha e pergunte aos alunos o que eles acham que faz. Certifique-se de que eles entendam que isso cria uma matriz de estudantes, semelhante à função `findEnemies ()` no jogo.

Aponte para a segunda linha de código e pergunte aos alunos o que ela faz. Certifique-se de que eles estejam cientes de tudo o que acontece nesta linha de código:

* A variável `studentIndex` é declarada e inicializada como 0
* Uma condição é definida para o loop ser executado apenas enquanto `studentIndex` for menor que o comprimento do array `students`
* `i` é incrementado após cada execução do loop

Em seguida, aponte para a terceira linha de código para perguntar aos alunos o que ela faz. Eles devem estar cientes de que cria uma variável chamada `student` e a define como o elemento atual da matriz` students`.

Aponte para a próxima linha e pergunte novamente aos alunos o que ela faz. Eles devem ver que esta segunda inicialização do loop `for` faz o seguinte:

* Declara e inicializa uma variável `i` para ser definida como 0
* Define uma condição para o loop ser executado apenas enquanto `i` for menor que 3
* Incrementa o `i` por 1 após cada execução do loop


Percorra a linha de alunos, um de cada vez, fazendo com que cada aluno pule três vezes. É muito importante mover-se lentamente através disso e apontar para a linha de código correspondente a cada salto e a cada mudança de aluno.

Certifique-se de apontar para cada segmento do loop `for` (inicialização, condição, corpo e expressão) conforme ele é executado para ajudar os alunos a ver visualmente o fluxo de controle.

Pode ser útil anotar os valores de `studentIndex`,` student`, `i` e` jumps` no quadro conforme você percorre os loops. Note que com cada novo aluno, `i` irá iniciar novamente em 0 e será incrementado toda vez que o loop` for` interno for executado.

Assegure-se de que os alunos entendam que, como nos loops `while` aninhados, o loop` for` interno irá rodar durante o tempo que for possível, então o código no loop externo será executado novamente.


#### Reflita (2 mins)


**Como um loop 'for' é semelhante a um loop `while`?** (Um loop for e um loop while podem ser usados para percorrer um array e executar uma ação um certo número de vezes.)

**Como um loop `for` é diferente de um loop `while`?** (Você não precisa criar e incrementar uma variável para o índice porque o Python faz isso automaticamente para você).




### Hora da Programação (30-45 mins)



Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```
Chame a atenção dos alunos para as instruções e dicas. Lembre-os de que, depois de configurar o loop `for`, não há necessidade de incrementar variáveis. Incentive os alunos a trabalhar juntos e escreva as respostas em inglês, se estiverem presos.

 
