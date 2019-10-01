
##### Planos de Aulas
# Guia do Curso de Desenvolvimento de Jogos 1 
- Pré-requisito Recomendado: Introdução à Ciência da Computação
- sessões de programação de 5 x 45 a 60 minutos
#### Bem-vindo ao curso de Desenvolvimento de Jogos 1!

No Desenvolvimento de Jogos 1, os alunos aprenderão como pensar em jogos e design de jogos através de discussões em sala de aula. Eles então levarão esse conhecimento para os níveis de desenvolvimento do jogo CodeCombat, onde aprenderão os comandos específicos usados para construir um jogo. Isso levará a um projeto final em que cada aluno projeta e cria seu próprio jogo exclusivo e coleta o feedback de seus colegas para fazer melhorias.

### Visão Geral do Curso


Durante o curso Desenvolvimento de Jogos 1, os alunos aprenderão como criar seus próprios jogos usando PEÇAS, MECÂNICAS e OBJETIVOS.

- Dia 1 - 3: aprender os conceitos básicos de design de jogos e os comandos usados para criar um jogo dentro do CodeCombat.
- Dia 4: os alunos irão projetar e implementar seu próprio jogo!
- Dia 5: Mostrar e Dizer - os alunos compartilharão seus jogos com toda a turma.

### Vocabulário de Referência

- **Objetivo:** Uma tarefa que um jogador deve realizar para ganhar (ou progredir) em um jogo.
- **Mecânica:** As regras que governam como um jogador interage com um jogo e como o jogo interage com o jogador.
     - * Por exemplo, a mecânica em Super Mario, o jogador aperta um botão que faz Mario pular.
- **Peça:** Os elementos específicos que compõem um jogo.
- **Jogador:** Refere-se à pessoa que joga o jogo, bem como à parte do jogo que o jogador controla.
- **Adicionável:** Um tipo de peça do jogo que o aluno pode "gerar/adicionar" em seu jogo.
- **Aluno:** Refere-se à pessoa que cria o jogo.


## Dia 1

### Introdução

**Pergunta para Discussão : Você joga jogos? Quais são seus jogos favoritos?**

Isso pode ser jogos de tabuleiro ou videogames ou esportes. Jogos vêm em muitas formas!

**Pergunta para Discussão: Qual é o jogo?**


Jogos têm:

- **Metas/Objetivos**
- **Mecânica** (também conhecida como Regras)
- **Peças** (dados, cartões, ativos digitais, equipamentos esportivos)
- **Diversão** (ou um desafio!)

#### Níveis de Desenvolvimento de Jogos

Os níveis de desenvolvimento de jogos têm algumas diferenças importantes dos níveis de Ciência da Computação:

- Os alunos usam **game** em vez de ** hero **.
    - Exemplo:`game.spawnXY("gem", 20, 34)`
    - Existe um botão "Teste" em vez do botão "Executar".
     - Cada nível apresenta novas **MECÂNICAS**, **PEÇAS** ou **OBJETIVOS/METAS** que os alunos podem usar em seus projetos finais.

### Nível 1: "Através da Parede do Jardim"

**Pergunta para Discussão: O que queremos dizer com "peças" do jogo ?**

- Um jogo tem vários elementos que fazem parte do jogo. Em um jogo de tabuleiro, geralmente são coisas como dados, fichas ou cartas. Os videogames também têm peças virtuais: os níveis, as armas, os power-ups e os inimigos.

**Pergunta para Discussão: Quais são as peças nos seus jogos favoritos??**

- Fornecemos uma variedade de peças *adicionáveis* para os alunos adicionarem aos seus jogos.
- A peça que o jogador controla é especial - nos referimos a esta peça como "o jogador", ou apenas "jogador".

#### Jogando o Nível

Este nível introduz o comando`game.spawnXY(type, x, y)` .

- Este comando cria ("spawns") uma nova peça em um determinado local no nível.
- `type` é uma * string * que nomeia o tipo de peça a ser adicionada. Nesse nível, os alunos geram uma "cerca".
- `x` e` y` são * números *. Estas são as coordenadas horizontais e verticais onde a peça deve aparecer.
- Lembre-se:
     - x começa em zero à esquerda e fica maior à direita.
     - y começa em zero na parte inferior e fica maior em direção ao topo
- Os níveis futuros introduzirão mais tipos de adicionáveis.
#### Reflexão

    - Novo Comando:
        - `spawnXY`
    - Novo Adicionável:
        - `"fence"`

### Nível 2: "Click Gait"

**Pergunta para Discussão:  O que queremos dizer com "mecânica" ou "regras"?**

- MECÂNICAS definem como o jogador interage com o jogo e como o jogo responde ao jogador.

**Pergunta para Discussão:  Quais são algumas das MECÂNICAS dos seus jogos favoritos?**

- Alguns exemplos podem ser:
     - Pressione X para pular.
     - Clique no botão esquerdo do mouse para atirar.
     - Um inimigo atacará se vir o jogador.
- Em Desenvolvimento de Jogos 1, os alunos não estarão criando novas mecânicas. Eles precisam passar para Ciências da Computação 2 e Desenvolvimento de Jogos 2 para aprender isso!
- CodeCombat fornece alguns mecanismos básicos que os alunos podem usar e configurar em seus jogos.

#### Jogando o Nível

Este nível introduz nossa primeira **mecânica** básica do jogo :

  **Mecânica #1: Clique com o mouse para mover o jogador.**

- Os alunos não precisam escrever nenhum código neste nível, basta clicar em `Testar` para jogar o nível. No entanto, é útil apontar o comando `spawnPlayerXY` aqui.
- O `jogador` é uma peça especial do jogo  que o jogador controla.
- Gerar o jogador com `game.spawnPlayerXY (type, x, y)`
     - `type` é uma *string* que nomeia o tipo de jogador para gerar
     - `x` e` y` são *números* representando uma localização no mapa
- **Erro comum:** os alunos podem gerar uma peça de jogador usando `game.spawnXY`, mas se o fizerem, o jogador não será controlável! Certifique-se de usar `game.spawnPlayerXY`! Este comando dá o passo extra de anexar a mecânica do movimento à peça do jogador.
- Este nível também mostra o comando `addMoveGoal (x, y)`, mas vamos olhar mais de perto para isso no próximo nível.

#### Reflexão

- Nova Mecânica:
    - `Clique para movimental`
- Novo Comando
    - `spawnPlayerXY`
- Novo Adicionável:
    - `"knight"`

### Nível 3: "Jornada dos Heróis"

**Pergunta para Discussão: O que queremos dizer com "Metas/objetivos"?**

- O jogador é obrigado a completar certas tarefas, a fim de ganhar ou progredir no jogo.

**Pergunta para Discussão: Quais são alguns dos objetivos de seus jogos favoritos?**

- Alguns exemplos típicos:
     - Recolha o máximo de moedas que puder antes de ficar sem tempo.
     - Derrote os inimigos.
     - Pegue a bandeira e devolva-a para sua base.
     - Jogue a bola no aro.
- Quando você cria seus jogos no CodeCombat, nós fornecemos algumas metas básicas que você pode usar. Em cursos avançados, os alunos criarão metas personalizadas!

#### Jogando o Nível

Este nível se concentra em nosso primeiro **objetivo** básico : movimento.

**Objetivo  #1:Mova para o X vermelho.**

- Use `game.addMoveGoalXY(x, y)`para adicionar um objetivo de movimento.
- `x` e `y` são *números*, representando a localização do objetivo no mapa de níveis.
- Uma meta de movimento é representada no mapa por uma marca X vermelha. A marca X desaparecerá quando o jogador se mover para esse ponto no mapa.
- Haverá mais tipos de meta nos futuros níveis de Desenvolvimento de Jogos 1.

#### Reflexão
- Novos comandos:
    - `addMoveGoalXY`
- Novos Adicionáveis:
    - `"captain"`


### Nível 4: "In-crí-vel"

**Discussão:**

Este nível introduz um novo tipo de **meta/objetivo**: coleta.

**Objetivo #2: Colete todas as pedras preciosas e baús.**

- Adicione um objetivo de coleta com o comando `game.addCollectGoal ()`.
- Duas novas partes adicionáveis: `" Forest "` e `" Chest "`
- Peças de `floresta`  podem ser usadas para criar labirintos e obstáculos.
- `" Chest "`   são peças colecionáveis.

#### Reflexão

- Novo Objetivo:
    - `addCollectGoal`
- Novos Adicionáveis:
    - `"forest"`
    - `"chest"`

### Nível 5: "Gemtacular"

#### Discussão:

**Quais são as coisas que você precisa fazer antes que seu jogo seja jogável?**

- Adicione um jogador.
- Adicione uma meta/objetivo.

Crie um jogo de coleta de gemas simples usando o comando `addCollectGoal`.

#### Reflexão

- Novo Adicionável:
    - `"gem"`


### Nível 6: "Mouse Letal"

#### Discussão

Este nível introduz três novas MECÂNICAS:

**Mecânica #2: Clique em um inimigo para atacar!**

**Mecânica #3: Inimigos atacarão se virem o jogador.**

**Mecânica #4: Algumas peças bloqueiam a "linha de visão".**

Este nível também usa dois novos tipos de meta, mas entraremos em mais no próximo nível.

#### Jogando o Nível

- Derrote os munchkins.
- Os alunos não precisam escrever nenhum código para esse nível, mas é útil examinar o código de amostra que fornecemos. Note que existem:
     - Novos tipos de adicionáveis: `" munchkin "` e `" guardian "`
     - Munchkins são inimigos!
         - Inimigos são tipos de peças de jogo que o jogador pode atacar.
         - Em Desenvolvimento de Jogos 1, os inimigos vêm com um comportamento simples (mecânica) já anexado a eles. Eles atacarão se virem o jogador.
         - Observe como os dois "munchkins" perto do final do mapa não podem ver o jogador no começo.
     - Usamos `spawnXY` para criar um labirinto de `floresta` . As partes `` `floresta` bloqueiam a **linha de visão** entre `munchkin` e o `"guardião"`.

#### Reflexão

- Novas Mecânicas
	- Clique para atacar.
     - Inimigos atacam se virem o jogador.
     - Linha de visão.
- Novos Adicionáveis:
    - `"munchkin"`
    - `"guardian"`

## Dia 2

### Revisão
- Da última vez aprendemos como:
     - Adicionar PEÇAS no jogo com `spawnXY`.
     - Adicionar o jogador com `spawnPlayerXY`.
     - O jogador pode se mover clicando no mapa.
     - Adicione um Objetivo com `addMoveGoalXY` e` addCollectGoal`

### Nível 7: "Esmagando"

#### Discussão

Este nível se concentra em dois novos tipos de OBJETIVOS:

**Objetivo #3: Derrote os Inimigos.**

**Objetivo #4: Sobreviver até que outros objetivos estejam completos.**

Objetivo #4 é um pouco diferente dos outros objetivos. Objetivos como mover, coletar e derrotar são todas as ações que o jogador deve completar para vencer. Sobrevier - fará com que o jogador perca e termine o jogo se o jogador for derrotado.

#### Jogando o Nível

- Adicione uma meta de derrota com o comando `game.addDefeatGoal ()`.
- Adicione uma meta de sobrevivência com o comando `game.addSurviveGoal ()`.
- Crie pelo menos 3 inimigos "munchkin", além do que foi gerado no código de amostra (para um total de pelo menos 4 munchkins).

#### Reflexão
- Novos Comandos:
    - `addDefeatGoal`
    - `addSurviveGoal`

### Nível 8: "Dar e Pegar"

#### Discussão

Este nível adiciona novas peças adicionáveis, com novas mecânicas anexadas a elas.

- Uma `armadilha de fogo` danifica o jogador quando ele chega perto demais!
- Uma `poção pequena` cura o jogador 150 pontos de vida quando o jogador se move para ele.
- Introduz a peça de jogador ` samurai `.

- Os alunos precisam adicionar pelo menos duas ` poções pequenas '`para completar o nível.
- Os pontos de movimento estão presos. Depois de largar a `armadilha de fogo` , o jogador deve se curar usando uma poção, e voltar para o X vermelho.
- Lembre-se, se o X vermelho ainda estiver no mapa, você ainda não completou essa meta de movimento!

#### Reflexão

- Npvos Adicionáveis:
    - `"samurai"`
    - `"Armadilha de Fogo"`
    - `"pequena poção"`

### Nível 9: "Treinamento do Exército"

#### Discussão


Este nível adiciona novas unidades de adicionáveis.
Os "atiradores" são inimigos com um ataque de lançamento de lança à distância.
- "soldados" são aliados para o jogador, com um ataque corpo a corpo.
- "arqueiros" são aliados com ataques à distância.

#### Reflexão

- Novos Adicionáveis
    - `"thrower"`
    - `"soldier"`
    - `"archer"`


### Nível 10: "Guarda Perigoso"

#### Discussão

Ao criar seus próprios jogos, encontrar o equilíbrio certo entre aliados e inimigos pode levar a alguma experimentação.

- Unidades à distância geralmente causam mais danos, mas têm menos saúde.
Os "soldados" são mais fortes que os munchkins, mas mais lentos.
- Mais tarde, os alunos poderão modificar as estatísticas do jogador e das unidades.

#### Jogando o nível

- Não há jogador neste nível.
- O código de nível começa com muitos soldados e não há arqueiros suficientes para derrotar o gigante Ogro Brawler.
- O aluno deve substituir dois dos "soldados" por "arqueiros", depois clicar no botão "Teste de Nível" para ver como a batalha se desenrola!
- Nesse nível, tudo bem se alguns de seus aliados forem derrotados, contanto que o ogro seja derrotado.

#### Reflexão

- Às vezes é preciso um pouco de tentativa e erro para encontrar o caminho certo do **balanço do jogo**.

### Nível 11: "Magia da Cerca"


#### Discussão

Este nível introduz o tipo de jogador `duelist` e o comando `game.spawnMaze (seed)`.

- Construir um labirinto inteiro de peças `forest`pode demorar um pouco, então nós lhe demos um comando para gerar um labirinto aleatório.
- O parâmetro de semente pode ser qualquer número. É chamado de `semente/seed` porque inicializa a aleatoriedade usada para criar o labirinto. Se você alterar a semente, o labirinto gerado será alterado.
- Experimente colocar diferentes números como argumentos no comando spawnMaze até encontrar um labirinto que você goste! Por exemplo:
    - `game.spawnMaze(42)`
    - `game.spawnMaze(1337)`

#### Reflexão

- Novo Comando
    - `spawnMaze(seed)

### Nível 12: Incursão Florestal

#### Discussão

Objetos de jogo têm **propriedades**. Propriedades são como variáveis específicas desse objeto específico. Este nível também introduz o tipo de jogador "goaliath".

- Neste nível, aprendemos sobre três propriedades das unidades.
- `maxSpeed` é um número que representa a velocidade com que uma unidade pode se mover.
- `maxHealth` é um número que representa quanta saúde uma unidade começa.
- `attackDamage` é um número que representa quanto dano a unidade faz em um único ataque.
- Alterar as propriedades do jogador ou outras unidades pode afetar drasticamente o saldo do jogo.
- As propriedades são comumente acessadas usando um ponto `.` entre o objeto e a propriedade, como:`object.propertyName`
- Note que todos os comandos do jogo são propriedades do objeto `game`, e você acessa esses comandos usando a mesma notação de pontos!

#### Jogando o Nível
- Observe que o código de exemplo salva o resultado do comando `spawnPlayerXY` na variável` player`.
- Dessa forma, os alunos podem usar a variável `player` para modificar as propriedades do jogador, como fazemos com` player.maxSpeed = 25`, que atribui um valor de `25` à propriedade` maxSpeed` do objeto `player` .
- Alterar as propriedades das unidades é um super poder especial que os alunos têm nos níveis de desenvolvimento de jogos. Eles são restritos de modificar diretamente a maioria das propriedades da unidade nos níveis do curso CS!

#### Reflexão

- Novos Adicionáveis
    - `"goliath"`
- Nova Propriedade de Unidades
    - `maxSpeed`
    - `maxHealth`
    - `attackDamage`


### Nível 13: Jogando Fogo

#### Discussão

Nos níveis de Desenvolvimento de Jogos 1, alguns objetos têm **mecânica** que pode ser configurada alterando os valores de suas propriedades.

- Este nível introduz o adicionável `"spewer"` do fogo.
- Os alunos podem usar a propriedade `direction` de um` "fire-spewer`" para configurá-lo para atirar em uma direção `" vertical "(para cima e para baixo) ou` `horizontal" `(esquerda e direita) .
- Em Desenvolvimento de Jogos 2, os alunos aprenderão como dar mecânica personalizada aos objetos do jogo, mas eles precisam concluir o curso de Ciência da Computação 2 antes de poderem fazer isso. Por enquanto, nós fornecemos algumas mecânicas configuráveis para tornar as coisas um pouco mais simples.

#### Jogando o Nível

- Observe que o código de amostra atribui o resultado do comando `spawnXY` a uma variável, para que o código posterior possa acessar as propriedades do objeto gerado.
- A propriedade `direction` só pode ser definida para uma **strin **, ou `"horizontal" `ou` "vertical" `.

#### Reflexão

- Novo objeto de jogo configurável
    - `"fire-spewer"`
        - Propriedade `direction` 

### Nível 14: Them Bones

#### Discussão

Este nível introduz os adicionáveis `` generator``, `" skeleton "`, e `"lightstone`, assim como o jogador `champion`
- Um `"generator"`adiciona uma unidade `"skeleton"` a cada 5 segundos.
- Unidades têm equipes diferentes. Unidades humanas vêem unidades de ogro como inimigos, e unidades de ogro vêem unidades humanas como inimigos.
- `"skeleton"`s são neutros, então eles atacarão os ogros e os humanos!
- `"skeleton"`s têm medo de `"lightstone"`. Quando o jogador carrega uma lightstone/pedra de liz, os esqueletos vão ficar longe!
- `"generator"`s podem ser configurados para gerar diferentes tipos de unidades, o que veremos em níveis futuros.

#### Jogando o Nível
- O gerador continuará a gerar esqueletos até que seja destruído.
- Use o lightstone para manter os esqueletos afastados, dando-lhe tempo para destruir o gerador.
- O lightstone não dura para sempre, então use-o com sabedoria!

#### Reflexão

- Novos Adicionáveis
    - `"generator"`
    - `"skeleton"`
    - `"lightstone"`
    - `"champion"`

## Dia 3

### Revisão

Quais tipos de objetivos estão disponíveis para construir nossos jogos?

- Mover
- Coleatr
- Derrotar
- Sobreviver


Que tipos de peças adicionáveis estão disponíveis?

- Obstáculos
    - `"fence"`
    - `"forest"`
- Coletáveis
   - `"gem"`
    - `"chest"`
- Inimigos:
    - `"munchkin"`
    - `"thrower"`
    - `"skeleton"`
- Jogadores:
    - `"knight"`
    - `"captain"`
    - `"guardian"`
    - `"samurai"`
    - `"duelist"`
    - `"goliath"`
    - `"champion"`
- Aliados
    - `"soldier"`
    - `"archer"`
- Diversos:
    - `"fire-trap"`
    - `"potion-small"`
    - `"fire-spewer"`
    - `"generator"`
    - `"lightstone"`

Lembre-se de que os alunos podem ver as propriedades desses objetos adicionáveis clicando neles na seção Adicionável do painel central da janela do jogo.

### Nível 15: Desenvolvimento Orientado por Comportamento

#### Discussão

Este nível introduz o adicionável `"ogre"`, assim como a propriedade de unidade `behavior`, que permite aos estudantes modificar a mecânica anexada a uma unidade, e fazê-los comportar-se de maneira diferente.

- Todas as unidades (aliadas e inimigos) podem ser configuradas com diferentes ** mecânicas ** usando a propriedade `behavior`.
- A propriedade `behavior` deve receber uma **string**, que pode ser uma das seguintes:
     - `" AttacksNearest "` configura a unidade para atacar seu inimigo mais próximo.
     - `" Scampers "` configura a unidade para se movimentar aleatoriamente.
     - `" Defends "` configura a unidade para ficar no lugar e atacar qualquer inimigo que esteja dentro do alcance.
- Em Desenvolvimento de Jogos 2, os alunos aprenderão a personalizar o comportamento das unidades de maneiras mais complexas.

#### Jogando o Nível


- Este nível é um pouco mais complicado do que ganhar - como um jogo real pode ser!
- Uma estratégia é usar as pedras para afastar os esqueletos de um ogro e afastar o ogro dos outros, para onde seu aliado estiver esperando para ajudá-lo a derrotar o ogro. Isso leva algum movimento cuidadoso do seu jogador para conseguir.
- Certifique-se de beber uma poção de saúde quando a sua saúde estiver baixa!
- Pode demorar algumas tentativas para vencer o jogo - não desista!
- Se você está realmente achando difícil, você sempre pode dar ao seu player mais `attackDamage` para facilitar as coisas.

#### Reflexão

- Novo Adicionável:
    - `"ogre"`
- Nova Propriedade de Unidade:
    - `behavior`


### Nível 16: Hora de Viver

#### Discussão

Este nível introduz o uso de um argumento para configurar uma meta de sobrevivência cronometrada e a configuração de um gerador para gerar `` munchkin``s.

- Anteriormente, os alunos usavam `addSurviveGoal ()` sem argumento (nada entre os parênteses). Isso significa que o jogador deve sobreviver até que todos os outros objetivos sejam atingidos.
- Agora, os alunos podem usar `addSurviveGoal (seconds)` para configurar uma meta que tenha sucesso enquanto o jogador sobreviver por um determinado número de segundos.
- O argumento `seconds` deve ser um número, como` addSurviveGoal (20) `por` 20` segundos.
- `" generator "` s tem uma propriedade chamada `spawnType`, que pode ser definida como uma string de qualquer tipo de unidade gerável.

#### Jogando o Nível

- Certifique-se de configurar o gerador e o player conforme instruído nos comentários do código de amostra, ou as metas não serão atingidas.
- 
#### Reflexão

- Nova configuração de meta:
    - `addSurviveGoal(seconds)`

- Nova configuração do gerador:
    - `spawnType`

### Nível 17: "Tabula Rasa"

#### O PROJETO FINAL!


Este nível é uma lousa em branco. Para passar do nível, os únicos requisitos são gerar um jogador e adicionar um objetivo - mas, na verdade, isso é só o começo. Incentive os alunos a serem criativos com todas as técnicas que aprenderam durante o curso!

Há um novo botão "GAME" acima da janela do editor de código. Clicar em GAME carrega a versão compartilhável do jogo do aluno e fornece um link que o aluno pode dar a seus amigos.

Os alunos devem projetar um jogo, combinando as PEÇAS, OBJETIVOS e MECÂNICA do jogo que aprenderam de maneiras criativas.

Todo jogo deve, pelo menos:

1. Adicione uma peça de jogador.
2. Adicione um ou mais objetivos para o jogador completar.
3. Use alguma combinação de obstáculos, inimigos, colecionáveis e outras peças para criar um desafio divertido para o jogador.

Além disso, os alunos podem usar o comando `db.add` para rastrear quantas pessoas jogaram o jogo. Eles também podem usar a propriedade `game.defeated` se quiserem rastrear quantos inimigos foram derrotados por seus jogadores no total! No curso Desenvolvimento de Jogos 2, os alunos aprenderão como reagir aos eventos à medida que eles ocorrem no jogo e poderão usar o banco de dados para rastrear estatísticas ainda mais interessantes sobre seus jogos.

Os alunos devem seguir os seguintes passos para criar seus jogos:

1. **Projete.** Isso pode ser feito em papel. Descreva a ideia, esboce o mapa, liste os objetivos.
2. **Construa.** Pegue o design inicial e construa-o no mecanismo de jogo (neste caso, use o nível Tabula Rasa para construir o jogo).
3. **Teste.** À medida que os alunos constroem seu jogo, eles devem sempre testá-lo jogando o jogo para se certificar de que está funcionando da maneira que imaginaram.
4. **Feedback.** Os alunos devem compartilhar o link do jogo com os amigos e coletar feedback sobre o que torna o jogo divertido ou frustrante.
5. **Melhore.** Com base no feedback, os alunos voltam para a fase de construção e fazem melhorias no jogo!

Para o restante do Dia 3, concentre-se nas etapas 1, 2 e 3.

## Dia 4

#### Conclua o trabalho nos projetos finais.


Concentre a primeira parte do Dia 4 em fazer com que os alunos se alinhem com um amigo.

Cada aluno deve usar o botão GAME para obter o link compartilhável e fornecer esse link ao parceiro.

Em cada par, um aluno primeiro joga o jogo do outro, enquanto o criador do jogo observa. Peça aos observadores que pensem nas seguintes questões:

- Seu parceiro jogou o jogo da maneira que você esperava que fosse jogado? Eles criaram uma maneira surpreendente de tocar?
- Eles pareciam se divertir? Eles pareciam frustrados?
- Eles quebraram o jogo ou funcionaram como você pretendia?

Em seguida, pergunte ao jogador por seus pensamentos sobre o jogo. O criador deve tomar notas sobre esse feedback.

Em seguida, troque de papel e repita o processo de teste e feedback para o jogo do parceiro.

Após este exercício, volte e trabalhe individualmente no seu jogo novamente. Há alguma melhoria que você possa fazer com base no que observou?

Se houver tempo, faça com que os alunos emparelhem novamente, dessa vez com um parceiro diferente, e veja se os resultados são diferentes.

## Dia 5

#### Mostrar e Contar o dia


Este dia encerra a semana de Desenvolvimento de Jogos 1.

Cada aluno deve ter alguns minutos para mostrar seu jogo para a turma. Incentive cada aluno a falar sobre coisas como:

- Qual foi a sua ideia original para o jogo?
- O que mudou da ideia original quando você estava construindo o jogo?
- Alguma coisa te surpreendeu quando os playtesters estavam jogando o seu jogo?
- Você fez alguma alteração depois de assistir aos playtesters jogando seu jogo?

Incentive os alunos a compartilhar links para seus projetos finais com a família e amigos!
 

---
