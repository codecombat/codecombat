###### Última atualização: 09/14/2016

##### Planos de Aula
# Ciência da Computação 2

### Sumário do Currículo
- Pré-requisito Recomendado: Introdução à Ciência da Computação
- 6 sessões de programação de 45 a 60 minutos

#### Visão Geral
Armados com conhecimento básico da estrutura e sintaxe de programas simples, os alunos estão prontos para abordar tópicos mais avançados. Condicionais, funções e eventos, oh meu Deus! A Ciência da Computação 2 é onde os alunos passam do estágio de programação de personagens para escrever código semelhante ao que usariam no próximo grande software ou aplicativo!

Em Ciência da Computação 2, os alunos continuarão a aprender os fundamentos (sintaxe básica, argumentos, strings, variáveis e loops), além de serem introduzidos a um segundo nível de conceitos para serem dominados. Declarações if permitirem que o aluno realize ações diferentes dependendo do estado do campo de batalha. As funções permitem que os alunos organizem seu código em partes reutilizáveis da lógica e, quando os alunos puderem escrever funções básicas, eles começarão a escrever códigos para lidar com eventos - que é a base para muitos padrões de codificação no desenvolvimento de jogos, desenvolvimento da Web e desenvolvimento de aplicativos.

_Este guia foi escrito com salas de aula em linguagem Python em mente, mas pode ser facilmente adaptado para JavaScript._

### Escopo e sequência


| Módulo                                                        | Primeiro Nível           | Metas                     |
| ------------------------------------------------------------- | :-------------------- | :--------------------------------- |
| [5. Condicionais (if)](#condicionais-if)                      | Defesa de Plainswood | Verifique a expressão antes de executar  |
| [6. Condicionais (else)](#condicionais-else)                  | De volta para trás          | Executar código padrão               |
| [7. Condicionais Aninhadas](#condicionais-aninhadas)          | Dança do Incêndio Florestal   | Coloque uma condicional dentro de outra |
| [8. Funções](#funcoes)                                        | Village Rover         | Salvar código para mais tarde                |
| [9. Eventos](#eventos)                                        | Amigo de sertão       | Ouça eventos e execute códigos |
| [10. Revisão - Arena Multiplayer](#revisao-arena-multiplayer) | Pico de energia          | Projetar e implementar algoritmos    |

### Vocabulário Básico

**Objeto** - m personagem ou coisa que pode executar ações. Objetos são os blocos de construção do Python. São coisas ou personagens que podem executar ações. Seu `hero/herói` é um objeto. Pode executar as ações de movimento. Em `hero.moveRight()`, o objeto é`hero`. No Curso 2, os alunos também estarão usando o objeto `pet` para realizar ações.

**Função** - uma ação executada por um objeto. Funções são ações que um objeto pode fazer. `moveRight()` é uma função. Os nomes das funções são sempre seguidos por parênteses.

**Argumento** - informações adicionais para uma função. Argumentos são o que colocamos dentro dos parênteses de uma função. Eles dizem a função mais informações sobre o que deveria fazer. Em `hero.attack(enemy)`, `enemy` é um argumento.

**Loop** - código que se repete. Um loop é uma maneira de repetir o código. Uma maneira de escrever loops usa-se a palavra-chave `while`, fseguido por uma expressão que pode ser avaliada como `True` ou `False`.

**Variável** - um detentor de dados. Uma variável mantém seus dados para mais tarde. Você cria uma variável dando um nome a ela e, em seguida, informando qual valor ela deve conter.

**Conditional** - O bloco de construção da programação moderna, a condicional. É nomeada como tal por causa de sua capacidade de verificar as condições no momento e realizar diferentes ações, dependendo da expressão. O jogador não é mais capaz de assumir que haverá um inimigo para atacar, ou se há uma gema para agarrar. Agora, eles precisam verificar se existe, verificar se as habilidades estão prontas e verificar se um inimigo está próximo o suficiente para atacar.

**Evento** - um objeto representando algo que aconteceu. Os alunos podem escrever código para responder a eventos: quando esse tipo de evento acontece, execute essa função. Isso é chamado de manipulação de eventos, e é um padrão de programação muito útil e uma alternativa para um loop while infinito.


#### Atividades extras para os alunos que concluírem o segundo curso mais cedo:
- Ajude outra pessoa
- Refine uma estratégia de arena multiplayer no Power Peak
- Escreva um passo a passo
- Escreva uma resenha do jogo
- Escreva um guia para o seu nível favorito
- Projetar um novo nível

##### Módulo 5
## Condicionais (If)

### Sumário

O curso 2 introduz conceitos de programação mais avançados, portanto o progresso nos níveis deve ser mais lento. Preste muita atenção às instruções, para que você saiba qual é o objetivo do nível e para os comentários em linha (denotados com um `#`) para saber qual código está faltando.

### Metas
- Construa uma condicional
- Escolha expressões apropriadas
- Avaliar expressões

### Standards
**CCSS.Math.Practice.MP1** Persevere em resolver os problemas.
**CCSS.Math.Practice.MP2** Razão abstrata e quantitativa.
**CCSS.Math.Practice.MP4** Modelo com matemática.
**CCSS.Math.Practice.MP7** Procure e faça uso da estrutura.

### Atividade instrutiva: condicionais (10 mins)
#### Explique (2 mins)

Condicionais executam código dependendo do estado do jogo. Eles começam avaliando uma declaração como `True` ou` False`, então eles executam o código somente se a declaração for `True`. Observe que a sintaxe é semelhante a um loop, pois precisa de dois pontos e um recuo de quatro espaços.

`if` é a palavra-chave e `==` é a expressão
``` python
if enemy == “Kratt”:
    attack(enemy)  # Está é a ação
```

A palavra-chave para uma condição é `if`. Um condicional irá funcionar apenas uma vez, mas se você quiser continuar checando, você tem que colocá-lo dentro de um loop. Observe como o recuo funciona.


``` python
while true:
    if enemy == “Kratt”:
        attack(enemy)
```

#### Interaja (5 mins)
Reescreva suas regras de sala de aula como condicionais usando a sintaxe do Python.


Identifique algumas regras da escola ou da sala de aula e escreva-as no quadro, por exemplo
- Levante sua mão para fazer uma pergunta.
- Você tem uma advertência se estiver atrasado.
- Pare de falar quando o professor bater palmas duas vezes.

Agora reformule novamente usando a sintaxe de Python, por exemplo

``` python
if student.hasQuestion():
    student.raise(hand)
```
``` python
if student.arrivalTime > class.startTime:
    teacher.giveDetention(student)
```
``` python
if teacher.claps == 2:
    class.volume = 0
```

Rotule cada uma das partes das condicionais: * palavra-chave *, * expressão *, * ação *.

#### Explique (1 min)
O código é chamado de código porque estamos codificando nossas ideias em uma linguagem que o computador possa entender. Você pode usar esse processo de três etapas para reformular suas ideias sempre que estiver escrevendo um código. Contanto que você conheça a sintaxe da linguagem de programação, você sabe como deve ser a ideia codificada!


#### Reflita (2 mins)
** Por que precisamos de condicionais? ** (nem todas as ações acontecem o tempo todo)
** Qual é a parte que vem entre o if e os dois pontos? ** (uma expressão)
** O que é importante saber sobre as expressões? ** (Eles precisam ser verdadeiros ou falsos)

### Hora da Programação (30-45 mins)
Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Meta: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

ircule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Os alunos precisarão usar coordenadas (x, y) para especificar locais. Coordenadas exatas podem ser encontradas colocando o ponteiro do mouse sobre a posição desejada. Os alunos também terão que usar uma condicional para verificar se uma condição é atendida antes de executar uma ação.

### Reflexão Escrita (5 mins)

** O que if significa? Que tipo de coisas você escreveu depois?
> Se o código só for verdadeiro. Você pode ver se todos os tipos de coisas são verdadeiras, como se sua arma estivesse pronta ou se o inimigo estivesse próximo. Às vezes você precisa == ou>, mas às vezes você só precisa do ().


** Se você pudesse criar um nível de CodeCombat, como seria? **
> Haveria muitos ogros e você tem que atacá-los, mas não os humanos. E você protegeria a aldeia construindo muros e fogueiras.


##### Módulo 6
## Condicionais (Else)
### Sumário

Esses níveis têm duas coisas acontecendo ao mesmo tempo. Os alunos têm que decidir sob qual condição fazer cada ação. Este é um bom ponto para ter uma discussão de dicas e truques, onde qualquer aluno que queira compartilhar uma descoberta ou um atalho com a turma pode apresentar seus conselhos.

### Metas
- Construa uma condicional if-else.
- Identificar diferentes ações que ocorrem em diferentes circunstâncias.
- Defina `else` como o oposto de` if`.


### Atividade Instrutiva: Condicionais (Else) (10 mins)

#### Explique (2 mins)
Estamos acostumados a usar condicionais para fazer algo se a expressão for `Verdadeira`, mas e se for `Falso`? É aí que `else` entra. `Else` significa `se não` ou `caso contrário` ou `o oposto`.

Observe que `else` deve ser indentado com o mesmo número de espaços que o if. E também precisa de dois pontos: `:` como `if`.

Abaixo, `if` e` else` são palavras-chave, e `==` é a expressão
``` python
if today == weekday:
    goToSchool() # action
else:  # keyword
    watchCartoons() # action
```


#### Interaja (6 mins)
Revise as regras da sala de aula da lição anterior e veja se há necessidade de outras declarações, por exemplo,

``` python
if student.hasQuestion():
    student.raise(hand)
else:
    student.payAttention()
```

``` python
if student.arrivalTime > class.startTime:
    teacher.giveDetention(student)
else:
    teacher.markPresent(student)
```

``` python
if teacher.claps == 2:
    class.volume = 0
# this doesn’t need an else because no action is taken if the teacher doesn't clap
```

Rotule as partes dessas condicionais: _palavras-chave_ (`if` e` else`), _expressões_, _ações_

#### Reflita (2 mins)
**O que else significa?** (senão)
**Por que não vem com outra expressão??** (a expressão está implícita - é o oposto do if, ou quando o if é falso)
**Você sempre precisa de um else?** (não, depende da situação)

### Hora da Programação (30-45 mins)
Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos usar o seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso[PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Meta: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```


### Reflexão Escrita (5 mins)
**Sabe mais código agora do que no começo? Que poderes você tem agora que não podia fazer antes?**
>No começo eu podia simplesmente andar por aí. Agora eu posso atacar inimigos e ver quem está mais próximo. Eu também posso colocar meu mouse na tela e ver as coordenadas. Eu posso usar if e mais para fazer duas coisas diferentes. E eu posso usar um loop para fazer meu código repetir.

**Que conselho você pode dar a alguém que está começando o jogo? **
>Leia as instruções. Primeiro, descubra o que você quer fazer e depois se preocupe com o código. Você tem que colocar: depois de passar True e if. E você tem que usar quatro espaços de cada vez. Na maioria das vezes, o nível lhe dirá o que fazer na escrita azul e você só precisa fazê-lo. Você pode usar suas gemas para comprar coisas.

**O que você faz quando você não sabe o que fazer?**
>Eu pergunto à pessoa ao meu lado se eles fizeram esse nível. Se eu estou à frente, eu olho para ele mais um pouco até que eles se atualizem. Então nós trabalhamos juntos. Ou peço ao professor. Às vezes a resposta está na ajuda ou no texto azul.

##### Módulo 7
## Condicionais Aninhadas
### Sumário

Programação séria começa agora. Os alunos terão que lembrar como construir condicionais e expressões, ou consultar as dicas abaixo do editor de código. Esses níveis têm três ou mais ações para controlar, de modo que exigem pensamento e planejamento complexos. Até três níveis de recuo são usados, portanto, verificar espaços é vital para escrever código que é executado.

### Metas
- Construir uma condicional aninhada
- Leia e compreenda uma condicional aninhada
- Entenda a indentação


### Atividade instrutiva: condicionais aninhadas (10 mins)

#### Explique (3 mins)
Nós começamos com condicionais verificando uma coisa antes de tomarmos uma ação. Então nós tivemos duas ações para fazer e tivemos que decidir qual delas fazer quando. Mas às vezes você tem mais do que duas coisas que você quer fazer. É quando você quer colocar um condicional dentro de outro condicional.

 primeira condicional abaixo é "se for um final de semana", a segunda condicional (aninhada) é "se eu tiver um jogo de futebol".
``` python
if it’s a weekend:
    if I have a soccer game:
        Wake up at 6
    else:
        Sleep in
else:
    Wake up at 7
```

A indentação começa a importar muito agora. Recuamos quatro espaços para colocar o código dentro de um loop ou condicional, e isso inclui outros condicionais. O código dentro da segunda condicional é recuado em um total de oito espaços.

#### Atividade (5 mins)

Peça aos alunos que escrevam a hora que acordam, hora de dormir ou de recreio como condicionais aninhados. Faça pelo menos três ações diferentes, então você precisa usar uma condição aninhada.

Quando terminarem, troque papéis com um parceiro. Leia os horários uns dos outros e discuta-os. Verifique a sintaxe e o recuo.

Convide voluntários para compartilharem seus horários acabados com a turma.

#### Reflita (2 mins)
**Por que precisamos de condicionais aninhadas?** (Porque às vezes são possíveis mais de duas ações diferentes
**Por que indentamos a segunda condicional por 4 espaços?** (Para mostrar que está dentro da primeira condicional.)
**O que significa quando uma ação é indentada com 8 espaços?** (Depende de duas expressões sendo True ou False)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos usar o seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso[PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Meta: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

### Reflexão Escrita (5 mins)
**Fale-me sobre cleave.**
>Cleave esmaga um monte de inimigos ao seu redor. Você faz isso dizendo hero.cleave (). Você tem que colocar (), mas você não precisa dizer cleave (inimigo). Apenas faz isso para todos. A Cleave demora um pouco para se aquecer, você pode verificar se ela está pronta com o relógio e, se ainda não estiver pronta, faça um ataque normal.

**Debate: O seu herói é um cara bom ou um cara mau?**
>Meu herói é uma espécie de bom rapaz e um cara malvado. Ele é um cara legal porque ele protege os aldeões de se machucar. Mas ele é um cara mau porque roubou as gemas dos ogros da masmorra. E ele mata pessoas. Talvez ele deva proteger as pessoas sem matar e não roubar.

### Escrevendo Checkpoint: Condicionais

**O que é uma condição? Quantas maneiras diferentes você pode escrever uma condicional? Dê um exemplo.**
>Uma condicional pergunta "if". Você pode dizer se algo é verdade, então faça alguma coisa. Você pode usar else if para fazer algo se a primeira coisa não for verdadeira. Elif é para se você quiser fazer três coisas, como se estivesse chovendo usar um casaco, e se está nevando usar um chapéu com uma camiseta. Você pode colocar ifs dentro de outros ifs, mas você precisa lembrar o número correto de espaços.

**O que é elif? É um elfo?**
>Elif significa "outra coisa se/else if". Você o usa para fazer três coisas ao invés de duas com if. É como um elfo porque é complicado.
**Me fale sobre os espaços.**
>Você usa quatro espaços para fazer o código em loop ou condicional como while True, if, else ou elif. Se um if estiver dentro de outro if, você terá que usar oito espaços. É importante contar os espaços e acertá-los exatamente, ou o computador acha que você quer dizer algo diferente. Você tem que ter muito cuidado.


#### Módulo 8
## Funções
### Sumário
Esses níveis dão aos alunos a chance de pegar alguns atalhos. Assim como os loops deram a eles o poder de escrever mais código rapidamente, as funções permitem a reutilização do código. A sintaxe continua sendo vital; Portanto, verifique se os dois pontos e a indentação estão no lugar certo e lembre-se de ler e entender as instruções de cada nível antes de começar a codificar uma solução.

### Metas
- Identifique funções.
- Construa uma definição de função.
- Chame uma função.
 

### Atividade Instrutiva: Funções (10 mins)
#### Explique
ocê já usou funções! Quando você digita `hero.cleave ()`, `cleave ()` é uma função. Até agora você só usou funções internas, mas também pode escrever suas próprias. Primeiro, você precisa definir a função usando `def

``` python
def getReady():
    hero.wash(face)
    hero.brush(teeth)
    hero.putOn(armor)
```

Então você precisa chamar a função.
``` python
getReady()
```

**Qual é a diferença entre definir e chamar?** (Para definir precisa de um def antes e dois pontos depois. Então tem algum código indentado sob ele. Ambos têm parênteses.)

Os programadores usam funções para tornar seu código fácil de ler e rápido de escrever. É como uma jogada de basquete: você sabe lançar, driblar e passar, então você pode criar uma função que combine essas partes e dê um nome a ela.

``` python
def out-over-up():
    p1.driblar()
    p1.passar(p2)
    p2.lançar()
```

Então, quando o treinador quer que essa sequência de ações aconteça, ela apenas chama o nome da peça: “Out-over-up!”

### Interaja (5 mins)
**Simon Diz.**

Como uma classe, escreva suas próprias funções para movimentos complicados do Simon Diz no quadro usando a sintaxe do Python. Aqui estão alguns exemplos para você começar:

``` python
def pogo():
    student.handsOn(hips)
    student.jump()
```

``` python
def pipoca():
    if student.sittingDown():
        student.standUp()
    else:
        student.sitDown()
```


Então, Simon fala chamando as funções, por ex.
- Simon diz levante a mão!
- Simon diz pipoca!
- Pogo! (Simon não disse)

### Reflita (2 mins)
**Por que as funções facilitam a codificação?** (Porque você não precisa dizer as etapas complicadas toda vez; basta usar o nome da função.)
**Por que é importante dar bons nomes às suas funções?** (Então você pode lembrar para o que eles são para mais tarde.)
**O que a palavra-chave def significa?** (definir)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos usar o seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso[PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Meta: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```


### Reflexão Escrita (5 mins)

**Por que as funções são úteis? Quando eles não seriam úteis?**
>Eles fazem com que você não precise escrever o mesmo código várias vezes e eles facilitam a leitura do código. Eu não acho que seja útil se você colocar apenas uma linha de código na sua função. Seria mais fácil apenas escrever essa linha toda vez.


##### Module 9
## Eventos
### Sumário
Um ** evento ** é um objeto que representa algo que aconteceu. Os alunos podem escrever código para responder a eventos: quando esse tipo de evento acontece, execute essa função. Isso é chamado de manipulação de eventos, e é um padrão de programação muito útil e uma alternativa para um loop while infinito.

### Metas
- Ouça eventos e execute código
- Use o tratamento de eventos para controlar um animal de estimação
- Escrever código simultâneo, misturando execução direta e manipulação de eventos

### Atividade Instrutiva: Professor Presidente (12 mins)
#### Explique (2 mins)
Até agora, você tem escrito código que é executado uma vez, de cima para baixo: primeiro faça isso, então faça isso, então faça isso *. Você também aprendeu a escrever loops while, onde você pode dizer, * então faça isso para sempre . Usando a manipulação de eventos, agora você tem uma maneira de dizer,  **quando** isso acontece, **então** faça isso *. É como se fosse uma declaração if, exceto que os eventos podem acontecer a qualquer momento, não apenas quando você está verificando-os.

#### Interaja (8 mins)
Explique à classe que você está esperando por uma ligação importante do Palácio do Planalto sobre se você foi eleito o próximo presidente. Você vai escrever um programa para atender o telefone quando ele tocar usando um loop while e um if, mas sem eventos ainda:

``` python
while True:
    if phone.isRinging:
        teacher.answer(phone)
```

Mas isso é chato, já que você não está fazendo mais nada. Então você vai avaliar o dever de casa enquanto espera:

``` python
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
    if phone.isRinging:
        teacher.answer(phone)
```


Diga que cada trabalho leva cinco minutos para ser avaliado. Pergunte à classe o que provavelmente acontecerá se você estiver executando esse programa e receber um telefonema do Palácio do Planalto. (Você provavelmente estará no meio da classificação do jornal e só verificará se o telefone está tocando a cada cinco minutos, assim você provavelmente perderá a ligação e não conseguirá ser o Presidente.)

Agora reescreva o programa para usar o tratamento de eventos, explicando como você **ouve** os eventos para que, quando eles acontecerem, você possa **manipulá-los** executando uma função:

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("toca", answerPhone)
```

Explique que você pronuncia isso como: "No evento `toca` do telefone, execute a função `answerPhone`.  Agora, diga que você quer avaliar os papéis enquanto espera, basta adicionar um loop while e, quando o evento acontecer, interromperá sua avaliação para que você possa atender ao telefone e se tornar presidente:

``` python
def answerPhone():
    teacher.answer(phone)

phone.on("tocar", answerPhone)
while True:
    paper = teacher.findNextPaper()
    teacher.grade(paper)
```

Explique que o `phone.on (" tocar ", answerPhone)` faz com que seu código comece a escutar o evento `ring`, e note que **você não usa parênteses** na função com a qual está escutando: `answerPhone`, não` answerPhone () `. Isto é porque você está dizendo ao código o nome da função a ser executada, mas você não está **ainda executando**. (Os parênteses executariam a função imediatamente.)

Peça à classe mais exemplos de eventos e funções que possam responder a elas e escreva-os no quadro, algo assim:

``` python
student.on("wake", goBackToSleep)
dog.on("hear", obeyMaster)
goal.on("touchBall", increaseScore)
bigRedButton.on("press", initiateSelfDestruct)
```


#### Reflita (2 mins)
**O que você usa para manipulação de eventos?** (Para executar uma função quando algo acontece a função.)
**Que tipo de dados é um nome de evento?** (O nome do evento que você ouve é uma string.)
**Por que você não usa parênteses de função quando começa a ouvir um evento?** (Os parênteses tornariam a função executada agora e você deseja executá-la mais tarde quando o evento acontecer.)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos usar o seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso[PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Meta: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```


### Reflexão Escrita (5 mins)
Selecione o (s) prompt (s) apropriado (s) para os alunos responderem, referindo-se às suas anotações.

**Me fale sobre o gato.**
>Eu tenho um gato de estimação e é um puma ou uma leoa. Havia uma função que dizia miau, e o gato esperou até você falar com ele e depois disse miau. Eu acho que o gato deve ajudar a protegê-lo dos inimigos. Você deve ser capaz de fazer outras coisas por comandos, como pular e morder.

**Os eventos são realmente úteis no desenvolvimento de jogos. Adivinhe os nomes de pelo menos três tipos de eventos que você acha que podem acontecer no código dos jogos que você gosta de jogar.**p
>Em Minecraft pode haver um evento de "explosão" quando uma trepadeira explode. No xadrez, pode haver um evento "xeque-mate". Em Bejeweled pode haver um evento "combo".


##### Módulo 10
## Revisão - Arena Multiplayer
### Summary

O nível da arena é uma recompensa por completar o trabalho necessário. Os alunos que ficaram para trás nos níveis ou que não completaram suas reflexões escritas devem usar esse tempo para terminar. À medida que os alunos entregam seus trabalhos, eles podem entrar na arena Power Peak e tentar várias soluções até que o tempo seja chamado.

Veja o [Guia de Níveis Arena](/teachers/resources/arenas) para mais detalhes.

### Metas
- Projete um algoritmo para resolver um problema.
- Implemente um algoritmo em Python.
- Depure um programa em Python.

### Atividade Instrutiva: Ciclo de Engenharia (10 mins)
#### Explique (3 mins)
Engenharia é tudo sobre como resolver problemas, mas a primeira regra da engenharia é que ninguém acerta da primeira vez. É aí que entra o ciclo de engenharia:

Primeiro, nós PROJETAMOS uma solução para o nosso problema. Isso inclui descobrir qual é o problema e dividi-lo em partes menores. Então, IMPLEMENTAMOS esse design, que coloca nossas ideias em ação com o código. Terceiro, testamos nossa implementação. Funciona? Isso resolve o problema? Se nosso teste falhar, temos que decidir se foi por causa do PROJETO ou da IMPLEMENTAÇÃO.

Então continuamos projetando, implementando e testando até que o problema seja resolvido!

#### Reflita (2 mins)
**Quais são as etapas do ciclo de engenharia?** (Projetar, implementar, testar)
**Quando o Ciclo de Engenharia é interrompido? ** (Quando o problema é resolvido, ou você fica sem tempo)

#### Interaja (5 mins)
Como classe, faça uma lista de todas as coisas que seu herói pode fazer (funções). Use vocabulário apropriado. Anote com quaisquer dicas ou trechos de código que os alunos julguem úteis.
`moveUp()`, `moveDown()`, `moveLeft()`, `moveRight()`
`moveToXY(x,y)`
`attack(something)`

### Hora da Programação (30-45 mins)

Peça aos alunos que naveguem até o último nível, **Pico de Poder**, e conclua no seu próprio ritmo.

#### Rankings

Once students beat the default computer they will be put in for the class ranking. Red teams only fight against blue teams and there will be top rankings for each. Students will only compete against the computer and other students in your CodeCombat class (not strangers).

Note that the class rankings are plainly visible. If some students are intimidated by competition or being publicly ranked, give them the option of a writing exercise instead:

- Write a walkthrough or guide to your favorite level
- Write a review of the game
- Design a new level

#### Dividindo a Turma


Os alunos devem escolher uma equipe para participar: Vermelho ou Azul.  É importante dividir a turma, pois a maioria dos alunos escolherá vermelho. Não importa se os lados estão equilibrados, mas é importante que existam jogadores para ambos os lados. 

- Divida a classe em duas, aleatoriamente, a partir de um baralho de cartas.
- Alunos que entregam seu trabalho cedo juntam-se à equipe azul, e os retardatários jogam no time vermelho.

#### Refining the Code

O código para o nível Pico de Poder pode ser enviado mais de uma vez. Incentive seus alunos a enviar o código, observe como ele se comporta em relação aos colegas de classe e, em seguida, faça melhorias e reenvie. Além disso, os alunos que concluíram o código de uma equipe podem criar código para a outra equipe.

**PROJETE**: Faça observações sobre o nível. Faça uma lista de requisitos. Decida em qual parte do problema você vai começar.
**IMPLEMENTE**: Escreva a solução para essa parte do seu problema no código. Dica: Use uma função diferente para resolver cada parte do problema!
**TESTE**: Seu código funciona? Se não, corrija seu código. Em caso afirmativo, resolve a parte certa do problema? Se não, redesenhe. Se assim for, passe para a próxima parte!

### Reflexão Escrita (5 mins)

**Checkpoint: O que é código?**
>Código é quando você digita instruções para fazer o computador fazer coisas. Às vezes, dá dicas e completa as palavras para você. Você tem que soletrar tudo corretamente e indentar o número certo de espaços. Às vezes os quebra-cabeças são fáceis e às vezes são difíceis. Você tem que fazer um plano para resolvê-lo e depois escrever o código exatamente para fazê-lo funcionar. A linguagem que usamos é chamada Python. Ele tem while True: para fazer seu código repetir e if, else, e elif para fazer coisas diferentes acontecerem em momentos diferentes.
