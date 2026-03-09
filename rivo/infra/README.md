# Infra do Rivo

Este diretório concentra os artefatos de infra usados em 2 cenários:

1. `local/dev`: importar OSM no PostgreSQL local e usar `.pbf` local no app.
2. `AWS/prod`: gerar grafo do GraphHopper no S3 e rodar import/reimport do OSM no RDS via GitHub Actions + CodeBuild.

## O que existe aqui

- `osm2pgsql/osm2pgsql-flex.lua`
  - Transform do `osm2pgsql` para importar OSM no schema `geo`.
- `osm2pgsql/import-local.ps1`
  - Script para importar o `.pbf` local no PostgreSQL local.
- `codebuild/osm-import-buildspec.yml`
  - Buildspec que o CodeBuild usa para importar no RDS.
- `graphhopper/config.yml`
  - Config do build do grafo do GraphHopper.
- `iam/codebuild-routing-policy.json`
  - Policy base da role do CodeBuild.
- `aws/`
  - Kit operacional consolidado para criar e validar a infra da AWS.

## Fluxo local

No ambiente local, você não precisa de AWS para testar o import OSM nem para o GraphHopper.

### 1. Coloque o `.pbf` aqui

Use este arquivo:

- `src/main/resources/osm/south-america-latest.osm.pbf`

O app já está configurado para usar esse caminho por default em local.

### 2. Suba o PostgreSQL local

O script local assume por default:

- `DB_HOST=localhost`
- `DB_PORT=5432`
- `DB_NAME=routing`
- `DB_USER=routing`
- `DB_PASSWORD=routing`

### 3. Rode o import local

```powershell
cd E:\014-routing\rivo
.\infra\osm2pgsql\import-local.ps1
```

### 4. Rode o app local

O backend vai usar o `.pbf` local automaticamente quando:

- `routing.graphhopper.local=true`

Na primeira subida, o GraphHopper vai construir o cache em `data/graph-cache`.
Nas próximas, ele reaproveita esse cache local.

## Fluxo AWS/prod

Em produção, o desenho é este:

1. GitHub Actions baixa o `.pbf` ou diff do Geofabrik.
2. GitHub Actions sobe os arquivos no S3.
3. GitHub Actions dispara o CodeBuild.
4. CodeBuild roda dentro da VPC.
5. CodeBuild lê credenciais do RDS no Parameter Store.
6. CodeBuild executa `osm2pgsql` contra o RDS.
7. O app em produção usa o grafo pré-processado do GraphHopper vindo do S3.

## Script AWS único

O fluxo AWS agora fica centralizado em um único executável:

- [provision-routing-stack.ps1](/E:/014-routing/rivo/infra/aws/provision-routing-stack.ps1)

Comando mínimo:

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 -DbPassword 'SUA_SENHA_FORTE'
```

Esse script:

1. cria ou reaproveita rede base
2. cria ou reaproveita o RDS
3. cria ou atualiza bucket, Parameter Store, role do CodeBuild e projeto CodeBuild
4. valida a infra
5. imprime o resumo final com IDs e endpoint

## Topologia de rede recomendada na AWS

Use uma topologia simples com separação entre internet, aplicação e banco.

### Estrutura recomendada

- `1 VPC`
- `2 subnets públicas`
  - para `NAT Gateway` e opcionalmente `ALB`
- `2 subnets privadas de aplicação`
  - para `CodeBuild em VPC`
  - para o runtime do backend `rivo` se ele rodar em `EC2`, `ECS` ou `EKS`
- `2 subnets privadas de banco`
  - para o `RDS PostgreSQL/PostGIS`

### Vínculos principais

- `RDS` usa `rivo-rds-subnet-group` + `rivo-rds-sg`
- `CodeBuild` usa `rivo-vpc` + `rivo-app-a/b` + `rivo-codebuild-sg`
- backend `rivo` na AWS usa `rivo-app-a/b` + `rivo-app-sg`
- `ALB`, se existir, usa `rivo-public-a/b` + `rivo-alb-sg`

## Guia rápido AWS

- [AWS setup kit](/E:/014-routing/rivo/infra/aws/README.md)
- [Network and resource binding for Rivo](/E:/014-routing/rivo/infra/aws/network-bootstrap.md)

## Workflows que o GitHub realmente executa

Como o repositório git está na raiz `E:\014-routing`, os workflows ativos precisam ficar em `.github/workflows` na raiz do repo.

Workflows prontos:

- [rivo-ci.yml](/E:/014-routing/.github/workflows/rivo-ci.yml)
- [rivo-graphhopper-build.yml](/E:/014-routing/.github/workflows/rivo-graphhopper-build.yml)
- [rivo-osm-postgis-full-import.yml](/E:/014-routing/.github/workflows/rivo-osm-postgis-full-import.yml)
- [rivo-osm-postgis-diff.yml](/E:/014-routing/.github/workflows/rivo-osm-postgis-diff.yml)

## Como o app usa isso em produção

### GraphHopper

Em produção, configure:

- `routing.graphhopper.local=false`
- `routing.graphhopper.s3.bucket=routing-data`
- `routing.graphhopper.s3.prefix=graphhopper/brazil-latest`

Quando subir, a aplicação:

1. baixa o grafo pronto do S3
2. grava em `data/graph-cache`
3. carrega o cache sem rebuild do `.pbf`

### OSM/PostGIS

O app não importa OSM diretamente em produção.
Quem faz isso é o fluxo:

- GitHub Actions → S3 → CodeBuild → RDS

## Arquivos principais deste processo

- [import-local.ps1](/E:/014-routing/rivo/infra/osm2pgsql/import-local.ps1)
- [osm2pgsql-flex.lua](/E:/014-routing/rivo/infra/osm2pgsql/osm2pgsql-flex.lua)
- [osm-import-buildspec.yml](/E:/014-routing/rivo/infra/codebuild/osm-import-buildspec.yml)
- [config.yml](/E:/014-routing/rivo/infra/graphhopper/config.yml)
- [codebuild-routing-policy.json](/E:/014-routing/rivo/infra/iam/codebuild-routing-policy.json)
- [provision-routing-stack.ps1](/E:/014-routing/rivo/infra/aws/provision-routing-stack.ps1)
- [AWS setup kit](/E:/014-routing/rivo/infra/aws/README.md)
## Logs e rollback do provisionamento AWS

O fluxo AWS centralizado em [provision-routing-stack.ps1](/E:/014-routing/rivo/infra/aws/provision-routing-stack.ps1) agora gera um arquivo de log por execucao em `infra/aws/logs/`.

Se houver erro na criacao, atualizacao ou vinculacao de recursos AWS, o script:

1. registra a falha no `.log`
2. executa rollback automatico em ordem reversa
3. preserva recursos que ja existiam antes da execucao

Na pratica, isso cobre tanto recursos novos quanto restauracao de estado em itens que podem ser atualizados no caminho, como `Parameter Store`, inline policy do `CodeBuild` e configuracao do projeto `CodeBuild`.

A configuracao opcional de `GitHub Secrets/Variables` fica fora da transacao AWS: ela roda apenas depois da validacao final da infra e, se falhar, o erro fica no log sem destruir a infra que ja foi provisionada com sucesso.
