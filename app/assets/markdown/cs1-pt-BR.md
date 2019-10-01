###### última atualização: 02/24/2017

##### Plano de Aula
# Introdução à Ciências da Computação

### Sumário do Curriculo
- Nivel: Iniciante
- 4 x 45-60 minutos de sessão de programação


#### Visão Geral
Com o ambiente certo, aprender os conceitos básicos de sintaxe formal e programação pode ser divertido e intuitivo para os alunos desde o primeiro ano. Em vez de linguagens de programação visual baseadas em blocos que impedem a compreensão correta do código pelo aluno, o CodeCombat introduz a codificação real desde o primeiro nível. Ao fortalecer suas habilidades de digitação, sintaxe e depuração, capacitamos os alunos a se sentirem capazes de construir programas reais com sucesso.

_Este guia foi escrito para aulas de Python em mente, mas pode ser facilmente adaptado para JavaScript._

### Escopo e sequência

| Módulo                                                     |             Níveis | Metas               |
| ---------------------------------------------------------- | :----------------- | :--------------------------- |
| [1. Sintaxe Básica](#basic-syntax)                           |                1-6 |Chamar funções em ordem      |
| [2. Loops](#loops)                                         |               7-14 | Repetir sequência de códigos  |
| [3. Variáveis](#variables)                                 |              15-20 | Salvar e acessar dados         |
| [4. Revisão - Arena Multiplayer](#review-multiplayer-arena) |                 21 | Sintaxe mestre e sequenciamento |

### Vocabulário Básico

**Sintaxe Básica** - a ortografia e gramática básicas de uma linguagem devem ser cuidadosamente observadas para que o código seja executado corretamente. Por exemplo, enquanto Python e JavaScript são usados para fazer coisas semelhantes no Curso 1, a sintaxe deles é visivelmente diferente, porque são linguagens de programação diferentes.

**Objeto** - um personagem ou coisa que pode executar ações.

**String** - um tipo de dados de programação que representa um texto. Tanto no Python quanto no JavaScript, as strings são representadas por texto dentro de aspas. No Curso 1, as strings são usadas para identificar objetos para o herói atacar.

**Função** - uma ação executada por um objeto.

**Argumento** - informação extra passada em um método para modificar o que o método faz. Tanto no Python quanto no JavaScript, os argumentos são representados pelo código que está dentro dos parênteses depois de um método. No Curso 1, os argumentos devem ser usados para definir inimigos antes que o herói possa atacá-los, e também podem ser usados para mover várias vezes sem escrever novas linhas de código.

**Propriedade** - dados sobre ou pertencentes a um objeto.

**Loop While** - usado para repetir ações sem que o jogador precise escrever as mesmas linhas de código repetidamente. No Python, o código que está em loop deve ser recuado abaixo da instrução while true. Em JavaScript, o código que está em loop deve ser colocado entre chaves {}. No curso 1, os loops se repetem para sempre e são usados para navegar por labirintos formados por caminhos idênticos, bem como para atacar objetos que exigem muitos golpes para derrotar (portas fortes, por exemplo).

**Variável** - um símbolo que representa dados e o valor da variável pode mudar à medida que você armazena novos dados nela. No Curso 1, as variáveis são usadas para definir primeiro um inimigo e, em seguida, passadas como um argumento para o método de ataque, para que o herói possa atacar o inimigo certo.

##### Módulo 1
<a name="basic-syntax"></a>
## Sintaxe Básica 
### Sumário

Os quebra-cabeças nesses níveis são enquadrados como labirintos para os alunos resolverem usando o Pensamento Computacional e a programação de computadores. Eles são projetados para ser uma introdução suave à sintaxe de Python por meio de um meio de comunicação. 

O herói começa em um lugar específico e tem que andar até o objetivo sem ser visto por ogros. 

Alguns alunos podem querer excluir seu código toda vez e digitar apenas o próximo passo. Explique a eles que o código deve conter todas as instruções do início ao fim, como uma história: tem um começo, um meio e um fim. Toda vez que você clica em Iniciar, o herói retorna ao começo. 

### Metas

- Use a sintaxe do Python
- Chamar funções
- Entenda que a ordem é importante

### Padrões 

- **CCSS.Math.Practice.MP1** Persevere em resolver os problemas.
- **CCSS.Math.Practice.MP6** Procure ser preciso.

### Atividade Instrutiva: Sintaxe Básica (10 mins)

#### Explique (3 mins)

**Sintaxe** é como escrevemos código. Assim como a ortografia e a gramática são importantes para escrever a prosa, a sintaxe é importante ao escrever código. Os seres humanos são bons em descobrir o que algo significa, mesmo que não seja exatamente correto, mas os computadores não são tão inteligentes e precisam que você escreva sem erros. 

- Exemplo de código: `hero.moveRight()`
- Vocabulário:   (objeto) (função)
- Leia em voz alta: “hero ponto move right”

**Objetos** são os blocos de construção do Python. São coisas ou personagens que podem executar ações. Seu herói é um objeto. Pode executar as ações de movimento.

**Funções** são ações que um objeto pode fazer. `moveRight()` é uma função. Os nomes das funções são sempre seguidos por parênteses. A ordem das funções é importante!

#### Interaja (5 mins): Robô de Reciclagem

Pratique dando instruções escritas usando funções em Python em ordem.

**Materiais:** Mesa, lixeira, bolas de papel para reciclar

Você (o professor) será o robô que a classe controla usando funções. O objetivo deste exercício é que a classe escreva coletivamente um programa como este: 

``` python
professor.pickUpBall()
professor.turnRight()
professor.moveForward()
professor.moveForward()
professor.turnLeft()
professor.moveForward()
professor.dropBall()
```

A experiência deve apresentá-los à sintaxe de Python (incluindo o ponto entre o objeto e a função e os parênteses no final) e a importância da ordem em uma sequência de instruções. 

Na frente da classe, coloque algumas bolas de papel amassadas em uma superfície plana. Coloque a lixeira a alguns passos de distância. Explique que você é um robô de reciclagem e que o trabalho da classe é programá-lo. 

O robô é um objeto Python. Qual o seu nome em Python? Seja qual você escolher, certifique-se de começar com uma letra minúscula. Escreva no quadro. 

`professor`

Para fazer o robô executar uma ação, você precisa chamar uma função. Escreva um ponto após o nome do objeto e decida com a turma qual deve ser a primeira ação. Depois do ponto, escreva o nome da função seguido por parênteses vazios. De um lado, desenhe um botão "Executar".  

`professor.pickUpBall()`

Peça a um voluntário que pressione o botão "Executar" para executar o programa e testar se ele funciona. 

_É importante que você redefina a si mesmo e as bolas de papel toda vez que o código for alterado, e execute todo o programa desde o início._

Peça aos alunos que adicionem código ao programa, um de cada vez. Se houver um erro na sintaxe, faça um sinal sonoro engraçado e pare. Peça à turma que trabalhe em conjunto para escrever e reescrever o programa até que você consiga jogar uma bola com sucesso na lixeira. 

#### Reflexão (2 mins)

**Por que a sintaxe é importante??** (Ela permite que você seja específico sobre exatamente o que você quer que aconteça.)

**A ordem importa?** (sim)

**Um humano pode entender as instruções mesmo se houver um erro na sintaxe?** (às vezes)

**Um computador consegue entender?** (não)

### Hora da Programação (30-45 mins)

**Na primeira vez os alunos precisarão criar contas**
Para obter informações adicionais sobre como ajudar os alunos a criar uma conta, Veja nosso [Guia de Iniciação do Professor](http://files.codecombat.com/docs/resources/TeacherGettingStartedGuide-pt-BR.pdf).

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas.

Se o aluno tiver dificuldade em resolver o problema, consulte a [Planilha de Ciclo de Engenharia [PDF]](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet-pt-BR.pdf) para reforçar os passos para resolver cada quebra-cabeça.

### Reflexão Escrita (5 mins)

Selecione o prompt apropriado para os alunos responderem, consultando suas anotações.

**Diga-me como jogar CodeCombat.**

> Você tem que se mover para a gema sem bater nos espinhos. Eu aprendi que você tem que digitar "herói/hero". Depois, o código de movimento. Você tem que soletrar direito e colocar () no final. MAs também mostra o que você pode digitar e selecionar. Você então clica em EXECUTAR para rodar seu código. Você pode tentar quantas vezes precisar.

**Qual é a diferença entre um objeto e uma função?**

> O objeto é o herói e ele tem funções que são coisas que ele pode fazer. O objeto tem um ponto depois dele e a função tem (). 

**Como você sabe quando cometeu um erro no seu código? Como você conserta isso?**

> Às vezes, o código não é executado porque há um erro. É indicado em vermelho a linha com erro para tentar ajudá-lo!. Mas você precisa ler o código para descobrir o que está errado.

**Por que o seu herói está no Kithgard Dungeon? Qual é a sua missão? Você é um cara bom ou mau?**
_(escreva a sua própria história de fundo)_

Fui para as Masmorras de Kithgard Dungeon roubar pedras dos ogros. Eu preciso de um monte de pedras preciosas para pagar o resgate para a minha aldeia, caso contrário, um grande monstro intimidador irá destruí-la e minha família ficará desabrigada. Eu acho que sou um cara legal, mas os ogros provavelmente pensam que eu sou ruim porque eu estou roubando deles. 


##### Módulo 2
<a name="loops"></a>
## Loops

### Sumário

Até agora, os alunos tiveram que escrever longas sequências de ações sem atalhos. Esses níveis introduzem loops, o que lhes permite obter mais com menos linhas de código. 

Os quebra-cabeças desta seção são mais difíceis de resolver do que no primeiro módulo. Encoraje a colaboração entre os alunos, pois eles precisam primeiro entender qual é o objetivo deles, depois planejem uma estratégia para resolver o nível e, em seguida, ponham esse plano em prática. 

### Metas

- Escreva um loop infinito
- Quebre um problema em pedaços menores
- Decidir quais partes de uma ação se repetem

### Padrões
- **CCSS.Math.Practice.MP1** Persevere em resolver os problemas.
- **CCSS.Math.Practice.MP8** Procure e expresse regularidade em um raciocínio repetido.

### Atividade instrutiva: Loops (10 mins)

#### Explique (3 mins)

Um **loop**  é uma maneira de repetir o código. Uma maneira de escrever loops é usar a palavra-chave _while, _ seguida por  uma **expressão**, que pode ser avaliada como True ou False. _ while_ é uma palavra especial que diz ao computador para avaliar (ou resolver) o que vem depois dele e, em seguida, executar as ações abaixo até que a expressão se torne Falsa.

Estes níveis no CodeCombat requerem um **loop infinito**, ou um loop que repete para sempre.  Para isso, precisamos de uma expressão que seja sempre verdadeira. Por sorte, _True_ é um atalho do Python que sempre é avaliado como Verdadeiro!

Abaixo, `while` é a palavra chave, e `True` é ume expressão
``` python
while True: 
    hero.moveRight()  # ação
    hero.moveUp()     # outra ação
```

Você pode colocar quantas linhas de código quiser dentro do loop. Todos eles precisam ser indentados com quatro espaços. É assim que o Python sabe que eles fazem parte do loop. A indentação é uma parte importante do Python! Sempre que você tiver um problema com seu código, verifique primeiro a indentação. 

#### Interaja (5 mins)

Como turma, pense em quantas maneiras possíveis de escrever uma ação repetitiva em inglês. (Use os exemplos a seguir se os alunos tiverem dificuldade em pensar por conta própria.) 

Circule as palavras em inglês que dizem que é um loop. Reescreva estas instruções usando `while`. Verifique a indentação. Rotule cada parte como palavra-chave, expressão ou ação. Aqui estão alguns exemplos para você começar:

Continue caminhando **até** você chegar na porta. _While/Enquanto você não está na porta, continue andando._
``` python
while door == 0: 
    walk()
```

Jogue a bola 5 **vezes**. _While/Enquanto for menor que 5, continue jogando a bola._

``` python
while bounces < 5: 
    ball.bounce()
```

Jogue fora **todo** brinquedo. _While/Enquanto ainda existem brinquedos, jogue um brinquedo fora._

``` python
while toys > 0: 
    putAway(toy)
```

Peça aos alunos que se revezem escrevendo, verificando e rotulando o código até que se torne fácil. 

#### Reflexão (2 mins)

**O que é um loop?** (uma maneira de repetir ações)

**O que é uma expressão?** (algo que é verdadeiro ou falso, geralmente usando =, <, ou >)

**Como você escreve um loop que nunca termina?** (Use `while True`)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas.

Se o aluno tiver dificuldade em resolver o problema, consulte a [Planilha de Ciclo de Engenharia [PDF]](http://files.codecombat.com/docs/resources/EngineeringCycleWorksheet-pt-BR.pdf) como uma ferramenta de ajuda, ou peça-lhes para seguir esta lista:

1.Leia os comentários linha por linha
2. Leia seu código linha por linha
3. Leia as dicas
4. Explique o problema que você está tendo para um colega
5. Pressione o botão de reiniciar e tente novamente
6. Pergunte ao professor

### Reflexão Escrita (5 mins)

**Diga-me como você usou um atalho para economizar tempo e esforço.**

Eu usei While True para fazer meu código repetir para sempre. Eu tive que lembrar de colocar quatro espaços em cada linha. É bom porque você não precisa digitar todo o código. 

**Quais são as coisas que você tem que lembrar para escrever um loop infinito?**

> Você tem que digitar While True, e lembre-se de colocar : depois dele. Na próxima linha, coloque quatro espaços antes do seu código. Se você quiser que mais de uma linha seja repetida, todas elas precisam ter quatro espaços. 

**Você pode me dar dicas sobre como resolver esses tipos de níveis? Dê um exemplo.**
> Você tem que ver quais são as coisas que se repetem. Às vezes é apenas uma coisa e, às vezes, são muitas coisas. Por exemplo, no Haunted Kithmaze você vai para um beco sem saída se você colocar  moveRight () no loop porque ele vai apenas para a direita, depois para a direita, e depois para a direita. Você também tem que fazer o moveUp (), então ele vai para a direita, para cima, para a direita, para cima. 


##### Módulo 3
<a name="variables"></a>
## Variáveis

### Sumário

Estes níveis introduzem a mecânica de ataque no jogo. Os ataques não funcionarão a menos que você especifique quem atacar (`hero.attack()` está errado; `hero.attack(jeremy)` é o correto.) 

Alguns desses quebra-cabeças podem ser difíceis para alguns estudantes. Certifique-se de que leiam as instruções completamente e compreendam o objetivo de cada nível. O desafio depende de não saber os nomes dos objetos que você deseja manipular. Pense em variáveis como apelidos para se referir a objetos quando você não sabe mais o que chamar.  

### Metas
- Criar uma variável
- Usar uma variável como argumento
- Escolher o nome apropriado para a variável

### Padrões

- **CCSS.Math.Practice.MP1** Persevere em resolver os problemas.
- **CCSS.Math.Practice.MP2** Razão abstrata e quantitativa.

### Atividade instrutiva: variáveis (10 mins)

#### Explique (3 mins)

Uma **variável** mantém seus dados para serem usados mais tarde. Você faz uma variável dando-lhe um nome, depois dizendo qual **valor** ela deve manter. 

`enemy = “Kratt”`

A variável `enemy` mantém (`=`) o valor `"Kratt"`

Agora você pode usar sua variável em vez do próprio valor!

`hero.attack(“Kratt”)` é o mesmo que `hero.attack(enemy)`

Assim, uma variável pode representar um valor. 

Variáveis também podem ser alteradas e verificadas. Você poderia dizer "pontuação = 0" e depois "pontuação = 1". Ou você poderia usar sua variável em uma expressão em loop, exemplo `while score < 10:` 

#### Interaja (5 mins)

Com a turma, discuta seus preconceitos da palavra "variável". 

Em matemática, é um símbolo que representa um número, que você geralmente está resolvendo.

Na ciência, é parte de um experimento que pode mudar e ser observado. 

Quais aspectos das variáveis de programação são parecidos com as variáveis de matemática e quais são como as de ciência? 

#### Reflexão (2 mins)

**Como você cria uma variável?** (variável = alguma coisa)

**Como você pode usar uma variável?** (Representando um valor, verificando em um loop)

**Você pode usar uma variável antes de criá-la?** (Não, ainda não existe!)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas.

Concentre-se em comunicar claramente a meta do nível e descreva o problema que está enfrentando no momento. Lembre os alunos de lerem o código do início ao fim antes de pedir ajuda. A maioria dos problemas pode ser resolvida inserindo-se aspas ausentes ou corrigindo-se a indentação. 

### Reflexão Escrita (5 mins)

**Qual foi o quebra-cabeça mais difícil que você resolveu hoje? Como você resolveu isso?**
> 15 foi um nível difícil. Havia muitos inimigos e eu morri. Então eu fiz um loop de ataque, mas eu não sabia o nome de quem atacar. Então eu cliquei nos óculos e ele disse que eu poderia usar `findNearestEnemy`, mas não funcionou sem dizer `enemy =`. Então eu pude fazer `attack(enemy)` e funcionou. 

**Escreva um manual do usuário para findNearestEnemy.**

> O herói pode ver qual inimigo está mais próximo escrevendo `hero.findNearestEnemy()`. Mas você tem que lembrar qual deles está em uma variável. Você pode dizer `enemy = hero.findNearestEnemy()`. Então você pode atacar o inimigo na próxima linha dizendo `hero.attack(enemy)`. 


##### Módulo 4
<a name="review-multiplayer-arena"></a>
## Revisão - Arena Multiplayer 
### Sumário 

O nível arena é uma recompensa por completar o trabalho necessário. Os alunos que ficaram para trás nos níveis ou que não completaram suas reflexões escritas devem usar esse tempo para terminar. À medida que os alunos entregam seu trabalho, eles podem entrar na arena Wakka Maul e tentar várias soluções até que o tempo acabe. 

Veja o [Guia dos Níveis Arena](/teachers/resources/arenas) para mais detalhes.

### Metas
- Escreva a sintaxe precisa em Python
- Depurar programas em Python
- Refinar soluções com base em observações

### Padrões
- **CCSS.Math.Practice.MP1** Persevere em resolver os problemas.
- **CCSS.Math.Practice.MP2** Razão abstrata e quantitativa.
- **CCSS.Math.Practice.MP6** Seja preciso.

### Hora da Programação (40-55 mins)

Peça aos alunos que sigam até o último nível **Wakka Maul**, e completá-lo em seu próprio ritmo. 

#### Rankings

Quando os alunos vencerem o computador padrão, eles serão colocados no ranking de classe. As equipes vermelhas só lutam contra equipes azuis e haverá classificações para cada equipe. Os alunos só competirão com o computador e com outros alunos da sua turma no CodeCombat .

Note que os rankings de classe são claramente visíveis. Se alguns alunos forem intimidados pela competição ou por serem classificados publicamente, dê a eles a opção de um exercício de escrita: 

- Escreva um passo a passo ou um guia para o seu nível favorito
- Escreva uma resenha do jogo
- Projete um novo nível

#### Dividindo a turma

Os alunos devem escolher uma equipe para participar: Vermelho ou Azul.  É importante dividir a turma, pois a maioria dos alunos escolherá vermelho. Não importa se os lados estão equilibrados, mas é importante que existam jogadores para ambos os lados. 

- Divida a classe em duas, aleatoriamente, a partir de um baralho de cartas.
- Alunos que entregam seu trabalho cedo juntam-se à equipe azul, e os retardatários jogam no time vermelho.

#### Refinando o Código

O código para o Wakka Maul pode ser enviado mais de uma vez. Incentive seus alunos a enviar o código, observe como ele se comporta em relação aos colegas de classe e, em seguida, faça melhorias e reenvie. Além disso, os alunos que concluíram o código de uma equipe podem criar código para a outra equipe.

### Reflexão (5 mins)

**Discussão em classe: Como codificar uma solução é diferente de controlar um herói em tempo real?**

Você tem jogado um jogo que requer que você pense sobre um plano inteiro com antecedência, então deixe o herói executar suas instruções sem intervenção. Isso difere drasticamente da forma tradicional de jogar videogame controlando diretamente o herói e tomando decisões enquanto o jogo está sendo executado. Fale sobre como essas diferenças . Qual é mais divertido? Que é mais difícil? Como sua estratégia muda? Como você lida com erros? 
