# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition e restart policy unless-stopped.

## Output Original da IA

A IA sugeriu a criação de um ambiente com três serviços: uma API em Node.js com Express, um banco PostgreSQL e um Redis para cache. Também incluiu uma rede Docker personalizada para conectar os serviços, um volume nomeado para persistir os dados do PostgreSQL e o uso de variáveis no arquivo `.env`.

Além disso, a resposta já indicava o uso de healthchecks, política de reinício dos containers e `depends_on`, para que a API aguardasse os serviços necessários estarem prontos antes de iniciar.

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|---|---|
| Usei nomes exclusivos nos containers (`technova-aula02-*`) | Eu já tinha outros containers de laboratórios anteriores em execução. Usar nomes diferentes evitou conflito entre eles. |
| Expus a API pela porta 3001 do computador, direcionada à porta 3000 do container | A porta 3000 já estava ocupada por outro projeto. A aplicação continua usando a porta 3000 internamente. |
| Não expus PostgreSQL e Redis ao computador | A API consegue acessar os dois serviços pela rede interna do Docker. Assim, também evitei conflitos com as portas 5432 e 6379. |
| Configurei todas as variáveis via `.env` | Dessa forma, as credenciais não ficam escritas diretamente no arquivo `docker-compose.yml`. |
| Adicionei healthcheck à API | Isso permite verificar se a aplicação está respondendo corretamente pelo endpoint `/health`. |
| Mantive volumes nomeados para PostgreSQL e Redis | Os volumes ajudam a preservar os dados mesmo se os containers forem recriados. |
| Validei o ambiente com `docker compose ps`, `/health` e endpoints de cache | Os testes confirmaram que a API, o banco de dados e o Redis estavam funcionando juntos. |

## O que a IA Acertou

- A estrutura sugerida com API, PostgreSQL e Redis estava correta para a atividade.

- O uso das imagens `postgres:15-alpine` e `redis:7-alpine` foi uma boa escolha por serem versões leves.

- A IA incluiu práticas importantes, como rede personalizada, volume, healthchecks e política de reinício.

- O uso de `depends_on` com condição de healthcheck ajudou a garantir que a API só fosse iniciada após os serviços dependentes estarem saudáveis.

## O que a IA Errou ou Omitiu

- A IA não tinha como saber que já existiam containers e portas em uso no meu computador. Por isso, foi necessário ajustar os nomes dos containers e a porta exposta pela API.

- Foi necessário testar o ambiente na prática, porque uma configuração aparentemente correta pode apresentar conflitos ou falhas de comunicação entre os containers.

- Ao alterar a senha inicial do PostgreSQL no `.env`, foi preciso recriar o volume do banco. Isso aconteceu porque o PostgreSQL guarda as credenciais definidas na primeira inicialização dentro do volume persistente.

## Minha Avaliação

- **Tempo economizado usando IA:** aproximadamente 30 minutos.

- **Tempo gasto validando e corrigindo:** aproximadamente 25 minutos.

- **Nota para o output da IA:** 8/10.

- **Usaria novamente para este tipo de tarefa?** Sim. A IA ajudou a criar uma boa estrutura inicial e a lembrar configurações importantes. Porém, ainda é necessário revisar o arquivo, testar os containers e adaptar a solução ao ambiente em que ela será executada.