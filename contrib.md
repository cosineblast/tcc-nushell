
# Meu histórico de contribuições com o projeto nushell

Eu possuo um total de 7 PRs para o repositório principal do nushell,
minha primeira [pull request](https://github.com/nushell/nushell/pull/11182),
foi sobre a remoção de operações IO desnecessárias em testes do projeto,
para resolver uma [issue](https://github.com/nushell/nushell/issues/7189) documentada sobre isso.

Minha segunda contribuição de código com o projeto, foi
a implementação de uma operação nova `chunk_by` para o projeto.
Esta operação é comum em ambientes com incentivos a programação funcional (python, clojure, haskell)
sobre sequências, mas era ausente no projeto, então a implementei. Nesta experiência pude entender
melhor como funciona a infraestrutura de comandos do projeto, e como adiona-los.

Minhha terceira contribuição foi uma otimização de multithreading do comando `ls`, para que este tenha tempos
de resposta melhores quando coletando dados em uma quantidade grande de pastas (`ls */**`).
Acompanhada dessa contribuição, também resolvi um problema em relação a re-entrância dos comandos
`get` e `reject`, melhorando seus tempos de resposta.

## Background jobs em nushell

Desde sua criação em 2019, o projeto nushell possui solicitações para a implementação de [background jobs](https://github.com/nushell/nushell/issues/247), feature
comum em shells POSIX. Em particular, usuários costumavam solicitar uma maneira de suspender os processos spawnados em unix
(comumente executado pelo comando Ctrl-Z em terminais unix), e spawnar jobs de background.

Já houveram esforços no passado para implementar este recurso, em uma [PR](https://github.com/nushell/nushell/pull/11696),
mas as features solicitadas pelos usuários nunca foi implementadas e mergeadas com sucesso no passado.

O meu projeto de trabalho de conclusão de curso é a implementação e documentação de uma infraestrutura de background jobs no nushell.
Isto de dá inicialmente pela trabalhosa PR [#14883](https://github.com/nushell/nushell/pull/14883),
desenvolvida entre janeiro e fevereiro de 2025. Já mergada, esta contribuição adicionou suporte a background jobs no projeto, por meio de threads.
Além disso, essa contribuição dá suporte à solicitada feature de Ctrl-Z do projeto.


