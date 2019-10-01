##### Plano de Aula
# Ciência da Computação 5 (Python)

### Curriculum Summary
- Recomendado Pré-requisito: Ciência da Computação 4
- 12 x 45-60 minutos de sessões de codificação


### Escopo e Sequência

| Módulo                                                             |
| ------------------------------------------------------------------ |
| [28. Módulo para Arrays](#modulo-para-arrays)                      |
| [29. Funções Pré-definidas](#usando-funcoes-pre-definidas)         |
| [30. Pesquisa por String](#pesquisa-por-string)                    |
| [31. Loops For com 1-passo](#loops-for-com-1-passo)                |
| [32. Array Push](#array-push)                                      |
| [33. Mesma pesquisa de Array](#mesma-pesquisa-de-array)            |
| [34. Fors aninhados como grade](#fors-aninhados-como-grade)        |
| [35. Arrays aninhados como grade](#arrays-aninhados-com-grade)     |
| [36. Acesso de Array 2D ](#acesso-de-array-2d)                     |
| [37. Acesso de Array com Loop For ](#acesso-de-array-com-loop-for) |
| [38. Geometria](#geometria)                                        |
| [39. Conversão de Base Numérica](#conversao-de-base-numerica)      |

##### Módulo 28
## Módulo para Arrays 
### Sumário

Neste módulo, os alunos aprenderão sobre o operador **módulo**. O operador de módulo é um operador aritmético usado para calcular o restante de dois inteiros depois que eles são divididos. O símbolo usado pelo operador é `%`.

O operador de módulo pode ser usado simplesmente para encontrar o resto depois de dividir dois números, mas é freqüentemente usado para outras tarefas na programação. Uma tarefa para a qual é usada é envolvida de volta ao início de uma matriz. Isso é útil ao tentar acessar um índice que é maior que o comprimento do próprio array.

Nesses níveis, os alunos aprenderão como usar o operador de módulo com uma matriz para voltar ao início de uma matriz. Eles usarão essa habilidade para convocar e comandar tropas em batalha.


### Metas
- Entenda o que o operador de módulo faz
- Use o operador de módulo para envolver uma matriz
 


### Atividade Instrutiva: Módulo Clock(10 mins)
#### Explique (3 mins)


Os alunos aprenderam sobre os operadores aritméticos `+`, `-`,` * `e` / `. Hoje, eles aprenderão sobre um novo operador chamado **operador de módulo**. O símbolo para o operador do módulo é `%`.

`%` retorna o resto depois de dividir dois inteiros. Por exemplo:

```
5 % 3 = 2
10 % 7 = 3
1 % 4 = 1
```

Nesse ponto, se os alunos tentarem acessar um índice que esteja fora de uma matriz, eles receberão um erro. Eles podem ter encontrado esse erro já durante o jogo.

Agora, no entanto, os alunos sabem sobre `%` e como usá-lo para encontrar o restante. Eles podem usar isso para envolver uma matriz se o índice for maior que o comprimento da matriz.

Por exemplo, considere a seguinte matriz:

```
summonTypes = ["soldier", "archer", "peasant", "paladin"]

```

Embora o array/matriz tenha apenas quatro elementos, com o uso de `%`, os alunos podem invocar mais de quatro tropas, assim:

```
summonTypes = ["soldier", "archer", "peasant", "paladin"]
for i in range(10):
	type = summonTypes[ i % summonTypes.length ]
	hero.summon(type)
```
O código acima fará com que o herói invoque dez tropas diferentes com base nos tipos listados na matriz `summonTypes`. Especificamente, as tropas serão convocadas nesta ordem:

1. `0 % 4 = 0` so type = `"soldier"`
2. `1 % 4 = 1` so type = `"archer"`
3. `2 % 4 = 2` so type = `"peasant"`
4. `3 % 4 = 3` so type = `"paladin"`
5. `4 % 4 = 0` so type = `"soldier"`
6. `5 % 4 = 1` so type = `"archer"`
7. `6 % 4 = 2` so type = `"peasant"`
8. `7 % 4 = 3` so type = `"paladin"`
9. `8 % 4 = 0` so type = `"soldier"`
10. `9 % 4 = 1` so type = `"archer"`


Observe que, usando o operador `%`, as tropas são criadas na ordem em que estão listadas na matriz `summonTypes`.

#### Interaja (5 mins)


Esta atividade utilizará o operador de módulo para ajudar os alunos a ver e entender o tempo militar. Você pode querer ter um relógio analógico (um com as mãos) como um visual para esta atividade.

Comece perguntando aos alunos se eles já ouviram falar do tempo militar e do que eles sabem sobre isso. Os estudantes podem saber que o tempo militar vai de 0000 horas (leia-se de cem horas) a 2359.

Explique que você deseja que os alunos o ajudem a escrever um código que possa converter o tempo do horário militar para o horário padrão. Comece fazendo com que eles o ajudem a criar uma matriz das horas que são usadas no horário padrão. Porque nossos dias começam com 12:00, você vai querer colocar isso como o primeiro elemento, assim:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
```


Dê aos alunos uma breve descrição do modo como o horário militar funciona, se já não foi mencionado por um dos alunos. Não deixe de dar exemplos de algumas das conversões, por exemplo, 1400 = 2:00 e 1900 = 7:00.

Observe que o código que você escreve com os alunos converterá apenas horas do horário militar para o horário padrão. Assim, para o horário militar de 23 horas, será emitido o horário padrão de 11 horas.

Peça aos alunos que o ajudem a escrever um código que converta uma hora de hora militar em sua hora correspondente no horário padrão:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
hour = standardHours[militaryHour % standardHours.length]
```


Analise alguns exemplos de conversão com os alunos enquanto percorre o código para mostrar como isso funciona. Observe que o restante calculado fornece o elemento da hora padrão correspondente na matriz. Por exemplo, 12% 12 = 0, então isso dá o 0º elemento na matriz, que é 12.

Certifique-se de apontar para o elemento correspondente na matriz com cada conversão. Pode ser útil escrever os números e equações com cada um deles.

Peça aos alunos que ajudem você a adaptar o código para que ele percorra todas as horas do horário militar e o converta para a hora padrão correspondente. Isso deve ser feito com um loop `for`, conforme mostrado abaixo:

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
for (i in range(24)):
	hour = standardHours[militaryHour % standardHours.length]
```


Diga aos alunos agora para imaginarem que um grupo de alienígenas pousa na Terra. Esses alienígenas usam uma maneira de dizer o tempo que é semelhante ao tempo militar, mas em vez de contar até as horas em um dia, eles contam até as horas em uma semana.

Peça aos alunos que o ajudem a adaptar o código para lidar com isso. Isto requer simplesmente mudar o alcance do loop 'for' mostrado acima para percorrer até 24 * 7, ou 168.

```
standardHours = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
# note that you can put either 24 * 7 or 168 in these parentheses
for (i in range(24 * 7)):
	hour = standardHours[alienHour % standardHours.length]
```


Mais uma vez, analise alguns exemplos com os alunos para mostrar como esse código funciona para as conversões.

Ao longo desta atividade, também pode ser útil usar o relógio (se você tiver) como uma forma de mostrar a natureza circular na qual o array é passado usando `%`.


#### Reflita  (2 mins)
**O que o operador `%` retorna?** (O resto depois de dividir dois números).
**Como o operador `%` ajuda a envolver uma matriz?** (Calculando o resto entre um número e o comprimento da matriz para que você nunca tente acessar um índice que esteja fora dos limites.)


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

 

##### Módulo 29
## Usando Funções Pré-Definidas
### Sumário

Neste módulo, o CodeCombat fornece funções predefinidas que podem ser usadas para desenhar formas e posicionar itens a uma certa distância um do outro. Essas funções já estão escritas e devem ser usadas para passar os níveis.

Nesses níveis, os alunos aprenderão sobre esses métodos e praticarão o uso deles. Embora os alunos possam não entender exatamente como as funções funcionam, eles chamarão as funções e usarão os valores de retorno para posicionar soldados e desenhar formas.


### Metas
 

- Chame uma função predefinida e use seu valor de retorno apropriadamente  
- Use elementos diferentes de uma matriz para posicionar um item como desejado

 
### Atividade Instrutiva: Função Pictionary (15 mins)

#### Explique (3 mins)


**Funções predefinidas** são funções que já foram escritas para uso pelos programadores. Os alunos usam funções pré-definidas em muitos módulos anteriores do CodeCombat. Mesmo nos primeiros módulos, os alunos aprenderam como fazer isso chamando métodos como `hero.findEnemies ()`. Embora os alunos não saibam o funcionamento interno da função `findEnemies ()`, eles sabem como chamá-lo e como manipular o valor de retorno.

Neste módulo, os alunos praticarão o uso de funções adicionais predefinidas. Muitas das funções predefinidas nesses níveis são escritas no código inicial para os alunos verem. Parte do código utiliza trigonometria e os alunos podem não entender o que isso significa ou exatamente como funciona. Note que isso é esperado. O foco não é fazer com que os alunos entendam a trigonometria, mas sim praticar as funções de chamada e lidar com a saída.

Por exemplo, considere a seguinte função:


```
# here is a function for drawing a circle
# x, y - center of the circle
# size - length of the circle's radius
def drawCircle(x, y, size):
    angle = 0
    hero.toggleFlowers(False)
    while angle <= Math.PI * 2:
        newX = x + (size * Math.cos(angle))
        newY = y + (size * Math.sin(angle))
        hero.moveXY(newX, newY)
        hero.toggleFlowers(True)
        angle += 0.2
```


Para usar essa função e prever sua saída, os alunos não precisam saber o que cada linha significa ou como ela funciona. Em vez disso, eles precisam simplesmente ler os comentários para ver o que a função faz. Além disso, eles observam a **assinatura de função**, o nome da função, os parâmetros que ela aceita e o que ela retorna.

Observe que os comentários e o nome da função indicam que ela pode ser usada para desenhar um círculo. Assim, os alunos podem inferir que chamar a função resultará em um círculo sendo desenhado.

Na assinatura da função, também se pode ver que a função requer três argumentos, `x`,` y` e `size`. Os comentários da função mencionam que `x` e` y` se referem ao ponto central do círculo. A variável `tamanho` refere-se ao  **raio do círculo**, que é o comprimento da linha desde o ponto central do círculo até a sua borda. Observe que o raio é equivalente do ponto central de um círculo a qualquer uma de suas bordas.

Com base apenas nos comentários e na assinatura da função, os alunos podem chamar a função e prever sua saída corretamente. Por exemplo, para desenhar um círculo com um raio de 5 no ponto (50, 70), basta escrever a seguinte linha de código:


`drawCircle(50, 70, 5)`

Como os comentários indicaram o significado de cada variável, é claro que o valor x do ponto deve ser substituído por `x`, o valor y deve ser substituído por` y` e o raio desejado deve ser substituído por `tamanho` .


#### Interaja (10 mins)


Para esta atividade, você precisará de um papel  básico, com apenas as linhas de grade, para os alunos usarem. Você deve ter pelo menos uma folha para cada aluno.

Comece dividindo os alunos em pares e dando a cada par duas folhas de papel quadriculado. Diga-lhes para trabalharem juntos para criar um design simples usando apenas círculos e quadrados. Eles podem usar uma folha de papel para esboçar seu desenho. Dê a eles cerca de dois minutos para trabalhar em seu design.

Enquanto os alunos trabalham em seus projetos, coloque o seguinte código no quadro:

```
# Here are some functions for drawing shapes:
# x, y - center of the shape
# size - size of the shape (radius, side length)
def drawCircle(x, y, size):
    angle = 0
    while angle <= Math.PI * 2:
        newX = x + (size * Math.cos(angle))
        newY = y + (size * Math.sin(angle))
        hero.moveXY(newX, newY)
        angle += 0.2

def drawSquare(x, y, size):
    cornerOffset = size / 2
    hero.moveXY(x - cornerOffset, y - cornerOffset)
    hero.moveXY(x + cornerOffset, y - cornerOffset)
    hero.moveXY(x + cornerOffset, y + cornerOffset)
    hero.moveXY(x - cornerOffset, y + cornerOffset)
    hero.moveXY(x - cornerOffset, y - cornerOffset)
```


Instrua os alunos a examinar o código no quadro e conversar com seus parceiros para discutir como ele funciona. Em seguida, peça-lhes que trabalhem juntos para determinar uma sequência de chamadas de função, usando os métodos predefinidos no quadro, que produzirão seu design. Cada linha de grade no papel é uma unidade. Note que eles devem anotar a seqüência do código.

Depois de permitir alguns minutos para gerar seu código, faça com que cada par troque seu código por outro par. Cada par deve usar sua segunda folha de papel quadriculado para percorrer o código recebido e extrair a saída dele.

Quando cada par terminar de desenhar o código de outro par, peça-lhes que entreguem a saída desenhada ao par que escreveu o código. Pergunte aos alunos se a saída é o que eles esperavam. Certifique-se de lidar com quaisquer discrepâncias consultando as funções predefinidas.

Se necessário, saliente que os parâmetros `x` e` y` referem-se ao centro de cada forma. Note também que a variável `size` refere-se a todo o comprimento do lado de um quadrado e o raio de um círculo. Percorra um exemplo de cada forma, apontando suas variáveis ​​`x`,` y` e `size` se os alunos precisarem de orientação extra.



**Como você pode dizer o que uma função predefinida faz, mesmo que você não entenda como cada linha funciona?** (Olhando o nome e os comentários da função, você pode decifrar o que ela faz.)

**Como olhar para a assinatura da função (seu nome e argumentos) ajuda ao chamar uma função predefinida?** (olhar para uma assinatura de função ajuda ao chamar uma função porque você pode ver quais argumentos ela requer e garantir que você passe em todos desses argumentos e não causem erro.)




### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:



``` 

##### Módulo 30
## Pesquisa por String
### Sumário


Os alunos usaram as strings e os arrays extensivamente no CodeCombat até o momento. Neste módulo, os alunos aprenderão que as strings são praticamente matrizes de **caracteres** ou letras únicas. Com esse conhecimento, os alunos percorrerão as strings uma letra por vez para encontrar um determinado elemento (caractere) ou índice.

Esses níveis ensinam os alunos a indexar e pesquisar através de strings para detectar espiões, abrir baús de tesouro e escapar da magia negra.

### Metas
- Atravessar uma string um caractere de cada vez
- Encontre um certo caractere em uma string
- Encontre o índice de um caractere em uma string
- Encontre uma string dentro de uma string maior
 

### Atividade instrutiva: Carrasco (10 mins)
#### Explique (2 mins)

Os alunos devem estar muito familiarizados com as strings neste momento. Eles usaram strings muitas vezes durante o jogo, particularmente quando checam contra nomes de amigos e tipos de inimigos:

```
if enemy.type != "sand-yak":
	do something
```


Observe que, em Python, tudo o que aparece entre aspas é considerado uma string. Isso inclui aspas simples, como ` sand-yak`  e aspas duplas, como`"sand-yak"`.

Os alunos também tiveram ampla experiência com matrizes até o momento. Eles escreveram código para percorrer uma matriz, conforme mostrado abaixo:

```
# code to iterate through each friend in the friends array
friends = hero.findFriends()
for i in range(len(friends)):
	friend = friends[i]
```


Os alunos verão nesses níveis que as strings são, de fato, exatamente como matrizes. Eles são semelhantes aos arrays porque são compostos de um conjunto de elementos, em que cada elemento é um único caractere.

Como as strings são como matrizes, elas têm um tamanho e podem ser iteradas exatamente como as matrizes podem:

```
# code to loop through each character in the string 'apple'
word = 'apple'
for i in range(len(word)):
	character = word[i]

```
Iterar através de uma string permite ao programador examinar cada caractere separadamente. Então o programador pode determinar se uma string contém um certo caractere adicionando uma condicional simples, como:

```
for i in range(len(word)):
	character = word[i]
	if character == 'q':
		# do something
```
Os alunos utilizarão o código, como mostrado acima, para retornar valores e índices booleanos, se uma string contiver um determinado caractere.

 

#### Reflita (2 mins)
**O que é semelhante entre arrays e strings?** (as duas arrays e strings têm comprimento e podem ser referenciadas por índices.)
** Que tipo de dados são cada um dos elementos em uma string? ** (Cada elemento em uma string é um único caractere ou letra.)



### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:

```
 

##### Módulo 31
## Loops For com 1-passo
### Sumário


Os alunos usaram loops `for`  várias vezes para iterar por meio de matrizes. Eles também usaram loops `for` para executar uma ação um certo número de vezes, iterando através de uma lista de números. Em cada uma dessas implementações, a iteração acontece um item por vez.

Neste módulo, os alunos aprenderão como usar loops 'for' para iterar por uma lista por mais de um por vez (ou seja, dois de cada vez, três de cada vez, etc.). Eles usarão essa nova habilidade para colocar barreiras em posições igualmente colocadas, a fim de protegerem a si mesmos e aos aldeões.

### Metas
- Use um loop `for` para incrementar em mais de um item por vez
- Coloque os itens a uma certa distância, com o uso de loops `for`
 


### Atividade instrutiva: Team Up(10 mins)
#### Explique (3 mins)

Até agora, os alunos usaram loops `for` para iterar listas e arrays, um item de cada vez. Os alunos também usaram loops `for` para executar uma ação um certo número de vezes, assim:
```
for i in range(4):
	# do something
```

Lembre-se de que o código acima executará a ação 4 vezes, uma vez que cada vez que `i` for 0, 1, 2 e 3.

Loops `for` também podem ser usados com` range () `para incrementar em mais de um valor por vez. A sintaxe geral para isso é a seguinte:

```
for i in range(start, stop, step)
```


`start` refere-se ao valor inicial da iteração,` stop` refere-se ao valor final e `step` refere-se ao valor a ser incrementado a cada vez. Note que o valor `start` está incluído na iteração, mas o valor` stop` não é.

Por exemplo, considere o seguinte segmento de código:

```
for i in range(0, 50, 10):
	hero.say(i)
```

O código acima fará com que o herói diga os números 0, 10, 20, 30 e 40. O herói começa com 0 porque esse é o valor inicial. 50 não é falado porque o valor de parada não está incluído na iteração. 10 indica o número para aumentar `i` a cada iteração.

Note que usando `for` e` range () `desta maneira, as iterações não precisam começar com 0. Por exemplo,
```
for i in range(5, 50, 10):
	hero.say(i)
```

faria com que o herói dissesse os números 5, 15, 25, 35 e 45.

 

### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```
##### Module 32
## Array Push
### Summary


Nos módulos anteriores, os alunos aprenderam como inicializar e iterar por meio de matrizes. Além disso, eles aprenderam como examinar um único elemento e compará-lo a uma determinada condição.

Neste módulo, os alunos aprenderão como filtrar os itens em uma matriz e, em seguida, **empurrar** elementos para uma nova matriz. Empurrar um item para uma matriz aumenta o tamanho da matriz em um, depois adiciona o item como o último elemento na matriz.

Os alunos usarão suas habilidades recém-aprendidas para filtrar moedas e classificá-las em matrizes separadas com base em seu tipo.


### Metas
- Filtrar itens em uma matriz
- Empurrar elementos em uma matriz
 

### Atividade instrutiva: Meninas vs. Meninos(10 mins)
#### Explique (2 mins)

Os alunos aprenderam uma variedade de habilidades relacionadas a matrizes em módulos anteriores. Neste ponto, eles sabem como inicializar matrizes, como percorrê-los e como examinar elementos individuais, como:

```
enemies = hero.findEnemies()
for i in range(len(enemies)):
	enemy = enemies[i]
```
Neste módulo, os alunos aprenderão sobre uma nova função incorporada para matrizes chamada `push ()`. A função `push ()` aceita um elemento como um argumento e adiciona esse elemento ao final da matriz em que é chamado. Por exemplo:
```
friends = []
friends.push('Aurum')
```


O código acima primeiro cria um array vazio chamado `friends`. Então, quando a função `push ()` é chamada, o comprimento da matriz é aumentado em um (então o comprimento é agora 1). `'' Aurum'` é então adicionado no final da matriz, que neste exemplo é o primeiro elemento.

A função push pode ser chamada inúmeras vezes para continuamente empurrar elementos para o final da matriz:

```
friends.push('Argentum')
friends.push('Cuprum')
```
As duas linhas acima adicionam um elemento ao final do array `friends` e preenchem esses elementos com os nomes dos respectivos amigos. O array `friends` agora apareceria assim:

`friends = ['Aurum', 'Argentum', 'Cuprum')`


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

##### Módulo 33
## Mesma Pesquisa de Array
### Sumário


Os alunos aprenderam a pesquisar em uma matriz por um elemento específico. Eles também aprenderam a examinar elementos únicos com base em uma determinada condição. Além disso, os alunos aprenderam a usar loops `for` aninhados para iterar em dois arrays ao mesmo tempo.

Neste módulo, os alunos combinarão essas habilidades para aprender como pesquisar por duplicatas dentro da mesma matriz. Fazendo um loop pelo mesmo array duas vezes e comparando elementos entre si, os alunos escreverão código para procurar por gemas e paladinos correspondentes. Eles também utilizarão lógica semelhante para encontrar a distância mínima entre um conjunto de itens.

### Metas
- Use loops `for` aninhados para percorrer o mesmo array duas vezes
- Comparar elementos dentro da mesma matriz
- Encontrar itens duplicados em uma única matriz



### Atividade instrutiva: O Paradoxo do Aniversário (10 mins)
#### Explique (2 mins)



Encontrar duplicatas de um conjunto é uma tarefa comum na solução de problemas. Como os alunos viram nos módulos anteriores, um conjunto de itens é frequentemente armazenado como um array.

Para encontrar duplicatas em uma matriz, cada item deve ser comparado a todos os outros itens da matriz. Isso requer um loop através da matriz para examinar cada elemento, em seguida, percorrer o restante da matriz para comparar cada elemento a ser examinado no loop externo.

A sintaxe para fazer isso é escrita assim:

```
for i in range(len(array)):
	elemI = array[i]
	for j in range(len(array)):
		if i == j:
			continue
		elemJ = array[j]
		if elemI == elemJ:
			# do something
```

Observe que tanto o loop externo quanto o interno passam por cada elemento do array, um de cada vez. Assim, é necessário verificar se `i` e` j` não são iguais para assegurar que os valores encontrados sejam duplicados reais e não o mesmo elemento.



### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


##### Módulo 34
##  Fors aninhados como Grade
### Sumário


Neste módulo, os alunos usarão suas habilidades de loops `for` aninhados para construir uma grade. Eles farão isso com um laço `for` que itera através das coordenadas x e outro loop` for` que percorre as coordenadas y.

Em seguida, os alunos definirão os loops `for` aninhados para incrementar em mais de uma para colocar as minas e acordar os soldados em forma de grade, a fim de defender a aldeia.


### Metas
- Use loops `for` aninhados para criar uma grade virtual
- Atravessar loops `for` aninhados para colocar itens ou executar ações de maneira semelhante à grade.


### Instructive Activity: Treasure Hunter (10 mins)
#### Explain (3 mins)


Os alunos usaram loops `for` aninhados em módulos anteriores para percorrer os elementos de uma matriz e executar uma ação em cada item um determinado número de vezes.

Neste módulo, os alunos usarão aninhamentos `for` aninhados para criar uma grade virtual. Isso permitirá que eles coloquem itens e executem ações de maneira semelhante a uma grade (ou seja, em linhas e colunas).

Ao usar loops `for` aninhados como uma grade, um loop inicializa as linhas e o outro loop inicializa as colunas. Por exemplo, considere o seguinte segmento de código:

```
for x in range(10, 100, 10):
	for y in range(10, 100, 10):
		hero.moveXY(x, y)
```

Percorra o código acima, tendo em mente o fluxo de controle. Observe que a primeira linha de código itera através de coordenadas x de 10 a 100 com uma etapa de 10. A próxima linha de código, que é o loop interno, itera as coordenadas y de 10 a 100 com uma etapa de 10 **para cada coordenada x**.

O efeito do código acima pode ser visualizado da seguinte forma:

```
# the hero moves to each tile in a 100 x 100 square

# (10, 10)	(20, 10)  (30, 10) ... (90, 10)
#    |	   /	|	 /	  |    /	   |
#    V	  /		V	/	  V	  /		   V
# (10, 90)	(20, 90)  (30, 90) ... (90, 90)
```


Observe que o herói se move para a primeira coordenada x, então se move para baixo para as coordenadas y apropriadas para aquela coordenada x. O herói então se move para a próxima coordenada x na coordenada y original e desce novamente a coluna das coordenadas y apropriadas.

Note que o herói pode atravessar uma linha de cada vez (em vez de uma coluna de cada vez), mudando a ordem dos loops para que o loop de coordenada y `for` chegue primeiro.



#### Reflita (2 mins)

**Como os loops aninhados são usados para criar uma grade virtual?** (Loops Aninhados `for` são usados para criar uma grade virtual primeiro configurando um loop para passar por cada coordenada x, em seguida, percorrendo cada coordenada y para. Esse x examina uma coordenada x, passa pelas coordenadas y para esse x, depois passa para a próxima coordenada x e faz a mesma coisa.

**Como os loops `for` devem ser inicializados para percorrer uma grade uma linha de cada vez?** 
(Para percorrer uma grade uma linha de cada vez, você deve configurar o loop externo` for` para examinar cada coordenada y. O loop interno `for` passaria então por cada coordenada x para esse y.A próxima iteração do loop` for` externo moveria o fluxo para a próxima coordenada y e passaria por cada coordenada x para que y.)


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

##### Módulo 35
## Arrays Aninhados com Grade
### Sumário


Arrays podem conter qualquer tipo de dados ou objeto. Nos módulos anteriores, os alunos viram matrizes de inteiros, cordas, inimigos e muito mais. Neste módulo, eles aprenderão que um array pode manter arrays.

Esses arrays **aninhados** ou **2D** podem ser usados para representar grades virtuais, semelhantes àquelas usadas no módulo anterior. Nesses níveis, os alunos usarão matrizes aninhadas para colocar armadilhas e cercas de maneira semelhante a uma grade.

### Metas
- Use matrizes aninhadas para criar uma grade virtual
- Atravessar arrays 2D com o uso de loops `for` aninhados
- Acessar uma linha, coluna ou elemento de uma matriz aninhada 

### Atividade instrutiva: Grade de Salto (10 mins)
#### Explique (3 mins)



Nesses níveis, os alunos verão que os arrays podem conter outros arrays! Os arrays em que cada elemento é outro array são chamados de **aninhados** ou **matrizes 2D**.

Arrays aninhados são representados como grades e podem ser visualizados da seguinte forma:

```
arrayGrid = [
	[0, 1, 0, 0],
	[2, 0, 0, 3],
	[0, 0, 4, 0],
	[0, 0, 1, 5] ]
```

Observe que a visualização mostra cada matriz como uma linha separada. Assim, cada matriz representa uma linha na grade. As colunas da grade são compostas dos elementos em cada matriz na mesma posição. A primeira coluna é cada elemento com um índice de 0 de cada matriz, a segunda coluna é cada elemento com um índice de 1 e assim por diante.

Como no módulo anterior, os loops `for` aninhados são usados para iterar pela grade. O primeiro loop, ou externo, `for` itera através do array externo. A sintaxe desse loop deve ser familiar para os alunos:

```
for i in range(len(arrayGrid)):
```


Note que este loop percorre cada item de arrayGrid, um de cada vez. Lembre-se de que cada item é também um array e que esses arrays internos são representativos das linhas da grade. Assim, `arrayGrid [i]` refere-se a uma matriz ou linha diferente, com cada iteração do loop.

Em seguida, um segundo loop for for aninhado dentro do primeiro. Isso permite a iteração de cada matriz ou linha interna. Note que, como cada linha é uma matriz, a propriedade `length` deve ser usada para percorrer cada elemento. Os loops `for` aninhados serão escritos da seguinte forma:

```
for i in range(len(arrayGrid)):
	for j in range(len(arrayGrid[i])):
```


Lembre-se que cada elemento em `arrayGrid` é uma matriz. Assim, `arrayGrid [i]` é uma matriz. Como é um array, ele é iterado como qualquer outro array, com um loop for no intervalo de comprimento.

Depois que os loops `for` aninhados são inicializados, um único elemento pode ser acessado chamando cada um de seus elementos, assim:

```
for i in range(len(arrayGrid)):
	for j in range(len(arrayGrid[i])):
		value = arrayGrid[i][j]
```
A variável `value` pode então ser usada como qualquer outra variável.


#### Reflita (2 mins)

**Como uma matriz 2D atua como uma grade?** (Uma matriz 2D atua como uma grade porque cada elemento na matriz é uma matriz. Cada uma dessas matrizes é como uma linha na grade, enquanto cada um dos elementos o array interno é como uma coluna.)

**Descreva o processo usado para percorrer um array 2D.** (Para percorrer um array 2D, você configura dois loops `for` aninhados. O primeiro, ou loop externo, passa pelo array externo, acessando cada array interno ou linha, uma de cada vez.O loop interno passa por cada linha acessando cada elemento, um de cada vez.



### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```



##### Módulo 36
##  Acesso de Array 2D
### Sumário


No último módulo, os alunos aprenderam a usar e percorrer os arrays 2D como grades. Eles iteraram através do array com loops `for` aninhados para acessar cada elemento na grade, um de cada vez. Embora geralmente seja útil iterar por meio de cada elemento de uma matriz aninhada, há momentos em que apenas um único elemento deve ser acessado.

Neste módulo, os alunos aprenderão como acessar elementos específicos de uma grade de matriz 2D. Ao acessar células específicas, os alunos serão capazes de definir armadilhas e atirar munição em alvos específicos.

### Metas
- Acessar um elemento específico de um array 2D
- Use indexação baseada em zero para matrizes aninhadas



### Atividade Instrutiva: Tic-Tac-Toe (10 mins)
#### Expique (3 mins)


Nos últimos níveis, os alunos usaram loops `for` aninhados para iterar através de matrizes aninhadas e acessar cada elemento um de cada vez. Nesses níveis, os alunos aprenderão como acessar elementos específicos de uma matriz aninhada, em vez de todos eles.

Os alunos devem estar familiarizados com a sintaxe para acessar um elemento específico de um único array. Isso pode ser feito usando o nome da matriz com o índice do elemento a ser acessado. Os alunos devem lembrar que os índices de array sempre começam em 0.

Por exemplo, para acessar o segundo elemento de um array chamado `array`, a seguinte linha de código poderia ser usada:

```
# code to access the 2nd element of an array.
element = array[1]
```
Lembre-se de que os arrays 2D podem ser visualizados como grades, como mostrado abaixo:

```
grid = [
	[0, 1, 2],
	[3, 4, 5] ]
```

Observe que `grid` tem 2 matrizes internas ou linhas e 3 colunas. Para acessar um elemento específico da matriz, use o nome da matriz com dois índices - o índice de sua matriz, ou linha, em `"grid"` e o índice do elemento dentro de sua matriz interna.

Por exemplo, para obter o elemento "1" acima, use o seguinte código:

```
one = grid[0][1]
```

Note que porque `1` está na primeira linha, o índice de sua matriz dentro de` grid` é 0. Como `1` está na segunda posição de sua matriz, seu índice dentro da matriz é 1. Assim, o índice de `1` dentro de` grid` é `[0] [1]`.

O código a seguir mostra a sintaxe para obter o valor de outros elementos de `"grid"` mostrados acima:

```
# get the first element
grid[0][0] #returns 0

# the last element
grid[1][2] #returns 5

# the first element of the second row
grid[1][0] #returns 3
```

Lembre-se de que o índice da linha do elemento sempre vem antes do índice de sua coluna.


#### Reflita (2 mins)

**Como você acessaria o 3º elemento da segunda linha em um array 2D chamado `grid`?** (` grid [1] [2] `)

**Ao acessar um elemento em uma matriz 2D, por que o índice da linha vem antes do índice da coluna?** (O índice da linha vem antes do índice da coluna porque você primeiro precisa encontrar em qual array, ou linha, o elemento está. você encontra qual posição nessa matriz o elemento é.



### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```



##### Módulo 37
##  Acesso de Array com Loop For
### Sumário

Os alunos usaram matrizes muitas vezes em módulos anteriores. Eles aprenderam a criar, acessar e percorrer arrays em vários níveis diferentes. Neste módulo, os alunos usarão suas habilidades de programação existentes para interagir com os arrays de uma nova maneira. Especificamente, eles irão escrever código para fazer um loop através de múltiplos arrays simultaneamente. Ao fazer isso, eles ajudarão um lugar de pastores e cuidarão de suas renas adequadamente.

### Metas
- Faça um loop por várias matrizes de uma só vez
- Associar os elementos de um array a outro


### Atividade Instrutiva: Robô de Chamada (10 mins)
#### Explique (3 mins)
Os alunos usaram matrizes muitas vezes em módulos anteriores. Eles aprenderam como usar o índice de um elemento para acessar ou definir um elemento específico como desejarem:

```
array = [null, "one", "two"]

# accesses the second element, at index 1, returning "one"
element = array[1]

# sets the first element, at element 0
array[0] = "zero"
```

Os alunos também aprenderam como fazer um loop através de arrays com um loop `for'`, assim:

```
for i in range(len(array)):
	# do something
```


Neste módulo, os alunos usarão suas habilidades de programação existentes para percorrer várias matrizes simultaneamente. Isso é particularmente útil ao tentar rastrear algum tipo de informação sobre os itens em uma matriz.

Por exemplo, suponha que o herói do aluno tenha cinco amigos por perto e queira acompanhar o papel de cada amigo (por exemplo, "soldado" ou "arqueiro"). Para fazer isso, o aluno poderia criar uma matriz para manter a função de cada amigo, assim:

`friendRoles = ["unknown", "unknown", "unknown", "unknown", "unknown"]`


Para começar, o aluno poderia preencher esse array com strings como "unknown", uma string vazia ("" "`), ou outra frase, já que as funções ainda não são conhecidas.

Para preencher o array com os papéis apropriados, o aluno pode encontrar os amigos perto do herói, pegar seus papéis e armazená-los no array `friendRoles`:

```
# this array creates all of the friends
friends = hero.findFriends()

# loop through each friend and fill in the friendRoles array with their role
for i in range(len(friends)):
	friend = friends[i]
	friendRoles[i] = friend.type
```


Observe que o papel de cada amigo é armazenado no mesmo índice no array `friendRoles` quando o amigo é armazenado no array` friends`. Em outras palavras, o papel para o amigo em `friends [0]` é armazenado em `friendRoles [0]`, o papel para o amigo em `friends [1]` é armazenado em `friendRoles [1]`, etc.

Uma vez que a matriz para `friendRoles` seja preenchida corretamente, ela também pode ser colocada em loop. Por exemplo, o herói poderia dizer o papel de cada amigo em voz alta usando código como este:

```
for i in range(len(friendRoles)):
	hero.say("The friend at index " + i + " is a " + friendRoles[i])
```



#### Reflita (2 mins)

**Por que os arrays são úteis para rastrear os dados?** (Arrays são úteis para rastrear os dados porque os dados são todos armazenados juntos em um lugar e podem ser passados facilmente).

 

### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```


##### Módulo 38
## Geometria
### Sumário

Neste módulo, os alunos aprenderão conceitos básicos de geometria e os implementarão via código. Em particular, eles escreverão código que calcula a área e o perímetro de um retângulo e também comandarão soldados em um quadrado.


### Metas
- Computacionalmente, calcular o perímetro e a área de um retângulo
- Computacionalmente formar os 4 pontos de um quadrado


### Atividade Instrutiva: Design de Interiores (10 mins)
#### Explique (3 mins)


Nesses níveis, espera-se que os alunos tenham uma compreensão dos conceitos básicos de geometria relacionados a retângulos e quadrados. Abaixo está uma sumarização desses conceitos para dar aos alunos uma atualização, se necessário.

Um **retângulo** é uma forma que tem quatro lados e quatro cantos. Note que esta é a forma da maioria das salas, portas e janelas. Um **quadrado** é um tipo especial de retângulo que possui quatro lados do mesmo comprimento.

O **perímetro** de um objeto é o comprimento total de suas arestas. Para os retângulos, pode-se encontrar o perímetro simplesmente adicionando os comprimentos dos quatro lados juntos.

A **área** de um objeto é a medida do seu tamanho ou espaço dentro das bordas. Para encontrar a área de um retângulo, pode-se multiplicar o comprimento de um lado pelo comprimento do lado ao lado (mas não através dele).

Para calcular a área e o perímetro via código, basta executar a aritmética com os operadores apropriados.

Por exemplo, as seguintes linhas de código computariam a área e o perímetro de um retângulo com os lados `side1` e` side2`:
```
area = side1 * side2
perimeter = side1 * 2 + side2 * 2
```


#### Reflita (2 mins)

**Como você encontra a área de um retângulo se tiver uma variável para cada um dos lados?** (Você pode encontrar a área simplesmente multiplicando os lados, como `side1 * side2`.)

**Como você encontra o perímetro de um retângulo se tiver uma variável para cada um dos lados?** (Você pode encontrar o perímetro multiplicando cada lado por 2 e depois adicionando os produtos juntos, como `side1 * 2 + side2 * 2`)


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```

##### Módulo 39
## Conversão de Base Numérica
### Sumário


O sistema numérico com o qual os alunos e a maioria das pessoas estão familiarizados é chamado de **base-10**. Este é o sistema numérico usado em todo o mundo para matemática, contagem, transações financeiras, etc. No entanto, os computadores geralmente trabalham em outros sistemas numéricos, particularmente **binário**, sobre os quais os alunos já ouviram falar antes.

Neste módulo, os alunos aprenderão sobre sistemas numéricos ** binário **, ou ** base-2 ** e ** ternário **, ou ** base-3 ** . Eles escreverão códigos que usam os operadores `/` e `%` para converter entre sistemas numéricos, a fim de comandar robôs e defender-se contra brawlers.

### Metas
- Compreender a diferença entre os sistemas numéricos base-10, base-2 e base-3
- Converta números de base-10 para base-2 ou base-3
- Converta números de base-2 ou base-3 para base-10



### Atividade Instrutiva: uma mensagem de extraterrestres (20 mins)
#### Explique (10 mins)


O sistema numérico que é usado diariamente é referido como **base-10** ou **decimal**. É chamado assim porque cada dígito pode ser representado por um de 10 números que variam de 0 a 9. Um número de dígito único tem 10 possibilidades de 0 a 9. Um número de dígito duplo tem 100 possibilidades, de 00 a 99.

Além disso, esse sistema numérico é chamado de base-10 porque cada dígito de um número simboliza um fator de dez. Por exemplo, considere os seguintes números:
```
11			10 + 1				1 * 10 + 1 * 1
23			20 + 3				2 * 10 + 3 * 1
456			400 + 50 + 6		4 * 100 + 5 * 10 + 6 * 1

```


Observe nos números acima que cada dígito é representativo de uma potência diferente de 10, dependendo de seu posicionamento no número. No número 456, o primeiro dígito, 4, está no lugar dos 100; o 5 está no lugar dos 10 e o 6 está no lugar do 1. O número em cada ponto é então multiplicado pela potência apropriada para obter o número final. Portanto, neste exemplo, 4 é multiplicado por 100, 5 por 10 e 6 por 1 para obter 456.

Se os alunos estiverem familiarizados com expoentes, você pode descrever como esses poderes são mostrados exponencialmente. O lugar dos 100's é 10 para a 2ª potência, o 10's é 10 para a 1ª potência, e o da 1 é 10 para a 0ª potência. Se os alunos ainda não aprenderam expoentes, simplesmente observe que o dígito mais à direita está sempre no lugar de 1, e cada dígito à esquerda aumenta multiplicando por 10 a cada vez.

Números de ** Base-2 **, ou ** binário **  funcionam de forma semelhante à base-10, exceto que em vez de 10 possibilidades numéricas para cada dígito, existem apenas 2 - os números 0 e 1. Similarmente, cada dígito sobe por uma potência de 2, em comparação com a potência de 10 usada no sistema de números de base 10.

Considere os seguintes números de base 2:

```
10			2 + 0				1 * 2 + 0 * 1
111			4 + 2 + 1			1 * 4 + 1 * 2 + 1 * 1
1011		8 + 2 + 1			1 * 8 + 0 * 4 + 1 * 2 + 1 * 1

```


Observe nos números acima que cada dígito é representativo de uma potência diferente de 2. No número 1011, por exemplo, o primeiro 1 está no lugar do 8, o 0 está no lugar do 4, e os próximos dois estão no 2 e 1 lugar.

Mais uma vez, se seus alunos estiverem familiarizados com expoentes, você poderá explicar os dígitos em termos de 2 para diferentes poderes. O dígito mais à direita é de 2 à 0º potência, o dígito à esquerda é 2 à primeira potência, à esquerda é 2 à segunda potência e assim por diante.

Se os seus alunos não estão familiarizados com expoentes, então aponte que cada dígito é representativo do dígito à direita multiplicado por 2. O dígito mais à direita representa 1, o próximo à esquerda representa 2, o próximo 4, e assim por diante .

Note que para converter números base-2 para base-10, pode-se simplesmente multiplicar o número pelo fator apropriado para aquele dígito e depois adicioná-los todos juntos. Por exemplo, para converter o número 1011, comece multiplicando cada dígito pela potência correspondente a 2, ou seja, 1 * 8, 0 * 4, 1 * 2 e 1 * 1. Os produtos encontrados - 8, 0, 2 e 1 - pode então ser adicionado para encontrar o número decimal, 11.

Para converter um número de base-10 para base-2, deve-se dividir repetidamente por 2 e anotar o restante a cada vez. Como o restante pode ser apenas 0 ou 1, isso fornece os números a serem usados ​​na representação binária.

Por exemplo, observe as etapas usadas para converter o número 13 em binário:

```
13 / 2 = 6, with remainder = 1
6 / 2 = 3, with remainder = 0
3 / 2 = 1, with remainder = 1
1 / 2 = 0, with remainder = 1

# remainders from bottom to top give the binary representation
13 in binary is 1101
```


Note que depois de dividir o número por 2, o quociente (resposta encontrada da divisão) é então dividido por 2 até que o quociente seja 0. Os restantes são então ordenados de baixo para cima para formar a representação binária do número.

** Base-3 **, ou ** ternário ** funciona de forma semelhante à base-2 e base-10, exceto que cada dígito pode ser representado por 3 números - 0, 1 ou 2. Além disso, cada dígito de um número representa uma potência diferente de 3.

Por exemplo, considere os seguintes números de base 3:

```
10			3 + 0				1 * 3 + 0 * 1
112			9 + 3 + 2			1 * 9 + 1 * 3 + 2 * 1
1021		27 + 0 + 6 + 1		1 * 27 + 0 * 9 + 2 * 3 + 1 * 1

```

Observe nos números acima que cada dígito representa uma potência diferente de 3. Por exemplo, no número 112, o primeiro 1 está no lugar do 9, o próximo está no lugar do 3 e o 2 está no lugar do 1. Como nos números de base 2 e 10, o dígito mais à direita é sempre representativo dos 1s.

Como mencionado acima, se os alunos estão familiarizados com expoentes, você também pode mostrar cada dígito no que se refere a potências de 3. O dígito mais à direita é 3 à potência 0, o próximo dígito à esquerda é 3 à 1ª potência, a esquerda disso é 3 para o segundo e assim por diante.

Tal como acontece com os números da base 2, para converter os números da base 3 para a base 10, pode-se multiplicar o número pelo fator apropriado para esse dígito e depois adicionar os produtos juntos. Por exemplo, para converter o número 1021, primeiro multiplique cada dígito pela sua potência correspondente de 3 - 1 * 27, 0 * 9, 2 * 3 e 1 * 1. Os produtos encontrados - 27, 0, 6 e 1 - pode então ser adicionado para encontrar o número decimal, 34.

Para converter números base-10 para base-3, siga os mesmos passos usados ​​para converter em base-2, exceto dividir o número por 3 em vez de 2. Por exemplo, observe os passos abaixo para converter 13 de base-10 para base 3:

```
13 / 3 = 4, with remainder = 1
4 / 3 = 1, with remainder = 1
1 / 3 = 0, with remainder = 1

# remainders from bottom to top give the ternary representation
13 in ternary is 111
```

Abaixo está uma lista dos números de 0 a 10 em base-10, base-2 e base-3:
```
Base-10:			Base-2:			Base-3:
0					0					0
1					1					1
2					10					2
3					11					10
4					100					11
5					101					12
6					110					20
7					111					21
8					1000				22
9					1001				100
10					1010				101

```



#### Reflita (2 mins)

**Como o nosso sistema numérico (base-10) difere da base-2 e base-3?** (O sistema numérico base-10 difere da base-2 e base-3 porque é baseado no número 10. significa que cada dígito pode ter um de dez números diferentes e que cada dígito em um número representa uma potência diferente de 10.)

**Descreva o processo usado para converter números de base-10 para base-2 ou base-3.** (Para converter um número de base-10 para base-2 ou base-3, você divide o número pela base quer, coloque o restante na frente do número convertido e repita.)


### Hora da Programação (30-45 mins)


Permita que os alunos participem do jogo em seu próprio ritmo, anotando todos os níveis em papel ou documento digital. Recomendamos o uso do seguinte formato, que você também pode imprimir como modelos: [Diário de Progresso [PDF]](http://files.codecombat.com/docs/resources/ProgressJournal-pt-BR.pdf)

```
Nível #: _____  Nome do Nível: ____________________________________
Objetivo: __________________________________________________________
O que eu fiz:

O que eu aprendi:

Qual foi o desafio:


```
