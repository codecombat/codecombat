##### Plano de Aula
# Desenvolvimento de Web 1

### Sumário do Currículo

#### Visão Geral
No curso de Desenvolvimento de Web 1, os alunos aprenderão os conceitos básicos do desenvolvimento da web, começando com HTML e CSS.

Para Fazer: Explique como este guia é apresentado (diferentemente de outros guias do curso)
Para Fazer: Explique como usar o projeto - brainstorm que leva ao cartaz de procurado. Construa o universo com atividades não codificadoras.

_**Nota da Linguagem** Desenvolvimento de Web 1 usa HTML e CSS, independentemente da linguagem de programação em que sua classe está definida._

### Escopo e Sequência

| Módulo                                              |Metas               |
| ----------------------------------------------------|:--------------------------- |
| [1. Sintaxe Básica de HTML](#basic-html-syntax)          | Uso das tags `<br>` e `<p>` para quebra de página e parágrafo. |
| [2. Imagens & Atributos](#images-attributes)       | Adicione e redimensione uma imagem usando a tag `<img>` . |
| [3. Organização](#organization)                    | Organize uma página de Web usando `<div>` e a lista de tags como `ul`, `ol` e `li`. |
| [4. Sintaxe CSS](#css-syntax)                        | Controle elementos de estilo de uma página usando `<style>` e tags CSS. |
| [5. Seletores CSS ](#css-selectors)                  | Adicione estilos personalizados a uma página da Web usando classes e IDs. |
| [6. Projeto Final](#final-project)                  | Demonstrar conhecimento de HTML / CSS adicionando elementos. |

### Vocabulário Básico

**HTML** - 

**CSS** -

**Tags** -

**Atributos** -

**Seletores** -

##### Módulo 1
## Sintaxe Básica de HTML 

### Sumário

**HTML**, significa **H**yper**T**ext **M**arkup **L**anguage, é uma linguagem usada para criar documentos para a web. Este primeiro módulo trata da introdução de HTML aos alunos fazendo com que eles coloquem algo na página e dando a eles a chance de ver como o conteúdo que eles adicionam ao documento evolui com o uso de tags, atributos e estilos em módulos posteriores.

### Metas
- Adicionar conteúdo a um documento HTML
- Reconhecer os sinais `<` e  `>` nas tags de HTML.
- Uso da tag `<br>` para adicionar quebra de linha em um documento HTML.
- Reconhecer quando a sintaxe HTML começa e termina.
- Uso da tag `<p>` para adicionar um parágrafo em um documento HTML.
- Uso das tags `<h1>`, `<h2>`, `<h3>`, e `<h4>`  para adicionar seções de cabeçalho significativas a uma página HTML, juntamente com a tag `<p>` para conteúdos em parágrafos.


### Editor HTML

#### Atividade instrutiva: tinta na página

Páginas da Web são compostas de documentos - texto em uma página, assim como livros e revistas. Eles podem ser muito mais do que isso, com vídeos, jogos e outras coisas interativas excitantes - mas, na base de tudo isso, temos páginas em HTML.
 **HTML**significa **H**yper**T**ext **M**arkup**L**anguage, e é um dos blocos de construção da web.

HTML não é apenas texto normal. Possui tags que executam tarefas especiais (como incorporar imagens ou dividir parágrafos). Essas tags são escritas na página, mas quando você as visualiza em um navegador, as tags em si não aparecem - são as coisas dentro delas que você vê. Também é geralmente visto com CSS - que permite alterar o estilo da página - cores, fontes e layouts legais, e às vezes JavaScript - que permite tornar a página interativa.

Nós vamos dar início a uma série de lições nas quais você pode ter um texto simples e entediante em uma página e torná-lo muito mais interessante. A primeira coisa que precisamos fazer é impedir que a página fique em branco, então vamos começar a adicionar conteúdo!

#### Hora da Programação

Peça aos alunos que adicionem e removam conteúdo da página de amostra no editor (Nível 1 - Começos Humildes). Incentive-os a adicionar muito texto (várias linhas valem), não apenas algumas palavras. Se os alunos precisarem de um aviso, peça-lhes para escrever uma pequena biografia para seu herói ou um anúncio para sua espada favorita.

#### Reflexão

**O que você escolheu para escrever na página?**
>Eu escrevi uma introdução de diário sobre o meu personagem herói. Seria muito legal se meu herói tivesse um blog.


### A tag `<br>`

Vamos explorar nossa primeira tag HTML com`<br>`. Esta tag nos permite inserir quebras de linha em uma página.

#### Atividade instrutiva: Quebra de linha (10-15 mins)

Quantos de vocês apertaram a tecla enter quando queriam colocar algum espaço entre as coisas que você escreveu? (procure por mãos levantadas)

Funcionou? (não!)

É aqui que vamos usar nossa primeira tag HTML e ver alguns dos trabalhos por trás das cenas que você pode fazer com essas tags. Nossa primeira tag é chamada *break/quebra*, e se parece com isso:

`<br>`

Você pode consultar seu documento sempre que quiser ver uma quebra de linha.

#### Interaja (3 mins)

Vamos em frente e ver as coisas que você escreveu na página no Nível 1. Adicione algumas tags `<br>`  onde você apertaria a tecla enter, ou onde você acha que uma nova linha deve começar.

#### Explique (2 mins)

Ok, alguém viu as letras`br` misturado com suas palavras no lado esquerdo do nível? (se sim, certifique-se de que eles fecharam os símbolos de maior e menor).

A razão pela qual você acabou de ver os espaços em vez das coisas que você digitou na tag (`<br>`) é porque esses símbolos de maior e menor estão dizendo ao navegador que a tag deve ser lida como uma instrução, não exibida na página.

Nós podemos reconhecer `elementos` de HTML por estas `tags`. Eles sempre serão incluídos em `<` símbolos de maior e menor `>`. Algumas tags, como as que veremos mais tarde, têm dois conjuntos de símbolos e alguns (como `<br>`) têm `auto-fechamento` e precisam apenas de um conjunto.

Uma boa maneira de saber se uma tag deve ser de fechamento automático ou não: * ela coloca algo na própria página? * (Como uma quebra ou uma linha horizontal) ou * a tag diz ao navegador como mostrar algo sobre a página? * (como texto ou uma imagem)

#### Interaja (3-5 mins)

Agora, vamos usar as quebras de página, para que possamos ver como as coisas podem ficar um pouco engraçadas se não escrevermos nossas tags corretamente.

Peça aos alunos que "estraguem" os seus suas tags `<br>`  adicionando espaços a eles ou colocando outro texto neles. Circule conforme eles mudam o que aparece no lado esquerdo do editor e peça aos alunos que tentem coisas como:

*começando um texto*
```
CodeCombat é muito legal.
Meu Herói é o mais legal.
```

*adicionando uma tag br sem o símbolo de maior e menor*
```
CodeCombat é muito legal.
br
Meu Herói é o mais legal.
```

*Esquecendo de fechar a tag*
```
CodeCombat é muito legal. <br
Meu Herói é o mais legal.
```

#### Reflexão (2 mins)

**Como é uma tag HTML?** O nome do elemento dentro dos símbolos de maior e menor é `< element >`

**Se eu apenas apertar a tecla enter entre coisas em uma página, o que acontecerá?** O texto ficará na mesma linha


#### Hora de Programação (5-8 mins)

Se os alunos estiverem com dificuldades para concluir o nível, peça-lhes que se certifiquem de que estão colocando corretamente a tag `<br>` .



### A tag `<p>` de parágrafo

Desmembrando cada parágrafo em HTML com a tag `<br>` não é o mais eficaz. Este módulo explora o built-in  da tag de **parágrafo** (`<p> </p>`) que nos permite agrupar e formatar o texto do parágrafo. Também é nossa introdução às tags de* abertura * e * fechamento *.

#### Atividade instrutiva: rompê-lo (8-10 mins)

uando você lê texto (em livros, em revistas, na internet), é sempre dividido em linhas simples? Provavelmente não - você provavelmente está acostumado a ler parágrafos. Felizmente, HTML tem a solução para isso com -- a tag `<p>` .

Nós usamos `<br>` para fazer quebras de linha única, mas se precisarmos de um grupo de texto para aparecer na página como um parágrafo, podemos envolvê-lo em tags de parágrafo.

Este é o nosso primeiro elemento HTML que possui uma tag de abertura e fechamento. (Desenhe no quadro branco e identifique as partes - os colchetes em torno de ambos os p's, e a / que indica a tag de fechamento)

`<p>` <--- abertura
`</p>` <--- fechamento

Qualquer texto que quisermos que seja um parágrafo vai entre as tags, desta maneira:

`<p>Oi, sou um parágrafo Eu tenho duas frases.</p>`


#### Interaja (3 mins)

Peça aos alunos que adicionem mais texto ao seu editor (ou trabalhem fora do nível anterior) e certifique-se de que haja pelo menos dois parágrafos de texto. Peça-lhes para tentar envolver frases com tags `<p>` , e ver o que acontece se eles misturam e combinam as tags `<p>` com tags `<br>` (ou troque as tags `<br>` por `<p>`).

Circule e lembre aos alunos que esses elementos vêm com tags de abertura e fechamento.

#### Reflexão (2 mins)

**Quais são as diferenças das tags `<br>` e `<p>` **
> A tag `<br>` faz quebra de linha enquanto a tag `<p>` é para fazer parágrafos. A tag `<br>` é de auto-fechamento e a tag `<p>` tem tags de abertura e fechamento.


#### Hora da Programação (5-8 mins)

Se os alunos estiverem com dificuldades para concluir o nível, peça que eles se certifiquem de que estão abrindo e fechando corretamente as tags.

### A tag `<h>`

Construindo a lição anterior sobre tags de parágrafo, vamos introduzir **tags de títulos** agora

#### Atividade instrutiva: manchete de notícias (8-10 mins)

*Prepare o quadro branco com este texto, tomando o cuidado de usar tamanhos de fonte diferentes para indicar a distinção entre texto do título, sub cabeçalhos e texto de parágrafo comum*

*OU Imprima um artigo de jornal aqui!*

*** 
# Guia do Aventureiro

## Como começar

### Equipamento
Espada   
Escudo 

### Habilidades

tiro com arco
luta de espadas
Magia

## Dungeons Legais
Kithgard
Plainswood
***

Isto é o que pode parecer sem qualquer estilo. 

*** 
Guia do Aventureiro  
Como começar

Equipamento  
Espada  
Escudo  

Habilidade  
tiro com arco  
luta de espadas  
magia

Dungeons  Legais
Kithgard
Plainswood
***

Difícil de ler, certo? É confuso saber qual é o título, quais são os nomes das listas, etc

Vamos pensar em ler as notícias (ou um post no blog ou uma revista). Todo o texto da página é do mesmo tamanho? (não)

Por que alguns textos são maiores ou mais arrojados que outros textos? (para chamar a atenção para isso)

Qual é geralmente o maior texto na página? (o título)

HTML têm `tags de cabeçalho` para nos ajudar a identificar coisas importantes na página - estas funcionam  como as tags `<p>` tags, mas o texto é maior e mais ousado para aparecer.

Existem quatro tamanhos de tag de cabeçalho que você pode usar enquanto cria páginas da web. O maior é `<h1>` e é usado para o texto do título. `<h2>` é para sub-cabeçalhos importantes, e ainda é muito grande. `<h3>`é um pouco menor, e `<h4>` é um pouco menor do que isso, mas são todos maiores e mais arrojados do que a tag `<p>` , então você sabe prestar atenção a eles.


*Em seguida, modifique o texto do quadro branco escrevendo as tags de cabeçalho de abertura e fechamento em torno de cada seção do cabeçalho. Peça aos alunos para escolherem quais tags vão para onde. A final deve acabar assim:*

----------
# `<h1>`Guia do Aventureiro `</h1>`

## `<h2>`Como Começar`</h2>`

### `<h3>`Equipamento`</h3>`  
`<p>`Espada`</p>`  
`<p>`Escudo`</p>`

### `<h3>`Habilidade`</h3>`  
`<p>`tiro com arco  `</p>`  
`<p>`luta de espadas`</p>`  
`<p>`magia`</p>`

## `<h2>`Dungeons Legais`</h2>`  
`<p>`Kithgard`</p>`  
`<p>`Plainswood`</p>`
----------

*Após este exercício, os alunos devem estar prontos para concluir o nível. Enquanto eles estão trabalhando nisso, incentive-os a ver o que acontece se eles esquecerem de fechar uma tag.*


#### Hora da Programação (5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, peça que eles se certifiquem de que estão abrindo e fechando corretamente as tags.


##### Módulo 2

## Imagens & Atributos

### Sumário

Para fazer: Escreva um resumo deste módulo aqui.

### Metas

- Adicione uma imagem no HTML usando a tag `<img>`
- Entenda que as imagens precisam de fontes (URLs) para renderizar na página
- Adicione atributos de `altura` e `largura` na tag `<img>` para especificar o tamanho da imagem.


### A tag `<img>` 

#### Atividade instrutiva: Imagem Perfeita (10-13 mins)


O texto por si só não é tão empolgante, e as imagens são uma ótima maneira de adicionar algum interesse visual a uma página HTML. Nós vamos olhar para a tag `<img>` nesta lição.


O texto é bem legal, mas não é hora de tirarmos algumas fotos em nossas páginas?

HTML tem uma tag que permite incorporar imagens na página - é chamada `<img>`

Há algumas coisas importantes para saber sobre `<img>`

1. É uma tag de fechamento automático como `<br>` (porque está adicionando algo novo à página em vez de direcionar algo que é exibido entre duas tags ).
2. A tag`<img>` precisa deu uma fonte (`src`) então o navegador sabe de onde a imagem está vindo.


*Faça um diagram das partes da tag `<img>` no quadro, e chame a atenção sobre coisas importantes, por exemplo, como a tag está estruturada*

`<img src="http://www.codecombat.com/hero.jpg"/>`

Colocamos a tag em `<`símbolos de maior ou menor `>`assim como com os outros elementos que vimos, e você também pode colocar a `/` logo antes do símbolo de fechamento, se você quiser (é opcional).

Este elemento é nomeado `img` então começamos com isso. Tenha cuidado para não soletrar errado, ou você não verá uma foto!

Em seguida, temos `src="http://www.codecombat.com/hero.jpg"` que nos diz de onde a imagem está vindo. `src` é um `atributo` (veremos mais alguns deles depois - podemos fazer coisas como alterar o tamanho de nossas imagens com elas!). `src` está após um sinal de igual e dentro de aspas, e precisa ser um URL válido que termine em um tipo de arquivo de imagem (como .jpeg ou .png ou .gif). O CodeCombat tem uma galeria cheia de imagens que podemos usar - heróis, tesouros, monstros e muito mais!


#### Interaja (5 mins)

Peça aos alunos que selecionem imagens da galeria do CodeCombat (lado superior direito da página, acima do editor) e adicione-as a uma página em branco no editor. Em primeiro lugar, instrua-os a copiar o toda a tag `<img>` , mas veja se eles podem copiar apenas o URL da imagem e construir a tag desde o início.

Circule para ajudar; os problemas mais comuns com esta tag tendem a acontecer em torno da ortografia e da colocação das "" ao redor do `src`.

Enquanto os alunos estão trabalhando nisso, comece a introduzir o projeto do Cartaz de Procurado - indique que eles farão cartazes de procurado para os colegas e para si mesmos, então é uma boa hora para começar a escolher as imagens que eles gostam da galeria e praticar adicionando-os a uma página.

#### Hora da Programação (5-8 mins)

Se os alunos estiverem com dificuldades para concluir o nível, verifique a ortografia `img` e `src`, Se verificar um URL válido (entre aspas) em um arquivo de tipo de imagem para o `src`.


### Atributos de `largura` e `altura` 
Nem sempre queremos que as imagens sejam exibidas em uma página inteira. Os atributos de  `largura` e `altura`  nos dá a flexibilidade para redimensionar imagens para exibição.

#### Atividade instrutiva: Cachinhos Dourados e as Três IMGs (8-12 mins)

Se lembra da tag`img`? Quem pode me dizer as partes dessa tag? (img, src = e o URL da imagem nas aspas)

`<img src="http://www.codecombat.com/hero.jpg"/>`

Lembre que `src` é uma atributo de `img`. Vamos adicionar alguns outros atributos que informarão ao nosso navegador mais sobre como exibir essa imagem -- `largura` e `altura`

`<img src="http://www.codecombat.com/hero.jpg" height="100" width="100"/>`

Adicionar esses atributos funciona da mesma maneira que `src` -- digite o nome do atributo e, em seguida, um sinal de igual e, em seguida, o valor da altura ou largura entre aspas. Tudo isso vai dentro da tag.

*Desenhe um quadrado no quadro branco para representar a imagem e escreva um 100 ao longo de um dos lados verticais e um dos lados horizontais do quadrado para indicar que ele tem 100 de altura e 100 de largura*

```
			100
	 -------------------
	|				  |
	|				  |
	|				  |
100 |				  |
	|				  |
	|				  |
	|__________________|

```

Nota rápida: todas as imagens precisam ter um atributor `src`,  mas `altura` e `largura` são opcionais. Mais tarde, quando começarmos a olhar para o CSS, também aprenderemos outras maneiras de definir o tamanho das imagens em nossa página.

#### Interaja (5-7 mins)

Peça aos alunos que selecionem imagens da galeria do CodeCombat (lado superior direito da página, acima do editor) e adicione-as a uma página em branco no editor. Cada aluno deve adicionar pelo menos 3 imagens.

Instrua-os para adicionar os atributos de `altura` e `largura` para cada imagem.

- Primeira imagem: altura de 100, largura de 200
- Segunda imagem: altura de 200, largura de 100
- Terceira imagem: altura de 100, largura de 100


Se os alunos concluírem cedo, peça-lhes que retirem um ou ambos os atributos de tamanho da tag e relatem suas descobertas sobre o que aprenderam usando apenas um valor.

Circule para ajudar; os problemas mais comuns com este exercício tendem a ser ortográficos (é surpreendentemente fácil escrever erradamente "altura!") e fechar aspas nos atributos.


#### Hora da Programação (5-8 mins)
Como no primeiro módulo, se os alunos estiverem com dificuldades para concluir o nível, verifique a ortografia de`img` e `src` (e como `height` e `width`são escritas,  verifique se há um URL válido (entre aspas) em um arquivo de tipo de imagem `src`.


##### Módulo 3
## Organização


### Sumário

Para fazer: Por que precisamos organizar documentos HTML?

### Metas

- Divida uma página HTML em seções usando a tag`<div>`
- Crie uma lista não ordenada usando as tags <`ul>`e `<li>` 
- Crie uma lista  ordenada usando as tags`<ol>` e  `<li>` 


### Organizando com a tag`<div>` 

A tag`<div>`  nos ajuda a organizar partes de um conteúdo. É um bloco de construção que usaremos quando começarmos a estilizar as seções da página, de forma que o nível que reforça essa tag tenha alguns estilos internos para clareza visual.


#### Atividade instrutiva: fatia e dados (11-15 mins)

Nós adicionamos um monte de diferentes tipos de conteúdo às nossas páginas até agora. Quem quer recapitular quais elementos utilizamos? (quebra de linha, parágrafo, cabeçalhos, imagens, listas)

Quando criamos páginas da Web, não queremos apenas adicionar coisas aleatoriamente - queremos organizar nosso conteúdo em seções. Nós podemos fazer um pouco disso com algumas tags `<br>` e cabeçalhos, mas a tag`<div>`  nos permite agrupar itens nessas seções. Mais tarde, quando adicionarmos estilos à página (como cores de fundo e bordas), poderemos aplicar esses estilos a uma seção inteira de uma só vez.

Envolvendo as coisas em uma tag `<div>` se parece assim:

```
<div>
<h2>My Latest Quest</h2>
<p>This week, I had many adventures.</p>
<p>I also bought new boots!</p>
</div>
```

A abertura da tag`<div>` vai antes da primeira coisa que queremos agrupar juntos (a tag `<h2>`) e o fechamento vai depois da última coisa no grupo (a tag `<p>`). Agora, todos os três itens serão coletados juntos em uma tag `<div>` e podemos tratá-los como um grande item acumulado.

#### Interaja (8-10 mins)

Peça aos alunos que trabalhem em pequenos grupos para criar uma página de "anúncios classificados" para equipamentos usados, usando o conteúdo envolvido em divs.


Cada div deve conter:
- O nome do item para venda (como cabeçalho)
- O preço (como um cabeçalho menor ou texto de parágrafo)
- Uma descrição do item

Deve haver pelo menos 3 itens à venda na página.

Circule enquanto os alunos estão trabalhando, verifique se eles estão fechando todas as tags de abertura e o fechamento `<div>` 

#### Hora de Programação (5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, verifique a abertura e o fechamento da consistência da tag.


### Lista Desordenada (As tags `<ul>` e `<li>` )

Listas não ordenadas são listas com marcadores. Eles consistem de um grupo de `<ul>` que contém um conjunto de tags `<li>` (lista itens) .

#### Atividade instrutiva: fora de ordem(10-15 mins)

*Comece escrevendo uma lista de itens no quadro branco*

```
Habilidades de Herói

luta de espadas
tiro com arco
preparação de poções
treinamento de animal
```

Às vezes, queremos agrupar itens em uma lista com marcadores, em vez de apenas ter uma quebra de linha entre esses itens. Existem todos os tipos de situações em que podemos usar essas listas de tarefas pendentes, listas de compras, descrições de coisas - e o HTML nos fornece uma ferramenta para criar listas com marcadores.

É chamado de `<ul>`, que significa *unordered list/lista desordenada*.

A tag `<ul>` tag é apenas o intervalo em que os itens da lista vivem. Cada coisa que você deseja colocar na lista vai em outra tag, chamada `<li>`, que significa *lista item*.

Uma das coisas que você vai querer prestar atenção é ter certeza de que todos as suas tags`<li> estão fechadas, e que eles estão todos dentro das tags `<ul>` e `</ul>`.

Vamos pegar esse conjunto de habilidades básicas de herói no quadro branco e transformá-lo em uma lista desordenada.

*Adicione a tag `<ul>`para o lado de fora da lista e envolva cada item com tags `<li>` .  Coloque tags `<h2>`no título.*

```
<h2>Habilidades de Herói</h2>
<ul>
<li>luta de espadas</li>
<li>tiro com arco</li>
<li>preparação de poções</li>
<li>treinamento de animal</li>
</ul>
```

#### Interaja (5-8 mins)

Peça aos alunos que trabalhem em pequenos grupos para criar listas de compras de heróis, usando listas desordenadas para acompanhar todos os itens que o herói queira comprar para se aventurar.

Cada lista deve conter:
-  Um cabeçalho, então sabemos para que serve a lista
- Abrindo e fechando tags `<ul>`, então sabemos que é uma lista não ordenada
- Pelo menos 5 tags`<li>` com itens


Certifique-se de que eles estejam fechando todas as tags e que as tags de abertura e fechamento de `<ul>` estejam fora dos itens `<li>`.

#### Hora da Programação(5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, verifique a abertura e o fechamento da consistência da tag.

### Lista Ordenada (A tag `<ol>` )
As listas ordenadas são muito semelhantes em estrutura às listas ordenadas, mas em vez de marcadores, essas listas são numeradas. Eles consistem em um grupo `<ol>` que contém um conjunto de tags `<li>` (item de lista).

#### Atividade instrutiva: um de cada vez(12-18 mins)

*Comece escrevendo uma lista de itens no quadro branco*

```
Aventura Para Fazer

1. Embalar sacos
2. Aventure-se na natureza
3. Lute contra inimigos
4. Encontre um tesouro
5. Tire uma soneca
```

Listas com marcadores são ótimas, mas não são o único tipo de lista. Às vezes, queremos listar itens em ordem, com números para nos informar mais informações sobre os itens em uma lista - tabelas de classificação de um jogo ou a ordem das etapas em uma receita, por exemplo.

A * lista ordenada * é muito parecida com a `<ul>`, mas recebe a tag `<ol>`, então sabemos que ela aparecerá no navegador com números em vez de marcadores.

Assim como nas listas não ordenadas, cada item que você deseja colocar na lista vai em uma tag `<li>` dentro das tags `<ol>`.

Uma das coisas que você vai querer prestar atenção é ter certeza que todas as suas tags <li> `estão fechadas, e que elas estão todas dentro do` <ol> `e do` </ ol> ` .

Há uma lista de tarefas no quadro branco com as ações de nosso herói já em ordem - vamos colocar as tags corretas no lugar para que esses números apareçam no navegador sem que tenhamos que escrevê-los separadamente dentro da tag `<li>`.

* Adicione uma tag `<ol>` ao lado de fora da lista e coloque cada item em tags `<li>`. Apague os números antes de cada item. Envolva o cabeçalho nas tags `<h2>`. *

```
<h2>Aventura Para Fazer</h2>
<ol>
<li>Embalar sacos</li>
<li>Aventure-se na natureza</li>
<li>Lute contra inimigos</li>
<li>Encontre um tesouro</li>
<li>Tire uma soneca/li>
</ol>
```

#### Interaja (5-8 mins)


Peça aos alunos que trabalhem em pequenos grupos para criar listas de classificação para os monstros mais difíceis de vencer, usando listas ordenadas para organizar a ordem desses itens.

Cada aluno deve fazer uma lista top 5, então cada grupo pequeno deve comparar e combinar listas em uma lista grande .

Cada lista deve conter:
- Um título, então sabemos para que serve a lista
-tags de abertura e fechamento `<ol>`, então sabemos que é uma lista ordenada
- Pelo menos 5 `tags <li>`com itens, em ordem numérica



#### Reflexão(2 mins)

**Como você pode usar `<ul>` (lista desordenada)? Como você pode usar  `<ol>` (lista ordenada)? Comoe eles são similares?**
> Eu usaria um `<ol>` quando os números e a ordem fossem importantes, e usaria um `<ul>` se a ordem não fosse tão importante e eu quisesse marcadores. Eles são semelhantes porque ambos são listas que contêm tags `<li>`.

### Hora da Programação (5-8 mins)

Se os alunos estiverem com dificuldades para concluir o nível, verifique a abertura e o fechamento da consistência da tag.



##### Módulo 4
## Sintaxe CSS 

### Sumário

Esse módulo é uma introdução a **CSS**, ou **C**ascading **S**tyle **S**heets --um meio de adicionar estilos a uma página da Web, os estilos podem incluir cores, fontes, bordas, alinhamento, posicionamento e muito mais. Nós estaremos dando um passo introdutório usando a tag `<style>` e algumas regras de estilo simples.

### Metas

- Adicionar regras de estilo a uma página HTML usando a tag `<style>` e as regras CSS
- Aplicar esses estilos aos elementos da página

### A tag `<style>`  

#### Atividade instrutiva: estilo pelo livro (13-18 mins)

ParaFazer:Adicione vocabulário sobre propriedades e valores aqui.

Hora de começar a estilizar as nossas páginas! Há várias maneiras de destacar uma página ou uma seção, e muitas delas vêm de regras de estilo. Você pode definir cores, fontes, coisas como sublinhados, posicionamento e muito mais.

Estilos podem ser adicionados a uma página HTML com a tag `<style>`. Este é um pouco diferente de algumas das outras tags com as quais trabalhamos, por alguns motivos:

- Ele contém regras de CSS em vez de texto, imagens ou outras tags.
- Você só precisa definir o estilo uma vez em uma página (geralmente no topo)
- Você não verá nada na página em que a tag de estilo está, mas se tiver elementos na página que correspondam às regras de estilo, você verá como os estilos são aplicados

Vamos ver uma tag de estilo de amostra e dividi-la em partes:

*escreva o seguinte no quadro branco*

```
<style>
    h1 {
        color: orange;
        text-align: center;
    }

    p {
        text-align: left;
        color: blue;
    }
</style>
```

Primeiro, vamos detalhar o que essas duas regras significam. Temos uma regra para o h1, que diz que todas as tags de cabeçalho `<h1>` em nossa página terão dois estilos - elas serão laranja e estarão centralizadas na página. Então nós temos uma regra para o texto do parágrafo, que diz que todas as tags `<p>` em nossa página serão azuis e alinhadas à esquerda. Sempre que adicionarmos um `<p>` ou um `<h1>` na página, ela terá essas cores e alinhamentos definidos.

Em seguida, vamos dar uma olhada em como as regras são escritas, para que possamos escrever nossas próprias regras.
Entre as tags `<style>`, vemos:

- o elemento ao qual a regra se aplica
- uma chave aberta `{`
- o nome da propriedade que queremos definir (como cor, tamanho da fonte, alinhamento de texto, etc.), um caractere de dois pontos `:`e, em seguida, para o qual queremos configurá-lo (como laranja, 12px, centro etc.) e, em seguida, um ponto e vírgula `;`
- quantas mais regras quisermos
- um chave para fechar `}`

 

Então, por exemplo, digamos que queríamos adicionar outra regra ao conjunto acima, e colocar uma cor de fundo azul claro em todos os nossos `<div>` s, nós escreveríamos assim:

```
div {
    background-color: light-blue;
}
```
A regra mora dentro das `{` chaves `}`, e a maneira como a escrevemos é com dois pontos `:` entre o nome e o valor e um ponto-e-vírgula no final da regra.

#### Interaja (8-10 mins)

Peça aos alunos que trabalhem em pequenos grupos para adicionar elementos HTML a uma página (tags de cabeçalho, texto de parágrafo, imagens, listas, divs etc.) e, em seguida, crie pelo menos 3 regras de estilo para estilizar esses elementos.

Algumas sugestões:
- Faça os títulos e o texto do parágrafo se destacarem mais, deixando-os com diferentes `cores`.
- Divs é um ótimo elemento para adicionar `background-color/cor de fundo`, porque a cor estará lá para todos os elementos dentro do div, e o div irá aparecer na página.
- Dê uma olhada nas dicas se você estiver preso - algumas das regras de estilo só se aplicam ao texto, por exemplo, então se você definir `color` em um` img`, talvez não veja resultados visíveis.

Enquanto os alunos estão trabalhando nisso, lembre-os de que eles farão pôsteres de procurado, e é uma boa ideia começar a pensar em estilos agora. Mais dicas de regra de estilo estão no editor, na seção dica.

#### Hora da Programação (5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, verifique a pontuação e o posicionamento das regras de CSS, incluindo o uso adequado de propriedades e valores (por exemplo, algumas propriedades podem ter apenas determinados valores usados com elas). Para a utilização das regras CSS é necessário utilizar o vocabulário em inglês.




##### Módulo 5
## Seletores CSS 

### Sumário
As aulas nos ajudam a estilizar elementos repetidos com muito mais facilidade; em vez de estilizar todas as `<div>` s ou `<p>` s de uma determinada maneira, podemos usar classes para designar regras de estilo apenas a elementos que pertencem a um grupo.

### Metas

- Adicione uma classe a um elemento em uma página HTML
- Crie uma regra de estilo para os membros dessa classe
- Adicionar um id a um elemento em uma página HTML
- Crie uma regra de estilo para esse id

### Classes CSS
 
####  Atividade instrutiva: topo da Classe (12-18 mins)

Até agora, estamos nos sentindo muito confortáveis com a criação de novos elementos HTML com atributos, certo? Hoje, vamos dar uma olhada em outro atributo que podemos adicionar aos elementos que nos ajudarão com a estilização - `class`.

Digamos que queremos que mais de uma div em nossa página pareça a mesma - talvez uma cor de fundo brilhante para todas as postagens de blog em uma página - mas não queremos colocar uma regra em `div` porque nós também pode ter alguns outros divs na página que não deveriam ter essa cor de fundo. Podemos colocar esses divs especiais em um grupo, chamado `class`, e deixar que nosso navegador saiba que eles estão nessa classe, adicionando um atributo de classe à tag.

Desta maneira:
```
<div class="blog">
<h1>Minha última aventura</h1>
<p>Deixe-me contar essa história...</p>
</div>
```

Nós demos ao div uma classe de `blog` adicionando` class = "blog" `à tag de abertura, e agora podemos adicionar regras especiais a ela.

As regras de estilo para classes são um pouco diferentes do que para elementos regulares. Temos que dizer ao navegador que estamos fazendo a regra para uma classe, e usamos um ponto `.` antes do nome na regra para fazer isso:

```
.blog {
	background-color: pink;
}
```

O restante da regra é semelhante a outras regras de estilo. A única coisa especial que estamos fazendo aqui é adicionar o ponto antes de * blog * para que o navegador saiba procurar todos os elementos na página que pertencem à classe de blog, e dê a eles um fundo rosa.

#### Interaja (10-12) mins)

Peça aos alunos que trabalhem em pequenos grupos para criar uma página de Cartões de Negociação de Herói, com um cartão para cada aluno do grupo. Os divs que representam as cartas devem ter classes, e deve haver regras de estilo para essas classes.

Um Cartão de Negociação de Herói precisa:
- Uma imagem representando cada herói.
- Texto de cabeçalho (qualquer uma das tags de cabeçalho) para o nome do herói.
- Uma frase de uma linha para o herói (`<p>`)
- Uma cor de fundo para sabermos o que pertence a um cartão e o que está no restante da página.
- Qualquer outro estilo que você queira aplicar
- Certifique-se de separar os cartões (dica: temos uma tag para isso)

#### Hora da Programação (5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, verifique a sintaxe de classe adequada.
### IDs CSS 

Os IDs nos ajudam a estilizar elementos exclusivos com muito mais facilidade; em vez de estilizar todas as `<div>` s ou `<p>` s de uma certa maneira, podemos usar classes para atribuir regras de estilo apenas a um único elemento desse tipo.

#### Atividade instrutiva: um de um tipo (12-18 mins)

As classes foram realmente impressionantes para as coisas que queríamos repetir, como o cartão de troca de heróis, ou posts de blog, ou as seções de personagem no nível. Mas e se algo for super especial e for a única coisa na página a ter esse estilo?

É ai que os `id`s entram.

Desta maneira:
```
<ul>
<li>Um peixe</li>
<li>Dois Peixes</li>
<li id="red">Peixe Vermelho</li>
<li id="blue">Peixe Azul</li>
</ul>
```


Podemos fazer os itens "peixe vermelho" e "peixe azul" apareçam com cores especiais, mas todas as marcas  `<li>`não terão uma cor, e não estamos repetindo vermelho ou azul , vamos usar um id aqui.

Usamos um ponto `.` Para informar ao navegador que estávamos falando sobre classes quando definimos esses estilos. Para o `id`s, vamos colocar um  `# `(hashtag) antes do nome na regra para fazer isso:

```
#red {
    color: red;
}
#blue {
    color: blue;
}
```

O importante a lembrar que usamos `id`s apenas para um único elemento. Se você quiser repetir a regra novamente, você pode querer usar uma `class` em seu lugar.

#### Interaja (15-20 mins)

No Módulo 11, os alunos trabalharam em pequenos grupos nas Cartas de Negociações. Agora, peça a todos que trabalhem individualmente para recriar as cartas da lição anterior, mas apliquem estilos especiais para o próprio cartão.

Cada aluno deve ser capaz de:
- Crie uma página com várias Cartas de Negociações de Heróis (divs, imagens, texto estilizado com classes) para os colegas que estavam em seu grupo
- Adicione um `id`de seu próprio nome ao div para seu cartão
- Crie regras de estilo especiais para o cartão que pareçam diferentes das outras cartas


#### Hora da Programação(5-8 mins)
Se os alunos estiverem com dificuldades para concluir o nível, verifique a sintaxe de classe adequada.

##### Módulo 6

### Projeto Final

O cartaz de procurado pode ser usado como um projeto em andamento ao longo da segunda metade dos módulos; quando os alunos atingirem o nível 13 no jogo, eles devem estar equipados para concluí-lo. Pensei em apresentá-lo mais cedo, mas não quero que os alunos fiquem cansados, então eu separei as outras partes do curso em alguns projetos menores focados para trabalho individual ou em grupo. O instrutor pode semear a idéia do pôster assim que achar apropriado, e designar seções dele como um trabalho de reforço depois que os alunos concluírem os níveis básicos e os miniprojetos durante os horários do Interação.

Meu agrupamento sugerido de lições (obviamente dependentes do tempo e que variam de classe para classe) é:

-  Módulos 1 - 4  em uma sessão para colocar texto na página e começar a reconhecer a marcação HTML básica. Nenhuma linha de projeto ainda, porque os alunos provavelmente terão mais aulas entre essas noções básicas e os tópicos mais alinhados ao projeto, e haverá muita reescrita.

-  Módulos 7 e 10  juntos (isso é um desvio da ordem de nível, mas não conseguimos encontrar nada nos níveis que seria um passo errado se eles fossem movidos), com mini-projetos sobre os diferentes tipos de listas (pequenos grupos de trabalho fazendo uma lista de compras para pegar o jeito de listas não ordenadas, e uma lista de classificação dos monstros mais difíceis de derrotar para lidar com listas ordenadas).

-  Módulos 5, 6, 8 e 9 * na mesma sessão ou back-to-back (pode ser necessário dividir por causa da duração, especialmente com os exercícios de estilo). O módulo 9 tem call-backs para 5 (atributos), e uma das melhores razões para agrupar as coisas em um `<div>` é para estilização, então 6 e 8 fluirão bem e definirão as classes e ids. Os módulos 5, 8 e 9 são prática de habilidades e não incluem miniprojetos específicos, mas o Módulo 6 apresenta um breve projeto de grupo pequeno (usando divs para criar uma página de "anúncios classificados" para equipamentos dso heróis), o projeto Cartaz de Procurado será mencionados aqui para que os alunos possam pensar em coisas que gostariam de incluir.

- Módulos 11 e 12 * juntos . Depois desses módulos, os alunos devem ser capazes de completar o pôster de procurado no nível 13, então o foco aqui deve ser sintetizar todos os conceitos anteriores e levá-los ao próximo nível. A parte de interação desses módulos envolve mais tempo gasto trabalhando individualmente e em pequenos grupos; enquanto os níveis anteriores podem ter um foco pequeno e singular.Os alunos devem estar preparados para escrever grandes partes de uma página HTML a partir do zero, depois levar essa página para o próximo nível com as lições desses módulos.

- Uma aula inteira para concluir o Nível 13, com a oportunidade de aprimorá-lo além dos requisitos básicos, se os alunos terminarem rapidamente. Estilos adicionais seriam uma ótima maneira de levar este cartaz ao próximo nível, e os alunos têm muita atitude em termos de quanto eles podem diferenciar seus pôsteres com CSS.


