##### Atividade
# Cibersegurança
Atividade de Inquérito

### Objetivos de Aprendizado:
- [LO 6.3.1] Identificar as preocupações com segurança cibernética existentes e as possíveis opções para abordar esses problemas com a Internet e os sistemas construídos sobre ela. [P1]
- [LO 7.1.2] Explique como as pessoas participam de um processo de solução de problemas que aumenta. [P4]

## Preparação

Antes da aula, encontre um pequeno artigo ou vídeo descrevendo um ataque cibernético que tenha aparecido nas notícias recentemente ou use um destes:

- Interferência eleitoral de 2016:  https://www.cbsnews.com/news/dhs-official-election-systems-in-21-states-were-targeted-in-russia-cyber-attacks/ 
- Ataque cibernético da HBO: http://www.newsweek.com/hbo-cyberattack-sony-hack-leak-game-thrones-645450 
- Ataque global de ransomware:
https://www.nytimes.com/2017/06/27/technology/global-ransomware-hack-what-we-know-and-dont-know.html?mcubz=0 

## Discuta Ataques Cibernéticos
Discuta o ataque cibernético. Pergunte aos alunos se eles já ouviram falar do ataque cibernético. Deixe que eles compartilhem o que já sabem e guiem a discussão em sala de aula:

- Como descobrimos esse ataque?
- Qual o impacto desse ataque?
- Como podemos nos defender contra esse tipo de ataque?

## Golpes de Phishing

Mostre aos alunos uma imagem de um e-mail de phishing (um e-mail de spam que solicita que você faça login com seu e-mail e senha).

<img alt="phishing scam" src="/images/pages/teachers/resources/markdown/phishing-scam.jpg" id="phishing-scam" />

Pergunte aos alunos o que eles fariam se recebessem este e-mail. Saliente que, embora o e-mail possa parecer legítimo, é, na verdade, um exemplo de phishing. O phishing é uma forma de ataques cibernéticos nos quais emails aparentemente legítimos são usados para coletar informações pessoais de destinatários desavisados.

Agora pergunte aos alunos se eles podem descobrir como você foi capaz de dizer que era ilegítimo. A razão é porque o site é http em vez de https. O Protocolo de Transferência de Hipertexto (HTTP) e o Protocolo de Transferência de Hipertexto Seguro (HTTPS) são dois protocolos usados para transferir informações entre dispositivos na Internet. A diferença entre os dois está na última letra, S. O S significa seguro, referindo-se à criptografia usada para transferir informações no site. Secure Socket Layer (SSL) é a tecnologia padrão usada para criptografar os dados entre navegadores e servidores na Internet. Usa criptografia simétrica e assimétrica. A criptografia simétrica é quando você usa uma chave para criptografar e descriptografar. Assimétrica é quando você usa uma chave para criptografar (uma chave pública) e outra para descriptografar (uma chave privada). Quando seu navegador acessa um site por meio de HTTPS, ele cria uma mensagem com a chave pública do site, que somente o site pode descriptografar com sua chave privada. Essa mensagem que o navegador envia inclui informações para gerar uma chave simétrica secreta que as duas máquinas podem usar para passar informações de maneira particular para frente e para trás. Esse processo é chamado de aperto de mão. Para maior segurança, o seu navegador só iniciará este aperto de mão se o site tiver um certificado emitido por uma autoridade de certificação confiável. Você pode usar seu navegador para procurar informações de certificado para qualquer site que seja servido por HTTPS. Quando seu navegador avisa que um site não é seguro, geralmente significa que ele possui um certificado inválido ou expirado.

Muitos invasores de phishing criam sites falsos que imitam o nome da empresa, mas são sites http e não https. Como os alunos já viram, criar um site não é muito difícil. Os invasores podem copiar imagens do website da empresa e criar algo que pareça quase idêntico. Eles então podem acessar as informações não criptografadas enviadas pelo usuário.

## Distributed Denial of Service Attacks

Uma Negação de Serviço Distribuída (DDoS) é um ataque cibernético no qual vários dispositivos atacam um serviço online, sobrecarregando-o a ponto de não poder mais funcionar. Esse tipo de ataque é frequentemente usado por grupos que desejam derrubar sites como uma forma de protesto.

Compartilhe o seguinte artigo com os alunos,
https://www.wired.com/story/reaper-iot-botnet-infected-million-networks/. Faça uma discussão de classe sobre o artigo e observe que a aceitação desses tipos de ataques está em debate. Também não deixe de discutir o impacto de ter várias pessoas participando do ataque.

## Reflexão

Finalmente, dê aos alunos essa tarefa para começar na aula e terminar para o dever de casa. Eles devem investigar um ataque cibernético por conta própria e escrever sobre isso. Lembre-os de que eles escolhem sites confiáveis como fontes. Peça-lhes que escrevam uma resposta de uma página para as seguintes perguntas:

- Que tipo de ataque é esse?
- Como foi descoberto?
- Quem estava alvejando?
- Qual foi o dano?
- Como pode ser defendido?

### Questões de Avaliações:
- Quais são alguns dos efeitos da guerra cibernética e do cibercrime? [EK 6.3.1C]
- O que é DDoS? [EK 6.3.1D]
- O que é criptografia de chave pública? [EK 6.3.1L]
