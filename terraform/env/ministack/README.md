# Ambiente local com MiniStack

Esse diretório aplica a infraestrutura da branch single-table ao MiniStack. Ele usa o backend local e endpoint `localhost:4566`; o ambiente AWS em `../dev` permanece separado.

O Compose também expõe a API em `localhost:9000` e o gerador de certificados em `localhost:9001`. A chamada de registro Solana do gerador é roteada para um mock local, para o teste não enviar transações reais. As URLs de imagem de fundo e logo são baixadas normalmente.

Na raiz de `certified-builder-infra-py`, suba os serviços:

```sh
docker compose -f compose.ministack.yaml up -d --build
```

Para compilar a API a partir de outro checkout, defina `API_BUILD_CONTEXT` no comando do Compose. O padrão é `../certified-builder-api-py`.

Inicialize e aplique Terraform neste diretório:

```sh
terraform init -backend=false
terraform apply \
  -var='aws_account_id=000000000000' \
  -var='github_actions_role_arn=arn:aws:iam::000000000000:role/local' \
  -var='api_key_value=00000000-0000-4000-8000-000000000000' \
  -var='service_url_registration_api_solana=http://example.local/register' \
  -var='service_api_key_registration_api_solana=local-test-key' \
  -var='tech_floripa_certificate_validate_url=http://example.local/validate'
```

O endpoint do emulador é configurado diretamente no provider local. Não passe variáveis AWS reais para esse ambiente.
