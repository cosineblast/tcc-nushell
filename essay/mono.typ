
#let fixme(thing) = thing
#let towork(thing) = thing

#import "stuff.typ": template

#show: template

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

    #text(17pt)[ MAC0499 -- TRABALHO DE FORMATURA SUPERVISIONADO ]
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

#set align(start + top)
#set par(justify: true)

#pagebreak()
#pagebreak()


#let my_summary_page(title: [], reference: [], description: [], keywords: []) = [

  #align(center)[
  #text(17pt)[ #title ]
  ]

  #block(inset: (left: 1.5cm, right: 1.5cm))[
  #reference
  ]

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
insiprado no modelo implementado pela linguagem de programação Erlang. Ao todo, foram
adicionados dez comandos novos para o shell, além de melhorias no comportamento do projeto
em Linux e MacOS.
    
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
//TODO: Update this description to match the portuguese one.
  ],
  keywords: [
  *Keywords*: Shell, Background jobs.
  ]
)

#pagebreak()

= Sumário

O sumário deste trabalho ainda está em desenvolvimento, o texto a seguir descreve
em termos gerais a estrutura desta monografia.

*- Capitulo 1: Introdução*
1. O que é o nushell
Uma breve descrição do projeto e do impacto dele (número de usuários, estrelas, etc),

2. Ausência de background jobs no projeto
Um relatório da falta de jobs no projeto e como isso afeta os usuários

*- Capitulo 2: Overview do trabalho*
1. O que foi implementado, e como isso se compara com shells tradicionais
11. Spawn de jobs
12. Listaegm de jobs
13. Remoção de jobs

2. Inter-Job-Communication

*- Capitulo 3: Detalhes de implementação*
1. Escolha de threads vs processos
2. Clonagem do estado de threads, estado compartilhado por mutex
3. Algoritmo de remoção de jobs
4. Process groups e pipelines
5. Comunicação entre jobs, estrutura de dados utilizada

*- Capítulo 4: Impacto*
1. Agradecimentos no Discord
2. Ocorrências de comandos de job em scripts pela busca no github


#pagebreak()

= Capitulo 1 \ Introdução

O terminal de texto é uma interface de interação entre
humanos e computadores frequentemente utilizada por usuários
técnicos em computadores desktop e servidores remotos.
No contexto dos terminais de texto, a interação do usuário
com o sistema operacional é feita por meio de um
programa denominado shell. O usuário pode interagir de
forma interativa, digitando um comando a ser realizado
e recebendo como feedback texto descrevendo o resultado
do comando concluído. Além disso, os shells
são fundamentais para a execução de scripts,
que são arquivos contendo sequências de comandos
que podem ser executados de forma não interativa
para automatizar tarefas.

Os shells mais tradicionais usados por usuários técnicos
de sistemas derivados de Unix (como Linux e macOS) são
denominados shells POSIX, sendo o maior representante desta
categoria o shell GNU Bash. Nestes shells, um recurso
ubíquo é a capacidade de concatenar a saída textual de
um comando na entrada textual de outro comando.
Este mecanismo é conhecido como _pipeline_ e permite
variadas manipulações textuais complexas e a construção
de fluxos de trabalho avançados.

Neste tipo de shell, não existe estrutura geral fixa para as entradas e saídas dos comandos, cada um
com suas própias convenções sobre o formato textual dos dados, logo é comum se referir a este como um modelo de dados não estruturados.

Em particular, é comum o uso de textos representando tabelas neste modelo, onde as linhas das tabelas são separadas
pelos caracteres de quebra de linha textuais (também conhecido por "\\n"), e as colunas das tabelas são separadas por quantidades variadas
de espaço em branco.

Como exemplo deste recurso, considere o seguinte problema: listar todos os arquivos da pasta atual que ocupam mais de 1kib, ordenados por tamanho.
Em shells, a maneira natural de se resolver este problema é com o uso de diversos comandos,
um para cada operação a ser realizada (i.e listar arquivos, filtrar, ordenar).
Primeiro, pode ser utilizado o comando `ls -l` para listar os arquivos diponíveis do sistema em um texto no formato de tabela.


#figure([
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
],
  caption: [ Exemplo de saída do comando `ls -l`. ]
) <ls_dash_l>



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

#align(center)[
```bash
ls -l  | sort -k5 -n | awk '$5 > 1024'
```
]

#figure([
```
-rw-r--r-- 1 ron ron  168611 Feb 16 00:15 weird_circuit.png
-rw-r--r-- 1 ron ron  421037 Jan 24 16:49 last.png
-rw-r--r-- 1 ron ron  475167 Jan 24 16:45 slash.png
-rw-r--r-- 1 ron ron  587203 Jan 24 16:22 bam.png
-rw-r--r-- 1 ron ron 6152457 Jan 24 16:03 2025-01-24 16-03-20.mkv
```
],
caption: [ Exemplo de saída da pipeline `ls -l  | sort -k5 -n | awk '$5 > 1024'` ]
) <posix_pipeline>


Alternativamente, poderia ter sido utilizada a _flag_ `-S` do comando `ls`,
 para que a ordenação dos arquivos por tamanho seja feita no própio `ls`,
 ao invés do uso do comando `sort`.

Como pode ser visto, a solução deste simples problema em POSIX envolve
- Chutes educados, para inferir que a quinta coluna do `ls -l` representa o tamanho dos arquivos
- Interpretadores de linguagens de programação de manipulação de texto como `awk`
- Tratamento de conversão numérica-textual no `sort`

== Contextualizando Nushell

Nushell é um shell moderno desenvolvido com o objetivo de providenciar uma experiência
multiplataforma e amigável.
Este shell adota o uso de dados estruturados em seus comandos, permitindo que informações possam
ser manipuladas de acordo com seus tipos apropriados, sem a necessidade de conversões de texto
para a composição de operações, como ocorre em shells POSIX.

Em nushell, os comandos implementados pelo shell não recebem ou devolvem exclusivamente texto, mas sim valores de diversos outros tipos de dados, como
inteiros, tabelas, booleanas e datas. Apesar destes valores não serem textos em sua natureza, todos estes possuem alguma forma de representação
gráfica que pode ser mostrada aos usuários na saída dos comandos.

Esta diferença fundamental pode ser observada até no mais básico dos comandos. Por exemplo, na @nushell_ls, podemos ver a representação gráfica da
saída do comando `ls`, que devolve um valor de tipo tabela contendo as informações dos arquivos da pasta atual,
com colunas propriamente nomeadas.

#figure([

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
],

caption: [ Representação gráfica da tabela devolvida pelo comando `ls`. As colunas `name` e `type` guardam valores de tipo `string`,
enquanto as colunas `size` e `modified` guardam valores do tipo `filesize` e `date` respectivamente. ]
) <nushell_ls>



Essa diferença estrutural se manifesta mais explicitamente com o uso de operações para manipular tais tabelas.
Em nushell, o problema mencionado anteriormente (listar os arquivos da pasta atual acima de 1kb ordenados por tamanho)
pode ser resolvido com a seguinte _pipeline_:

#align(center)[
  ```bash
ls | where size > 1kb | sort-by size
```
]

Nessa pipeline, o comando `where` recebe uma tabela, e remove as linhas que não satisfazem a condição especificada, e o
comando `sort-by` ordena as linhas da tabela em ordem crescente pela coluna `size`, obtendo uma outra tabela como na @nushell_pipeline.
Como a coluna `size` é do tipo `filesize`, e o comando `sort-by` ordena os valores da coluna respeitando seus tipos, não há
problemas em relação a comparação dos tamanhos arquivos como strings.

#figure([
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
],
caption: [ Saída da _pipeline_ `ls | where size > 1kb | sort-by size`. ]
) <nushell_pipeline>

A solução em nushell é argumentavelmente mais simples e legível que a solução POSIX. Este modelo permite que operações complexas
possam ser expressas sem a necessidade de interpretadores complexos adicionais como `awk`. Adicionalmente, como não
acontecem manipulações de colunas textuais separadas por espaço, arquivos contedo espaços nos nomes não introduzem problemas adicionais.

Em particular, este modelo de resolução de problemas baseado em composições de transformações, se adequa bem ao paradigma de programação
funcional, tornando nushell uma linguagem apropriada para uma introdução sutil a este paradigma.

O projeto é amplamente utilizado, contando com 37 mil estrelas no Github, e milhares de repositórios
contendo arquivos de configuração na linguagem nushell.

// TODO: incluir footnote para a busca de arquivos
//  path:/(\/config.nu$|^config.nu$)/
// https://github.com/search?q=path%3A%2F%28%5C%2Fconfig.nu%24%7C%5Econfig.nu%24%29%2F&type=code

No chat do servidor oficial do Discord do nushell, podem ser encontrados vários
depoimentos de usuários sobre aspectos positivos e negativos do projeto, incluindo o seguinte depoimento anônimo, incluido com permissão do autor:

#quote(attribution: [Annonymous])[
  
I've been a pretty avid Nushell user for the past year, and I have to say it's been nothing but pleasant. There's some inefficiencies here and there, sure, but the language design is really nice.

I'm a programmer by trade, but in my current position I wander around a lot. Some of my tasks are for R&D purposes, some for application maintenance, other times I'm focused on data analysis and data governance. Especially for the latter, I've found data transformation and insights are such a breeze compared to other languages. It's much more natural to write. I tend to do my transformations in Nushell, and then persist them to file so I can visualize them in other tooling (like Python's suite of graphics libs, since it's just so vast and settled)

One of the big things I've noticed help keep things manageable is that the command names and keywords are pretty much all in natural language. Abbreviations are an exception, which means it's quite easy to read and understand. To illustrate, I was able to teach some people who don't have any programming experience how to get started, and they told me after the fact it was the "programming intuition" they were missing. As in, they had a hard time visualizing what needed to happen in other to solve the problem, but they barely felt Nushell was another obstacle to overcome, since it's all relatively self-documenting.
]

== Motivação

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
foi criada no mesmo ano de surgimento do projeto, em 2019, e dentre as mais de 6 mil issues do projeto,
esta é a quinta solicitação com mais reações
positivas "Thumbs Up".

Nos comentários dessa issue, é possível ver o descontento de múltiplos usuários com a ausência destes recursos
no nushell:


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


#pagebreak()

= Capitulo 2 \ Visão Geral

Durante o ano de 2025, múltiplas Pull Requests foram propostas no desenvolvimento deste trabalho.
Já aceitas no projeto, estas contribuições integram no shell os recursos solicitados pelos usuários, além de outros adicionais. 
Neste capítulo será descrito o que foi desenvolvido neste trabalho e acrescentado
ao projeto nushell, do ponto de vista do usuário, enquanto os detalhes de implementação são
tratados no Capítulo 3.
// TODO: add footnote about pull request definition

== Criação de Tarefas em Segundo Plano

Quando um comando é executado em um shell POSIX, um processo novo é iniciado para a
execução do programa, e o shell espera até que este termine antes de continuar
executando outros comandos.
Desta forma, o usuário fica impossibilitado de utilizar o shell, até que o programa iniciado termine sua execução.
// TODO: rephrase this ^
Isso também garante que, em scripts, os comandos sejam executados um por vez.

Existem cenários em que é adequada a execução de um processo, ao mesmo tempo em que
o shell continua livre para iniciar outros comandos. Em shells POSIX, isto é possível
por meio do operador especial `&`, que quando adicionado ao final de um comando,
instrue o shell a executar o programa como um processo em segundo plano, e não
esperar este terminar para continuar executando outros comandos.

Na @tar_vim_bash, é exibido um exemplo de código bash que inicia um processo
em segundo plano para realizar uma operação demorada, comprimir e arquivar
uma pasta grande "`Downloads`" em um arquivo "`downloads.tar.gz`", e iniciar um outro processo,
 o editor de texto `vim`,
enquanto a compressão ocorre em segundo plano.

#figure([
 ```bash
tar --create --gzip --file downloads.tar.gz Downloads &
vim todo.txt
```
],
caption: [ Exemplo de código em bash para iniciar uma compressão em segundo plano, enquanto o usuário usa o editor de terminal vim ]
) <tar_vim_bash>

Esta capabilidade foi adicionada ao shell nushell neste trabalho, por meio
da adição do comando `job spawn`. Este comando recebe uma closure -- um bloco de código executável como uma
função -- e executa ela em segundo plano.

#figure([
  ```bash
job spawn { tar --create --gzip --file downloads.tar.gz Downloads }
vim todo.txt
```
]) <tar_vim_nu>

== Listagem de Tarefas

Em shells POSIX, é comum que a criação de tarefas em segundo plano mostre
ao usuário um número indicando um ID numérico dedicado para a tarefa. Ao se utilizar
o comando especial `jobs`, é possível listar as tarefas atualmente ativas e seus IDs.
De maneira similar, o comando `job spawn` implementado retorna um inteiro representando
o ID do job adicionado.

Para listar as tarefas de segundo plano em execução no nushell, foi providenciado
o comando `job list`. No exemplo da @spawn_then_list, duas tarefas de segundo plano são iniciadas,
a primeira comprimindo a pasta "Downloads" no arquivo "downloads.tar.gz" diretamente, e a segunda tarefa
converte um arquivo "logs.txt.gz" (comprimido
utilizando o formato _gzip_) para um arquivo "logs.txt.xz" (utilizando o formato de compressão _xz_, que costuma
ser mais compacto).

#figure([
```bash
job spawn { tar --create --gzip --file downloads.tar.gz Downloads }
# 5
job spawn { gunzip --stdout logs.txt.gz | xz | save logs.txt.xz }
# 6
job list
#               ┏━━━┳━━━━┳━━━━━━━━┳━━━━━━━━━━━━━━━┓
#               ┃ # ┃ id ┃  type  ┃     pids      ┃
#               ┣━━━╋━━━━╋━━━━━━━━╋━━━━━━━━━━━━━━━┫
#               ┃ 0 ┃  5 ┃ thread ┃ ┏━━━┳━━━━━━━┓ ┃
#               ┃   ┃    ┃        ┃ ┃ 0 ┃ 94796 ┃ ┃
#               ┃   ┃    ┃        ┃ ┗━━━┻━━━━━━━┛ ┃
#               ┃ 1 ┃  6 ┃ thread ┃ ┏━━━┳━━━━━━━┓ ┃
#               ┃   ┃    ┃        ┃ ┃ 0 ┃ 94797 ┃ ┃
#               ┃   ┃    ┃        ┃ ┃ 1 ┃ 94795 ┃ ┃
#               ┃   ┃    ┃        ┃ ┗━━━┻━━━━━━━┛ ┃
#               ┗━━━┻━━━━┻━━━━━━━━┻━━━━━━━━━━━━━━━┛
```
],
caption: [
  Exemplo de execução do comando `job list`. Nesta listagem, as saídas dos comandos é indicada por "`#`" no começo das linhas.
]
) <spawn_then_list>

Em particular, como a implementação desenvolvida recebe uma closure
para executar tarefas em segundo plano, e closures podem executar múltiplos processos simultaneamente
por meio pipelines, a listagem de jobs do nushell mostra uma lista de todos
os processos atualmente em execução por cada tarefa. Na @spawn_then_list, isto pode ser visto
no job de ID 6, que simultâaneamente executa os comandos `gunzip` e `xz`, e em sua listagem, aparecem
os dois PIDs.
// TODO: Add PID to glossary.

Adicionalmente, também foi providenciado o comando `job id`, que devolve o ID do job
atual, ou 0 caso executado fora de uma tarefa em segundo plano.

== Ctrl-Z em sistemas POSIX

Os sistemas operacionais POSIX possuem o conceito de #link("https://en.wikipedia.org/wiki/Signal_(IPC)")[sinais],
mensagens instantâneas numéricas predeterminadas que podem ser enviadas de um processo para outro.
Um destes sinais, é o sinal `SIGTSTP`, que para/congela a execução de um processo quando recebido.
Uma vez congelado, um processo pode ser ter sua execução resumida ao receber o sinal `SIGCONT`.

Os emuladores de terminais tradicionais de sistemas POSIX possuem o recurso de enviar o sinal `SIGSTP` para o processo
ativo no terminal, caso o usuário do terminal digite a sequência de teclado Ctrl-Z. Levando isso
em consideração, os shells em sistemas POSIX costumam ser capazes de detectar quando o processo
ativo recebe este sinal, registrar um job em nome do processo que foi congelado, e
retomar o controle do terminal para si, permitindo que o usuário possa continuar a
executar comandos enquanto o programa está congelado.

Uma das utilidades deste recurso é permitir que o usuário continue usando o shell atual
mesmo que inicie um comando demorado sem querer. Por exemplo, imagine
que um usuário de shell POSIX gostaria de comprimir uma pasta chamada `Videos` em um arquivo `videos.tar.gz`,
e executa o comando `tar -czf videos.tar.gz Videos`, mas subestima a quantidade de
tempo demorada para comprimir vídeos, e esquece de colocar `&` no final do comando. Em condições normais,
o usuário estaria impossibilitado de utilizar o sistema, até que o arquivamento termine, ou até
o usuário aborte a execução do programa. Utilizando `Ctrl-Z`, o usuário consegue
suspender a execução do comando, e continuar sua execução em segundo plano com o comando `bg`
(abreviação para _background_, plano de fundo).

Um outro caso de uso para este recurso, é um em que o usuário utiliza um
programa de terminal simples como `nano` para editar arquivos de código fonte `.c`,
e gostaria de executar um comando de compilação como `make`, para depois voltar a
utilizar o editor de texto. Sem Ctrl-Z, o usuário precisa fechar o seu editor para
executar o comando de compilação, ou abrir
outras instâncias simultâneas de shell em outros terminais, ou usar multiplexadores de terminais
como `tmux`. Inserindo a combinação Ctrl-Z enquanto o editor está ativo, o processo do editor é congelado,
e o terminal volta seu foco ao shell ativo. Assim, o usuário pode executar os comandos
de compilação que deseja, e retomar a edição do arquivo em primeiro plano como antes, por meio do
comando `fg` (abreviação para _foreground_).


Antes da implementação deste trabalho, o nushell não possuia suporte ao sinal `SIGSTP`,
e este tipo de manipulação de processos não era possível. Agora, o shell responde apropriadamente
ao sinal `SIGTSTP` emitido pela sequência `Ctrl-Z`, e permite que comandos congelados possam ser
continuados em primeiro plano (_foreground_, `fg`) com `job unfreeze`, ou continuados em segundo plano (_background_, `bg`) com `job spawn { job unfreeze }`.

// TODO: incluir fotos de antes/depois em Ctrl-Z
// TODO: incluir fotos de ctrl-z em bash

== Assasinato de Jobs

Em sistemas POSIX, os shells permitem que jobs sejam removidos pelos seus usuários utilizando
o ID do job  utilizando o comando `kill %N` onde `N`
é o ID do job a ser removido. 
O ID do job é mesmo que é exibido quando a tarefa é criada, e pode ser confirmado
listando as tarefas ativas com `jobs`.

A implementação nushell deste recurso é similar, por meio do comando `job kill`, que
recebe o ID retornado por `job spawn`, e interrompe a tarefa, matando
todos os processos ativos nela.

// TODO: incluir foto de exemplo

== Comunicação entre Jobs

Apesar de não ter sido solicitado originalmente pelos usuários do projeto, este trabalho
adicionou  capabilidades de comunicação entre tarefas de segundo plano ao projeto nushell.

A ideia inicial era a 
implementação de comunicação entre threads
por meio do modelo de interação concorrente
#link("https://en.wikipedia.org/wiki/Communicating_sequential_processes")[
  Communicating Sequantial Processes
] (CSP), de Tony Hoare,
que também inspirou o design das linguagens `OCaml`, `Go`, `Rust`, e `Clojure`.
Neste modelo, seria implementado um tipo de dado mutável denominado 'canal', que poderia
ser compartilhado entre jobs, do qual o envio de mensagens seria possível por meio de comandos
como `channel send` e `chanel recv`.
// TODO: add citation 
// TODO: should we move this to implementation details?

Entretanto, isto iria introduzir estado local mutável compartilhado na linguagem, o que traria
complexidades adicionais negativas, como ciclos de referência, e por consequência, garbage collection.
Por este motivo, outro modelo foi investigado e utilizado.

O modelo de comunicação entre tarefas implementado foi inspirado no da linguagem de programação
funcional Erlang, inspirado por sua vez no modelo de computação concorrente baseado em
#link("https://en.wikipedia.org/wiki/Actor_model")[atores].

No modelo implementado, cada job possui uma lista interna de valores denominada sua "caixa de entrada"
ou _mailbox_. Dado o ID de um job, é possível enviar uma mensagem para este
(ou seja, adicionar uma mensagem à sua mailbox), utilizando o comando
`job send`, informando o valor a ser enviado, e o ID do destinatário. Qualquer valor
pode ser enviado.
Um job pode verificar as mensagens em sua mailbox utilizando o comando `job recv`, que
retira uma mensagem da mailbox, em estilo First-In-First-Out (ou seja, ele retira
a mensagem mais antiga inserida na mailbox). Caso não tenha nenhuma mensagem
na mailbox, o comando `job recv` fica inativo esperando até que alguma mensagem
chegue, ou até que este tenha sua execução interrompida (por exempo, por `Ctrl-C`).

A @job_msg mostra um exemplo de uso deste recurso, que permite a possibilidade de
esperar uma tarefa de segundo plano terminar com algum resultado.
Neste exemplo, a tarefa computa o número de ocorrências da palavra _"machine"_
no livro _On the Economy of Machinery and Manufactures_ de Charles Babbage.

#figure([
```bash
let parent = job id

let id = job spawn {
  http get https://www.gutenberg.org/cache/epub/4238/pg4238.txt
    | split words
    | str downcase
    | find machine
    | length
    | job send $parent
}

# Quando o usuário quiser obter o resultado, executa
job recv
```
]) <job_msg>
// TODO: caption on this

Além disso, o comando `job send` permite que mensagens sejam enviadas com um metadado
numérico chamado `tag`. Essa tag pode ser utilizada no comando `job recv`, que só vai
remover da mailbox mensagens que possuam as mesmas tags que as enviadas.

// TODO: incluir exemplo disso

Adicionalmente, o comando `job flush` foi adicionado, que remove todas as mensagens da mailbox.

// TODO: adicionar comparação com erlang
// nos detalhes de implementação

Não originalmente planejado na implementação deste trabalho, mas posteriormente
solicitado por usuários, foi implementado o recurso de adicionar tag/nomes a jobs,
por meio da flag `--tag` do comando `job spawn`, ou do comando `job tag`, que
adiciona uma tag a um job existente.

#pagebreak()

== Documentação

Além da implementação destes comandos, também foi escrita a documentação no shell para todos estes, que podem ser acessadas
pela flag `--help` em cada comando, ou pelo uso do comando `help`. Também foi providenciado um comando `job` que
lista todos os comandos de controle de tarefas implementados.

#figure([
```
Various commands for working with background jobs.

You must use one of the following subcommands. Using this command as-is will only produce this help message.

Usage:
  > job

Subcommands:
  job flush - Clear this job's mailbox.
  job id - Get id of current job.
  job kill - Kill a background job.
  job list - List background jobs.
  job recv - Read a message from the mailbox.
  job send - Send a message to the mailbox of a job.
  job spawn - Spawn a background job and retrieve its ID.
  job tag - Add a description tag to a background job.
  job unfreeze - Unfreeze a frozen process job in foreground.
  job unfreeze (alias) - Alias for job unfreeze

Flags:
  -h, --help: Display the help message for this command
```
],
  caption: [Saída do comando `job`, que lista todos os comandos de controle de tarefas. ]
)


= Capitulo 3 \ Detalhes de Implementação

/*

=== 1. Tarefas em segundo plano, por meio de threads
Um dos requisitos solicitados pelos usuários do projeto, que tarefas em segundo plano 
não apenas sejam capazes de executar programas separados, mas também de executar código nushell.
Como exemplo, o código abaixo em `bash` utiliza do recurso deste shell de realizar operações
aritméticas, para computar o resultado da expressão 10+20, e salvar este em um arquivo `result.txt`,
por meio de um background job.

```bash
(let result=10+20; echo $result > result.txt) &
sleep 1
cat result.txt
```

Para dar suporte a este recurso, o a implementação realizada neste trabalho
utiliza de threads para implementar
tarefas de segundo plano, ou seja, cada job é definido por uma thread distinta.

Em sistemas operacionais POSIX, uma alternativa é a utilização da _syscall_ `fork` para
iniciar uma cópia do processo atual, ao invés de iniciar uma nova thread. É desta forma,
que atividades em segundo plano são implementadas em shells tradicionais.
Isto não é uma opção viável para o projeto nushell, pois este é multiplataforma,
e não existe nenhuma _syscall_ equivalente a esta
no sistema operacional Windows. Logo, o modelo de implementação de tarefas em segundo
plano escolhido foi o de threads.

O código abaixo em nushell replica o comportamento do código bash apresentado acima.

```bash
job spawn { let result = 10 + 20; $result | save result.txt }
sleep 1sec
open result.txt
```
// TODO: fazer ilustrações mostrando a diferença entre os dois modelos
*/

#pagebreak()

// TODO: falar do lance de sair do shell mostrar uma mensagem de aviso.

= Capitulo 4 \ Impacto

== Feedback direto dos Usuários

As contribuições desenvolvidas neste trablaho já foram aceitas no projeto nushell, por meio
das Pull Requests \#14883 e \#15253. A primeira implementa tarefas de segundo plano e Ctrl-Z, enquanto a segunda
implementa comunicação entre tarefas.

Durante o desenvolvimento da PR principal, esta já tinha 16 reações positivas
de usuários entusiasmados com o desenvolvimento no Github.
Antes mesmo da implementação estar completa, a PR já
tinha usuários testando os recursos implementados, e providenciando feedback positivo.
A @pr_feedback mostra um comentário de um usuário satisfeito com o comportamento do Ctrl-Z adicionado.
// TODO: add PR to glossary

#figure([
 #image("pr_feedback.png"),
],
 caption: [Feedback positivo de um usuário nos comentários da PR principal, mesmo em um estado prematuro desta]
) <pr_feedback>

Após o fim do trabalho, este foi parabenizado por
mantenedores, e múltiplos usuários entraram em contato
com o autor descrevendo seu contento com o que foi realizado.

#figure([
 #image("omg.png"),
 #image("tag.png"),
 #image("thx.png"),
 #image("way_to_go.png"),
],
 caption: [Feedbacks positivos de mantenedores e usuários no chat Discord e github do nushell depois de
terminadas as PRs. ]
) <omg>


== Uso em repositórios públicos

A plataforma Github possui uma #link("")[ferramenta de busca] que permite que textos
específicos sejam buscadas em repositórios públicos. Com isso, podemos procurar instâncias de uso do termo `job spawn`
em arquivos nushell. Realizando uma busca por arquivos de extensão `.nu` (de scripts nushell), que contém o termo `job spawn`,
obtemos 113 arquivos, de múltiplos usuários diferentes.

#figure([
  #image("job_spawn_search.png"),
], caption: [Resultado da busca `path:*.nu "job spawn"` na busca avançada do Github, devolvendo 113 arquivos])

Buscando por ocorrências de "`job unfreeze`" e `fg`, obtemos ocorrências em cerca de 50 arquivos públicos diferentes,
em que usuários vindos de shells POSIX configuram o comando familiar `fg` para `job unfreeze`.

#figure([
  #image("job_unfreeze_search.png"),
], caption: [Resultado da busca `path:*.nu "job unfreeze" fg` na busca avançada do Github, devolvendo 48 arquivos])

Mesmo recursos argumentavelmente menos relevantes, como `job send` e `job recv` são
utilizados em scripts públicos desenvolvidos pela comunidade. Em particular, um usuário escreveu uma
#link("https://github.com/nushell/nu_scripts/blob/main/games/paperclips/game.nu")[cópia] do jogo
universal paperclips em nushelll, utilizando os comandos `job send` e `job recv` para realizar comunicação entre diferentes
partes do jogo.

Com essas informações, podemos concluir que os recursos implementados
neste trabalho já estão sendo utilizados por dezenas de usuários diferentes,
para diversos propósitos.

== Planos futuros




/*

=== 2. Tarefas em segundo plano baseadas em processos

Shells tradicionais mantém registro de todas as tarefas de segundo plano iniciadas,
para, por exemplo, que o usuário do shell possa se informar de quais jobs ainda estão executando,
e avisar se o usuário tentar terminar o shell enquanto algum job ainda está em andamento.
Entretanto, caso o usuário queira iniciar um processo em segundo plano, e não queira que o shell
mantenha registro deste processo, shells POSIX permitem que o shell remova os
registros internos de um processo em segundo plano, por meio do comando `disown`.

Além de tarefas em segundo plano baseadas em threads, a primeira PR também planejava
permitir que os usuários iniciassem processos específicos em segundo plano sem que
o shell mantenha registro destes processos, equivalente a executar `disown` após
inicar o processo. Esta tarefa foi determinada como fora do escopo da implementação
inicial, e não implementada. A issue #link("https://github.com/nushell/nushell/issues/15200")[\#15200]
do projeto foi criada para representar a demanda por este recurso.

=== 3. Comunicação entre threads por meio de _Communicating Sequential Processes_

A escolha de threads para a implementação de background jobs abre oportunidade
para a adição de mecanismos de comunicação entre threads à linguagem,
permitindo que scripts em nushell possam implementar algorítmos paralelos.


*/

/*
== Detalhes de Implementação da PR

=== Criação de Jobs

O projeto nushell é implementado na linguagem de programação Rust, que tem como
 um de seus principais objetivos a facilitação na implementação de programas multi-threaded
seguros. Isto facilitou consideravelmente a implementação inicial de multithreading no projeto.

Um exemplo de políticas da linguagem que facilitam a implementação de programas
multithreaded, é o fato da linguagem por padrão proibir a criação de variáveis globais mutáveis, incentivando
o uso de structs passadas como argumento para subrotinas para implementar estado compartilhado.
Em nushell, isso se dá por meio das structs `EngineState` e `Stack`, que guardam todo o estado mutável da
thread principal, como símbolos e variáveis locais.

Na implementação deste trabalho, essas structs são clonada para cada thread nova inicializada,
para que o estado das múltiplas threads não interfiram entre sí.

Para a criação de jobs, foi adicionado o comando `job spawn`, que recebe uma função/closure
e executa esta em uma nova thread. // TODO: falar do ID retornado pelo job spawn

...

// Dúvida: Vale mais a pena documentar as coisas como foram feitas, ou será que é melhor documentar o resultado final?
// Acho que vou falar das coisas na ordem que foram implementadas,  mas falar dos designs finais desses recursos implementados,
// e salientar mudanças de design importantes, como CSP vs Actor Model.
- Alterações implementadas:

[X] Spawn de jobs:
Falar de closures, da struct EngineState, comandos experimentais, e do comando `job spawn`, e tratamento de erros.
falar de como posteriormente, o job spawn foi modificado para que este retorne o id do job spawnado.

. Listagem de jobs
Falar da tabela de jobs, salva por um mutex compartilhado entre as `EngineState`s, falar do modelo de exclusão de acesso da linguagem Rust.
Falar de como o id do primeiro job é o zero.

. Assasinato de jobs
Falar do algorítmo de matagem de jobs implementado, qual a brincadeira de lock unlock, falar do model acquire-relesase e da issue de rust
que falta da falta da documentação desse detalhe.

. TSTP e Ctrl-Z
Falar do manual da GNU que eu li, quais syscalls foram usadas, UnfreezeHandle etc.
Falar de process groups, e do commit (per-pipelines)[https://github.com/nushell/nushell/pull/14883/commits/267b092c7954b2100df0fdab3b6ef9668aeee240].

. Saída do program e aviso na saída
Falar de como foi implementado o esquema de avisar o usuário se ele tentar sair do shell enquanto tem algum job na tabela.
Falar de como o programa se comporta quando o shell termina e ainda tem jobs rodando (matar ou não matar os processos?)
Falar de como o programa não mostra a saída dos procesoss por padrão, mas ainda permite que comandos que explicitamente printam coisas na tela funcionem (print).

. Alterações que sairam de escopo
Falar da ideia do `job dispatch`, de como ele é mais ou menos desncessário (job spawn meio que serve)

== Pull Request  \#15253 - "Inter-Job Direct Messaging"

// Falar bla bla bla detalhes Erlang.

= Capítulo 3
= Resultado e Impacto

Falar de como o projeto foi bem vindo, e falar de depoimentos e agradecimentos que a galera no github e discord falou da contribuição.


// glossário:
// PR - Pull Request
// TODO: adicionar termos em inglês
// TODO: deixar claro a interoperabilidade de tarefa de segundo plano, background job, job
*/
