+++
title = 'Relatório TCC'
+++

# Relatório de progresso de TCC: 16/3 - 22/3

Neste período, ocorreu uma nova release do nushell (versão 0.103.0), e assim, os usuários
do projeto que utilizam a versão mais recente (e.g usuários dos repositórios do Arch e homebrew) já podem desfrutar
das features implementadas na PR [#14883](https://github.com/nushell/nushell/pull/14883) introduzindo job control e suspensão.

Com isso, já existem issues comentando sugestões e melhorias para a feature, que serão implementadas com o passar do tempo por mim
(e outros mantenedores com o passar do tempo).

### O que foi feito:

- Continuei trabalhando na PR que introduz comunicação entre jobs ([#15253](https://github.com/nushell/nushell/pull/15253))
  para implementar modificações sugeridas por mantenedores, corrigir o comportamento da feature em WebAssembly (um dos targets do projeto)
  adicionar testes, melhorar os testes antigos de comunicação entre jobs, e resolver bugs que meus testes encontraram =(

- Comecei a implementar as sugestões feitas recentemente pelos mantenedores do projeto, em relação à [documentação](https://github.com/nushell/nushell.github.io/pull/1826) que escrevi
  sobre a feature de job control.

- Conversei com alguns dos mantenedores para discutir o design de processos externos no projeto.
  Planejo implementar um comando `job dispatch` para spawnar _processos_ separados no background, e estamos discutindo sobre como
  os mantenedores idealizam a semântica disto.

