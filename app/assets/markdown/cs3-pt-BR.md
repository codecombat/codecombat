###### última atualização: 12/19/2016

##### Planos de Aula
# Ciência da Computação 3

### Sumário
- Pré-requisito Recomendado: Ciência da Computação 2
- 11 x 45-60 minutos de sessões de codificação

#### Visão Geral
Agora que os alunos têm uma base sólida nos tipos mais úteis de fluxo de controle (condicionais, funções e eventos), eles estão preparados para aprimorar suas habilidades de lógica condicional. A maioria das diferenças nos programas que os alunos querem escrever e os programas que sabem escrever começam a cair em Ciência da Computação 3.

Neste curso, os alunos continuarão praticando suas funções, eventos e condicionais aninhadas. Além disso, eles entrarão em operadores e palavras-chave mais sofisticadas. A concatenação de strings permite que os jogadores modifiquem strings dinamicamente em seu código para produzir o texto que quiserem. A aritmética ajudará os jogadores a se sentirem mais à vontade com o uso da matemática na programação. Todas as coisas no CodeCombat são objetos (essa é a parte "objeto" da programação orientada a objetos) e essas coisas têm atributos acessíveis, como a posição de Munchkin ou o valor de uma moeda; ambos são importantes para começar a visualizar a estrutura interna dos objetos que compõem seu mundo de jogo. Juntamente com as propriedades, os alunos desbloqueiam a mecânica de jogo adicional de manipulação de entrada em tempo real com bandeiras. Eles então aprendem a usar funções que retornam valores, para dividir cálculos em partes menores. Os operadores booleanos *igualdade*, * desigualdade *, *ou* e * e* permitem que eles expressem condicionais compostas. Combinando-os com a aritmética e as propriedades do computador, os jogadores finalmente exploram o movimento relativo, direcionando seu herói para locais dinâmicos. Eles também aprendem a trabalhar com o tempo de maneira programática e a manipular seus loops while com as instruções * break * e * continue *.


_Este guia foi escrito para ualas em linguagem Python em mente, mas pode ser facilmente adaptado para JavaScript._

### Escopo e Sequência
| Módulo                                                         | Primeiro nível          | Metas                                            |
| -------------------------------------------------------------- | :-----------------   | :-----------------                                        |
| [11. Concatenação de Strings](#concatenacao-de-string)         | Amigo e Inimigo      | Adicionar strings junto com `+`                             |
| [12. Aritmética Computacional](#aritmetica-computacional)      | TPorta do Feiticeiro    | Faça aritmética com os códigos (`+` `-` `*` `/`)                 |
| [13. Propriedades](#propriedades)                              | Bombardeio de Backwoods | Acessar propriedades de objetos com `.`                         |
| [14. Funções com Retorno](#funcoes-com-retornos)               | Arvoredos de Burlbole      | Escreva funções que retornam respostas                       |
| [15. Desigualdades](#desigualdade)                             | Concorrentes Úteis   | Teste se duas coisas não são as mesmas                  |
| [16. Booleano Ou](#booleano-ou)                                | Terra salgada        | Executar declarações if se uma das duas coisas forem verdadeiras      |
| [17. Booleano E](#booleano-e)                                  | Trovão da Primavera       | Executar declarações if se as duas coisas forem verdadeiras      |
| [18. Movimento Relativo](#movimento-relativo)                  | The Iaque de Areia Poderoso  | Combine as propriedades x e y e a aritmética para movimento   |
| [19. Tempo e Saúde](#tempo-e-saude)                            | Campo Minado         | Código baseado no tempo decorrido e na saúde do herói                |
| [20. Quebre e continue](#break-e-continue-quebrar-e-continuar) | Açambarcamento de ouro        | Pule ou termine while-loops com instruções break e continue |
| [21. Revisão - Arena Multiplayer](#revisao-arena-multiplayer)  | Ossos Cruzados          | Sintetize todos os conceitos de CS3                              |


### Vocabulário Básico

* Concatenação ** - A concatenação de strings é usada para adicionar duas strings junto com o operador de concatenação **string:** `+`

**Aritmética** - Adição, subtração, multiplicação e divisão. O curso 3 começa a facilitar o uso do matemática na codificação. Níveis que atendem a aritmética básica abordam como usar a matemática conforme necessário para realizar ações diferentes de maneira eficaz.

**Propriedade** - dados sobre ou pertencentes a um objeto. Você chega a ele especificando o objeto, depois um ponto, depois o nome da propriedade, como `item.pos`.

**Bandeiras** - Dispositivos de entrada em tempo real. Até agora, os programas CodeCombat dos alunos não foram interativos - não houve entradas do jogador em tempo real enquanto o nível estava sendo executado. Agora, com as flags ou bandeiras, os alunos têm uma maneira de enviar informações para seus programas: clicar em um mouse cria uma bandeira que o herói pode responder com a função `hero.findFlag ()`.

**Retornar** - Uma instrução de retorno permite que uma função calcule um valor de resultado e retorne-o ao local que chamou a função. Quando suas funções podem retornar seus resultados, é mais fácil dividir os cálculos de produção de dados em etapas menores.

**Booleano** - Uma variável binária com dois valores possíveis: `True` e` False`. As condicionais que você usa em declarações if e while-loops são avaliadas como resultados booleanos. A lógica booleana é a maneira como os valores booleanos se combinam para formar um único valor booleano.

**Break** - Uma maneira de sair de um loop while antes de terminar. As declarações de pausa dizem: "Quebre o loop, acabamos com isso". Você pode usar uma instrução break para passar para o resto do programa depois de um loop.

**Continue** - Uma maneira de voltar para o início de um loop while. Continue com as declarações dizendo: "Vamos parar este loop aqui e continuar no topo da próxima iteração". Se você não precisa terminar um loop (porque não precisa fazer nada agora), você pode usar uma instrução continue.


#### Atividades extras para os alunos que concluírem o terceiro curso:
- Ajude outra pessoa
- Refine uma estratégia de arena multiplayer em Ossos Cruzados
- Escreva um passo a passo
- Escreva uma resenha do jogo
- Escreva um guia para o seu nível favorito
- Projetar um novo nível


##### Módulo 11
## Concatenação de String
### Sumário
**A concatenação de strings** é usada para adicionar ou combinar duas strings juntas. Strings são estruturas de `" texto dentro de aspas "`. Os alunos usarão o operador **de concatenação de strings**, `+` para construir uma string mais longa dentre duas strings mais curtas, ou para combinar uma string e uma variável.

No CodeCombat, usar strings e `hero.say ()` é útil para se comunicar com amigos no jogo. Esses níveis prepararão o aluno para uma comunicação mais sofisticada usando strings concatenadas.

### Metas
- Concatene duas strings com `" string1 "+" string2 "`
- Concatenar strings e variáveis, como `" string1 "+ variável1`
- Use espaçamento adequado em torno de variáveis concatenadas


### Atividade Instrutiva: Strings (12 mins)
#### Explique (2 mins)
Strings são pedaços de texto dentro de citações. Os alunos têm usado strings desde o Curso 1. Por exemplo, na função `buildXY ()`, os alunos usam a string `" fence "`, para construir uma cerca como em `hero.buildXY (" fence ", 34, 30) `. Na função `attack ()`, a pessoa pode escolher atacar um baú passando a string, `" Chest "` como parâmetro, com `hero.attack (" Chest ")`.

Nesses níveis, os alunos precisarão combinar duas strings para formar uma string mais longa. Na programação, isso é chamado de **concatenação de string**. Os alunos aprenderão como concatenar ou adicionar duas strings juntas usando o operador de concatenação de strings, `+`.

A sintaxe para concatenar duas strings é a seguinte:

```
# resulta no herói dizendo "Venha até mim, Treg!"
hero.say(" Venha até mim, " + "Treg!")
```
Observe no código acima que cada uma das strings separadas tem seu próprio conjunto de aspas, mas o `+` não está entre aspas. O `+` não faz parte de nenhuma das strings, mas é o operador que é colocado entre as duas strings.

Observe também o espaço extra na primeira string, "Venha até mim". Ao concatenar strings, a segunda string é anexada ao final da primeira e ambas as strings aparecem exatamente como são mostradas entre aspas. Assim, sem o espaço extra, o herói diria: "Venha até mim, Treg!"

Além de concatenar duas strings, os alunos aprenderão a concatenar uma string e uma variável, pois qualquer variável está armazenando uma string.

O código a seguir mostra a concatenação de uma string e uma variável:

```
ogre = hero.findNearestEnemy()
hero.say("Come at me, " + ogre.id)
```
Usando uma variável, os alunos podem chamar um ogro sem codificar seu nome em seu código. Isso permitirá que eles chamem os ogros sem saber seus nomes primeiro.

Observe novamente no código acima do espaço extra após a primeira string. Assim como com duas strings, a concatenação de uma string e uma variável simplesmente anexam as duas strings juntas conforme são escritas no código. É importante lembrar-se de incluir um espaço extra se as cadeias de caracteres forem separadas por um espaço quando forem concatenadas.

Note que a concatenação só funcionará com strings nos dois lados do `+`. Tentar concatenar uma string com um tipo diferente, como um inteiro, ou com uma variável que não esteja armazenando uma string, resultará em um erro.

#### Interaja (8 mins)

Esta atividade demonstrará como usar o operador de concatenação de strings e também a importância de usar espaços corretamente ao concatenar strings.

Guie a classe através da concatenação de strings para criar uma frase comum. O objetivo deste exercício é que a classe escreva coletivamente um programa como este:

```
noun = "wood"
verb = "chuck"
teacher.write("How much " + noun + " would a " + noun + verb + " " + verb + " if a " + noun + verb + " could " + verb + " " + noun + "?")
```

Comece escrevendo esta string no quadro:

```
goal = "How much wood would a woodchuck chuck if a woodchuck could chuck wood?"
```

Explique para a classe que você quer fazer esta string apenas escrevendo as palavras `" wood "` e `"chuck"` uma vez. Pergunte aos alunos como isso pode ser feito e guie-os na ideia de usar variáveis para armazenar as strings para reutilização.

Em seguida, escreva as seguintes linhas no quadro:
```
noun = "wood"
verb =
teacher.write("How much " + noun)
```

Peça aos alunos que preencham o verbo e o resto da frase uma string ou variável de cada vez. Adicione uma variável de saída sob sua variável de meta para registrar a saída à medida que você avança:

```
output = "How much wood"
```

Deixe os alunos encontrarem seus próprios erros na saída. Eles provavelmente esquecerão de adicionar espaços nas strings primeiro e obterão a saída assim:

```
output = "How much woodcould a woodchuckchuckif a"
```

Lembre-os de que, para obter um espaço para aparecer na sequência de saída concatenada, ela precisa ser incluída na sequência antes ou depois da variável. Além disso, uma string que é apenas um espaço simples pode ser usada para adicionar espaços.


Quando o programa estiver concluído, peça à classe um novo nome e um novo verbo. Reescreva as variáveis e a saída final de acordo. Exemplo:

```
noun = "cheese"
verb = "spray"
teacher.write("How much " + noun + " would a " + noun + verb + " " + verb + " if a " + noun + verb + " could " + verb + " " + noun + "?")

goal = "How much wood would a woodchuck chuck if a woodchuck could chuck wood?"
output = "How much cheese would a cheesespray spray if a cheesespray could spray cheese?"
```

Se os alunos estão entendendo bem o conceito e parecem estar prontos para um desafio extra, encoraje-os a tentar escrever um código que produza a sequência de meta apenas escrevendo a sequência `" ould "` uma vez. Insentive-os para ver que eles podem criar uma variável para `" ould "` e então concatena-os da seguinte forma:

```
noun = "wood"
verb = "chuck"
ould = "ould"
teacher.write("How much " + noun + " w" + ould + " a " + noun + verb + " " + verb + " if a " + noun + verb + " c" + ould + " " + verb + " " + noun + "?")
```

#### Reflita (2 mins)
** Quando você usou strings antes no CodeCombat? ** (Para atacar por nome, como `hero.attack (" Treg ")`; to `buildXY` por tipo, como` hero.buildXY ("fence", 34, 30) `; para dizer senhas, como` hero.say ("Hush!") `; Etc.)
**Que tipo de texto você pode colocar em uma string?** (Qualquer texto que você quiser!)
**O que significa concatenação de strings?** (Adicionando uma string ao final de outra string).

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas e, especialmente, para a concatenação de strings, as mensagens de erro. Você pode precisar reforçar que cada string precisa de cotações de abertura e fechamento, e que entre strings e outras strings ou strings e variáveis, você sempre precisa de um `+` para concatenar. Lembre aos alunos para checar novamente o espaçamento e os tipos em ambos os lados do `+`.

Os alunos podem encontrar erros com código como este:

```
hero.say("Take " + numToTakeDown " down, pass it around!")  # Missing second +
hero.say("Take " + numToTakeDown + down, pass it around!")  # Missing second opening "
```

Se o aluno tiver dificuldade em descobrir um erro, peça-lhe que analise com cuidado a sintaxe da string e da concatenação, ou veja se um colega pode identificar o erro. Incentive-os também a ler cuidadosamente cada linha e anotar no papel o que eles acham que será a saída.

### Reflexão Escrita (5 mins)

**Quando você usa o operador de concatenação de string, `+`?**
>Quando você tem que colocar duas cordas juntas, ou quando você tem que colocar uma string junto com uma variável. Por exemplo, se você não sabe o que a variável está adiantada, mas precisa fazer algo com ela, como cantar em uma música, pode colocar a letra da música com um `+` e a variável.

**Como você combina duas variáveis em uma string com um espaço entre elas?**
>Você não pode simplesmente colocar as variáveis juntas como `x + y`, porque elas não terão espaço. Você tem que colocar uma string que tenha apenas um espaço no meio, como `x +" "+ y`.

**Por que você acha que as pessoas que projetaram o Python escolheram o sinal `+` para representar sequências de concatenação juntas?**
>Porque o que você está fazendo é adicionar uma string à outra string, e o símbolo para a adição é `+`.




##### Módulo 12
## Aritmética Computacional
### Sumário
Assim como as calculadoras, os computadores podem ser usados para realizar cálculos matemáticos. De fato, a palavra computador deriva do ato de computar, em um sentido matemático. **Aritmética computacional** está escrevendo código para que um computador execute operações matemáticas.

Os computadores podem ser usados para adicionar, subtrair, multiplicar e dividir números. Além disso, eles podem ser usados para executar operações em variáveis que representam números e os resultados de funções que retornam números.

A aritmética computacional é usada nesses níveis para permitir que os alunos calculem dinamicamente os números mágicos necessários para passar por uma série de assistentes. Os alunos terão que editar e executar seus programas várias vezes para obter as instruções de cada assistente e computar cada um dos números mágicos.

### Metas
- Aprender como usar os operadores de adição, subtração, multiplicação, divisão e módulo: `+`, `-`,` * `,` / `e`% `
- Executar aritmética em "numéricos literais " (como `2 + 2`)
- Realizar aritmética em variáveis (como `x - 5`)
- Realizar aritmética em propriedades (como `hero.pos.y + 10`)

### Atividade instrutiva: Números de Granizo (15 mins)
#### Explique (2 mins)
Assim como a aritmética pode ser feita manualmente ou com uma calculadora, ela também pode ser feita com o uso de código de computador. Os mesmos operadores que podem ser encontrados em uma calculadora básica também podem ser codificados facilmente.

Adicionando dois números pode ser feito com `+`, assim:
```
5 + 2  # resposta: 7
```

Da mesma forma, subtrair dois números pode ser feito com `-`:

```
5 - 2  # resposta: 3
```

Para multiplicação, `*` é usado em vez de `x` para evitar confusão com variáveis ou strings:

```
5 * 2  # resposta: 10
```

Finalmente, a divisão pode ser feita com `/`:

```
5 / 2  # resposta: 2.5
```

Além de executar operações em números, as operações também podem ser executadas em variáveis que armazenam números:

```
x = 3
5 * x  # resposta: 15
```
Uma operação adicional que pode ser executada com código é **módulo**. Essa operação não precisa ser usada nesses níveis do CodeCombat, mas ainda pode ser útil ou interessante para os alunos. Módulo é usado para encontrar o restante depois de dividir dois números:

```
5 % 3  # resposta: 2
9 % 4  # resposta: 5
6 % 2  # resposta: 0 (sem resto)
```

O benefício da **aritmética computacional** é que os computadores são muito rápidos e, portanto, as respostas podem ser calculadas quase instantaneamente. Isso permite que os programas executem um grande número de cálculos enquanto ainda estão em execução muito rapidamente.

#### Interaja (13 mins)

Explique para a classe que você quer a ajuda deles escrevendo código para um jogo matemático chamado sequências de granizo. O fluxo geral do jogo é o seguinte:

* A turma irá escolher um número
* Se o número for par, será dividido por 2
* Se o número for ímpar, será multiplicado por três e aumentado por 1
* Os dois passos anteriores são repetidos até que o número restante seja 1

Demonstre a atividade para a turma com o seguinte exemplo, começando com o número 5. Certifique-se de escrever as etapas à medida que avança. Você também pode escolher que um aluno escreva cada etapa, se desejar.


```
5 é ímpar
5 * 3 + 1 = 16, o qual é par
16 / 2 = 8, o qual é par
8 / 2 = 4, o qual é par
4 / 2 = 2, o qual é par
2 / 2 = 1, o qual é par
-------------------------
total de 5 passos
```

Agora diga à classe que você quer escrever uma função chamada granizo que inclua um número como parâmetro e execute o granizo (as etapas acima) no número. A função deve imprimir a seqüência de etapas geradas ao longo do caminho. Faça com que os alunos ajudem a criar a função conforme você a escreve no quadro:

```
def hailstone(number):
    teacher.write("Sequence: " + number)
    while number != 1:
        if isEven(number):
            number = number / 2
        else:
            number = number * 3 + 1
        teacher.write(" " + number)
```
Garanta que os alunos entendam o código e, particularmente, a aritmética antes de prosseguir. Eles devem entender que a linha number = number / 2 reatribui a variável number dividindo o valor original por 2. O `number` à esquerda do` = `contém o novo valor e o` number` no lado direito mantém o original. Isso também é verdade para a linha 'number = number * 3 + 1`.

Peça aos alunos um número entre 2 e 10 para começar e, em seguida, percorra o programa com eles, escrevendo os números à medida :

```
hailstone(10)
Sequence: 10 5 16 8 4 2 1
```

Se você explicou o operador de módulo e acredita que os alunos estão prontos para um desafio extra, encoraje-os a substituir a linha `isEven (number)` por uma linha de código que determinará se o número é par. Estimule-os para pensar em todos os operadores que aprenderam antes da atividade.

A linha de código apropriada para usar é:

`if number % 2 == 0:`

Explique aos alunos que esse código funciona porque todos os números pares são divisíveis por 2 e, portanto, têm um resto de 0 ao dividir por 2.

Se o tempo permitir, peça aos alunos que adicionem um contador ao código para acompanhar quantos passos foram necessários:

```
def hailstone(number):
    teacher.write("Sequence: " + number)
    steps = 0
    while number != 1:
        if isEven(number):
            number = number / 2
        else:
            number = number * 3 + 1
        teacher.write(" " + number)
        steps = steps + 1
    teacher.write("Steps: " + steps)

hailstone(3)
Sequence: 3 10 5 16 8 4 2 1
Steps: 7
```

Garanta que os alunos entendam como o contador funciona no código acima. Compartilhe que `hailstone (27)` leva 111 passos e chega a 9232 antes de cair para 1.

Explique que eles são chamados de números de granizo porque, como granizo, eles sobem e descem várias vezes antes de cair inevitavelmente por todo o caminho. No entanto, ninguém foi capaz de provar que isso tem que acontecer todas as vezes, mesmo que os computadores possam calcular o número de passos de granizo para números com milhares de dígitos instantaneamente com o código. Se alguém encontrasse um número que não caísse em 1, eles seriam famosos.

#### Reflita (2 mins)
**Quais operações você pode executar em um computador? Quais são os operadores para usar para eles?** (Você pode usar um computador para fazer adição, subtração, multiplicação e divisão. Os operadores que você usa são `+`, `-`,` * `e` / `, respectivamente.)
**Qual é a sintaxe apropriada para multiplicar uma variável chamada `number` por 5 e armazenar o resultado em` number`?** (`number = number * 5`)

### Hora da Programação (25 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas e lembre-os de que eles terão que editar e executar seus programas várias vezes para obter todas as instruções. Você pode ter que lembrar alguns alunos que o operador para multiplicação é `*` e não `x`.

### Reflexão Escrita (5 mins)
 


**Quando faz sentido usar um computador para fazer matemática?**
> Quando você tem que fazer muita matemática muito rápido, gostaria de calcular um grande número. Ou quando você não sabe quais são os valores antecipados, o computador pode fazer as contas em uma variável.

**Que tipo de matemática você sabe fazer sozinho, mas não sabe como usar um computador, e como você acha que pode fazer isso com um computador?**
> Eu posso elevar ao quadrado números. Talvez haja uma função , para o quadrado do (número)?




##### Módulo 13
## Propriedades
### Sumário
Os alunos usaram **propriedades** em módulos anteriores para fazer coisas como mover seu herói para uma posição específica e verificar o tipo de um inimigo. Propriedades são atributos específicos de objetos que podem ser usados para distingui-los. Nesses níveis, os alunos verão a importância de usar propriedades com o uso de **flags/bandeiras**.

Bandeiras dão ao jogo um elemento em tempo real. Os alunos colocam bandeiras na tela do jogo e fazem o herói responder a elas. As bandeiras são colocadas depois que o jogo já está sendo executado e, portanto, as propriedades devem ser usadas para acessá-las, pois os alunos não podem prever exatamente onde serão colocadas.


### Metas
- Acesse uma propriedade usando notação de ponto.
- Salve uma propriedade em uma variável.
- Compreenda a diferença entre uma propriedade e uma função.

### Atividade instrutiva: propriedades do brinquedo (10 mins)
#### Explique (3 mins)

Uma **propriedade** é um atributo ou característica de um objeto. Por exemplo, um objeto inimigo possui propriedades como tipo e posição. O objeto de sinalização, que os alunos usarão extensivamente nesses níveis, possui uma propriedade de posição.

As propriedades são semelhantes às funções, porque ambas as funções e propriedades são coisas que pertencem ao objeto. Eles diferem, no entanto, porque as funções são como ações ou verbos e propriedades são como aspectos (adjetivos) ou posses (substantivos).

As propriedades podem ser acessadas especificando o objeto e, em seguida, `.`, em seguida, o nome da propriedade. O código a seguir retorna a propriedade position de um objeto de flag:

`flag.pos`

Algumas propriedades também são objetos e, portanto, possuem propriedades próprias. Por exemplo, a propriedade de posição é um objeto com duas propriedades adicionais, uma para a posição x e uma para a posição y. Estes podem ser acessados adicionando outro ponto e o segundo nome da propriedade da seguinte forma:

`flag.pos.x`


Quando uma propriedade é acessada, seu valor pode ser encontrado e usado no código. Para cada tipo de objeto, diferentes instâncias de cada objeto têm as mesmas propriedades que são acessadas da mesma maneira, mas essas propriedades podem, e provavelmente terão, valores diferentes.

Por exemplo, flags diferentes têm o mesmo modo de acessar sua propriedade position, mas os valores da posição de cada flag podem ser diferentes. As diferenças nesses valores permitem que cada objeto seja distinguido e trabalhe separadamente.

#### Interaja(5 mins)

Uma vez que uma propriedade é acessada, seu valor pode ser encontrado e para esta atividade, traga um animal de pelúcia ou uma boneca exclusiva para a aula. Seria melhor se o animal ou a boneca tivessem muitas características distintas, tais como pêlo colorido diferente do que pele ou pêlo, cauda, roupas únicas, etc. Quanto mais divertido ou maluco o animal ou boneca, mais provável é que as crianças vão se divertir com a atividade.

Com a ajuda dos alunos, registre as diferentes propriedades do boneco no quadro. Certifique-se de usar a sintaxe correta ao gravar as propriedades, da seguinte forma:

`doll.hair`

Incentive os alunos a sugerirem propriedades de outras propriedades, como:

`doll.hair.color`

Depois que cada propriedade for escrita corretamente, peça aos alunos que os ajudem a preencher os valores, de modo que cada linha seja construída para ter a seguinte aparência:
```
doll.hair.color = "blue"
doll.fur.length = "short"
doll.legs.amount = 4
```


Crie uma lista de pelo menos dez propriedades diferentes seguindo o mesmo padrão de fazer os alunos sugerirem uma propriedade, escrevendo a propriedade corretamente no quadro e, em seguida, adicionando o valor correto. Se desejar, peça a um aluno que o ajude a escrever tudo no quadro. Sua lista deve

Quando a lista estiver completa, pergunte aos alunos se há alguma propriedade na lista que possa ser compartilhada por todos os bonecos semelhantes àqueles que você trouxe. Incentive-os a pensar se cada boneco tem ou não o mesmo valor para aquela propriedade. Se possível, você pode querer trazer uma segunda boneca que tenha a mesma propriedade, mas um valor diferente para aquela propriedade (como cabelo verde em vez de cabelo azul).

#### Reflita(2 mins)
**O que é uma propriedade?** (Um atributo de um objeto)
**Como você pode dizer a diferença entre uma função e uma propriedade?** (Funções têm parênteses () e propriedades não. Além disso, funções executam ações, enquanto propriedades descrevem atributos sobre objetos.)

**Dois objetos do mesmo tipo podem ter a mesma propriedade? Explique.** (Sim, porque eles são do mesmo tipo, eles provavelmente têm as mesmas propriedades. Por exemplo, cada inimigo no jogo tem um tipo.)


**As propriedades de dois objetos sempre terão o mesmo valor se os objetos forem do mesmo tipo? Explique.** (Não. Por exemplo, existem muitos tipos diferentes de inimigos no jogo, então mesmo que todos os inimigos tenham a propriedade type, o valor desta propriedade pode ser diferente entre eles.)


### Hora da Programação (25 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. As bandeiras podem ser complicadas para alguns alunos, então permita que eles emparelhem-se para superar os níveis. Cada aluno deve escrever seu próprio código, mas não há problema para outro aluno colocar as bandeiras para ele.

Se os alunos estiverem com problemas para colocar os sinalizadores, não se esqueça de direcioná-los para as instruções. Os alunos podem colocar bandeiras clicando na cor da bandeira ou digitando a primeira letra da cor e, em seguida, clicando na tela para colocar a bandeira. Os alunos devem usar `hero.pickUpFlag ()` para fazer o herói ir até a bandeira e limpá-la.


### Reflexão Escrita (5 mins)

**Como você usou propriedades hoje?**
> Eu usei propriedades para determinar onde as bandeiras eram para que o herói pudesse se mover para elas. Para fazer isso, usei a propriedade flag chamada pos e as propriedades pos, x e y para determinar onde estava o sinalizador.

**Conte-me sobre as flags/bandeiras.**
> Você usa bandeiras para dizer ao herói o que fazer quando o jogo está rodando. Você pode escrever um código para dizer se há um sinalizador e, em seguida, acessá-lo. Sinalizadores têm uma pos que tem x e y. X é da esquerda para a direita e y é de cima para baixo.



##### Módulo 14
## Funções com retornos
### Sumário

**Declarações de retorno** são usadas para criar funções que calculam e retornam um valor, em vez de apenas executar uma ação. Se uma função contiver uma instrução `return`, ela será igual a qualquer valor que ela retorne sempre que for chamada.

Quando uma função chega a uma instrução `return`, o valor é retornado imediatamente e o fluxo de controle também é retornado ao local em que a função foi chamada. Isso faz com que a função termine imediatamente.

Nesses níveis, os alunos usarão as declarações `return` para retornar valores booleanos e números para distâncias inimigas.

### Metas
- Escreve funções que "retornam" respostas
- Use as declarações `return` para sair das funções
- Use o valor retornado por uma função

### Atividade instrutiva: Vending Machine (12 mins)
#### Explique (2 mins)

Anteriormente, os alunos escreviam funções que faziam seu herói ou animal de estimação executar uma ação. Por exemplo, a função `goFetch ()` faz o pet buscar um item. A função `moveXY` faz o herói se mover para uma posição específica.

Nesses níveis, os alunos aprenderão a escrever código usando **declarações de retorno**. As declarações `return` permitirão que os alunos criem funções que, ao invés de executar uma ação, executem uma computação e retornem o resultado com uma instrução `return`.

O código a seguir mostra um exemplo de uma função que usa instruções `return`:

```
def howMany(things):
    if things == 1:
        return "a"
    if things == 2:
        return "a couple"
    if things <= 4:
        return "a few"
    if things <= 7:
        return "several"
    return "a lot of"

teacher.say("I see " + howMany(hats) + " hats.")
```
Observe no código acima que cada declaração `if` contém uma declaração` return`. Isso garante que apenas um valor será retornado pela função e esse valor é condicional com base no número que é passado como um parâmetro.

Observe também a última instrução `return` localizada fora das declarações` if`. Esta declaração `return` é executada se nenhuma das condicionais das declarações` if` forem atendidas. Se estiver usando condicionais e declarações `return`, é importante certificar-se de que a função sempre retornará algo, mesmo quando as condições não forem atendidas.

O valor retornado por uma função pode ser usado como qualquer variável pode. Observe a linha final no segmento de código acima. `howMany (hats)` é concatenado com o resto da string para formar uma frase completa como saída do professor.

É importante observar que quando uma função retorna um valor, ela também retorna o fluxo de controle para o local do qual foi chamado. Isso garante que apenas um valor seja retornado pela função. Note que, por causa disso, qualquer código escrito dentro de uma função, mas abaixo de uma instrução `return`, é inacessível.

Por exemplo, o código a seguir geraria um erro:
```
def howMany(things):
    if things == 1:
        return "a"
        things += 1  # this line is unreachable

    # more code below here
```
Como a função é interrompida quando atinge uma instrução `return`, nenhum código adicional dentro da função é executado quando um valor é retornado. Assim, planejamento e recuo apropriados são particularmente importantes ao escrever funções com declarações `return`.


#### Interaja (8 mins)
Nesta atividade, você trabalhará com os alunos para escrever o código de uma simples máquina de vendas. Para tornar a atividade mais interativa, reúna os seguintes materiais:

* 4 ou mais caixas
* Um lanche diferente para cada uma das caixas

Você também pode optar por colocar bebidas ou até mesmo brinquedos em cada uma das caixas. Se você escolher um item além da comida, certifique-se de alterar os nomes das variáveis e das funções no seu código de exemplo para que o substantivo e o verbo apropriados sejam usados.

onfigure as caixas de modo que a parte inferior de cada caixa esteja voltada para a classe e a parte superior aberta esteja voltada para você. Coloque as caixas em pelo menos duas linhas para que você tenha algum tipo de sistema de grade. Marque a parte inferior das caixas (o lado voltado para os alunos) com A1 no canto superior esquerdo, A2 à direita de A1, B1 abaixo de A1 e assim por diante. O resultado final deve ser uma representação de uma máquina de venda automática.

Peça aos alunos para ajudá-lo a escrever o código da máquina de venda automática. Comece com este esqueleto da máquina de venda automática:

```
def vend(button):
    if button == "A1":
        return ""

while True:
    button = class.pressButton()
    food = vend(button)
    class.eat(food)
```

Certifique-se de que os alunos entendam o código acima. Atualmente A1 ainda está retornando algo, mas é apenas uma string vazia. Assim, se os estudantes tentassem vender o item agora para comê-lo, não comeriam nada.

Peça a um aluno para subir e "apertar" o botão A1. Revele o que está por trás desse botão e escreva-o como a primeira string para "retornar". Sinta-se à vontade para se divertir com isso, fazendo com que os alunos lhe deem alguma forma de dinheiro para os itens ou escolhendo itens bobos ou inesperados por trás de cada botão.

Peça à classe que o ajude a pressionar o resto dos botões para descobrir os itens adicionais e escreva o resto das declarações `if` e` return`. Você pode acabar com 

```
def vend(button):
    if button == "A1":
        return "Cheetos"
    elif button == "A2":
        return "Apple"
    elif button == "B1":
        return "Slime"
    elif button == "B2":
        return "A bear"

while True:
    button = class.pressButton()
    food = vend(button)
    class.eat(food)
```
Garanta que os alunos entendam como o código acima funciona e por que as declarações `elif` foram usadas (porque apenas uma condição pode ser verdadeira). Questioná-los brevemente perguntando qual item eles receberão se pressionar cada um dos botões. Pode ser útil apontar para cada linha, pois os alunos "pressionam" cada botão para mostrar o fluxo de controle. Lembre-se de que o fluxo é o seguinte:

* Aperte o botão
* Botão Vend
* Verifique cada condicional até que o botão direito seja encontrado
* Devolve a string apropriada
* Atribuir variável `food` à string
* Coma a comida

Reitere como a função `vend` está usando declarações` return` para retornar valores de comida quando a função é chamada. Pergunte aos alunos se existe algum cenário em que eles não recebam algo retornado da máquina de venda automática (não existe porque cada condição tem uma declaração `return`).


Em seguida, mostre a classe como modificar o código, movendo todas as declarações `return` para apenas` retornar` uma variável `result`:

```
def vend(button):
    result = "money"
    if button == "A1":
        result = "Cheetos"
    elif button == "A2":
        result = "Apple"
    elif button == "B1":
        result = "Slime"
    elif button == "B2":
        result = "A bear"
    return result

while True:
    button = class.pressButton()
    food = vend(button)
    if food != "money":
        class.eat(food)
```

Certifique-se de que os alunos entendam o novo código e por que o retorno de uma única variável no final funcionará. Novamente, peça aos alunos que "pressionem" os botões enquanto apontam para a linha de código correspondente para mostrar o fluxo de controle. O fluxo de controle é agora o seguinte:

* Aperte o botão
* Botão Vend
* Inicialize a variável `result` como dinheiro
* Passar por condicionais até que o caminho certo seja encontrado
* Configure `result` para a string apropriada
* Retornar `resultado`
* Definir `comida` para ser o valor de retorno (` result`)
* Coma a comida (se não for dinheiro)

Pode ser necessário lembrar aos alunos que as variáveis não podem ser usadas fora da função em que foram definidas, a menos que sejam passadas como parâmetros. Assim, no exemplo acima, 'food = result' não seria uma linha de código válida. Usar as declarações `return` permite virtualmente o mesmo resultado.

Se você não tiver caixas para essa atividade, basta desenhar uma imagem de uma máquina de venda automática com quatro botões na placa e rotular os botões A1, A2, B1 e B2 em uma grade de 2x2. Em vez de fazer com que os alunos descubram qual item está por trás de cada botão, você pode fazer com que eles simplesmente sugiram itens diferentes para cada um dos botões.

#### Reflita (2 mins)
**Como um valor de retorno é usado ?** (valores de retorno são usados para que funções possam ser criadas para realizar cálculos e retorná-los para outra função. Isso permite que o código seja melhor organizado.)

**Quais são algumas funções embutidas do CodeCombat que você usa com os valores `return`?** (` hero.findNearestEnemy () `,` hero.isReady ("cleave") `,` hero.distanceTo (target) `,` hero.findNearestItem () `)

** Por que uma declaração de retorno imediatamente sai de uma função? ** (Porque se você chamar `retornar` duas vezes, você não saberia qual valor usar.)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Sempre que um aluno estiver tendo problemas com uma função, faça com que ela execute a função para que possa dizer exatamente qual valor ela retornará.

Lembre aos alunos para garantir que eles façam algo com o valor de retorno da função, uma vez que tenham sido chamados. Os exemplos a seguir mostram o uso correto e incorreto dos valores de retorno:
```
# Correto: armazenando o valor de retorno em uma variável e, em seguida, usando if
canAttack = inAttackRange(nearestEnemy)
if canAttack:
    hero.attack(nearestEnemy)

# Correto: usando o valor de retorno diretamente em if
if inAttackRange(nearestEnemy):
    hero.attack(nearestEnemy)

# Incorreto: não fazendo nada com valor de retorno
inAttackRange(nearestEnemy)
hero.attack(nearestEnemy)
```

### Reflexão Escrita (5 mins)


**Quando as funções com retornos são úteis?**
> Quando você quer descobrir algo, como atacar um inimigo ou pegar uma moeda, em vez de apenas atacá-lo diretamente dentro da função. Ou quando você deseja obter algum valor de retorno de fora do seu código, como com findNearestEnemy ().

**Nomear funções que retornam valores é importante. Crie três nomes de funções que retornem um valor útil no dia-a-dia e escreva alguns valores de exemplo que eles retornariam para garantir que os nomes façam sentido.**
>`whatTimeIsIt()` deveria retornar,como `"7:30 am"` ou `"1:11 pm"`. `findColor(thing)` retornaria a cor  , como `"red"` ou `"mahogany"`. `isFriend(person)` retornaria se alguém gosta de você, seja `True` ou `False`.b

##### Módulo 15
## Desigualdade
### Sumário
Os estudantes usaram o ** operador de igualdade **, `==`, em módulos anteriores para testar expressões condicionais para declarações `if`. O operador de igualdade verifica se os valores em ambos os lados são iguais entre si. A expressão retorna `True` se eles forem diferentes e` False` se não forem.

Nesses níveis, os alunos aprenderão sobre o ** operador de desigualdade **, `! =`. Este operador funciona de forma semelhante a `==`, mas em vez de verificar se os valores em ambos os lados são iguais, ele verifica se eles não são iguais uns aos outros. A expressão retorna 'True' se eles não forem iguais e 'False' se eles forem.

Os alunos usarão `! =` Nesses níveis para manter seus heróis a salvo, ajudando-os a evitar perigos como o veneno.

### Metas
- Teste se duas coisas não são as mesmas
- Use `! =` E `==` apropriadamente no código
- Leia `! =` Como "não é igual"

### Atividade instrutiva: Comendo (10 mins)
#### Explique (2 mins)
No curso anterior e nos módulos anteriores deste curso, os alunos escreveram um número de declarações `if` semelhantes a isto:

```
if gem.pos.x == 34:
        hero.say('left!')
```
Note que a expressão condicional na declaração `if` usa o **operador de igualdade**,` == `para verificar se` gem.pos.x` é igual a `34`. Os alunos usaram esse operador muitas vezes e devem estar familiarizados com ele. Expressões contendo `==` retornam `True` se os dois valores que estão sendo comparados forem iguais e `False` se não forem.

Neste módulo, os alunos aprenderão sobre um novo operador chamado **operador de desigualdade**. Em vez de verificar se dois valores são iguais entre si, o operador de desigualdade verifica se os dois valores **não** são iguais entre si.

O símbolo para o operador de desigualdade é `! =`. `!` é o equivalente de `not` e, portanto, é colocado antes de` = `para traduzir como `diferente`.

Abaixo está um exemplo de código que usa `! =` Para ver se um item não é uma jóia:

```
item = hero.findNearestItem()
    if item:
        if item.type != "gem":
            hero.moveXY(item.pos.x, item.pos.y)
```
O código acima primeiro procura por um item e, em seguida, se um for encontrado, ele verifica se o item não é * uma joia. Se o item não é uma oia, então a expressão `item.type! =" Gem "` retorna `True`. Se o item for uma joia, a expressão retornará "False".

Assim como `==`, `! =` Pode ser usado com números, variáveis, sequências de caracteres e propriedades em ambos os lados do operador. Nesses níveis, os alunos praticarão usando `! =` Para comparar esses diferentes tipos de dados.

#### Interaja (6 mins)
Diga à classe para imaginar que são 4:00 da manhã e eles acordam para um lanche, indo para a geladeira no modo zumbi. Como um zumbi, eles não estão pensando direito, então precisamos escrever um algoritmo simples para eles seguirem seus lanches. Escreva o seguinte código no quadro:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
```

Pergunte à classe o que fazer a seguir com a variável `food`, orientando-os a criar uma chamada de função como `zombie.eat (food)`. Pergunte se eles querem comer qualquer alimento, ou se querem comer um alimento específico. Os alunos devem mencionar vários itens alimentares que desejam comer. Você pode obter ajuda para começar a codificar isso da seguinte maneira:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
    if food.type == "cake":
        zombie.eat(food)
    if food.type == "cookies":
        zombie.eat(food)
    if food.type == "fruit":
        zombie.eat(food)
    if food.type == "ice cream":
        zombie.eat(food)
```

Os alunos devem ver que codificar uma solução dessa maneira levaria muito tempo e exigiria muitas linhas de código, especialmente ao considerar todas as diferentes opções que os alunos podem querer comer.

Pergunte aos alunos se, em vez de especificar alimentos que eles *querem* comer, se há um alimento específico que eles querem *evitar* comer. Pegue o primeiro item de comida mencionado e adapte o código para incluir esse item de alimento com um operador de desigualdade, como mostrado abaixo:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
    if food.type != "broccoli":
        zombie.eat(food)
```

Explique que, como no exemplo acima, você poderia criar uma série de condições para todos os itens alimentares que o zumbi não gostaria de comer. Pergunte aos alunos se talvez eles possam apenas evitar alimentos com qualquer atributo, como forma ou cor. Em seguida, adicione uma comparação de desigualdade aninhada ao código para incorporar isso:

```
fridge = zombie.findNearestFridge()
zombie.moveXY(fridge.pos.x, fridge.pos.y)
while True:
    food = zombie.ransack(fridge)
    if food.type != "broccoli":
        if food.color != "green":
            zombie.eat(food)
```


Explique que porque eles querem comer a maioria dos alimentos, eles não devem nomear explicitamente cada comida que eles * querem * comer com '=='. Em vez disso, eles podem usar `! =` Para evitar os itens que eles * não * querem comer. Os alunos devem entender que agora o zumbi vai comer todos os outros alimentos que não são verdes e não brócolis.

Observe que os alunos ainda não aprenderam como fazer um composto condicional, mas se os alunos perguntarem, eles aprenderão como fazer isso nos próximos dois módulos. Isso permitirá que eles escrevam declarações como: `if food.type! =" Broccoli "e food.color! =" Green "`.

#### Reflita (2 mins)
**O que seria retornado de 1 * 2! = 3?** (Verdadeiro porque 2 não é igual a 3.)
** Como você escreveria uma instrução `if` para verificar se um item não é uma joia? ** (` if item.type! = "Gem": `)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Quando os alunos estiverem verificando `item.type` e` enemy.type`, lembre-os para ter certeza de que estão soletrando os tipos corretamente: `if enemy.type! =" Peon "`, `if item.type! =" Poison " `, e` se item.type! = "gem" `.

Peça aos alunos que prestem muita atenção nas setas amarelas que indicam onde codificar, já que às vezes precisam modificar as condições `if` existentes.

### Reflexão Escrita (5 mins)



**O que são `==` e `! =` E como você os pronuncia?**
> `==` é o operador de igualdade e você diz "é igual a". `! =" é o operador de desigualdade, e você diz "não é igual a". `! =` é o oposto de `==`.

**Onde você usa `==` e `! =` No seu código?**
> Você os usa em instruções if, porque você tem que decidir se faz algo ou não, com base em se dois valores são iguais ou diferentes.

##### Módulo 16
## Booleano Ou
### Sumário

Um ** booleano ** é um tipo de dados com dois valores possíveis, `True` ou` False`. Os alunos usaram booleanos em módulos anteriores com o uso de declarações `if` e loops` while`. As condicionais usadas nelas são expressões que devem ser `True` ou` False` e, portanto, são expressões booleanas. A instrução ou loop é executado se a condição for `True` e não executada se a condição for `False`.

** A lógica booleana ** é uma forma de aritmética que é executada em valores booleanos. O resultado da lógica booleana é sempre um único valor booleano, que é 'True' ou 'False'.

Um operador que é usado na lógica booleana é o operador **booleano ou**. Ao usar `or`, se um ou ambos os valores na expressão forem `True`, então a expressão inteira será avaliada como  `True` . Se ambos os valores na expressão forem "False", a expressão inteira será avaliada como "False".

### Metas
- Definir o que é um valor booleano
- Entenda como usar o operador booleano `ou`
- Execute declarações `if` se uma das duas condições for verdadeira
- 
### Atividade instrutiva: Simon diz - Ou (10 mins)
#### Explique (2 mins)
**Booleanos** são tipos de dados que possuem dois valores possíveis, `True` e` False`. Embora os estudantes não tenham aprendido extensivamente sobre valores booleanos, eles os usaram muitas vezes no CodeCombat antes.

Por exemplo, todo laço `while` visto até agora foi definido como` True`, assim:
```
while True:
    # faça alguma coisa
```

Além disso, os alunos usaram funções que retornam valores booleanos, como a função `isReady`:

```
hero.isReady("cleave") # esta função retorna True se cleave estiver pronta e False se não
```
Eles então usaram o resultado de tais funções para executar ações diferentes com base no valor de retorno:

```
# if hero.isReady("cleave") retorna Verdadeiro então o herói irá se dividir se hero.isReady ("cleave"):
    hero.cleave()
```
No código acima, o herói irá usar cleave se `hero.isReady (" cleave ")` retornar `True`. Se a função retornar `False`, o herói não irá se dividir e o fluxo de controle irá para a próxima linha fora da instrução` if`.

Expressões também podem ser avaliadas para um valor booleano. Os alunos viram isso nos últimos níveis, com código como este:

```
if item.type == 'coin'
    # faça alguma coisa
```
Assim como com os valores booleanos que são retornados, no código mostrado acima, o código dentro da instrução `if` será executado se` item.type == 'coin'` resultar em `True`. Se ele for avaliado como 'False', o código na instrução `if` não será executado.

Neste módulo e no próximo, os alunos aprenderão como executar operações em valores booleanos com o uso da **lógica booleana**. A lógica booleana é uma forma de álgebra na qual os operandos (valores sendo operados) e resultado são todos valores booleanos.

Nesses níveis, os alunos usarão um operador chamado **booleano ou**. No Python, este operador é escrito digitando a palavra `or` entre duas expressões ou valores booleanos, como:

```
enemy.type == 'thrower' or enemy.type == 'munchkin'
```


Note que ambos os lados do `or` são expressões inteiras que podem ser avaliadas como` True` ou `False`. `or` só funcionará com valores booleanos, portanto, é necessário, ao usar` ou` entre expressões, que sejam expressões booleanas totalmente escritas.

O resultado de uma operação booleana `ou` é determinado pelos valores em ambos os lados do` or`. Se um ou ambos os valores forem `True`, a expressão retornará` True`. Se ambos os valores forem "False", a expressão retornará "False".

```
hero.say(False or False) # Hero says 'False'
hero.say(False or True) # Hero says 'True'
hero.say(True or False) # Hero says 'True'
hero.say(True or True) # Hero says 'True'
```


#### Interaja (7 mins)

Esta atividade é uma adaptação do popular jogo Simon Diz. Em vez de começar instruções com "Simon diz", no entanto, você começará cada instrução com uma instrução `if` contendo `ou`. Em vez de ouvir a frase "Simon diz", os alunos têm que determinar se qualquer uma das condicionais é "verdadeira" para elas antes de seguir ou não seguir as instruções.

Por exemplo, uma instrução poderia ser: "se o seu nome começar com" A "ou o seu nome começar com" B ", coloque as mãos na sua cabeça". Apenas os alunos cujos nomes começam com "A" ou "B" devem colocar as mãos sobre a cabeça.

Cada declaração deve ser escrita no quadro após cada jogada. Certifique-se de usar a sintaxe correta ao escrever as instruções. Por exemplo, o código da declaração acima poderia ser escrito da seguinte forma:

```
if name.startsWith("A") or name.startsWith("B"):
    hands.putOn(head)
```


Tal como acontece com Simon diz, existem algumas maneiras para os alunos serem eliminados:

* Execute a ação errada
* Executar uma ação quando não é suposto (ou seja, nenhuma das expressões é `True` para elas)
* Falha ao executar uma ação quando é suposto

Quando os alunos são eliminados, em vez de retornarem a seus lugares, você pode optar por ajudá-los em qualquer uma das seguintes tarefas:

* Escreva as declarações `if` no quadro
* Forneça instruções `if` ou expressões booleanas adicionais para as instruções
* Atuar como olhos adicionais para ajudar a ver quando outros estudantes devem ser eliminados

Sinta-se à vontade para ser criativo com as condições e instruções durante toda esta atividade. Você também pode optar por terminar o jogo sempre que sentir que os alunos têm uma boa noção do conceito. Além disso, você pode executar o jogo novamente se achar que eles precisam de mais prática.

#### Reflita(1 min)
**Como  `or` é usado?** (Para determinar se uma ou mais condições em uma expressão é `True`.)
**O que é um valor booleano?** (Um valor que é `True` ou` False`.)

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Lembre aos alunos que ambos os lados de `ou` precisam ter expressões inteiras que possam ser avaliadas como` True` or `False`:

```
# incorreto, desde que o computador veja (inimigo.type == "lançador") ou "munchkin"
if enemy.type == "thrower" or "munchkin":

# correto
if enemy.type == "thrower" or enemy.type == "munchkin":
```

### Reflexão Escrita (5 mins)

**Como você usou `or` nessas lições?**
> Usei 'or' para pegar moedas ou pedras preciosas, mas não objetos nocivos. Eu também usei para atacar apenas certos tipos de inimigos.

 **Qual é a propriedade `type`? Que tipos de coisas você viu no CodeCombat até agora?**
> A propriedade `type` é uma string informando que tipo de objeto é algo, como` "munchkin" `,` "thrower" `,` "burl" `,` "gem" `,` "coin" `, e `" veneno "`.



##### Módulo 17
## Booleano E
### Sumário

Nos próximos níveis, os alunos aprenderão sobre um segundo operador booleano, ** booleano E **. Assim como o booleano ou é escrito como `OR`, booleano e é escrito como `AND`.

Ao usar `AND`, se ambos os valores na expressão forem` True`, então a expressão inteira será avaliada como `True`. Se um ou ambos os valores forem `False`, a expressão inteira será avaliada como `False`. Nesse sentido, `AND` é quase o oposto de` ou`.

Os alunos usarão `AND` para executar ações somente quando duas condições forem `Verdadeiras`. Nos níveis posteriores, eles precisarão combinar seus conhecimentos de `AND`,` OR` e `not` .

### Meta
-- Entenda como usar o operador booleano `E`
- Compreender a diferença entre o operador `E` e` OR`
- Executar instruções if se as duas coisas forem verdadeiras

### Atividade Instrutiva: Simon diz - E (10 mins)
#### Explique (2 mins)
Nos últimos níveis, os alunos usaram o booleano `or` para encontrar o resultado de expressões contendo` == `e`! = `, Assim:

```
if item.type == "gem" or item.type == "coin":
    hero.moveXY(item.pos.x, item.pos.y)
```


Nesses níveis, os alunos aprenderão sobre booleano `e`, um operador booleano que funciona de maneira semelhante, mas que fornece resultados diferentes.

A sintaxe para usar `e` é a mesma que` ou`, exceto com um operador diferente:

```
if item.type == "coin" and item.value == 2:
    # faça alguma coisa
```

Note que ambos os lados do `e` são expressões que podem ser avaliadas como valores booleanos.

O resultado de uma operação booleana `e` difere daquela de` ou`. Se ambos os valores em ambos os lados do `e` forem `True`, a expressão retornará `True`. Se um ou ambos os valores forem `False`, a expressão retornará `False`.

```
hero.say(False and False) # Hero says 'False'
hero.say(False and True) # Hero says 'False'
hero.say(True and False) # Hero says 'False'
hero.say(True and True) # Hero says 'True'
```

Como um  booleano`E` sempre resultará em `False` se um operando (valor em um dos lados de`E`) for `False`, se o primeiro valor for encontrado como`False`, toda a expressão será imediatamente avaliada como `False`, sem verificar o resto da operação booleana. Isso permite que um código como esse seja escrito:

```
# rifica se existe um inimigo e se o inimigo é um dragão
if enemy and enemy.type == "dragon":
    # faça alguma coisa
```
Se não houver nenhum inimigo presente, a primeira parte da operação booleana é considerada 'False'. Assim, a segunda parte da declaração `if` simplesmente não será verificada, pois já pode ser determinado que a expressão será avaliada como` False`. Portanto, uma variável que pode nem estar presente pode ser referenciada sem que o código gere um erro.


#### Interaja (6 mins)

Esta atividade é uma repetição da Simon Diz usado no último módulo. Em vez de usar declarações `if` contendo` ou`, você usará instruções `if` contendo` e` para instruir os alunos.

Por exemplo, uma instrução pode ser: "se o seu nome começar com `A` e você tiver cabelo castanho, coloque as mãos nos quadris". Somente os alunos cujos nomes começam com `A` **e** que têm cabelos castanhos devem colocar as mãos nos quadris.

Como na última atividade, certifique-se de escrever a declaração no quadro após cada movimento, usando a sintaxe apropriada. Por exemplo, o código da declaração acima poderia ser escrito da seguinte maneira:

```
if name.startsWith("A") and hair.color == 'brown':
    hands.putOn(hips)
```


Os estudantes podem ser eliminados por qualquer um dos seguintes motivos:

* Realizar a ação errada
* Realizar uma ação quando não é suposto (ou seja, a expressão é 'False' para eles)
* Falha ao executar uma ação quando é suposto

Quando os alunos são eliminados, em vez de retornarem a seus lugares, você pode optar por ajudá-los em qualquer uma das seguintes tarefas:

* Escreva as declarações `if` no quadro
* Forneça instruções `if` ou expressões booleanas adicionais para as instruções
* Atue como olhos adicionais para ajudar a ver quando outros estudantes devem ser eliminados

Você deve ter certeza de ter algumas declarações `if` que se aplicam a nenhum dos alunos, a fim de garantir que eles compreendam completamente o conceito. Por exemplo, você poderia dizer "se o seu nome começar com 'A' e o seu nome começar com 'B', ponha as mãos nos quadris". Nesse caso, nenhum dos alunos deve executar a ação, pois cada nome só pode começar com uma letra.

Sinta-se à vontade para ser criativo com as condições e instruções durante toda esta atividade. Você também pode optar por terminar o jogo sempre que sentir que os alunos têm uma boa noção do conceito. Além disso, você pode executar o jogo novamente se achar que eles precisam de mais prática.

#### Reflita (2 mins)
**Para que serve o operador `e/AND`?** (Para executar uma ação se duas condicionais forem` True`)
**Qual é o código que você escreveu no CodeCombat que você pode usar `e/AND` para simplificar?** (Verificar se existe um inimigo e se o cleave está pronto, ou se a cleave está pronta e o inimigo está próximo o suficiente).


### Hora da Programação (35-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Lembre os alunos de lerem as declarações 'se' em voz alta para se certificar de que fazem sentido. Também os lembre, se necessário, que ambos os lados de um operador booleano devem ser expressões completas que avaliem valores booleanos.

### Reflexão Escrita (5 mins)
 

**Desafio: o que acontece no código como `if item and item.type == "gem":`?**
> `item` é convertido para` True` ou `False`, dependendo se existe, e` item.type == "gem" `é convertido para` True` ou `False` dependendo se é uma jóia, e então o `e` os combina em` True` se o item existir e for uma gema, caso contrário `False`.

**Dada uma variável 'inimigo', você pode pensar em uma maneira de usar booleano `e` para checar se há um inimigo e para checar se o inimigo está a menos de 10 metros, em uma linha?**
> `if enemy and hero.distanceTo(enemy) < 10:`

**Faça um exemplo de `if`, seja no CodeCombat ou na vida real, que use` e` e `ou` na mesma linha para combinar três valores booleanos.**
> `if fridge.hasFood() and (me.isHungry() or me.isBored()): me.open(fridge)`



##### Módulo 18
## Movimento Relativo
### Summary
In prior modules, the students learned how to move their heroes to a particular spot by using `hero.moveXY()` and passing in numbers or properties as the coordinate values.

In this module, the students will combine their knowledge of computer arithmetic and properties to learn about **relative movement**. This will allow the students to move their hero dynamically by specifying coordinates that are relative to a known position.

The students will execute relative movement by adding and subtracting from properties and values to create new x and y position values for their hero to move to. They will use this new skill in these levels to move their hero relative to the current position in order to dodge obstacles.

### Metas
- Use `moveXY ()` para se mover em relação a posições dinâmicas com coordenadas aritméticas
- Internalize como as coordenadas positivas e negativas `x` e` y` se relacionam com o movimento para cima, baixo, esquerda e direita
- Combine movimento relativo com loops e condicionais para produzir padrões de movimento desejados

### Atividade Instrutiva: Patrulha do Professor (12 mins)
#### Explique (2 mins)
Até agora, os alunos usaram três tipos de movimento:

```
hero.moveRight()
hero.moveXY(34, 20)
hero.moveXY(item.pos.x, item.pos.y)
```


Agora que eles sabem como fazer a aritmética do computador, os alunos podem usar essas habilidades para fazer seu herói se mover dinamicamente com **movimento relativo**. Usando o movimento relativo, os alunos podem mover seus heróis em relação a outra coisa, como sua posição anterior ou uma unidade inimiga.

Abaixo está o código que irá mover o herói para uma nova posição em relação à sua posição atual:

```
x = hero.pos.x
y = hero.pos.y

x += 10
hero.moveXY(x, y)
```

Observe no código acima que as variáveis `x` e` y` estão definidas para a posição original do herói. x é então incrementado em 10, significando que seu valor é agora 10 maior do que era originalmente. Chamando `hero.moveXY ()` com `x` e` y` agora move o herói 10 unidades para a direita. Como o valor de `y` não mudou, o herói se move apenas horizontalmente.

É importante notar que quando x diminui, o herói se move para a esquerda; quando é aumentado, o herói se move para a direita. Quando `y` é diminuído, o herói desce; quando é aumentado, o herói sobe.

#### Interaja (8 mins)

Explique à turma que o objetivo é escrever um programa para fazer com que você (o professor) ande em um quadrado ao redor de um aluno sempre que o aluno bater palmas.

Peça um voluntário para ficar na frente da classe e bater palmas. Peça à classe que ajude a escrever o manipulador de eventos desde o início, solicitando um nome de função e o código para começar a ouvir um evento de palmas de um aluno. O código deve ser semelhante a este:

```
def heardClap():


student.on("clap", heardClap)
```

Agora desenhe um diagrama no quadro de um quadrado com um ponto no meio e rotule o ponto como "{x: 0, y: 0}". Digamos que você vai começar no canto superior direito. Marque-o como '{x: 5, y: 5} `e escreva a primeira linha da sua função:
```
def heardClap():
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)

student.on("clap", heardClap)
```


Peça ao aluno que vá ao quadro e diga ao aluno escolhido para bater palmas. Mova para a coordenada correspondente cerca de um metro e meio à direita e um metro e meio à frente do aluno.

Faça a turma trabalhar no restante do programa no quadro para criar uma solução que o faça andar corretamente em um quadrado. Peça ao aluno que bata palmas toda vez que uma nova linha de código for adicionada para testar a solução. Trabalhe com a nova linha de código a cada vez, mesmo que esteja errada, para que os alunos possam ver o resultado do código.

Se você estiver se movendo no sentido horário, seu código pode ficar assim. No entanto, cabe a você e à classe a ordem para se mover e de que maneira seus eixos estão alinhados.

```
def heardClap():
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)
    teacher.moveXY(student.pos.x + 5, student.pos.y - 5)
    teacher.moveXY(student.pos.x - 5, student.pos.y - 5)
    teacher.moveXY(student.pos.x - 5, student.pos.y + 5)
    teacher.moveXY(student.pos.x + 5, student.pos.y + 5)

student.on("clap", heardClap)
```


Preste atenção no código que eles sugerem, pois pode não ser o que eles significam. Os alunos provavelmente cometerão erros que envolvem você andando diagonalmente pela praça, esbarrando no aluno no centro. Finja lançar uma mensagem de erro e depois depure o que aconteceu para corrigir o código.

Certifique-se de que os alunos entendam que a posição para a qual você se muda é sempre relativa ao aluno que está batendo palmas. Se você tiver mais tempo, escolha outro aluno para ficar em outro lugar da sala e bater palmas. Mova o segundo aluno em um quadrado para mostrar que a posição é relativa ao aluno que bate palmas e não a um ponto fixo.


#### Reflita (2 mins)
**O que aconteceria se o aluno se movesse enquanto a professora estivesse se movendo em torno dela?** (O professor andaria em uma forma diferente dependendo de onde o aluno estava quando cada `moveXY` começou).
**Quais são os dois novos conceitos do Curso 3 que você deve combinar para fazer o movimento relativo?** (Propriedades e aritmética do computador).
**No CodeCombat, quais são as direções -x, + x, -y e + y?** (Esquerda, direita, para baixo e para cima).

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Se eles não estiverem se movendo como eles esperavam, faça com que eles arrastem o depurador de tempo até o momento em que tudo deu errado e pause o código, depois pense exatamente em quais coordenadas estão sendo calculadas naquele momento.

Lembre os alunos de pensar sobre a direção que você moveu quando `x` e` y` foram adicionados e subtraídos.

### Reflexão Escrita (5 min)
**Como você implementaria `hero.moveRight ()`, onde o herói se move 12 metros para a direita, usando `hero.moveXY ()` e movimento relativo? E sobre `hero.moveLeft ()`, `hero.moveUp ()` e `hero.moveDown ()`?**
>For `hero.moveRight()`: `hero.moveXY(hero.pos.x + 12, hero.pos.y)`
>For `hero.moveLeft()`: `hero.moveXY(hero.pos.x - 12, hero.pos.y)`
>For `hero.moveUp()`: `hero.moveXY(hero.pos.x, hero.pos.y + 12)`
>For `hero.moveDown()`: `hero.moveXY(hero.pos.x, hero.pos.y - 12)`

**Invente uma história: por que você acha que os yaks são tão violentos no CodeCombat que atacariam se você chegasse perto demais deles?**
> Provavelmente, eles aprenderam a se defender contra caçadores de ogros para que eles tenham uma resposta de luta embutida quando se aproximarem de qualquer coisa com duas pernas. Antes que os ogros viessem, eles viriam até você e pediriam comida, mas agora eles viviam em paranóia e medo depois que os ogros começaram a caçá-los.



##### Módulo 19
## Tempo e Saúde
### Sumário

**Tempo** é uma entrada básica para muitos programas. Por exemplo, programas podem ser feitos para executar uma ação em um determinado momento. Eles também podem ser construídos para executar uma declaração após o tempo suficiente ter passado.

Neste módulo, os alunos aprenderão como responder ao tempo que passa com a função `hero.now ()`. Eles usarão essa função para executar ações em um determinado momento, usando o tempo decorrido desde o início do nível.

Neste módulo, os alunos também irão praticar o uso de `hero.health` para determinar quando fazer algo. Esta propriedade permite que os alunos realizem uma ação quando a saúde de seu herói atinge um certo limite.

### Metas
- Escrever código baseado no tempo decorrido usando a função `hero.now ()`
- Escreva código baseado em limites usando `hero.health`
- Aprenda quando alterar as estratégias gerais no código

### Atividade Instrutiva: Jogo Silencioso (12 mins)
#### Explique (3 mins)

Os alunos já aprenderam como usar eventos para determinar quando fazer as coisas em seus programas. Por exemplo, eles aprenderam como fazer seus animais de estimação reagirem a eventos como ouvir o herói falar:

```
def speak(event):
    pet.say("Meow!")

pet.on("hear", speak)
```

Além disso, os alunos usaram loops `while` em conjunto com declarações` if` para decidir quando fazer uma coisa ou outra com base em uma determinada condição. Por exemplo, eles escreveram código para atacar se houver inimigos por perto ou usar o clivagem se ele estiver pronto para ser usado:

```
while True:
    if hero.isReady("cleave"):
        hero.cleave()
```


Hoje, os alunos aprenderão como realizar ações com base no tempo e não em eventos e condições. Uma maneira de fazer isso é com a função `hero.now ()`. `hero.now ()` retorna a quantidade de tempo, em segundos, que passou desde que o botão "Executar" foi pressionado. Cada vez que o botão é pressionado, o tempo começa novamente de 0 segundos.

A função `hero.now ()` pode ser usada assim:

```
if hero.now() < 10:
    enemy = hero.findNearestEnemy()
    if enemy:
        hero.attack(enemy)
```

O código acima garante que nos primeiros 10 segundos do nível, o herói atacará enquanto houver um inimigo presente. Ao combinar declarações `if` e` elif` que possuem condicionais para diferentes quantidades de tempo, os alunos podem definir ações diferentes para ocorrer em momentos específicos.

Além da função `hero.now ()`, os alunos aprenderão sobre as propriedades `hero.health` e` hero.maxHealth`. Os alunos podem definir condicionais usando essas propriedades para que determinadas ações ocorram quando sua saúde atingir um determinado valor:

```
healingThreshold = hero.maxHealth / 2
if hero.health < healingThreshold:
    hero.say("Can I get a heal?")
```
A primeira linha do segmento de código acima usa `hero.maxHealth` para definir um limite no qual o herói deve executar uma determinada ação. Observe que a variável `healingThreshold` é criada na primeira e depois usada na instrução` if` logo abaixo dela. Esta declaração `if` será executada somente quando a saúde do herói estiver abaixo do` healingThreshold`.

#### Interaja (7 mins)


Esta atividade é uma versão modificada do Jogo Silencioso, em que toda a turma tenta ficar quieta pelo máximo de tempo possível.

Diga à turma que você vai escrever um programa para pontuar em quanto tempo eles podem ficar quietos. Comece com este código no quadro:

```
def calculateScore():
    endTime = now()

startTime = now()
students.on("noise", calculateScore)
```

Diga que você vai testar o programa. Diga aos alunos que você fará uma contagem regressiva de 3 e eles deverão ficar em silêncio. Uma vez que eles estão quietos, registre a hora atual, incluindo os segundos no tabuleiro da seguinte forma:

 "`startTime` is 10:05:30".


Para a primeira rodada, o objetivo é que os alunos fiquem em silêncio por alguns segundos. Se seus alunos são geralmente bons em ficar em silêncio, você pode começar a fazer caretas ou fazer um barulho alto para assustá-los, para que eles não fiquem em silêncio por muito tempo. Isso também ajuda a adicionar um aspecto divertido ao jogo.

Depois que os alunos fizerem barulho, anote a hora atual e diga em voz alta para os alunos (por exemplo, "10:05:35"). Diga-lhes que, como fizeram barulho, o ouvinte de evento `calculateScoreScore disparou para o evento" noise ".

Pergunte aos alunos o que deve ser o 'endTime' e oriente-os para ver se é a hora atual, 10:05:35. Note que não é a hora atual no presente, mas a hora em que eles começaram a fazer barulho.

Peça aos alunos para ajudá-lo a descobrir por quantos segundos eles ficaram em silêncio. Guie-os para ver que você deve subtrair as duas vezes e, em seguida, comece a classificá-las:

```
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 10:
        score = "amateurs"
```

Peça aos alunos outros limites de tempo e pontuações até que você tenha um programa como este:

```
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 10:
        score = "amateurs"
    elif duration < 20:
        score = "acceptable"
    elif duration < 30:
        score = "good"
    elif duration < 40:
        score = "professionals"
    else:
        score = "robots"
    return score

startTime = now()
students.on("noise", calculateScore)
```


ê aos alunos entre 5 e 10 rodadas para ver como eles podem ficar em silêncio por muito tempo. Mais uma vez, você pode se sentir livre para fazer caretas engraçadas ou ruídos surpreendentes se for apropriado para sua turma.

Registre a duração de cada rodada. Explique à turma que, como agora você conhece o intervalo, é possível usar a aritmética do computador para ajustar o programa para se adaptar à melhor pontuação.

Adapte o código na placa para que agora apareça da seguinte maneira:

```
maxTime = 55
def calculateScore():
    endTime = now()
    duration = endTime - startTime
    if duration < 1 / 5 * maxTime:
        score = "amateurs"
    elif duration < 2 / 5 * maxTime:
        score = "acceptable"
    elif duration < 3 / 5 * maxTime:
        score = "good"
    elif duration < 4 / 5 * maxTime:
        score = "professionals"
    else:
        score = "robots"
    return score

startTime = now()
students.on("noise", calculateScore)
```

Explique aos alunos que, se os alunos estivessem em silêncio, com quatro quintos da duração de sua tentativa mais longa, seriam "robôs". Note que como a instrução `elif` é escrita como` elif duration <4/5 * maxTime`, ela não inclui `4/5 * maxTime`. Da mesma forma, se os alunos ficassem em silêncio por pelo menos três quintos da duração de sua tentativa mais longa, seriam "profissionais" e assim por diante.


#### Reflita (2 mins)
**Como você obtém uma duração de tempo de dois tempos absolutos?** (Subtraia a hora inicial da hora final).
**Como se pronuncia `if duration <1/5 * maxTime:`?** ("Se a duração for inferior a um quinto do maxTime ...")

### Hora da Programação (30-45 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```

Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Lembre-os de comparar sua `hero.health` atual com alguma fração de` hero.maxHealth`. Também incentive os alunos a procurar erros comuns em seus códigos, como erros de digitação ou operadores relacionais incorretos (`<`, `<=`, `>`, e `> =`).

 ##### Módulo 20
## Break e Continue (Quebrar e Continuar)
### Sumário

Programadores usam **declarações break** para sair de um loop while. As instruções `break` são indicadas para quebrar o loop e passar para a próxima linha de código. Eles são usados para passar para o restante do programa após um loop, porque é determinado que o restante do loop não deve ser executado.

**As declarações de continuação** são como instruções de interrupção, mas elas pulam para o início do loop while em vez de sair. As instruções `continue` indicam para parar este loop aqui e continuar no topo com a próxima iteração. Se um loop não precisa ser terminado (porque não precisa fazer nada agora), uma instrução `continue` é usada.

### Meta
- End while loops with break statements
- Skip while loop iterations with continue statements
- Understand when break/continue are cleaner than nested if/else


###Atividade instrutiva: Duck Duck Goose (17 mins)
#### Explique (5 mins)


Os alunos têm usado e escrito`while True:` em todo o jogo até o momento. Como os loops são sempre verdadeiros, não há como finalizar os loops e eles são infinitos.

Agora os alunos aprenderão como parar de executar um loop e começar a fazer outra coisa. Por exemplo, talvez eles tenham derrotado todos os inimigos e desejem mandar seu herói para casa. Isso pode ser feito com o uso de uma instrução `break`:

```
# this loop stops running if there is not an enemy
while True:
    enemy = hero.findNearestEnemy()
    if enemy:
        hero.attack(enemy)
    else:
        break

hero.say("My job here is done!")
hero.retire()
```

Pseudocódigo para o código escrito acima é o seguinte:
```
while True:
    find the nearest enemy
    if there is an enemy:
        attack the enemy (and return to the top of the loop)
    or if there are no enemies:
        break and move out of the loop to the next line of code

say "My job here is done!"
retire and go home
```

Observe que o código acima tem uma condição dentro do loop while que determina se o loop deve continuar em execução ou não. Sem a instrução `break`, o loop continuaria a rodar para sempre, mesmo quando não houvesse inimigos presentes, e as duas linhas de código abaixo do loop não poderiam ser alcançadas.

Semelhante a instruções `break` são declarações` continue`. Em vez de sair de um loop, as instruções `continue` são usadas para parar a iteração atual de um loop e continuar para a próxima iteração. Os alunos podem usar instruções `continue` para escrever um loop que tenha muitos códigos para rodar se houver inimigos, mas não fizer nada se não houver inimigos:

```
# this loop continues to run but starts again from the beginning if there is not an enemy
while True:
    enemy = hero.findNearestEnemy()
    if not enemy:
        continue
    # ...
    # ... lots of code here to deal with the enemy
    # ...
```


O código acima usa uma condicional para determinar se deve completar a iteração atual do loop ou parar a iteração atual e passar para a próxima. Observe que, como o loop não é quebrado com uma instrução `break`, ele será executado infinitamente.

É importante observar que `continue` e` break` alteram o fluxo de controle e impedem que as próximas linhas de código sejam executadas, pelo menos nessa iteração de loop atual. Assim, ao combiná-los com condicionais, eles podem ajudar a eliminar o número de condicionais necessários.

Por exemplo, o código acima poderia ser escrito assim sem o uso de `continue`:

```
while True:
    if not enemy:
        # do something
    else:
        # do something else
```
Para esse cenário, `continue` ajuda não só a permitir que o herói não faça nada se ele não vir um inimigo, mas também para evitar a cláusula extra`else` porque o código não será alcançado nessa iteração uma vez que `continue` esteja executado.


#### Interaja (10 mins)


Esta atividade é uma versão modificada do popular jogo Duck, Duck, Goose. O objetivo é escrever código que represente o jogo e também incorpore `continue` e` break`.

Peça aos alunos que se sentem em círculo para se prepararem para o jogo. Escreva a primeira linha de código no quadro para iniciar o programa:

`while True:`

Peça para um aluno se voluntariar para ser "ele". Faça com que o aluno ande devagar, digamos, "pato" algumas vezes antes de pausar o jogo. Peça à turma para ajudá-lo a escrever código para simular o que acontece no jogo quando "ele" diz "pato". Provoque-os para chegar ao código semelhante a este:

```
while True:
    it.moveTo(nextStudent)   # note: this first line is optional
    if it.say("duck"):
        continue
```

Assegure-se de que os estudantes entendam porque o `continue` é usado aqui. Como o loop apenas recomeça (ou seja, ele simplesmente passa para o próximo aluno e diz "pato" ou "ganso" novamente, é apropriado parar a iteração atual do loop e recomeçar no início do próximo movimento.

Retomar o jogo lembrando "ele" para mover-se lentamente de pessoa para pessoa. Aponte para a linha de código correspondente com cada movimento e instrução até que diga "ganso". Grite rapidamente "Pausa!" quando isso acontece, os alunos o ajudam a terminar de escrever o código.

Pergunte à classe o que acontece no jogo agora. Muitos estudantes provavelmente mencionarão que o "ganso" agora persegue "ele" ao redor do círculo. Certifique-se de orientar a discussão dos dois possíveis resultados da perseguição - ou o "ganso" captura "ele" ou não.

Agora pergunte aos alunos o que acontece se o "ganso" pegar "isso". Eles devem responder que "ele" então recomeça de onde ele parou, repetindo o mesmo processo de antes. Pergunte-lhes como representar isso como código, e empurre-os para ver que desde que o loop começa novamente a partir do topo, isso pode ser representado com `continue`:
```
while True:
    it.moveTo(nextStudent)   # note: this first line is optional
    if it.say("duck"):
        continue
    if goose.catch(it):
        continue
```

Depois pergunte a eles o que acontece se o "ganso" não pegar "ele". Eles deveriam responder que "isto" toma o lugar do "ganso" e o "ganso" então se torna "aquilo". Você deve enfatizar que se o "ganso" não pegar "ele", a rodada atual termina, e o jogo pode até terminar naquele ponto. Peça-lhes que o ajudem a completar o código para que você tenha algo semelhante a isto:

```
while True:
    it.moveTo(nextStudent) # note: this first line is optional
    if it.say("duck"):
        continue
    if goose.catch(it):
        continue
    else:
        break

# determine whether to play another round
# if you play another round, it = goose

```

Assegure-se de que os alunos entendam porque o 'break' é usado quando o "ele" é capturado. Porque há uma nova pessoa para ela, a rodada é completada, então o loop é quebrado. Isso permite que o código abaixo do loop `while` seja executado e que o professor decida se outra rodada deve ser executada.

Permita que os alunos joguem mais algumas rodadas do jogo, garantindo que apontem para a linha de código correspondente a cada movimento. Sinta-se à vontade para pausar o jogo quando necessário para explicar o fluxo de controle. Sinta-se à vontade para terminar o jogo depois de alguns minutos.


#### Reflita (2 mins)
**Quando faz sentido usar `break`?** (Quando você quer parar de fazer um loop while e fazer outra coisa.)
**Quando faz sentido usar `continue`?** (Quando você não quer ter tudo aninhado dentro de` else`.)

### Hora da Programação (25-40 mins)

Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```


Circule para ajudar. Chame a atenção dos alunos para as instruções e dicas. Se eles ficarem presos, faça-os arrastar o depurador da linha de tempo até o ponto em que o código parou de fazer o que esperavam e peça-lhes que reconstruam o que o código está tentando fazer naquele momento.

Para ajudar na depuração, esse pode ser um bom momento para usar a planilha de Ciclo de Engenharia novamente se os alunos não tentarem isso recentemente.


##### Módulo 21
## Revisão - Arena Multiplayer 
### Sumário


Este é um nível de chefe que exigirá engenhosidade e colaboração para resolvê-lo. O objetivo do nível é derrotar o chefe principal, mas os estudantes também terão que coletar moedas, contratar mercenários e curar seu campeão.

Peça aos alunos que trabalhem em pares e compartilhem suas dicas com outras equipes. Os alunos devem fazer observações sobre o nível em papel de rascunho e usá-los para fazer um plano.

O nível da arena é uma recompensa por completar o trabalho necessário. Os alunos que ficaram para trás nos níveis ou que não completaram suas reflexões escritas devem usar esse tempo para terminar. À medida que os alunos entregam seus trabalhos, eles podem entrar na arena Ossos Cruzados e tentar várias soluções até que o tempo seja chamado.

Veja [Guia de Níveis Arena](/teachers/resources/arenas)para mais detalhes.

### Meta
- Sintetize todos os conceitos do CS3.

### Atividade Instrutiva: Revisão e Síntese (10 min)

#### Interaja(10 mins)
Peça aos alunos para ajudarem a listar e definir todas as novas palavras de vocabulário que aprenderam até agora. Como turma, decida sobre uma definição e um exemplo. Peça aos alunos que escrevam isso no quadro e corrijam o trabalho um do outro. Consulte o jogo onde existem disputas.

**Objeto** - um personagem ou coisa pode fazer ações, `hero` <br>
**Função** - uma ação que um objeto pode fazer, `hero.cleave ()` <br>
**Argumento** - informação adicional para uma função, `hero.attack (enemy)` <br>
**Loop** - código que repete, `while True:` <br>
**Variável** - um detentor de um valor, 'inimigo = ...' <br>
**Condicional** - código que verifica se `se hero.isReady ()`: <br>
**Concatenação** - adicionando duas strings juntas, `" string1 "+" string2 "`  <br>

**Aritmética** - usando o Python para fazer matemática, como `2 + 2` <br>
**Propriedade** - atributo pertencente a um objeto, como `item.pos` <br>
**Flags/Bandeiras** - objetos que você colocou para enviar dados para o seu programa <br>
**Retornar** - quando uma função calcula um valor e o retorna <br>
**Booleano** - um valor que é verdadeiro ou falso <br>
**Break** - uma maneira de sair de um loop `while` <br>
**Continue** - uma maneira de pular para o início, ou próxima iteração, de um `loop  while` <br>

### Hora da Programação (30-45 mins)


Peça aos alunos que concluíram o restante do Curso 3 que trabalhem em duplas e naveguem até o último nível, ** Ossos Cruzados**, e concluam em seu próprio ritmo.

Observe que a área do jogador está no canto inferior esquerdo e as tendas podem estar obscurecidas pela barra de status. Os alunos podem pressionar SUBMITER para ver a tela inteira.

Para os alunos com problemas, lembre-os de todas as estratégias de depuração que aprenderam até agora. Diga-lhes que leiam atentamente as instruções e lembrem-se das dicas. Encoraje-os a sentar e pensar em como resolver o problema e a escrever um plano para resolvê-lo antes de começar a codificar.

Os alunos devem abordar esses níveis com os hábitos e a mentalidade de um bom programador e solucionador de problemas fazendo o seguinte:

* Defina o problema
* Quebre o problema em partes
* Faça um plano sobre como resolver o problema
* Preste atenção à sintaxe
* Depurando para encontrar a causa dos erros
* Peça dicas quando necessário

#### Rankings


Quando os alunos vencerem o computador padrão, eles serão colocados no ranking de classe. As equipes vermelhas só lutam contra equipes azuis e haverá classificações de topo para cada uma. Os alunos só competirão com o computador e outros alunos da sua turma CodeCombat .

Note que os rankings de classe são claramente visíveis. Se alguns alunos forem intimidados pela competição ou por serem classificados publicamente, dê a eles a opção de um exercício de escrita:

- Escreva um passo a passo ou um guia para o seu nível favorito
- Escreva uma resenha do jogo
- Projetar um novo nível

#### Dividindo a Turma


Os alunos devem escolher uma equipe para participar: Vermelho ou Azul.  É importante dividir a turma, pois a maioria dos alunos escolherá vermelho. Não importa se os lados estão equilibrados, mas é importante que existam jogadores para ambos os lados. 

- Divida a classe em duas, aleatoriamente, a partir de um baralho de cartas.
- Alunos que entregam seu trabalho cedo juntam-se à equipe azul, e os retardatários jogam no time vermelho.

#### Refinando o Código

O código para Ossos Cruzados pode ser enviado mais de uma vez. Incentive seus alunos a enviar o código, observe como ele se comporta em relação aos colegas de classe e, em seguida, faça melhorias e reenvie. Além disso, os alunos que concluíram o código de uma equipe podem criar código para a outra equipe.

### Reflexão Escrita(5 mins)

**Escreva uma crônica de sua batalha épica do ponto de vista do herói ou do chefe.**
>Eu sou Tharin Thunderfist, o grande herói da batalha de Ossos Cruzados. Juntamente com meu guardião, Okar Stompfoot, eu ataquei os ogros e liberei o vale de sua tirania. Eu recolhi moedas para pagar arqueiros e lutadores para se juntar à batalha. Então eu curei Okar quando ele estava ferido.

**Como você quebrou o problema? Que desafios você enfrentou? Como você os resolveu? Como você trabalhou em conjunto?**
> Primeiro vimos que o código já coletava moedas. Então nós fizemos as tendas quando nós poderíamos ter recursos para contratar combatentes.. Então nós tivemos que pegar a poção, mas estragamos o código. O professor nos ajudou a consertar. Mas nós ainda não vencemos, então pedimos ajuda a outra equipe e eles nos mostraram como derrotar o inimigo. Nós trabalhamos bem juntos. Foi divertido e difícil.
