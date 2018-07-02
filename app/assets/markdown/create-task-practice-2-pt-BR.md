# Guia de Princípios de Desenvolvimento de Jogos 2

## Visão Geral

Este guia deve ser usado em conjunto com o Plano de aula de Desenv. de Jogos 2 e mostrar como usar este curso para praticar os conceitos e objetivos daTarefa.

Nestes, existem oito linhas, divididas em três categorias de relatórios. Em Desenvolvimento de Jogos 1, os alunos aprenderam como satisfazer a primeira categoria de reportagem, "Desenvolvendo um Programa com um Propósito". Em Desenvolvimento de Jogos  2 continuará a praticar esses conceitos e também ensinará como satisfazer a segunda categoria de relatórios, "Aplicando Algoritmos".

## Complexidade Algorítmica

Para ser bem classificado nas linhas “Aplicando Algoritmos", os alunos devem incluir um código de complexidade suficiente. A maneira mais simples de satisfazer todos os requisitos é fazer o seguinte:

* Tenha uma função que chama duas outras funções
* Uma dessas funções chamadas inclui conceitos lógicos ou matemáticos suficientes
* O aluno marca e explica suficientemente esses algoritmos

Como tal, os níveis de Desenvolvimeno de Jogos 2 são preenchidos com exemplos destes que podem ser apontados para os alunos enquanto eles estão jogando:

* O loop de jogo da seta de desintegração chama duas outras funções, checkGoal e checkSpawnTimer, cada uma delas usando “if”.
* Corra para as chamadas de loop de jogo do Gold, checkSpawns e checkGameOver, cada uma delas usando “if”.
* "Jogo das Moedas 5: Equilíbrio" inclui uma função `checkTimers` que executa` checkTimeScore` e `checkPowerTimer`, cada um dos quais usa` if`.

Aponte essas áreas para fora enquanto os alunos jogam através dos níveis. Para o projeto, você e os alunos devem aplicar a rubrica cuidadosamente para garantir que todos os requisitos sejam atendidos. É claro, os alunos provavelmente criarão algoritmos de maior complexidade em seus projetos; O importante é garantir que eles sejam suficientemente complexos de acordo com a rubrica. Os exemplos de código fornecidos devem ajudá-lo a aplicar a rubrica corretamente.

Além disso, observe que chamar funções indiretamente por meio de manipuladores de eventos não atende à rubrica. Funções devem ser chamadas diretamente. Supondo que o aluno tenha escrito `func1` e` func2`, e um ou ambos contenham conceitos matemáticos e / ou lógicos, isso satisfará a rubrica:

```
while True:
  func1()
  func2()
```

Mas isso não acontece:
```
munchkin.on("spawn", func1)
munchkin.on("spawn", func2)
```

Isto é baseado em nossa interpretação das Diretrizes de Pontuação 2018 nas linhas 5 e 6:

> NÃO atribua um ponto se o [...] algoritmo selecionado consistir apenas em chamadas de biblioteca para a funcionalidade de idioma existente.

E os critérios de pontuação na linha 6:

> O segmento de código selecionado implementa um algoritmo que inclui pelo menos dois ou mais algoritmos.

Nosso sistema de manipulação de eventos é uma "chamada de biblioteca", em vez de um algoritmo que chama diretamente outros
algoritmos. Isso também não é realmente uma "integração" de dois ou mais algoritmos, os dois são chamados
independentemente um do outro através do sistema de manipulação de eventos. Veja também 2018 Exemplo C, que tem
várias funções, mas "integra-as" através de manipuladores de eventos e, portanto, não recebe o ponto para a linha 6.
 

## Conceitos matemáticos ou lógicos

Para que os algoritmos tenham complexidade suficiente, o código deve usar determinados conceitos. No entanto, neste ponto, seus alunos só serão ensinados  sobre declarações if/else . Nos cursos de Ciência da Computação 3 e de Desenvolvimento de Jogos posteriores, os alunos aprenderão como incorporar iteração, conceitos matemáticos e álgebra booleana, mas, enquanto isso, incentivarão os alunos a experimentar if/else em seus programas.


## Iteração

Os níveis de Jogo das Moedas servem como um exemplo do processo iterativo. Aproveite o tempo para enfatizar como ter o programa trabalhando em vários pontos de várias maneiras exemplifica a iteração e por que é útil: pode ser demonstrado para outras pessoas, o que você aprende ao construí-lo pode afetar o que e como você constrói seu projeto e são capazes de mudar o que você acaba construindo mais facilmente. Também é importante que os alunos demonstrem em seus diários como vários pontos do processo iterativo estão conectados entre si (consulte a linha 2 das Diretrizes de pontuação). Mostre como cada um desses níveis se baseia um no outro e como esse tipo de história é necessário em suas respostas escritas. Esta é uma linha fácil de perder, então o foco extra será bem gasto!

## Resposta Escrita

Os alunos devem praticar a parte 2c da Resposta Escrita depois de terminarem o projeto DJ2:

> Capture e cole um segmento de código de programa que implemente um algoritmo (marcado com um **oval** na **seção 3** abaixo) e que seja fundamental para que o seu programa atinja o objetivo pretendido. Este segmento de código deve ser um algoritmo que você desenvolveu individualmente, deve incluir dois ou mais algoritmos e deve integrar conceitos matemáticos e / ou lógicos. Descreva como cada algoritmo dentro de seu algoritmo selecionado funciona de forma independente, bem como em combinação com outros, para formar um novo algoritmo que ajude a alcançar a finalidade pretendida do programa. * (Não deve exceder 200 palavras) *.

Eles devem pelo menos fazer isso para o seu próprio projeto de desenvolvimento de jogos 2. Eles também podem praticar a identificação e a descrição de algoritmos nos níveis listados em Complexidade algorítmica ou nos projetos de desenvolvimento de jogos 2.
