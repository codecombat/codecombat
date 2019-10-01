##### Atividade
# Como a Internet Funciona
Atividade de Inquérito
 
### Princípios de Ciências da Computação: Objetivos de Aprendizagem:

- [LO 6.1.1] Explique as abstrações na Internet e como a Internet funciona. [P3]
- [LO 6.2.1]Explique as características da Internet e os sistemas construídos nela. [P5]
- [LO 6.2.2] Explique como as características da Internet influenciam os sistemas construídos sobre ela. [P4]
 
## Como a Internet Funciona? 
 
Comece dando aos alunos de 3 a 5 minutos para escrever como eles acham que a internet funciona. Peça a dois ou três alunos que compartilhem seus pensamentos. Por enquanto, não se concentre em informar se eles estão certos ou errados. Em vez disso, permita que eles simplesmente compartilhem suas diferentes opiniões com a turma.

## Endereço do Protocolo da Internet (IP)

Pergunte aos alunos que já ouviram falar de um endereço IP antes. Sinta-se à vontade para permitir que os alunos discutam rapidamente o que eles acham que é um endereço IP. Compartilhe a seguinte definição escrevendo-a no quadro ou projetando um slide:

Um endereço IP (Internet Protocol) é um endereço de identificação exclusivo para cada dispositivo na Internet.

Peça aos alunos que pensem em algumas analogias com um endereço IP. As respostas apropriadas incluiriam um endereço para correspondência, um número de telefone, um número do seguro social e um endereço de e-mail.

Peça aos alunos que usem um dispositivo (computador, tablet ou smartphone) e visitem o site https://whatismyipaddress.com/. Peça a alguns alunos que compartilhem seus endereços IP com a turma. Observe que cada endereço IP tem o mesmo formato, #. #. #. #., Em que cada # é um número no intervalo de 0 a 255. 

Além disso, muitos alunos da turma podem ter endereços IP semelhantes, principalmente no primeiro semestre. Se este for o caso, pergunte aos alunos por que eles acham que é assim. Levar a discussão para o esquema de nomenclatura de endereços IP. A parte inicial do endereço IP identifica a rede à qual o dispositivo está conectado. A parte final do endereço identifica o dispositivo real. Essa hierarquia é o que permite que sites como https://whatismyipaddress.com/ identifiquem onde um dispositivo é de seu endereço IP.


Com base no formato dos endereços IP, pergunte à classe quantos endereços IP possíveis existem. Eles devem descobrir que existem mais de 4 bilhões de endereços possíveis (calculando 256 * 256 * 256 * 256 ou 256 ^ 4). Pergunte aos alunos se eles acham que esses endereços são suficientes para acomodar o dispositivo de todos no mundo.

Na verdade, devido à ascensão de dispositivos móveis e ao número de endereços IP reservados para determinadas organizações, há uma escassez de endereços IP. Para acomodar isso, um novo protocolo, chamado IPv6, foi estabelecido para lidar com muito mais dispositivos.

Endereços IP são atribuídos a dispositivos pelo Protocolo de Configuração Dinâmica de Hosts (DHCP). O servidor DHCP mantém um conjunto de endereços IP que ele atribui aos dispositivos por um período de tempo limitado. Cada dispositivo na rede recebe seu próprio endereço IP. Quando um endereço IP não está sendo usado, ele é colocado de volta no pool para ser alocado novamente.

Uma analogia para a atribuição de endereços IP por DHCP é obter números na fila em uma lanchonete. Cada cliente obtém seu próprio número e, embora seja possível obter o mesmo número repetidamente, não é garantido.

## Servidores de Nome de Domínio (DNS)


Um componente adicional da Internet é o Servidor de Nomes de Domínio (DNS). Um DNS traduz os URLs de sites, ou nomes de domínio, para endereços IP. O DNS é necessário porque os dispositivos acessam sites com base em endereços IP, mas os humanos os acessam por meio de nomes de domínio.

Uma analogia para o DNS é um catálogo telefônico. A maioria das pessoas não memoriza os números de telefone um do outro, mas pode procurar o nome de uma pessoa para obter o seu número de telefone. Isso é semelhante a digitar um URL, que é então traduzido para um endereço IP para o qual o dispositivo pode navegar.

Diga aos alunos para navegar para uma página da Web comum, como www.nytimes.com. Peça-lhes para clicar em vários links no site e anote o URL após cada clique. Pergunte aos alunos o que eles notam sobre os URLs. Eles devem ver que todos os URLs começam com nytimes.com. Isso é chamado de nome de domínio.

Os nomes de domínio fazem parte da hierarquia de nomes do DNS. Um nível de hierarquia inclui os sufixos, como .com, .edu e .org. Outro nível inclui o nome do site, como facebook, nytimes e codecombat. Os períodos separam cada parte do nome, permitindo que o DNS execute a pesquisa e navegue até o site correto.

## Transmissão de Dados


A Internet move informações computadorizadas de um lugar para outro. Uma analogia para a Internet é o serviço postal dos Estados Unidos. A informação é passada entre os dispositivos, sem considerar o que é a informação ou por que ela está sendo enviada. Por causa dos protocolos e servidores padrão, a Internet pode ser usada para transmitir muitos tipos diferentes de informações. Além disso, podem ser criados aplicativos que simplesmente precisam se comunicar com a Internet para serem executados na rede.

A informação é transmitida na Internet via comutação de pacotes. Em vez de enviar informações de uma só vez, as informações são divididas em partes menores, chamadas de pacotes. Cada pacote é então enviado separadamente para o destino, onde todos são remontados. Como isso é feito é padronizado com o protocolo de controle de transmissão, ou TCP.

No final da lição, peça aos alunos que escrevam como a Internet funciona de uma maneira que as crianças possam entender. Instrua-os a explicar as abstrações da Internet em sua escrita. Eles podem revisitar sua escrita desde o início da aula e comparar seus pensamentos no início da aula com a realidade de como a Internet funciona.
 
### Questões de Discussões:
- Quais problemas podem surgir se dois dispositivos receberem o mesmo endereço IP em uma rede?
- O que você acha que acontecerá quando ficarmos sem endereços IP válidos?
- Por que precisamos de DHCP?
- Por que precisamos de DNS?
- Por que os endereços IP e os nomes de domínio são hierárquicos?
- Por que você acha que a comutação de pacotes é útil?
- Quais conexões existem entre as abstrações da Internet e as abstrações na programação?
- Compare e contraste a compressão de dados e a comutação de pacotes.
- Descrever como a comutação de pacotes pode ajudar a manter os dados mais seguros.

### Questões de Avaliação:
- Defina a internet [EK 6.1.1A]
- Como um dispositivo conectado à Internet é identificado por outro dispositivo? [EK 6.1.1E, EK 6.1.1G]
- Como os nomes de domínio e os endereços IP são organizados?? [EK 6.2.1B, EK 6.2.1C]
- O que torna a internet tolerante a falhas? [EK 6.2.2B]
- Quais são alguns protocolos que sustentam a internet? [EK 6.1.1E, EK 6.2.2G]
