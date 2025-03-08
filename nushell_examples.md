
## Exemplos de código nushell 

Aqui seguem alguns exemplos simples de código nushell que não tenho como comparar com bash/awk pois fogem
de meu conhecimento técnico dessas ferramentas.

**Obter número de linhas de todos os arquivos .rs sob a atual**

`ls **/*.rs | each { |file| open $file.name | lines | length } | math sum`

**Obter tamanho médio dos arquivos png da pasta atual**

``` 
ls | where name =~ png$ | get size | math avg
```

**Executar um comando 30 vezes e computar o tempo médio de execução do comando**

```
(0..30) | each { timeit { comando } } | math avg
```

**Listar nome e tamanho de todos os arquivos na home do usuário atual com tamanho maior que 100MB** 

```
ls **/* | where type == file | where size > 10mb | sort-by size | select name size
```

