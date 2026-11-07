# Certified Builder Infra PY

## Visão Geral do Projeto

Este projeto contém a infraestrutura como código (IaC) para a aplicação "Certified Builder". A infraestrutura é gerenciada com Terraform e provisiona os recursos necessários na AWS para executar a aplicação de forma escalável e econômica.

## Tecnologias Utilizadas

- **Terraform**: Ferramenta de infraestrutura como código para provisionar e gerenciar os recursos na nuvem.
- **AWS (Amazon Web Services)**: Provedor de nuvem onde a infraestrutura da aplicação é hospedada.

## Diagrama da arquitetura

O diagrama mostra as rotas da API, os recursos AWS e o fluxo assíncrono de geração e notificação de certificados. A versão SVG fica incorporada abaixo; a animação WebM ilustra o fluxo e o HTML oferece a versão interativa.

![Diagrama da API Certified Builder e arquitetura AWS](docs/api-certified-builder-e-arquitetura-aws.svg)

<video controls preload="metadata" width="100%">
  <source src="docs/api-certified-builder-e-arquitetura-aws.webm" type="video/webm">
  Seu navegador não consegue reproduzir WebM. <a href="docs/api-certified-builder-e-arquitetura-aws.webm">Baixe a animação</a>.
</video>

[Abrir versão interativa do diagrama](docs/api-architecture.html)

## Estrutura de Pastas

A estrutura de pastas do projeto é organizada da seguinte forma:

```
/
├── compose.ministack.yaml       # MiniStack + API e gerador locais
├── terraform/
│   ├── env/
│   │   ├── dev/                 # AWS, backend S3
│   │   └── ministack/           # Local, backend local
│   └── modules/
│       ├── 02.dynamodb/single_table/
│       ├── 03.bucket_s3/
│       ├── 04.sqs/
│       ├── 05.lambda/
│       └── 06.api-gateway/
└── README.md
```

- **terraform/env/dev/**: Perfil Terraform AWS, com state remoto em S3.
- **terraform/env/ministack/**: Perfil isolado para MiniStack, com state local.
- **terraform/modules/**: Módulos reutilizáveis para DynamoDB, S3, SQS, Lambda e API Gateway.

## Serviços Criados e Suas Variáveis

A seguir estão os serviços da AWS criados por este projeto e suas respectivas variáveis de configuração.

### API Gateway

- **Descrição**: Cria um API Gateway REST para expor a aplicação Lambda como uma API.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy (dev, staging, prod).
    - `lambda_function_name`: Nome da função Lambda.
    - `lambda_invoke_arn`: ARN para invocar a função Lambda.
    - `throttle_rate_limit`: Limite de taxa por segundo para throttling.
    - `throttle_burst_limit`: Limite de burst para throttling.
    - `api_key_value`: Valor da API Key para autenticação.

### S3 Bucket

- **Descrição**: Cria um bucket S3 para armazenar os arquivos do projeto.
- **Variáveis**:
    - `bucket_name`: Nome do bucket S3.
    - `environment`: Ambiente de deploy.
    - `project_name`: Nome do projeto.
    - `region`: Região da AWS.
    - `lifecycle_rule`: Regras de ciclo de vida dos objetos S3.

### DynamoDB Single-Table

- **Descrição**: Cria a tabela DynamoDB com padrão Single-Table Design.
- **Módulo**: `single_table`
- **Variáveis**:
    - `table_name`: Nome da tabela.
    - `environment`: Ambiente de deploy.
    - `project_name`: Nome do projeto.

#### Estrutura da Tabela

A tabela utiliza um design Single-Table com chaves compostas e 4 Global Secondary Indexes (GSIs).

| Atributo | Tipo | Descrição |
|----------|------|-----------|
| `PK` | String | Chave de Partição principal |
| `SK` | String | Chave de Ordenação principal |
| `GSI1PK`, `GSI1SK` | String | GSI1 - Certificate por UUID |
| `GSI2PK`, `GSI2SK` | String | GSI2 - Orders, Certificates, Participants por email |
| `GSI3PK`, `GSI3SK` | String | GSI3 - Products por nome, Certificates/Orders por product |
| `GSI4PK`, `GSI4SK` | String | GSI4 - Certificados por status de sucesso |

#### GSIs (Global Secondary Indexes)

| GSI | Key Schema | Access Pattern |
|-----|------------|----------------|
| GSI1 | `PK: UUID, SK: CERT#` | Certificate by UUID |
| GSI2 | `PK: email, SK: ENTITY#` | Orders, Certificates, Participants by email |
| GSI3 | `PK: product, SK: ENTITY#` | Products by name, Certificates/Orders by product |
| GSI4 | `PK: SUCCESS#Y/N, SK: CERT#` | Successful/Failed certificates |

#### Entidades Suportadas

| Entidade | PK | SK | GSIs Utilizados |
|----------|----|----|----------------|
| Certificate | `CERTIFICATE#<uuid>` | `CERTIFICATE#<uuid>` | GSI1, GSI2, GSI3, GSI4 |
| Order | `ORDER#<order_id>` | `ORDER#<order_id>` | GSI2, GSI3 |
| Product | `PRODUCT#<product_id>` | `PRODUCT#<product_id>` | GSI3 |
| Participant | `PARTICIPANT#<uuid>` | `PARTICIPANT#<uuid>` | GSI2 |

### Lambda

- **Descrição**: Cria as funções Lambda no formato ZIP e a infraestrutura associada.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy.
    - `aws_region`: Região AWS.
    - `lambda_timeout`: Timeout da função Lambda em segundos.
    - `lambda_memory_size`: Memória alocada para a função Lambda em MB.
    - `log_retention_days`: Dias de retenção dos logs do CloudWatch.
    - `builder_queue_url`: URL da fila SQS builder.
    - `url_service_tech`: URL do serviço Tech Floripa.
    - `prefix_api_version`: Prefixo da versão da API.
    - `dynamodb_table_arns`: ARNs das tabelas DynamoDB.
    - `builder_queue_arn`: ARN da fila SQS builder.
    - `notification_queue_arn`: ARN da fila SQS notification.
    - `notification_queue_url`: URL da fila SQS notification.
    - `s3_bucket_arn`: ARN do bucket S3.
    - `s3_bucket_name`: Nome do bucket S3.
    - `api_gateway_download_url`: URL base do endpoint de download do API Gateway.

## Fluxo de Deploy

- O Terraform cria as funções Lambda, roles, filas SQS, tabelas DynamoDB, bucket S3 e API Gateway.
- Cada função é inicializada com um ZIP placeholder mínimo apenas para permitir a criação do recurso.
- Os repositórios `certified-builder-api-py`, `certified_builder_py` e `certified-builder-notification-py` publicam o código real usando `aws lambda update-function-code`.
- O perfil MiniStack em `terraform/env/ministack` usa o backend local e endpoint `localhost:4566`; ele é separado de `terraform/env/dev`, que continua usando o backend S3 da AWS.

### Deploy na AWS

Para provisionar na AWS, use apenas o perfil `terraform/env/dev` e suas variáveis reais fornecidas pela configuração segura do ambiente:

```sh
cd terraform/env/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Depois do provisionamento, publique os pacotes de código das três Lambdas pelos workflows dos repositórios relacionados. O `apply` do perfil `dev` cria ou altera recursos AWS; o perfil `ministack` abaixo não usa nem atualiza esse state.

## Desenvolvimento e testes locais com MiniStack

O Compose sobe o emulador AWS MiniStack, a API em runtime Lambda local (RIE) e o gerador de certificados. O MiniStack persiste os dados no volume Docker `ministack-data`.

### Requisitos

- Docker Desktop/Engine em execução.
- Terraform instalado.
- AWS CLI instalado (as chamadas abaixo usam apenas `--endpoint-url http://localhost:4566` e credenciais fictícias).

### Subir os serviços

Execute na raiz deste repositório:

```sh
docker compose -f compose.ministack.yaml up -d --build
curl -fsS http://localhost:4566/_ministack/health
docker compose -f compose.ministack.yaml ps
```

Portas locais:

| Serviço | Endereço | Uso |
|---------|----------|-----|
| MiniStack | `http://localhost:4566` | APIs AWS simuladas |
| API Lambda RIE | `http://localhost:9000` | Invocação Lambda local |
| Gerador Lambda RIE | `http://localhost:9001` | Geração do certificado |
| Mock Solana | apenas na rede Compose | Responde com URL de transação de teste; não envia transação real |

Por padrão, a API é compilada do checkout vizinho `../certified-builder-api-py`, e o gerador de `../certified_builder_py`. Para usar outro worktree ou checkout, informe `API_BUILD_CONTEXT` ou `BUILDER_BUILD_CONTEXT` ao executar Compose. Exemplo:

```sh
API_BUILD_CONTEXT=/caminho/para/api-worktree \
BUILDER_BUILD_CONTEXT=/caminho/para/builder-worktree \
docker compose -f compose.ministack.yaml up -d --build
```

### Criar a infraestrutura single-table

O perfil local tem provider apontado diretamente para MiniStack, credenciais fictícias e backend Terraform local. Não use credenciais AWS reais nele.

```sh
cd terraform/env/ministack
terraform init -backend=false
terraform apply \
  -var='aws_account_id=000000000000' \
  -var='github_actions_role_arn=arn:aws:iam::000000000000:role/local' \
  -var='api_key_value=00000000-0000-4000-8000-000000000000' \
  -var='service_url_registration_api_solana=http://example.local/register' \
  -var='service_api_key_registration_api_solana=local-test-key' \
  -var='tech_floripa_certificate_validate_url=http://example.local/validate'
```

O comando cria a tabela single-table, bucket S3, filas SQS, Lambdas placeholder e API Gateway no MiniStack. O estado fica em `terraform/env/ministack/terraform.tfstate`; o backend S3 de `terraform/env/dev` não é inicializado.

### Testar geração de certificado

O gerador recebe um evento SQS Lambda: `Records[0].body` deve ser uma string JSON contendo uma lista de participantes. Os campos de entrada são `order_id`, `product_id`, `product_name`, `email`, `first_name`, `last_name`, `certificate_details`, `certificate_logo`, `certificate_background` e `order_date` (`YYYY-MM-DD HH:MM:SS`). `time_checkin` é opcional.

Crie um evento temporário com dados fictícios. As imagens usam o serviço público de placeholders; substitua-as por arquivos de teste locais se quiser executar sem acesso externo:

```sh
cat > /tmp/certificate-event.json <<'JSON'
{
  "Records": [{
    "body": "[{\"order_id\":123456,\"product_id\":42,\"product_name\":\"Demo Event\",\"email\":\"alex@example.test\",\"first_name\":\"Alex\",\"last_name\":\"Example\",\"certificate_details\":\"This is a fictional certificate for local testing.\",\"certificate_logo\":\"https://placehold.co/150x150.jpg?text=Demo+Logo\",\"certificate_background\":\"https://placehold.co/1200x627.png?text=Demo+Certificate\",\"order_date\":\"2025-01-15 12:00:00\"}]"
  }]
}
JSON

curl -sS -X POST \
  http://localhost:9001/2015-03-31/functions/function/invocations \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/certificate-event.json
```

O endpoint de invocação pode responder `200` mesmo quando a geração interna falha. Confirme o resultado pelos logs e pelo objeto S3:

```sh
docker compose -f compose.ministack.yaml logs --tail=150 certified_builder_lambda_function

AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
aws s3api list-objects-v2 \
  --endpoint-url http://localhost:4566 \
  --bucket tech-floripa-certificates-dev-bucket \
  --prefix certificates/42/123456/ \
  --query 'Contents[].{Key:Key,Size:Size}' --output table
```

Uma geração bem-sucedida registra `Certificado gerado` e o upload para S3 nos logs. Uma falha registra `Erro ao gerar certificado` ou `Erro ao enviar o arquivo`. A chave final inclui o código de validação aleatório criado na execução.

O gerador envia também uma notificação para SQS. As Lambdas criadas pelo Terraform usam código placeholder; portanto, a Lambda de notificação local pode consumir a mensagem sem atualizar o item no DynamoDB. Para testar atualização de status, publique o código real do repositório de notificações apontando seus clientes AWS para MiniStack. O `success` que já estiver no item de seed não comprova o resultado da execução atual.

### Parar e limpar

Pare os containers sem remover o volume persistente:

```sh
docker compose -f compose.ministack.yaml down
```

Para remover também os dados locais do MiniStack, remova o volume apenas quando não precisar mais do estado e dos objetos de teste:

```sh
docker compose -f compose.ministack.yaml down -v
```

Para excluir os recursos do Terraform local, execute `terraform destroy` dentro de `terraform/env/ministack`, passando as mesmas variáveis fictícias usadas no `apply`.

### SQS (Simple Queue Service)

- **Descrição**: Cria as filas SQS para processamento assíncrono.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy.
    - `queue_name_builder`: Nome da fila de build.
    - `queue_name_builder_dlq`: Nome da fila de build DLQ.
    - `queue_name_notification`: Nome da fila de notificação.
    - `queue_name_notification_dlq`: Nome da fila de notificação DLQ.

## Projetos Relacionados

- **[certified-builder-py](https://github.com/PythonFloripa/certified_builder_py)**: Este projeto gera certificados personalizados para participantes de eventos, processando mensagens do SQS e utilizando templates predefinidos.
- **[certified-builder-notification-py](https://github.com/PythonFloripa/certified-builder-notification-py)**: Este projeto é uma função AWS Lambda responsável por processar notificações de certificados gerados. Ele é acionado por mensagens em uma fila SQS, atualiza o status dos certificados e notifica um serviço externo sobre a conclusão.
- **[certified-builder-api-py](https://github.com/PythonFloripa/certified-builder-api-py)**: Esta API é responsável por gerenciar a criação, consulta e download de certificados. Ela é construída como uma função Lambda da AWS, utilizando uma arquitetura serverless.
