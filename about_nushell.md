
# nushell

Nushell é um shell moderno desenvolvido com o objetivo de providenciar uma experiência multiplataforma elegante e amigável.
Este shell adota o uso de dados estruturados em seus comandos, permitindo que dados possam ser manipulados
de acordo com seus tipos apropriados, sem a necessidade de conversões de texto para a composição de operações, como ocorre em shells
POSIX como bash, zsh e fish.

## Dados não estruturados em shells POSIX

Em shells tradicionais (POSIX), todos os comandos recebem como entrada uma stream de bytes, e devolvem
como saída uma stream de bytes, ambas normalmente na forma de texto. Por conta disto, para que os comandos nestes ambientes
possam ser combinados, eles precisam ser
capazes de formatar sua saída em um formato textual arbitrário,
para que outros comandos possam então ser capazes de interpretar o conteúdo deste texto,
manipular este conteúdo, e depois formatar sua saída novamente em um outro formato textual.

Considerando que neste modelo, não existe estrutura geral fixa para as entradas e saídas dos comandos - cada um
com suas própias convenções sobre o formato dos dados - é comum se referir a este como um modelo de dados não estruturados.

Em particular, é comum o uso de textos representando tabelas neste modelo, onde as linhas das tabelas são separadas
pelos caracteres de quebra de linha textuais (também conhecido por '\n'), e as colunas das tabelas são separadas por quantidades variadas
de espaço em branco.

Por exemplo, vamos considerar o seguinte problema: listar todos os arquivos da pasta atual que ocupam mais de 1kib, ordenados por tamanho.
Em shells tradicionais, a maneira natural de se resolver este problema é com o uso de diversos programas,
um para cada operação a ser realizada (i.e listar arquivos, filtrar, ordenar).
Primeiro, pode ser utilizado o comando `ls -l` para listar os arquivos diponíveis do sistema em um texto no formato de tabela.

```
total 7648
-rw-r--r-- 1 ron ron 6152457 Jan 24 16:03 '2025-01-24 16-03-20.mkv'
-rw-r--r-- 1 ron ron  587203 Jan 24 16:22  bam.png
-rw-r--r-- 1 ron ron  421037 Jan 24 16:49  last.png
-rw-r--r-- 1 ron ron       8 Mar  8 14:33  quick_notes.txt
-rw-r--r-- 1 ron ron  475167 Jan 24 16:45  slash.png
-rw-r--r-- 1 ron ron      14 Mar  3 23:37  status.txt
-rw-r--r-- 1 ron ron     245 Jan 14 12:53  todo
-rw-r--r-- 1 ron ron  168611 Feb 16 00:15  weird_circuit.png
```
> Figura 1: Exemplo de saída do comando `ls -l`.

Na saída do `ls -l`, como a coluna que representa o tamanho dos arquivos _aparenta_ ser a quinta
(este detalha não é comumente documentado no manual do comando), é possível
utilizar o programa `sort` para ordenar os elementos por esta coluna, como o comando `sort -k5 -n`.
Aqui, a _flag_ `-k5` indica que queremos ordenar as linhas pelo conteúdo da quinta coluna separada por espaço,
e a _flag_ `-n` indica que o comando `sort` deve interpretar os valores desta coluna como números para a ordenação.
Este comando ordena as colunas alfabeticamente por padrão, então "18" seria julgado menor que "8" sem esta última flag,
já que 1 é menor que 8.

Para selecionar as linhas onde o valor numérico da quinta coluna separada por espaço é maior que 1024,
podemos utilizar o interpretador da linguagem programação `awk`. Esta é uma linguagem de programação
focada em manipulação textual comumente utilizada para este tipo de tarefa.
Podemos realizar este filtro específico com comando `awk '$5 > 1024'`.

Conectando todos estes comandos com o operador de composição de comandos de shells, o símbolo _pipe_ `|`, obtemos a seguinte _pipeline_:

```bash
ls -l  | sort -k5 -n | awk '$5 > 1024'
```

```
-rw-r--r-- 1 ron ron  168611 Feb 16 00:15 weird_circuit.png
-rw-r--r-- 1 ron ron  421037 Jan 24 16:49 last.png
-rw-r--r-- 1 ron ron  475167 Jan 24 16:45 slash.png
-rw-r--r-- 1 ron ron  587203 Jan 24 16:22 bam.png
-rw-r--r-- 1 ron ron 6152457 Jan 24 16:03 2025-01-24 16-03-20.mkv
```
> Figura 2: Exemplo de saída da pipeline `ls -l  | sort -k5 -n | awk '$5 > 1024'`

Alternativamente, poderia ter sido utilizada a _flag_ `-S` do comando `ls`, para que a ordenação dos arquivos por tamanho seja
feita no própio `ls`, ao invés do uso do comando `sort`.

Como pode ser visto, a solução deste simples problema em POSIX envolve
- Chutes educados, para inferir que a quinta coluna do `ls -l` representa o tamanho dos arquivos
- Interpretadores de linguagens de programação de manipulação de texto como `awk`
- Tratamento de conversão numérica-textual no `sort`

## Dados estruturados em nushell

Em nushell, os comandos implementados pelo shell não recebem ou devolvem exclusivamente texto, mas sim valores de diversos outros tipos, como
inteiros, tabelas, booleanas, datas. Apesar destes valores não serem textos em sua natureza, todos estes possuem alguma forma de representação
gráfica que pode ser mostrada aos usuários na saída dos comandos.

Esta diferença pode ser observada até no mais básico dos comandos. Por exemplo, na Figura 3, podemos ver a representação gráfica da
saída do comando `ls`, que devolve um valor de tipo tabela contendo as informações dos arquivos da pasta atual,
com colunas propriamente nomeadas.

```
┏━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ # ┃          name           ┃ type ┃   size   ┃   modified   ┃
┣━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━╋━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ 0 ┃ 2025-01-24 16-03-20.mkv ┃ file ┃   6.1 MB ┃ a month ago  ┃
┃ 1 ┃ bam.png                 ┃ file ┃ 587.2 kB ┃ a month ago  ┃
┃ 2 ┃ last.png                ┃ file ┃ 421.0 kB ┃ a month ago  ┃
┃ 3 ┃ quick_notes.txt         ┃ file ┃      8 B ┃ 3 hours ago  ┃
┃ 4 ┃ slash.png               ┃ file ┃ 475.1 kB ┃ a month ago  ┃
┃ 5 ┃ status.txt              ┃ file ┃     14 B ┃ 4 days ago   ┃
┃ 6 ┃ todo                    ┃ file ┃    245 B ┃ 2 months ago ┃
┃ 7 ┃ weird_circuit.png       ┃ file ┃ 168.6 kB ┃ 2 weeks ago  ┃
┗━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━┻━━━━━━━━━━┻━━━━━━━━━━━━━━┛
```

> Figura 3: Representação gráfica da tabela devolvida pelo comando `ls`. As colunas `name` e `type` guardam valores de tipo `string`,
enquanto as colunas `size` e `modified` guardam valores do tipo `filesize` e `date` respectivamente.

Essa diferença estrutural se manifesta mais explicitamente com o uso de operações para manipular tais tabelas.
Em Nushell, o problema mencionado anteriormente (listar os arquivos da pasta atual acima de 1kb ordenados por tamanho)
pode ser resolvido com a seguinte _pipeline_:

```
ls | where size > 1kb | sort-by size
```

Nessa pipeline, o comando `where` recebe uma tabela, e remove as linhas que não satisfazem a condição especificada, e o
comando `sort-by` ordena as linhas da tabela em ordem crescente pela coluna `size`, obtendo uma outra tabela como na Figura 4.
Como a coluna `size` é do tipo `filesize`, e o comando `sort-by` ordena os valores da coluna respeitando seus tipos, não há
problemas em relação a comparação dos tamanhos arquivos como strings.

```
┏━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━━━━┓
┃ # ┃          name           ┃ type ┃   size   ┃  modified   ┃
┣━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━╋━━━━━━━━━━╋━━━━━━━━━━━━━┫
┃ 0 ┃ weird_circuit.png       ┃ file ┃ 168.6 kB ┃ 2 weeks ago ┃
┃ 1 ┃ last.png                ┃ file ┃ 421.0 kB ┃ a month ago ┃
┃ 2 ┃ slash.png               ┃ file ┃ 475.1 kB ┃ a month ago ┃
┃ 3 ┃ bam.png                 ┃ file ┃ 587.2 kB ┃ a month ago ┃
┃ 4 ┃ 2025-01-24 16-03-20.mkv ┃ file ┃   6.1 MB ┃ a month ago ┃
┗━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━┻━━━━━━━━━━┻━━━━━━━━━━━━━┛
```
> Figura 4: Saída da _pipeline_ `ls | where size > 1kb | sort-by size`.

A solução em nushell é argumentavelmente mais simples e legível que a solução POSIX. Este modelo permite que operações complexas
possam ser expressas sem a necessidade de interpretadores complexos adicionais como `awk`. Adicionalmente, como não
acontecem manipulações de colunas textuais separadas por espaço, arquivos contedo espaços nos nomes não introduzem problemas adicionais.

Em particular, este modelo de resolução de problemas baseado em composições de transformações, se adequa bem ao paradigma de programação
funcional, tornando nushell uma linguagem apropriada para uma introdução sutil a este paradigma.

## Números do projeto

Analisando o repositório às 22:00 do dia 8 de março de 2025 no commit git 4fe7865ad, podemos observar que este tem um total
de 296 mil linhas de código Rust (somando o total de linhas de todos os arquivos `.rs` no projeto), mais de 34 mil estrelas no github,
e mais de 10 000 commits no repositório principal. O projeto está disponível em diversos repositórios de software.

[![Packaging status](https://repology.org/badge/vertical-allrepos/nushell.svg?columns=3)](https://repology.org/project/nushell/versions)

## Opiniões

No chat do servidor oficial do Discord do nushell, podem ser encontrados vários
depoimentos de usuários sobre aspectos positivos e negativos do projeto, incluindo o seguinte depoimento anônimo, incluido com permissão do autor:

> I've been a pretty avid Nushell user for the past year, and I have to say it's been nothing but pleasant. There's some inefficiencies here and there, sure, but the language design is really nice.

> I'm a programmer by trade, but in my current position I wander around a lot. Some of my tasks are for R&D purposes, some for application maintenance, other times I'm focused on data analysis and data governance. Especially for the latter, I've found data transformation and insights are such a breeze compared to other languages. It's much more natural to write. I tend to do my transformations in Nushell, and then persist them to file so I can visualize them in other tooling (like Python's suite of graphics libs, since it's just so vast and settled)

> One of the big things I've noticed help keep things manageable is that the command names and keywords are pretty much all in natural language. Abbreviations are an exception, which means it's quite easy to read and understand. To illustrate, I was able to teach some people who don't have any programming experience how to get started, and they told me after the fact it was the "programming intuition" they were missing. As in, they had a hard time visualizing what needed to happen in other to solve the problem, but they barely felt Nushell was another obstacle to overcome, since it's all relatively self-documenting.
