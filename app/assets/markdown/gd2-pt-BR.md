##### Planos de Aulas
# Desenvolvimento de Jogos 2

### Sumário

* Pré-requisitos recomendados: Ciência da Computação 2, Desenvolvimento de Jogos 1
* 8 sessões de codificação de 45 a 60 minutos

#### Visão Geral


O curso Desenvolvimento de jogos 2 aplica as habilidades que os alunos aprenderam em Ciências da Computação 2 para que eles possam criar um jogo de estilo arcade completo, com o qual poderão compartilhar com amigos e familiares. É aqui que os conceitos abstratos, como condicionais e funções, mostram seu propósito de maneira prática e permitem que os alunos criem algo próprio.

O curso começa demonstrando algumas novas mecânicas e técnicas de jogo, que usam a sintaxe básica e a estruturação lógica que os alunos estão familiarizados com os cursos anteriores. Uma vez que estejam confortáveis com a nova mecânica, os alunos passarão por uma variedade de exercícios combinando-os em formas únicas de jogabilidade, incluindo uma série de níveis que constroem iterativamente um jogo arcade estilo Pac-Man. Finalmente, os alunos têm a oportunidade de criar seu próprio jogo de arcade.

*Este guia foi escrito para aulas em Python, mas pode ser facilmente adaptado para JavaScript.*

### Escopo e Sequência

1. [Mecânicas: Adicionáveis e Objetivos](#mecanicas-adicionaveis-e-objetivos)
2. [Mecânicas: Tempo, Aleatoriedade, Derrota](#mecanicas-tempo-aleatoriedade-derrota)
3. [Mecânicas: Metas manuais e mais eventos](#mecanica-metas-manuais-e-mais-eventos)
4. [Prática de Integração](#pratica-de-integracao)
5. [Jogo Arcade](#jogo-arcade)
6. [Projeto de Desenvolvimento de Jogos 2](#projeto-de-desenvolvimento-de-jogos-2)

## Mecânicas: Adicionáveis e Objetivos

### Sumário

Para expandir as opções do aluno ao criar seus próprios jogos, os alunos precisarão aprender funções e métodos que possam usar. Os módulos de mecânica não introduzem novas técnicas de programação, mas concentram-se em novas maneiras de usar funções e retornos de chamada para suportar novas mecânicas de jogo.

### Discussão

**Quais são algumas maneiras que o personagem se comporta em vários tipos de jogos?**

Exemplos:

* Os personagens CodeCombat podem atacar mais perto, defender ou fugir
* Esqueletos do CodeCombat fogem quando o jogador está carregando um orbe de luz


**Como alguns desses comportamentos se parecem no código?**
Essa pode ser uma oportunidade para escrever pseudocódigo, que não é necessariamente um código “válido” em um idioma específico, mas comunica a lógica e a estrutura geral do código que os alunos podem escrever posteriormente.

Exemplo de um inimigo de Minecraft:
```
if no player is nearby
  wander aimlessly
else
  if far away from player
    move closer
  else
    attack player
```

### Revisão
Este conjunto de níveis explora duas coisas:


* Usando o evento "spawn", que permite que os alunos definam seus próprios comportamentos para unidades em seus jogos, e
* Alteração de parâmetros para objetivos que eles aprenderam em Desenvolvimento de Jogos 1.

Antes de começar, os alunos devem estar familiarizados com os seguintes conceitos:

*   Eventos (CS2)
*   Parâmetros de Funções (CS2)
*   Declarações If (CS2)
*   Objetivos do Jogo (GD1)

### Níveis

Os alunos devem jogar os primeiros sete níveis:

*   Serviço de Guarda
*   Treinamento do Exército 2
*   Procedimento Operacional Padrão
*   Centro de Formação
*   Chokepoint
*   Fuga de Presos
*   Risco e Recompensa

### Discussão


* Quando você usaria o evento “spawn”?  
* Em um jogo, quando você gostaria de especificar quantos inimigos para derrotar ou itens para coletar?  
* Exemplo: um jogo onde você quer permitir que os jogadores passem e se superem.  Os jogadores devem derrotar um certo número de inimigos ou coletar um certo número de coisas para ganhar o jogo, mas eles poderiam ir mais para conseguir uma pontuação alta? 

## Mecânicas: Tempo, Aleatoriedade, Derrota

### Discussão

**Como os jogos se comportam com base no tempo?**

Há dois em particular: eventos regulares (alterando o estado do jogo com base na hora do dia) ou eventos únicos (a missão é mal sucedida se não for concluída em 5 minutos).

**Quando os jogos se comportam de maneira inconsistente ou aleatória?**


Exemplos:

* Um baralho de cartas é embaralhado
* Um personagem se move aleatoriamente sobre uma área
* Um mundo é gerado (como Minecraft)

**Que tipo de coisas podem acontecer em um jogo quando um personagem é derrotado?**

Exemplos:

* A pontuação muda (para cima ou para baixo)
* O estado de vitória muda (ganha ou perde)
* Áreas são disponibilizadas, indisponíveis
* Mudanças no comportamento dos personagens
* Eventos acontecem

### Revisão
Conceitos que podem ser revisados para ajudar os alunos a se prepararem para esses níveis:

*   Aritmética (CS2)

### Níveis


Os alunos devem jogar os próximos cinco níveis:

* Hora de Aventura
* Teatime
* Random Random
* Agonia de derrota
* Lernaean Hydra

### Discussão

**Por que o loop de checagem de tempo na Hora de Aventura acontece no final do código?**

Como é um loop infinito, qualquer código abaixo nunca será executado.

**Além da localização, o que mais no jogo pode ser definido aleatoriamente, dado um inteiro aleatório?**


Exemplos:

* Tempo
* Tipo: se um número aleatório entre 1 e 2 for menor que 1, adiciona um amigo, caso contrário, um inimigo


**Como a aleatoriedade pode ser emparelhada com probabilidade?**

Se seus alunos estiverem no ensino médio, essa é uma oportunidade de incorporar conceitos matemáticos, como expoentes ou logaritmos, e como eles podem afetar a probabilidade. Uma maneira simples de incorporar probabilidade em seu código é uma função como:

```python
def randomResult():
  i = game.randomInteger(1, 10)
  if i < 10:
    return False
  else:
    return True
```


Esta função terá 10% de chance de retornar `True`.

Outro exemplo de probabilidade no código seria:

```python
def randomResult():
  i = game.randomInteger(0, 10)
  i = i**2 # this is Python’s notation for an exponential, JavaScript has a function Math.pow
  return i
```

Esta função retorna entre 0 e 1024 \. Usando Math, podemos criar algoritmos que retornam todos os tipos de resultados aleatórios.

**Que outras coisas no CodeCombat você pode fazer quando um inimigo é derrotado?**


Exemplos:
* Adicionar mais inimigos
* Peça ao jogador que diga alguma coisa

## Mecânica: Metas Manuais e Mais Eventos

### Discussão

**Quais são as várias maneiras pelas quais os jogos são considerados “vencidos” ou “perdidos”? Como isso seria no código?**

Incentive o pensamento sobre metas que não incluem as fornecidas pelo CodeCombat até agora (derrote inimigos, sobreviva, colete, chegue a um local).

Exemplos:
* Complete uma série de missões
* Obter uma pontuação maior ou melhor do que um adversário
* Resolva um quebra-cabeça

**Quais são os exemplos de coisas que são removidas do ambiente do jogo durante o jogo?**

Exemplos:

* Você navega para uma nova área ou sala, tudo o que estava na área ou sala antiga deve ser removido
* Pouco tempo depois de um inimigo ser derrotado, o corpo do inimigo deve ser removido.
* Depois que algo é “consumido”, por exemplo, um item de saúde, o item deve ser removido.
* Quando algo é “alterado”, por exemplo, um item equipado, roupa ou animal de estimação, o item original deve ser removido.

**Quando algo é coletado em um jogo, que tipo de coisas podem acontecer?**

Exemplos:

* O comportamento do personagem pode mudar (outros personagens em um jogo podem dizer algo se um item for roubado! Ou eles podem lhe dar uma missão ou se comportar de maneira diferente de antes.)
* Atributos do jogador podem mudar (velocidade, poder, saúde, habilidades, especialmente jogos do Mario)
* A forma como o jogador interage com o ambiente pode mudar (uma chave que permite abrir uma porta, dinheiro que permite compras).

**Que coisas podem acontecer quando duas coisas (personagens, objetos) colidem em um jogo?**


Exemplos:

* O jogador pode perder o jogo (Pássaro Flappy colidindo com uma parede, Pac-Man colidindo com um fantasma enquanto não está ligado)
* Dano (se um personagem se deparar com algo prejudicial, como lava ou espinhos, eles podem perder a saúde)
* Rapidez

* Um personagem correndo para a parede irá parar de se mover
* Uma bola que bate em uma parede pode continuar se movendo, mas em outra direção

### Níveis
Os alunos devem jogar os próximos ocho níveis:

*   Deslocamento da Vara
*   Don't Touch Them
*   Do Pó ao Pó
*   Cages
*   Departamento de Contabilidade
*   Hot Gems
*   Berserker
*   Freeze Tag

### Discussão


**Como os objetivos manuais podem ser usados ​​para recriar os métodos de metas integrados?**

 Derrotar: use o evento "derrotar" para rastrear quantos inimigos são derrotados, definir o sucesso da meta como verdadeiro quando alto o suficiente.
* Mover: em um loop verdadeiro, verifique a posição do jogador e, quando estiver perto o suficiente da posição, defina o sucesso da meta como verdadeiro.
* Sobreviver: Se o jogador emite um evento de "derrota", defina o sucesso da meta como falso.
* Coletar: use o evento "coletar" para rastrear quantos itens são coletados, definir o sucesso da meta como verdadeiro quando alto o suficiente.

Como exercício, tente escrever o código para isso.

**Qual é a diferença entre derrotar e destruir?**

Destruir remove completamente a coisa do jogo. A derrota é para unidades e para desativa-as, mas elas ainda estão “dentro” do jogo.

**O que mais pode acontecer quando algo é coletado ou colidido?**

Exemplos:

* Adicionar mais inimigos
* Alterar o layout do mapa (adicionar, destruir)
* Atributos do jogador (saúde, velocidade, tamanho)
* O comportamento dos inimigos (fugir, correr em direção)


## Prática de Integração

### Sumário

Agora que todas as mecânicas foram introduzidas, os alunos começarão a explorar e experimentar mais maneiras de combiná-las para formar comportamentos únicos.

### Níveis


Os estudantes devem jogar estes níveis:

* Corrida para o Ouro
* Flecha de Desintegração

### Divisão de Código


Esses níveis estão ficando bastante complexos. Para cada função do código, peça aos alunos, em grupo ou individualmente, que discutam e expliquem:

* O que a função está fazendo?
* Qual mecânica está sendo usada (aleatoriedade, tempo de jogo, etc)
* Como a função se relaciona com o resto do código (está chamando, está sendo chamado, está configurado por)

### Discussão


**Qual é o benefício de dividir o código dessa maneira?**

Exemplos:

* Reutilização de código
* Explicativo: os nomes das funções explicam o que esse bloco de código faz

**De que outra forma este código poderia ter sido organizado?**

* De que outra forma as funções foram nomeadas?
* De que outra forma as funções foram divididas?
* Como eles seriam uma grande função?

## Jogo Arcade

### Sumário

Esta série de níveis orienta os alunos passo a passo através da criação de um jogo arcade ao estilo Pacman. Isso os ajuda a ver e praticar a integração desses conceitos em um projeto mais complexo e os prepara para realizar o mesmo tipo de processo iterativo no projeto final deste curso.

### Níveis

Os estudantes devem jogar estes níveis:

* Jogo das Moedas Parte 1: Layout
* Jogo das Moedas Parte 2: Pontuação
* Jogo das Moedas Parte 3: Inimigos
* Jogo das Moedas Parte 4: Power-ups
* Jogo das Moedas Parte 5: Equilíbrio

### Divisão de Código


Como no módulo anterior, peça aos alunos que expliquem para cada função:

* O que a função está fazendo?
* Que mecânica ou mecânica está usando (aleatoriedade, tempo de jogo, etc)?
* Como a função se relaciona com o resto do código (está chamando, está sendo chamado por, está configurado por)?

### Discussão

**Qual é a diferença entre construir um programa peça por peça e todos de uma vez?**


Essa discussão serve para destacar como, em cada estágio de desenvolvimento, esse nível é “jogável”. Pode ser reproduzido, testado e alterado. Cada estágio se concentrava em um aspecto diferente do jogo. Os benefícios para o desenvolvimento iterativo são muitos:

* O programa é sempre utilizável. Quando você pode executar o programa a qualquer momento, você pode:
  * Demonstre seu trabalho para outras pessoas em qualquer estágio.
  * Mantenha-se flexível em termos do que acaba sendo a versão “final”. No trabalho ou na escola, você pode ficar sem tempo, mas o trabalho parcial é sempre preferível a algo que não funciona.
  * Teste o que você está construindo e ajuste seu plano à medida que avança.
  * Sempre entenda em que estado o programa está
* Ao testar continuamente, os bugs tendem a ser a adição de código mais recente. Se você criar o código de uma só vez e começar a testar, os problemas serão muitos, compostos e em todo o lugar. Vai ser muito mais difícil.

Com toda a probabilidade, muitos estudantes ainda tentarão construir seus projetos (como em Desenvolvimento de Jogos 2) de uma só vez. Isso provavelmente levará à frustração quando o jogo entrar em um estado de bug e for preciso muito esforço para sair desse estado. Quando isso acontece, reforce os benefícios de se construir de maneira iterativa, incentivando o aluno a começar de um lugar mais simples e construir gradualmente, peça por peça.

## Projeto de Desenvolvimento de Jogos 2

### Sumário


Peça aos alunos que projetem e construam iterativamente seus próprios projetos. Há muitas maneiras de executar este módulo, mas isso deve acontecer pelo menos por vários dias, com o tempo reservado para design, criação e compartilhamento, por exemplo:

* Dia 1: debater ideias sobre o que construir e planejar como implementá-lo. Lembre aos alunos os mecanismos que aprenderam no Desenvolvimento de Jogos 1 e 2.
* Dia 2-4: Desenvolva o jogo de forma iterativa. Os alunos devem trabalhar em seus projetos e colaborar testando os projetos e o código um do outro, fornecendo feedback sobre como o jogo é reproduzido e como ele é desenvolvido.
* Dia 5:  Peça aos alunos que reflitam sobre o processo de construção de seus projetos, o que eles construíram e como eles construíram, e apresentar para o resto da turma.

Na atividade opcional no final: faça com que os alunos "quebrem o código" nos projetos uns dos outros. Incentive os alunos a reservar tempo para organizar seu código, nomear suas funções e variáveis ​​e incluir comentários para que seus colegas de classe possam entender como o código funciona.
