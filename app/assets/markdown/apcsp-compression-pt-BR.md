##### Atividade
# Compactação com perdas e sem perdas
Atividade de Inquérito

Dados - Existem trade-offs ao representar informações como dados digitais.	

### Objetivos de Aprendizagem
- (LO) 3.3.1 Analise de é a representação de dados, armazenamento, segurança e transmissão de dados envolvem manipulação computacional de informações. [P4]

**Informação para o instrutor**

Muitas decisões precisam ser tomadas ao armazenar ou transmitir dados digitalmente. Isso pode afetar a quantidade de espaço de armazenamento usado, a largura de banda necessária e a segurança dos materiais digitais.

Esta atividade demonstrará técnicas de compactação com e sem perdas e como elas podem afetar os dados. 

As técnicas de compactação com e sem perdas reduzirão o tamanho dos dados, reduzindo o espaço necessário para armazená-los ou a largura de banda necessária para transmitir os dados.

Ao usar a compactação sem perdas, todos os dados originais ainda estarão disponíveis e os dados originais poderão ser completamente restaurados à sua condição original. Esse é um método preferencial para dados que possuem informações específicas que não podem ser perdidas, como arquivos de texto e planilhas.

Ao usar a compactação com perdas, o tamanho do arquivo é reduzido, removendo as informações do original. Esses arquivos não podem ser totalmente restaurados para sua condição original. Esse é um método preferencial para dados em que a perda de informações não será prejudicial, como em arquivos de imagem, som e vídeo

## Compactação com perda


Este é um close-up de um mapa de Backwoods Forest, mantido por um dos heróis da CodeCombat, Anya.

<img alt="high res image" src="/images/pages/teachers/resources/markdown/compression-high-res.jpg" class="res-image" />

Os detalhes do mapa podem ser vistos claramente. Esta imagem não é compactada e ocupa 194KB ou espaço de armazenamento. Isso também significa que leva muita largura de banda para transmitir.

Aqui está a mesma imagem, mas depois é comprimida 90%. Agora, são necessários apenas 20 KB de espaço de armazenamento e largura de banda.

<img alt="low res image" src="/images/pages/teachers/resources/markdown/compression-low-res.jpg" class="res-image" />

eja como os detalhes ficaram embaçados. Esse é um dos custos da compactação com perdas.




## Compactação Sem Perdas

**Compactação Sem Perdas**
Aqui um exemplo utilizando um texto em inglês.
<table class="woodchuck">

<tbody>

<tr>

<td>

<span>How much wood could a woodchuck chuck  
</span>

<span>If a woodchuck could chuck wood?</span>

<span>  
As much wood as a woodchuck could chuck,</span>

<span>  
If a woodchuck could chuck wood.</span>

</td>

<td>

<span>How much</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><span> could a</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> </span><img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> </span>

<span>If a</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> could</span> <img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> </span><img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><span>?</span>

<span>As much</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><span> as a</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> could</span> <img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span>,</span>

<span>If a</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> could</span> <img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> </span><img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><span>.</span>

<span></span>

</td>

</tr>

<tr>

<td>

<span> 144 caracteres no total</span>

</td>

<td>

<span>Por usar</span> <img alt="wood image" src="/images/pages/teachers/resources/markdown/compression-wood-x.png" class="wood" /><span> and</span> <img alt="grass" src="/images/pages/teachers/resources/markdown/compression-grass.png" class="grass" /><span> para substituir “madeira” e “chuck” reduzimos o total de caracteres para 88 caracteres, o que equivale a uma compressão de 39%.</span>

<span>Como sabemos o que os símbolos representam, podemos reconstruir o twister original sem perda de dados.</span>

</td>

</tr>

</tbody>

</table>

144 caracteres no total
Ao usar e substituir "madeira" e "chuck", reduzimos o total de caracteres para 88 caracteres, o que representa uma compressão de cerca de 39%.Como sabemos o que os símbolos representam, podemos reconstruir o twister original sem perda de dados.

**Compactação com Perdas**
Veja o exemplo abaixo:

<table class="peter-piper">

<tbody>

<tr>

<td><span>Peter Piper picked a peck of pickled peppers.</span> <span>Did Peter Piper pick a peck of pickled peppers?</span> <span>If Peter Piper Picked a peck of pickled peppers,</span> <span>Where's the peck of pickled peppers Peter Piper picked?</span><span></span><span></span></td>

<td><span>Ptr Ppr pckd a pck of pckld ppprs.</span> <span>Dd Ptr Ppr pck a pck of pckld ppprs?</span> <span>If Ptr Ppr Pckd a pck of pckld ppprs,</span> <span>Whr's th pck of pckld ppprs Ptr Ppr pckd?</span></td>

</tr>

<tr>

<td><span>195 caracteres</span></td>

<td><span>Ao remover todas as vogais, exceto aquelas que iniciam palavras, reduzimos  para 148 caracteres para uma taxa de compactação de 24,1%</span></td>

</tr>

</tbody>

</table>
Pergunte aos seus alunos se eles acham que a compactação sem perdas seria mais eficiente?
Divida seus alunos em grupos e faça-os tentar.

Peter Piper picked a peck of pickled peppers.
Did Peter Piper pick a peck of pickled peppers?
If Peter Piper picked a peck of pickled peppers,
Where's the peck of pickled peppers Peter Piper picked?

Dê a eles alguns minutos para escrever isso em um formato compactado, substituindo grupos comuns de letras por palavras.
Peter, Piper, pickled, e peppers são todos comuns.
Entretanto, Peter & Piper só aparecem juntos, então um símbolo pode substituir as duas palavras
O mesmo é verdade para pickled peppers.

Poderia ser comprimido ainda mais?

### Análise de Vídeo
1. Peça aos alunos que encontrem um vídeo do YouTube de alta resolução (4K) e cliquem nas configurações para alterar a resolução de 2160p para 1080p, depois para 480p e, finalmente, para 144p.
2. Faça com que eles mudem de 2160p para 144p.
3. Peça-lhes para analisar as diferenças na qualidade do vídeo
4. Peça-lhes para analisar as necessidades de armazenamento do vídeo em 2160p vs 144p.

Aqui estão quatro vídeos de alta qualidade para uso se sua classe ainda estiver dividida em equipes:
- Amazing 4K Video of Colorful Liquid in Space
- Hubble The Final Frontier - Official Final Film
- NASA | 4K Video: Thermonuclear Art – The Sun In Ultra HD 4K
- 4k Hawaii Drone Footage

Peça-lhes para analisar se a transmissão de música é compactada usando compactação com perda ou sem perda.


### Questões de Discussão:
- Quando você usaria a compactação com perdas?
- Quando você usaria a compactação sem perdas?
- Quais são os trade-offs ao representar as informações digitalmente?
- Por que a compactação ao transmitir dados é importante?
- Os alunos podem pensar em algum exemplo em que você, como aluno, usa a compressão em sua vida?

*É esperado que os alunos percebam que usam isso quando escrevem.*
- Blz = Beleza
- Fds = Final de Semana
- vc = você

### Questões de Avaliação:
- O que é compactação sem perdas? O que é um exemplo de compactação sem perdas na computação? [EK 3.3.1D]
- O que é compactação com perdas? O que é um exemplo de compactação com perdas na computação?[EK 3.3.1E]
