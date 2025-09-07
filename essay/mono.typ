
#set quote(block: true)

#set align(center)

#grid(
  columns: 1fr,
  rows: (1fr, 1fr, 1fr, 1fr, auto),
  [
    #align(center, text(14pt)[
      UNIVERSIDADE DE SÃO PAULO

      INSTITUTO DE MATEMÁTICA E ESTATÍSTICA

      BACHARELADO EM CIÊNCIA DA COMPUTAÇÃO
    ])
  ]
  ,
  [
    #text(17pt)[ *Implementando tarefas em segundo plano em um shell moderno* ]

    #text(14pt)[ Renan Ribeiro Marcelino ]
  ]
  ,
  [
    #text(17pt)[ MONOGRAFIA FINAL ]

    #text(17pt)[ MAC0499 - TRABALHO DE FORMATURA SUPERVISIONADO ]
  ],
  [
    #text(17pt)[ Supervisor: Alfredo Goldman ]

    #text(17pt)[ Co-supervisor: Nelson Lago ]
  ],
  [
    #text(14pt)[ 
      São Paulo

      2025
    ]
  ]
)

#pagebreak()
#pagebreak()

#let my_summary_page(title: [], reference: [], description: [], keywords: []) = [

  #set align(center)

  #text(17pt)[ #title ]

  #set align(start + top)

  // TODO: find how to increase margin of this section 

  #reference

  #set par(
    justify: true
  )

  #description

  #keywords
]

#my_summary_page(
  title: [ *Resumo* ],
  reference: [
    
Renan Ribeiro Marcelino. *Implementando tarefas de segundo plano em um shell moderno*. Monografia (Bacharelado).
Instituto de Matemática e Estatística, Universidade de São Paulo, São Paulo, 2025.
  ],
  description: [

Nushell é um shell moderno de código fonte aberto desenvolvido com o objetivo de providenciar uma experiência multiplataforma amigável.
Este shell adota o uso de dados estruturados em seus comandos, permitindo que dados possam ser manipulados
de acordo com seus tipos apropriados, sem a necessidade de conversões de texto para a composição de operações, como ocorre em shells
POSIX como `bash`, `zsh` e `fish`.

Desde sua criação em 2019, o projeto possui solicitações para o suporte à tarefas em segundo plano e suspensão de processos, recursos
comuns em shells POSIX.
Este projeto de de trabalho de conclusão de curso consiste na implementação e documentação de uma infraestrutura de tarefas de segundo plano no projeto nushell.
Além de tarefas em segundo plano por meio de multithreading e suspensão de processos, também foi implementado um sistema de comunicação entre threads
insiprado no modelo implementado pela linguagem de programação Erlang.
    
  ],
  keywords: [
  *Palavras chave*: Shell, Tarefas em Segundo plano.
  ]
)



#pagebreak()

#pagebreak()


#my_summary_page(
  title: [ *Abstract* ],
  reference: [
    
Renan Ribeiro Marcelino. *Implementing background jobs in a modern shell*. Capstone Project Report (Bachelor).
 Institute of Mathematics and Statistics, University of São Paulo, São Paulo, 2025.
],
  description: [

Nushell is a modern open source shell aimed to provide a friendly multiplatform experience.
This shell employs structured in its commands, allowing data to be manipulated 
with appropriate data types, without the need for textual conversion in order to compose operations, like it occurs with
in POSIX shells such as `bash`, `zsh` and `fish`.

Ever since its inception in 2019, the project has been requested to implement background tasks and process suspension, features commonly found in POSIX shells.

This project consists in the implementation, documentation and integration of a background job infrastructure in nushell
On top of multithreading, background jobs and process suspension, Erlang-style message passing was also implemented.
  ],
  keywords: [
  *Keywords*: Shell, Background jobs.
  ]
)

#pagebreak()

#set align(start + top)

#set par(
  justify: true
)

Sumário

...

#pagebreak()

  Capitulo 1
= Introdução

== Contextualização

=== Shells Tradicionais

O terminal de texto é uma interface de interação entre humanos e computadores frequentemente
utilizada por usuários técnicos nos dias modernos em computadores desktop e servidores remotos.
No contexto dos terminais de texto, a interação do usuário com o sistema operacional é feita
por meio de um programa denomidado shell, no qual o usuário digita um comando a ser realizado
e recebe como feedback texto descrevendo o resultado do comando concluído.

Os shell mais tradicionais usados por usuários técnicos de sistemas derivados de unix (i.e Linux e MacOS), são denominados de shell
POSIX, e o maior representante desta categoria é o shell GNU bash. Nestes shells,
um recurso ubíquo é a capacidade de concatenar a saída textual de um comando,
 na entrada textual de outro comando, permitindo variadas manipulações textuais.


// TODO: use proper hyphen here, instead of dash
Neste tipo de shell, não existe estrutura geral fixa para as entradas e saídas dos comandos - cada um
com suas própias convenções sobre o formato textual dos dados - é comum se referir a este como um modelo de dados não estruturados.

Em particular, é comum o uso de textos representando tabelas neste modelo, onde as linhas das tabelas são separadas
pelos caracteres de quebra de linha textuais (também conhecido por "\\n"), e as colunas das tabelas são separadas por quantidades variadas
de espaço em branco.

Como exemplo deste recurso, considere o seguinte problema: listar todos os arquivos da pasta atual que ocupam mais de 1kib, ordenados por tamanho.
Em shells, a maneira natural de se resolver este problema é com o uso de diversos comandos,
um para cada operação a ser realizada (i.e listar arquivos, filtrar, ordenar).
Primeiro, pode ser utilizado o comando `ls -l` para listar os arquivos diponíveis do sistema em um texto no formato de tabela.

// TODO: use figure here

#set align(center)
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
Figura 1: Exemplo de saída do comando `ls -l`.

#set align(start + top)


Na saída do `ls -l`, como a coluna que representa o tamanho dos arquivos _aparenta_ ser a quinta
(este detalhe não é comumente documentado no manual do comando, e precisa ser inferido pelo usuário). É possível
utilizar o programa `sort` para ordenar os elementos por esta coluna, com o comando `sort -k5 -n`.
Aqui, a _flag_ `-k5` indica que queremos ordenar as linhas pelo conteúdo da quinta coluna separada por espaço,
e a _flag_ `-n` indica que o comando `sort` deve interpretar os valores desta coluna como números para a ordenação.
Este comando ordena as colunas alfabeticamente por padrão (ou seja, caracter por caracter), então sem a _flag_ `-n`, o valor  "18" seria julgado menor que "8",
já que 1 é menor que 8.

Para selecionar as linhas onde o valor numérico da quinta coluna separada por espaço é maior que 1024 (um kilobyte),
podemos utilizar o interpretador da linguagem programação `awk`. Esta é uma linguagem de programação
focada em manipulação textual comumente utilizada para este tipo de tarefa.
Podemos realizar este filtro específico com o comando `awk '$5 > 1024'`.

Conectando todos estes comandos com o operador de composição de comandos de shells, o símbolo _pipe_ '`|`', obtemos a seguinte _pipeline_:

#set align(center)
```bash
ls -l  | sort -k5 -n | awk '$5 > 1024'
```
#set align(start + top)



// TODO: use figure here
#set align(center)
```
-rw-r--r-- 1 ron ron  168611 Feb 16 00:15 weird_circuit.png
-rw-r--r-- 1 ron ron  421037 Jan 24 16:49 last.png
-rw-r--r-- 1 ron ron  475167 Jan 24 16:45 slash.png
-rw-r--r-- 1 ron ron  587203 Jan 24 16:22 bam.png
-rw-r--r-- 1 ron ron 6152457 Jan 24 16:03 2025-01-24 16-03-20.mkv
```
Figura 2: Exemplo de saída da pipeline `ls -l  | sort -k5 -n | awk '$5 > 1024'`
#set align(start + top)


Alternativamente, poderia ter sido utilizada a _flag_ `-S` do comando `ls`,
 para que a ordenação dos arquivos por tamanho seja feita no própio `ls`,
 ao invés do uso do comando `sort`.

Como pode ser visto, a solução deste simples problema em POSIX envolve
- Chutes educados, para inferir que a quinta coluna do `ls -l` representa o tamanho dos arquivos
- Interpretadores de linguagens de programação de manipulação de texto como `awk`
- Tratamento de conversão numérica-textual no `sort`

=== Nushell

Nushell é um shell moderno desenvolvido com o objetivo de providenciar uma experiência
multiplataforma e amigável.
Este shell adota o uso de dados estruturados em seus comandos, permitindo que informações possam
ser manipuladas de acordo com seus tipos apropriados, sem a necessidade de conversões de texto
para a composição de operações, como ocorre em shells POSIX.

Em nushell, os comandos implementados pelo shell não recebem ou devolvem exclusivamente texto, mas sim valores de diversos outros tipos de dados, como
inteiros, tabelas, booleanas e datas. Apesar destes valores não serem textos em sua natureza, todos estes possuem alguma forma de representação
gráfica que pode ser mostrada aos usuários na saída dos comandos.

Esta diferença fundamental pode ser observada até no mais básico dos comandos. Por exemplo, na Figura 3, podemos ver a representação gráfica da
saída do comando `ls`, que devolve um valor de tipo tabela contendo as informações dos arquivos da pasta atual,
com colunas propriamente nomeadas.

// TODO use figure
#set align(center)

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

Figura 3: Representação gráfica da tabela devolvida pelo comando `ls`. As colunas `name` e `type` guardam valores de tipo `string`,
enquanto as colunas `size` e `modified` guardam valores do tipo `filesize` e `date` respectivamente.

#set align(start + top)

Essa diferença estrutural se manifesta mais explicitamente com o uso de operações para manipular tais tabelas.
Em nushell, o problema mencionado anteriormente (listar os arquivos da pasta atual acima de 1kb ordenados por tamanho)
pode ser resolvido com a seguinte _pipeline_:

#set align(center)

```bash
ls | where size > 1kb | sort-by size
```

#set align(start + top)

Nessa pipeline, o comando `where` recebe uma tabela, e remove as linhas que não satisfazem a condição especificada, e o
comando `sort-by` ordena as linhas da tabela em ordem crescente pela coluna `size`, obtendo uma outra tabela como na Figura 4.
Como a coluna `size` é do tipo `filesize`, e o comando `sort-by` ordena os valores da coluna respeitando seus tipos, não há
problemas em relação a comparação dos tamanhos arquivos como strings.

#set align(center)
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
Figura 4: Saída da _pipeline_ `ls | where size > 1kb | sort-by size`.
#set align(start + top)

A solução em nushell é argumentavelmente mais simples e legível que a solução POSIX. Este modelo permite que operações complexas
possam ser expressas sem a necessidade de interpretadores complexos adicionais como `awk`. Adicionalmente, como não
acontecem manipulações de colunas textuais separadas por espaço, arquivos contedo espaços nos nomes não introduzem problemas adicionais.

Em particular, este modelo de resolução de problemas baseado em composições de transformações, se adequa bem ao paradigma de programação
funcional, tornando nushell uma linguagem apropriada para uma introdução sutil a este paradigma.

No chat do servidor oficial do Discord do nushell, podem ser encontrados vários
depoimentos de usuários sobre aspectos positivos e negativos do projeto, incluindo o seguinte depoimento anônimo, incluido com permissão do autor:

#quote(attribution: [Annonymous])[
  
I've been a pretty avid Nushell user for the past year, and I have to say it's been nothing but pleasant. There's some inefficiencies here and there, sure, but the language design is really nice.

I'm a programmer by trade, but in my current position I wander around a lot. Some of my tasks are for R&D purposes, some for application maintenance, other times I'm focused on data analysis and data governance. Especially for the latter, I've found data transformation and insights are such a breeze compared to other languages. It's much more natural to write. I tend to do my transformations in Nushell, and then persist them to file so I can visualize them in other tooling (like Python's suite of graphics libs, since it's just so vast and settled)

One of the big things I've noticed help keep things manageable is that the command names and keywords are pretty much all in natural language. Abbreviations are an exception, which means it's quite easy to read and understand. To illustrate, I was able to teach some people who don't have any programming experience how to get started, and they told me after the fact it was the "programming intuition" they were missing. As in, they had a hard time visualizing what needed to happen in other to solve the problem, but they barely felt Nushell was another obstacle to overcome, since it's all relatively self-documenting.
]

=== Ausência de tarefas de segundo plano no nushell

Por padrão, quando um usuário inicia um comando em um shell, o agente fica incapaz de
interagir com a interface até que o comando termine sua execução.
Existem situações, em que este comportamento pode não ser conveniente para o usuário
(por exemplo: tarefas de longa duração), e por conta disto, shells POSIX tipicamente
providenciam a capacidade de executar comandos em segundo plano, permitindo que o usuário,
continue a usar o shell enquanto o programa continua executando.

Adicionalmente, shells POSIX também tipicamente possuem a capacidade de suspender a execução
de um programa ativo, quando o terminal de texto emite um sinal de
suspensão (isto é tipicamente realizado quando o usuário do terminal aperta a sequência `Ctrl-Z`).
Um programa suspenso pode posteriormente ser resumido por um comando providenciado pelo shell (tipicamente chamado `fg`).

Antes do início deste trabalho acadêmico, nushell não possuia suporte a suspensão de processos por `Ctrl-Z`,
ou a tarefas de segundo plano. No repostiório Github do projeto, a `issue`  relacionada a estes
recursos é uma das mais antigas, e uma das mais apoiadas pelos usuários. Esta
foi criada no mesmo ano de surgimento do projeto, em 2019, e é a quinta solicitação com mais reações
positivas "Thumbs Up" do projeto, que possui mais de 6 mil issues.

Nos comentários dessa issue, é possível ver o descontento de múltiplos usuários com a ausência destes recursos
neste shell:


#quote(attribution: [tmillr])[
I _*need*_ this as well. I just need the ability to at least suspend one TUI application then come back to it later. [...]
]

#quote(attribution: [gabevenberg])[
  Honestly, my main want is background tasks and disown, for launching GUI applications without tying up the terminal.
]

#quote(attribution: [gabevenberg])[
And this is a feature in every single other shell I know of, so it's definitely something people need out of their shell.
]

#quote(attribution: [artem-nefedov])[
This (and, to lesser extent, the lack of `trap` functionality) is the main reason why I haven't switched to nushell yet, and this is likely true for other people.
[...]
]

Visando a demanda por estes recursos no projeto, e a relevância deste shell,
este trabalho acadêmico consiste na implementação e integração destes dois recursos
 no projeto nushell.

= Capitulo 2
= Desenvolvimento





