
## Implementação inicial dos testes

Os testes feitos na primeira [PR](https://github.com/nushell/nushell/pull/14883) de jobs
testam o comportamento do executável compilado do projeto,
providenciando um pequeno script de entrada. Cada script de teste consiste em spawnar
jobs (threads) de background, verificar algum comportamento feito pela thread, e depois devolver algum valor de resultado.

O código rust dos testes, em sequência, verifica se a saída devolvida pelo script está de acordo com o esperado.

Por exemplo, no seguinte script, o programa sob teste cria uma thread que espera
200 millisegundos para criar um arquivo chamado a.txt, e depois
o programa verifica a existência desse arquivo antes e depois de um intervalo de tempo de 400 millisegundos.

```
# spawna uma thread que espera 200ms e depois escreve "a"
# no arquivo a.txt
job spawn { sleep 200ms; 'a' | save a.txt };

# verifica a existência do arquivo no momento atual
let before = 'a.txt' | path exists

sleep 400ms

# verifica a existência do arquivo depois de 400 millisegundos
let after = 'a.txt' | path exists

# devolve um vetor contendo a existência do arquivo dos dois momentos
[$before, $after] | to nuon
```

Após isto, o código em rust verifica se a saída devolvida é `[false, true]`,
indicando que o arquivo não existia quando a primeira medição foi feita, e existiu 
quando a segunda medição foi feita (depois do _sleep_ de 400ms),
o que indica que o job executou com sucesso.

A maior parte dos testes segue uma estrutura similar, de criar threads,
esperar uma certa quantidade de tempo, e verificar se algum comportamento em relação às threads 
foi cumprido.

Esta estratégia de testes de thread baseada em operações _sleep_, é notavelmente frágil,
pois, por exemplo, caso as threads acabem tomando muito tempo para executar (o que pode acontecer naturalmente em sitações de high load), 
o teste pode acabar falhando, pois a thread principal não notou as mudanças 
realizadas pela thread nova.
Tempos de _sleep_ generosos (na casa dos segundos) foram escolhidos para ajudar a evitar isso, 
mas não há garnatias.

Em particular, foram implementados testes para testar os seguintes comporamentos, todos com alguma espécie de verifcação baseada em _sleep_:
- Jobs são executados corretamente (o teste acima)
- Jobs quando iniciados são adicionados a tabela de jobs corretamente
- Jobs quando terminados são removidos da tabela de jobs
- A lista de jobs mostra os PIDs dos processos que estão sendo executados pelos jobs
- Matar um job remove ele da tabela de jobs
- Matar um job mata todos processos ativos dele
- Sair do nushell mata todos os jobs ativos
- (Em unix) Os processos spawnados pelos jobs tem group IDs corretos

Em alguns destes testes, processos filhos são spawnados pelo script, e depois o script rust verifica a existência deles. Por exemplo, o teste a seguir
verifica se a lista de jobs mostra o PID de todos os processos criados
pelo job atual:

```
# Spawna um job que cria 2 processos, um durando 1 segundo, e outro durando 2
let job1 = job spawn {{ nu -c "sleep 1sec" | nu -c "sleep 2sec" }};

# Dorme por 500 segundos;
# sem azar, neste instante os dois processos filhos devem estar vivos.
sleep 500ms

# Lista os processos do job no instante atual
# sem azar, esta lista deveria ter 2 processos
let list0 = job list | where id == $job1 | first | get pids;

# Dorme por mais um segundo;
# sem azar, agora o primeiro processo está morto e o segundo
# processo continua vivo
sleep 1sec

# Lista os processos do job no instante atual
# sem azar, esta lista deveria ter 1 processo só
let list1 = job list | where id == $job1 | first | get pids;
```

Depois de executar o script, o programa rust verifica se a primeira
lista tem 2 elementos, a segunda tem 1 elemento, e se
a primeira é um subconjunto da segunda.

## Ideias de melhoria de qualidade dos testes

Em vários testes, nós precisamos esperar até que a thread criada tome
um certo comportamento (escrever em um arquivo, spawnar um processo, etc).

Uso de tempo de espera poderia ser evitado em alguns desses casos,
se tivéssemos algum mecanismo para realizar comunicação entre os jobs spawnados, 
ou entre os processos spawnados pelos jobs, o que está sob consideração pelo estudante.

