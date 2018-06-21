##### Atividade
# Pesquisando & Ordenando

### Objetivos de Aprendizagem
- [LO 4.2.1] Explique a diferença entre algoritmos executados em um tempo razoável e aqueles que não são executados em um tempo razoável.[P1]
- [LO 4.2.4] Avaliar os algoritmos analítica e empiricamente quanto à eficiência, correção e clareza. [P4]

Esta unidade analisa alguns algoritmos clássicos que surgem de tempos em tempos: pesquisando e ordenando. Esses são bons exemplos de algoritmos que podem ser analisados quanto à eficácia e desempenho.

## Algoritmos de Pesquisa

O professor começará explicando como muitas vezes há muitas soluções diferentes para os problemas, e parte da tarefa de um programador é pesar os prós e contras de cada solução, além de garantir que eles funcionem em todos os casos. Uma das tarefas mais comuns dos computadores é pegar um grande volume de dados e encontrar coisas. Na vida real:

Quando você entra em um serviço, o sistema procura suas informações com base em seu nome de usuário ou e-mail, o que pode estar entre milhares ou milhões de outros usuários.


Os mecanismos de pesquisa são sistemas extremamente complexos que usam palavras arbitrárias e encontram resultados relevantes, além de poder filtrar por itens específicos, como data de criação, tags ou popularidade.

Às vezes, os resultados são confusos ou exclusivos do usuário. Por exemplo, Facebook, Pinterest, Netflix, Spotify, Amazon e outros serviços encontrarão conteúdo ou itens que você pode achar interessante com base em coisas que você escolheu antes.


Nos videogames, os jogadores de computador geralmente procuram o “melhor caminho” para chegar a um determinado local.

Para esta unidade, a turma irá debater, analisar e executar um algoritmo de pesquisa usando dicionários da vida real. Peça aos alunos que apresentem possíveis passos para encontrar uma palavra arbitrária em um dicionário. Cada solução deve ser específica sobre quais etapas são tomadas, então “vire a página” ou “abra o livro um terço do caminho” ao invés de “folhear até ver a letra certa”. Para cada solução, peça aos alunos que avaliem:

Será que vai dar certo? A resposta correta (em qual página a palavra está) sempre será encontrada?
Quão rápido será? Avalie com base no número esperado de etapas e compare com outras soluções.

**Aqui estão alguns exemplos de algoritmos que podem ser discutidos e comparados:**

- **Pesquisa linear**: Comece na primeira página e percorra até encontrar a palavra.
- **Pesquisa linear de qualquer extremidade**:Se a palavra for anterior a "N", comece no início, caso contrário, comece no final. Em seguida, percorra cada página até encontrar a palavra.
- **Pesquisa Aleatória**: Escolha uma página aleatória. Verifique se a palavra está lá. Repita. (nota especial aqui, isso eventualmente funcionará, mas somente se a palavra estiver no dicionário, caso contrário, esse algoritmo poderá ser executado para sempre)
- **Pesquisa com guias**: Use os indicadores de letras ao lado do dicionário (ou adicione guias se não houver nenhum) para começar, depois faça uma pesquisa linear.
- **Pesquisa binária**: Abra para o meio do livro. Determine em qual metade do livro a palavra está. Pegue a metade, olhe para o seu ponto central e repita até encontrar a palavra.


Certifique-se de falar sobre buscas pelo menos lineares e binárias. Como uma atividade, dê a alguns alunos dicionários e faça com que eles "executem" pesquisas com alguns dos algoritmos discutidos. Eles podem competir uns com os outros, seja em tempo real ou uma volta de página de cada vez. Deve ficar bem claro que a busca binária é a vencedora.

Outra coisa a considerar é outras coisas que podem ser pesquisadas. Um verbo que começa com “T”. Um adjetivo com pelo menos dois "g". Quais algoritmos funcionariam para essas pesquisas? Parece que a pesquisa linear é a pesquisa mais flexível, mesmo que não seja a mais eficiente.

Uma vez que esta atividade é feita, siga para classificar algoritmos perguntando aos alunos que tipos de algoritmos eles podem usar para encontrar palavras se o dicionário não estiver em ordem. Considere quais algoritmos não funcionariam com um dicionário embaralhado. Geralmente, faz sentido ter dados não organizados e organizá-los de modo que as pesquisas possam ser feitas com eficiência, o que leva ao outro conjunto clássico de algoritmos:

## Algoritmos de Ordenação

Aqui está um problema comum: você tem várias coisas em uma lista, mas elas não estão em ordem. Isso pode fazer com que você encontre muito mais dificuldade. Há muitas maneiras de as pessoas usarem computadores para classificar informações como essa. Alguns são muito mais rápidos que outros.

Um exemplo simples, mas muito lento, é o Bubble Sort. Esse algoritmo funciona percorrendo a lista da esquerda para a direita, comparando pares adjacentes de valores. Se o par estiver fora de ordem um em relação ao outro, eles serão trocados; caso contrário, eles serão deixados sozinhos. Se você fizer isso N vezes para uma lista longa, você terá uma lista ordenada!
P: Sobre quantas comparações esse algoritmo faz? (A: N ^ 2 - N para cada vez que você passa pela lista. Se sua lista é de 1000 elementos, isso significa 1.000.000 de comparações!)


Se você tentar fazer isso sozinho, verá que isso acontece muito lentamente. Vamos compará-lo ao melhor algoritmo de classificação, Radix Sort. Com uma lista de números, o Radix Sort funciona primeiro pela classificação apenas pelo dígito mais alto, depois dentro de cada ordenação de bucket pelo próximo dígito mais alto, até que você classifique pelo 1s.
P: Sobre quantas comparações esse algoritmo faz? (A: Apenas N * W, para N números com W dígitos cada. Então, para classificar uma lista de 1000 números de 4 dígitos, levaria apenas 4.000 comparações)

Existem outras maneiras de classificar uma lista que é muito mais lenta. Vamos pegar o Bogo Sort como um exemplo. No Bogo Sort, você primeiro verifica se a lista está ordenada. Se não for, escolha aleatoriamente o pedido. Repita até que a lista esteja classificada. Isso não terminará em um período de tempo razoável. Na verdade, isso pode levar uma quantidade quase infinita de tempo.


A maioria das maneiras de classificar listas funciona em um período de tempo razoável, mesmo que sejam mais lentas do que outras (com exceção de itens como o Bogo Sort). Mas, para alguns problemas, até mesmo os melhores algoritmos são muito, muito lentos. Um exemplo clássico é o problema do Traveling Salesman, em que você deve encontrar o caminho mais rápido que percorre todo um conjunto de pontos em um mapa, o que pode levar mais de 2 ^ N passos para N pontos. Então, 1000 pontos levariam muitos passos para serem digitados nesta página!

A maneira de contornar isso é encontrar algoritmos que podem encontrar uma boa solução, mas não necessariamente a melhor solução. Ao afrouxar esse requisito, podemos obter resultados muito mais rápidos. Esses métodos tendem a envolver “funções heurísticas”, que aproximam alguma parte do algoritmo.

### Atividade

Alinhe os alunos em ordem aleatória e classifique-os por aniversário. Você pode começar com o bubble sort para mostrar que é bem lento, depois começar de novo e tentar usar radix sorting.

Instruções para classificar os alunos via bubble sorting:
  

- Começando pelo lado esquerdo, aponte para os dois alunos no final e peça que eles digam seus aniversários.  
- Se o da esquerda for posterior ao da direita, peça para trocar de posição.  
- Mova um aluno para a direita (por exemplo, das posições 1 e 2 para as posições 2 e 3)  
- Repita até chegar ao lado direito da lista  
- Repita o procedimento acima uma vez para cada aluno da sua turma (ou até que você decida que já demonstrou o suficiente - é muito lento!)

Instruções para classificação de alunos via radix sorting:
- Primeiro, identifique em que anos os alunos nasceram. Separe-os em um grupo por ano.
- Em cada grupo de anos, separe-os em um grupo para cada mês daquele ano.
- Em cada grupo mensal, separe-os em três grupos - um para os dias de 1-10, um para os dias de 11-20 e um para os dias de 21-31
- Em cada um desses grupos, separe-os no dia exato do mês.
- Enquanto isso, mantenha todos os grupos em ordem. No final, a turma deve ser classificada!

### Questões de Discussão:
- Para dois algoritmos, quão rápido eles são comparativamente? De que outra forma eles podem ser comparados?
- Para um determinado algoritmo, funcionará sempre? Mesmo no caso em que a coisa que está sendo vista não está na coleção? Como você pode ter certeza?
 
