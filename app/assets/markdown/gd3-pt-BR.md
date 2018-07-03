##### Planos de Aulas
# Desenvolvimento de Jogos 3

### Sumário


Pré-requisitos recomendados:

* Ciência da Computação 3
* Desenvolvimento de Jogos 2
* Opcional: algum conhecimento de física e / ou geometria. O curso oferece orientação suficiente para os alunos, mas se seus alunos tiverem alguma exposição a esses tópicos, esta é uma ótima oportunidade para aplicá-los, especialmente no projeto final e nas discussões.

#### Visão Geral

O curso de Desenvolvimento de Jogos 3 continua o de Desenvolvimento de Jogos 2, usando os conceitos aprendidos em Ciências da Computação 3 para criar jogos ainda mais variados e criativos. Desenvolvimento de Jogos 3 fornece aos alunos mais ferramentas abertas, permitindo que uma ampla variedade de jogos e programas sejam construídos, além de ver como os conceitos básicos da Ciência da Computação são usados no contexto de fazer algo para ser compartilhado com os outros.

Este guia foi escrito para aulas em Python, mas pode ser facilmente adaptado para JavaScript.

### Escopo e Sequência

1. [Atualização e configuração de posição](#atualizacao-e-configuracao-de-posicao)
2. [Animações](#animacoes)
3. [Tutorial do Projeto do Corredor](#corredor)
4. [Projeto de Desenvolvimento de Jogos 3](#projeto-de-desenvolvimento-de-jogos-3)

---

## Atualização e configuração de posição

### Sumário

Este módulo inicia o processo de dar aos alunos um controle mais refinado de seus jogos. Até agora, os jogos construídos dentro do CodeCombat terão usado a estrutura básica do jogo: existem unidades em um plano 2D com um certo conjunto básico de física, as unidades interagem umas com as outras e você controla uma unidade com mouse ou teclado. Com um controle mais refinado, os alunos poderão mais tarde criar qualquer tipo de comportamento físico ou interação, desde o deslocamento de asteróides sem gravidade até o salto de plataformas no estilo Mario.

### Introdução ao Loop no Jogo

Inicie este módulo ensinando os alunos sobre o loop no jogo. Esta é uma estrutura lógica padrão usada em qualquer jogo que inclui animações, e é algo como isto:

```
while True:
  update state
  draw to screen
  wait until the next time to update (usually a few milliseconds)
```


Atualizar estado significa tudo, desde atualizar uma posição com base na gravidade ou colisões com outros jogadores, atualizando estado de saúde ou de caráter. Qualquer estado lógico que muda com o tempo ou por causa da entrada do usuário é afetado aqui. Cada atualização é para um período de tempo pequeno e específico, geralmente frações de segundo.

Ao esperar, o jogo será executado em um ritmo estável e previsível. O jogo, a qualquer momento, terá mais ou menos trabalho a fazer e, portanto, você precisa esperar uma quantidade de tempo complementar para que as atualizações aconteçam constantemente.

Uma única iteração desse loop é um “frame”.

#### Variante de loop: pausado

Demonstrar como a pausa pode ser incorporada nesse loop básico. Se o seu jogo estiver em pausa, não atualizará o estado. Tudo sobre o jogo é mantido constante. No entanto, você ainda precisa desenhar o estado do jogo, e geralmente tem animações acontecendo nas telas de menu, e assim você ainda está desenhando e atualizando a tela. E assim você pode atualizar o loop do jogo para apoiar a pausa:

```
while True:
  if not game.paused:
    update state
  draw to screen
```

#### Variação de loop: largando frames


Muitas vezes, quando se discute o desempenho do jogo, FPS, ou quadros por segundo, é discutido. Este é o número de quadros desenhados para a tela por segundo de jogo. Com uma máquina suficiente, você pode ter um FPS estável e alto, e o jogo corre suavemente. Se a máquina não puder acompanhar tudo o que precisa fazer, no entanto, ela diminuiria de forma gradual e errática. Dependendo de quanto trabalho estava fazendo para atualizar o estado ou desenhar a tela, alguns loops passarão por cima do tempo alocado.

Por exemplo, digamos que seu jogo esteja rodando a 30 quadros por segundo. Isso significa que cada quadro tem 33ms de comprimento. Se atualizar o estado leva 20ms e desenhar na tela leva 20ms em média, o jogo não será capaz de acompanhar. Será 7ms atrás de cada frame, e então 231ms atrasados ​​a cada segundo, então cerca de 23% mais lento do que deveria estar indo.

Para lidar com isso, os jogos pularão a etapa de compra se a execução ficar para trás. Desta forma, as atualizações de estado do jogo permanecem estáveis. Estes são chamados de quadros perdidos e são refletidos nos FPS reais do jogo. Se o seu jogo tiver um FPS mais baixo do que o alvo, é isso que ele está fazendo para manter o jogo suave, se não animações suaves.

```
while True:
  update state
  if not falling behind:
    draw to screen
```

### Introdução à Reutilização de Recursos


Este módulo permite a reutilização de recursos através da manipulação inteligente da posição. Jogos e programas em geral farão isso para melhorar o desempenho. Discuta o desempenho do computador com os alunos, particularmente aproveitando as experiências que eles tiveram com máquinas lentas:

* Um computador executando muitos programas
* Um navegador com muitas guias abertas
* Um telefone executando muitos programas
* Um jogo recém-lançado que não pode ser executado em uma máquina mais antiga

Os jogos geralmente exigem uma boa quantidade de recursos de computação, por isso os programadores de jogos regularmente precisam pensar em como “otimizar” para que uma grande variedade de máquinas possa executar o programa razoavelmente bem.

Leva tempo para criar, rastrear e destruir recursos, especialmente para idiomas como Python e JavaScript, que automaticamente “apagam” recursos que não estão mais em uso (chamado Garbage Collection). Shen possível, é melhor reciclar recursos virtuais, ao invés de destruir e criar de novo. Os níveis a seguir demonstrarão como reutilizar recursos, atualizando a posição dos objetos para conservar o precioso poder de computação!

### Níveis


Os alunos devem jogar os primeiros quatro níveis:

* A regra do quadrado
* O Cara Grande
* Salto Quântico
* Floresta de Looping  

#### A Regra do Quadrado


Recomendamos que você analise esse nível juntos como uma turma para que os alunos entendam o que está acontecendo no código. Aqui estão alguns pontos importantes para analisar:

* O evento de atualização é um evento de baixo nível que acontece toda vez que o loop do jogo atualiza o estado atual, dando ao programador a oportunidade de atualizar a cena uma vez por quadro.
* O evento de atualização pode ser executado para cada unidade ou para o jogo em geral. Este nível demonstra ambos, com eventos de atualização, tanto para as unidades que estão sendo geradas quanto para o jogo.

Para resolver este nível, o aluno deve certificar-se de que cada tipo de unidade tenha o evento de atualização configurado:

<pre>
// Set the "update" event handler for "thrower" and "scout":
game.setActionFor("thrower", "update", onUpdateUnit);
game.setActionFor("scout", "update", onUpdateUnit);
// Set the "update" event handler for "archer" and "soldier":
<b>game.setActionFor("archer", "update", onUpdateUnit);
game.setActionFor("soldier", "update", onUpdateUnit);</b>
</pre>

E configure o comando de atualização do jogo para periodicamente gerar unidades de lançador e de reconhecimento usando a função personalizada spawnRandomUnit. Será o mesmo que a linha existente que gera arqueiros e soldados, como a função `spawnRandomUnit` foi configurada para abranger a funcionalidade comum: geração aleatória e uma posição y aleatória, com uma determinada posição x. Veja a questão de **discussão** abaixo para obter detalhes sobre como esses cronômetros trabalham para executar funções periodicamente.

<pre>
function onUpdateGame(event) {
    if (game.time > game.spawnTime) {
        game.spawnTime += game.interval;
        spawnRandomUnit(2, "archer", "soldier");
        // Use spawnRandomUnit with parameters:
        // x is 78, type0 is "thrower", type1 is "scout":
        <b>spawnRandomUnit(78, 'thrower', 'scout');</b>
    }
}
</pre>

Linhas a serem adicionadas em **negrito**.

#### O Cara Grande


Este nível envolve a criação de um mecanismo automático que mantém o jogador vivo, aumentando gradualmente seu poder e saúde até que eles superem inimigos suficientes. Em cada frame, o jogo irá verificar se o jogador está com pouca vida e aumenta sua saúde, tamanho e dano de ataque.

Para finalizar este nível, os alunos usarão `player.on` e` game.on` para configurar os manipuladores de eventos existentes e chamarão `checkTimers` e` checkGoals` dentro de `onUpdateGame`.

#### Salto Quântico


O foco deste nível é que os alunos agora podem definir diretamente a posição de uma unidade. Isso é diferente da maneira pela qual as unidades já tinham sido movidas. Com `moveXY`,` moveLeft` e similares, as unidades movem-se gradualmente de um lugar para outro em vários quadros e são afetadas ou paradas por obstáculos. Ao definir a posição x ou y diretamente, a unidade se move instantaneamente para o local determinado. Isso pode ser usado tanto para comportamentos únicos de "teletransporte" quanto para animações refinadas onde as unidades se comportam de acordo com um modelo físico personalizado. Este nível demonstra o comportamento semelhante ao teletransporte. Veja a **discussão** da pergunta abaixo para mais detalhes.

Para resolver esse nível, o usuário deve configurar o segundo fluxo de ogros para se mover instantaneamente da parte inferior da tela para a parte superior da tela. Isto é, sempre que um ogro alcança a parte inferior da tela (onde y é 0), sua posição y é ajustada para 68 (a parte superior da tela). Este é um exemplo de reutilização de recursos, conforme discutido anteriormente, que a configuração de posição permite. Do ponto de vista do jogador final, estes são ogros diferentes subindo e descendo a tela, mas o jogo está usando o mesmo `"recurso"` ogro.  

<pre>
## Isso controla o comportamento do escoteiro.

def onUpdateScout(event):
    unit = event.target
    # Scouts always move down:
    unit.moveXY(unit.pos.x, unit.pos.y - 5)
    # If unit.pos.y is less than 0:
    <b>if unit.pos.y < 0:</b>
        # Set its pos.y property to 68:
        <b>unit.pos.y = 68</b>
</pre>

And set up the player to move over the fence when the player reaches the fence.

<pre>
def onCollide(event):
    unit = event.target
    other = event.other
    # If other.type is "munchkin" or "scout".
    if other.type == "munchkin" or other.type == "scout":
        # The enemy's stomped the player.
        unit.defeat()
    # If other.type is "fence":
    <b>if other.type == "fence":</b>
        # Use unit.pos.x to change the player x coordinate.
        # Add 6 to the player's x position:
        <b>unit.pos.x += 6</b>
</pre>

Linhas a serem adicionadas em **negrito**.

#### Looping da Floresta


Tendo introduzido o evento `update`, o curso se move para a posição de configuração de ensino. Os alunos devem configurar seu código para evitar que os ogros saiam de uma determinada área. Se um ogro estiver muito longe, o jogo irá reposicioná-lo mais perto do centro do jogo.

Para passar este nível, os alunos devem terminar a lógica `onUpdate`. As bordas da floresta estão em x = 10, x = 70, y = 10 ey = 58 \. Eles são fornecidos com lógica para teleportar unidades da borda esquerda para o lado direito do mapa. O restante das instruções if move a unidade da direita para a esquerda, de cima para baixo e de baixo para cima. O resultado deve ser que sempre que uma unidade atingir qualquer um desses lados, a unidade “salta” para o lado oposto. Certifique-se de que as unidades sejam teletransportadas para uma posição “dentro” desses limites, caso contrário, elas podem se movimentar a cada atualização!

### Discussão

**Como os temporizadores trabalham em O Cara Grande e na Regra do Quadrado?**

Nós temos visto esses temporizadores nos níveis anteriores. Nós definimos uma propriedade para o jogo que usamos para rastrear quando é a próxima vez de fazer alguma coisa. Então o jogo constantemente verifica se game.time é igual ou maior que esse valor. Quando isso acontece, a ação é acionada e o valor é atualizado. Percorra alguns pseudocódigos para se certificar de que os alunos entendem como isso funciona.

```
game.triggerTime = 4
at regular intervals:
  if game.time >= game.triggerTime:
    doSomething()
    game.triggerTime += 4
```


Isso dispara `doSomething` a cada quatro segundos, quando` game.time` é 4, 8, 12, etc.

**O que acontece se você não incluir a parte que aumenta o `game.triggerTime`?**

Então `doSomething` é chamado uma vez a cada atualização de jogo, o que pode acontecer dezenas de vezes por segundo! A atualização do `game.triggerTime` é fundamental para limitar corretamente este evento.

**Como o moveXY é diferente do ajuste pos?**


`moveXY` é uma das várias `“ ações ”` do jogo. Quando `moveXY` ou outras ações do jogo como` attack` ou `moveLeft` são chamadas, o mecanismo do jogo atualiza a unidade em vários quadros com base em vários fatores, como velocidade, aceleração e obstáculos da unidade. Essa é uma função conveniente de alto nível, se esse for o tipo de comportamento que você deseja para o seu jogo.

Definir `pos` é de baixo nível. Define a posição da unidade para esse quadro, direta, imediatamente e sem levar em consideração nenhum outro estado. Por exemplo, você pode mover uma unidade em cima de uma floresta que `moveXY` foi projetada para não permitir.


---

## Animações

### Introdução a Animações


Antes de começar os níveis, acompanhe a aula através de alguns exercícios mentais sobre como as animações no código funcionam.

Primeiro, revise o que foi discutido no módulo anterior: ao definir a posição, a unidade se move instantaneamente para essa posição.

Em seguida, fale sobre como as animações funcionam no filme. Um flipbook é um bom exemplo de como uma sequência de imagens, quando mostrada em rápida sucessão, exibe uma animação. Nos filmes de claymation de um determinado modelo, o operador vai e volta entre ajustar o modelo e tirar uma foto do modelo. As animações por computador funcionam de maneira semelhante.

Combinando o comando de atualização e a posição de configuração, os alunos podem fazer todos os tipos de animações e comportamentos de unidade. Neste ponto, discuta os diferentes tipos de comportamentos visuais vistos nos jogos e esboce como a lógica nesses jogos pode parecer.

### Discussão

**Quais são alguns exemplos de movimento nos jogos?**


Isto é, física do jogo. Os jogos frequentemente modelam várias combinações de gravidade, momentum e atrito. O objetivo é chegar a alguns que sejam claramente diferentes uns dos outros, ou olhar para jogos específicos e articular como o movimento dentro deles geralmente funciona.

Exemplos:

* Asteróides: uma nave espacial se move a uma velocidade constante em todo o campo e muda de velocidade e direção com propulsores
* Jogo de plataforma: o personagem cai com a gravidade, parando quando pousam no chão ou inverte a velocidade quando pousam em algo saltitante.
 * Mario Bros 2 em NES e vários jogos de Mario desde que exemplificam pequenas variantes físicas: Mario, Luigi, Toad e Peach têm diferentes comportamentos de corrida e saltos.
* Pong ou Breakout: uma bola quica a velocidade constante, invertendo a direção sempre que atinge uma superfície, mudando de direção e velocidade especificamente dependendo de onde ela atinge a raquete ou quão rápido a pá está se movendo.

**Como alguns desses comportamentos se parecem no código?**


Tendo identificado e descrito geralmente alguns tipos diferentes de movimento de jogo, agora aproxime-o do código escrevendo pseudocódigo para eles.

Uma unidade indo em velocidade constante para o canto superior direito

```
unit.xSpeed = 1
unit.ySpeed = 1
every frame:
  unit.pos.x += unit.xSpeed
  unit.pos.y += unit.ySpeed
```

Uma unidade sob o efeito da gravidade
```
every frame:
  decrease unit.ySpeed slightly
```

Uma unidade que salta quando toca o “chão”

```
every frame:
  if the unit is below y position 0
    reverse the y direction by multiplying it by -1
```

Um objeto se movendo no sentido horário em um círculo com um ponto central de 20, 20 e raio 10

```
every frame:
  unit.pos.x = 20 + sine(game.time) * 10
  unit.pos.y = 20 + cosine(game.time) * 10
```

Ao longo de um caminho arbitrário, onde cada segmento do caminho é uma linha que é animada dentro de um determinado período de tempo. Por exemplo, este item se move para a direita e depois para a esquerda.

```
if game.time > 0 and game.time < 1
  unit.speedX = 1
  unit.speedY = 0
if game.time > 1
  unit.speedX = 0
  unit.speedY = 1
```

É particularmente importante discutir o efeito de rejeição, dado que ambos os níveis o utilizam. Discuta quadro a quadro o que acontecerá neste código de exemplo:

```
unit.pos.y = 20
unit.speed = 10
every frame
  if unit.pos.y >= 40:
    unit.speed *= -1
  if unit.pos.y <= 0:
    unit.speed *= -1
  unit.pos.y += unit.speed
```


O estado de `unit.pos.y` será, de um quadro para o outro, 20, 30, 40, 30, 20, 10, 0, 10, 20, etc. Isto ocorre porque `unit.pos.y  `chega a 40,` unit.speed` é multiplicado por -1 e se torna -10 \.  Quando isso acontece, com cada intervalo, em vez de adicionar 10 à posição, é adicionado -10, portanto, a unidade se move na direção oposta.  Quando atinge 0, a velocidade é multiplicada por -1 novamente, e a posição começa a aumentar mais uma vez.

### Níveis
#### Corrida Suave


Agora que os alunos foram apresentados ao evento de atualização e à capacidade de definir posições, agora eles são mostrados como animar unidades, deslocando-as para cima e para baixo e da esquerda para a direita continuamente.

O lançador de fogo serve como um exemplo de como animar algo que se move da esquerda para a direita, para frente e para trás. Você precisa rastrear a velocidade e em que direção a unidade está indo. A velocidade é um número, a distância a ser alterada por quadro e a direção é 1 ou -1 para ser multiplicada pela velocidade. Se a velocidade é multiplicada por -1, agora é movimento para a esquerda, caso contrário, é movimento para a direita. O evento de atualização inverte a direção quando o lançador atinge uma determinada posição.

As cercas se movem de forma similar ao fogo, mas para cima e para baixo ao invés de lado a lado. Cabe ao jogador preencher as lacunas de lógica para as cercas, com base em como a animação é configurada para o incêndio.

<pre>
def onUpdateFence(event):
    fence = event.target
    # Multiply fenceSpeed and fence.dir to calculate the moving distance and direction.
    # Assign the result to the variable 'dist':
    <b>dist = fenceSpeed * fence.dir</b>
    # Add the value of the 'dist' variable to fence.pos.y:
    <b>fence.pos.y += dist</b>
    # If the fence's y position is less than 10 or greater than 56:
    if fence.pos.y > 56 or fence.pos.y < 10:
        # Multiply fence.dir by -1 and save it:
        <b>fence.dir *= -1</b>
</pre>

Linhas a serem adicionadas em **negrito**.


#### Gemas Looney 


Isso leva as animações para a próxima etapa: combinando o movimento x e y para demonstrar o movimento na diagonal. Isso também usa a propriedade `dir`, mas agora ela pode ser definida como 0, caso em que a gema não se mova nesse eixo.

Para completar este nível, os alunos terminarão a função de evento `onUpdate`. Primeiro, eles atualizarão a posição do item pelo dado `diffX` e` diffY`, e então eles irão reverter o `item.dirY` quando a gema atingir o topo ou a base do nível. Como em Corrida Suave, as “arestas” do mapa são y = 10 e y = 58 \. Veja a **discussão** acima sobre como os comportamentos de rejeição são implementados.



## Corredor

### Sumário

Esta série de níveis orienta os alunos passo a passo através da criação de um jogo de arcade de deslocamento lateral. Isso os ajuda a ver e praticar a integração desses conceitos em um projeto mais complexo e os prepara para realizar o mesmo tipo de processo iterativo no projeto final deste curso.

### Níveis

#### Corredor Parte 1

Este nível fornece a estrutura básica para o jogo do corredor. Para passar este nível, os alunos terminarão a função `onUpdateStatic` que destrói as cercas que ultrapassam o lado esquerdo (x = -4) do nível, e reutiliza os tiles da floresta. Veja a discussão anterior sobre reutilização de recursos e o nível de salto quântico para exemplos anteriores desse comportamento.


Os alunos também devem revisar o restante do código fornecido:

* `spawnRandomY` cria a cerca
* `spawnFences` cria uma série de cercas, aumentando o número de cercas com o passar do tempo.
* `onCollide` tem cercas derrotando o jogador quando há uma colisão
* `checkPlayer` mantém o jogador bloqueado em um só lugar
* `checkTimers` periodicamente chama` spawnFences`

#### Corredor Parte 2

Este nível introduz gemas, melhor pontuação e jogo infinito. O código de gemas é bastante semelhante aos níveis anteriores: o evento de coleta (quando completado pelo jogador) aumenta a pontuação do jogo sempre que uma gema é coletada. A propriedade de jogo `topScore` é obtida do banco de dados quando o jogo é configurado e é atualizada quando o jogo termina com` setTopScore`.  
  
O método `onDefeatPlayer`, que o usuário completa, requer atenção especial. A maneira como o sistema de jogo CodeCombat funciona, o jogo está `acabado` quando as metas são concluídas, ou seja, com sucesso ou com falha. No entanto, este nível permite que o jogo continue indefinidamente, por quanto tempo o jogador puder passar sem colidir com uma cerca. O jogo é "ganho" quando o jogador sobrevive por 20 segundos, mas para permitir que o jogador vá mais longe, esse objetivo não é marcado como concluído até que o jogador seja derrotado e seja marcado como bem sucedido ou falido dependendo do tempo  do`jogo`. É por isso que o objetivo manual é definido como sucesso ou falha no manipulador de eventos `derrotar` do jogador.

#### Corredor Parte 3

Este nível adiciona ogros . O código vem com `onDefeatOgre`, que aumenta a pontuação quando um ogro é derrotado. As duas funções que o usuário deve terminar são `onUpdateOgre` e` spawnOgre`. `spawnOgre` precisa configurar os eventos` update` e `defeat` para o ogro gerado. `onUpdateOgre` é mais complexo e interessante para dissecar; veja a discussão abaixo para detalhes.

#### Corredor Parte 4


Este nível é semelhante ao da Parte 3, exceto que vários valores foram refatorados para o topo do nível como variáveis, e esses valores foram definidos para tornar o jogo desafiador (embora não impossível) de vencer. Assim como no Jogo das Moedas, os alunos são encorajados a experimentar as variáveis, fazendo hipóteses sobre como alterá-las afetará o jogo e depois testá-las. Eles devem pelo menos fazer os valores de tal forma que seja possível para eles ganharem o jogo.

Atividade em grupo: faça com que os alunos se agrupem e cada um ajuste o nível para vários níveis de dificuldade. Por exemplo, um grupo faz uma dificuldade fácil, um médio, um difícil e um impossível. Peça aos grupos que demonstrem e expliquem os jogos que construíram.

### Discussão

**Por que o `onUpdateOgre` é estruturado da maneira como é?**


Essa função é um híbrido do CodeCombat e da lógica do usuário. Como a propriedade ogre `behavior` é configurada para` "AttacksNearest" `, o ogro se moverá em direção ao jogador e atacará quando estiver perto o suficiente. No entanto, para este jogo, queremos que o Ogre se mova em um determinado passo para a direita para um ponto específico (x = 18) e, em seguida, pare de se mover para a direita. Assim, esta função de atualização é executada após o CodeCombat ter movido o ogro a uma certa distância para cima ou para baixo e para a direita na direção do jogador, e sobrescreve o conjunto de jogos para `unit.pos.x` com um valor baseado em um rastreador independente e atualizou a propriedade `unit.baseX`. Por exemplo, em um único `frame`, o estado da unidade evoluirá assim:

Posição inicial: {x: 5, y: 5, baseX: 5}

Após o jogo ter movido a unidade um pouco mais perto do jogador: {x: 6, y: 6, baseX: 5}

Depois que o comando customizado `onUpdateOgre` foi executado: {x: 5.03, y: 6, baseX: 5.03}

A alteração "y" do jogo foi deixada intacta, mas a alteração da posição x foi substituída.

**O que aconteceria se `onUpdateOgre` corresse por todos os ogros, não apenas pelos derrotados e invictos?**

Dê aos alunos a oportunidade de escrever o que eles acham que acontecerá. Eles podem testar suas suposições modificando o código de `if unit.health> 0` para` if unit.health> -100` ou `se True`. Quando eles jogam o jogo, os ogros não vão mais “cair” para a esquerda. Eles vão acompanhar o jogador!


---

## Projeto de Desenvolvimento de Jogos 3

### Sumário

Peça aos alunos que projetem e construam iterativamente seus próprios projetos, como em Desenvolvimento de Jogos 2.
