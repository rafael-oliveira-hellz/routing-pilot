# AWS setup kit

Este diretÃ³rio deixa o setup da AWS mais operacional para o `rivo`.

## Arquivos deste kit

- `provision-routing-stack.ps1`
  - executa toda a ordem principal sozinho: rede, RDS, bucket, Parameter Store, role do CodeBuild, projeto CodeBuild e validaÃ§Ã£o.
- `codebuild-trust-policy.json`
  - trust policy da role do CodeBuild.
- `github-actions-routing-policy.json`
  - policy para o usuario/role usado pelo GitHub Actions.
- `post-deploy-checklist.md`
  - checklist de validaÃ§Ã£o depois do setup.
- `network-bootstrap.md`
  - playbook de referÃªncia dos vÃ­nculos criados pelo script Ãºnico.

## Script Ãºnico recomendado

Use:

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 -DbPassword 'SUA_SENHA_FORTE'
```

Esse script faz, nesta ordem:

1. cria ou reaproveita a rede base do `rivo`
2. cria ou reaproveita o `RDS`
3. pega o endpoint real do `RDS`
4. cria ou atualiza bucket, Parameter Store, role do CodeBuild e projeto CodeBuild
5. valida a infra
6. imprime o resumo final com IDs e endpoint

## Parametros principais

ObrigatÃ³rio:

- `DbPassword`

Opcionais mais usados:

- `ProjectName` default `rivo`
- `AwsRegion` default `sa-east-1`
- `DbInstanceIdentifier` default `rivo-routing-db`
- `DbInstanceClass` default `db.t4g.large`
- `DbAllocatedStorage` default `200`
- `BucketName` default `routing-data`
- `CodeBuildProjectName` default `osm-postgis-import`

## Exemplo com customizaÃ§Ã£o

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 `
  -AwsRegion 'sa-east-1' `
  -DbPassword 'SUA_SENHA_FORTE' `
  -DbInstanceClass 'db.t4g.large' `
  -DbAllocatedStorage 300
```

## Opcional: configurar GitHub Secrets no mesmo script

Se vocÃª tiver o `gh` autenticado:

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 `
  -DbPassword 'SUA_SENHA_FORTE' `
  -ConfigureGitHubSecrets `
  -GitHubRepo 'OWNER/REPO' `
  -GitHubAwsAccessKeyId 'AKIA...' `
  -GitHubAwsSecretAccessKey '...'
```

Isso seta:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## O que o script Ãºnico vincula automaticamente

- `rivo-igw` na `rivo-vpc`
- route tables nas subnets corretas
- `rivo-nat` em subnet pÃºblica
- `rivo-rds-subnet-group` nas subnets `rivo-db-*`
- `rivo-rds-sg` no `RDS`
- `rivo-codebuild-sg` no `CodeBuild`
- `CodeBuild` nas subnets `rivo-app-*`
- `Parameter Store` com o endpoint real do `RDS`
- role `codebuild-routing-role` no projeto `osm-postgis-import`

## Workflows ativos no GitHub

Como o git root Ã© `E:\014-routing`, os workflows que o GitHub vai executar ficam na raiz do repo:

- `.github/workflows/rivo-ci.yml`
- `.github/workflows/rivo-graphhopper-build.yml`
- `.github/workflows/rivo-osm-postgis-full-import.yml`
- `.github/workflows/rivo-osm-postgis-diff.yml`

## ObservaÃ§Ãµes

- O script Ãºnico nÃ£o executa os workflows do GitHub; ele prepara a AWS para eles.
- Se vocÃª nÃ£o usar `-ConfigureGitHubSecrets`, o script vai te lembrar no final quais secrets configurar manualmente.
- O `CodeBuild` roda em subnets privadas `rivo-app-*` sem IP publico. Como o build atual faz download de pacotes (`yum`, `pip`) e arquivos externos/S3, ele precisa de saida para a internet. No desenho atual essa saida e feita via `NAT Gateway`; sem isso o build nao consegue baixar dependencias nem arquivos remotos.
## Logs e rollback

O `provision-routing-stack.ps1` agora grava um log por execucao em:

- `infra/aws/logs/provision-YYYYMMDD-HHmmss.log`

Se ocorrer erro durante a criacao, atualizacao ou vinculacao de recursos da AWS, o script:

1. registra o erro no `.log`
2. dispara rollback em ordem reversa
3. desfaz apenas o que foi criado ou alterado nesta execucao

Comportamento de rollback:

- recursos reaproveitados continuam intactos
- recursos novos criados nesta execucao sao removidos
- parametros do `SSM Parameter Store` preexistentes sao restaurados ao valor anterior
- a inline policy da role do `CodeBuild`, se ja existia, eh restaurada
- o projeto do `CodeBuild`, se ja existia, eh restaurado ao snapshot capturado antes da alteracao
- qualquer falha durante o rollback tambem fica registrada no mesmo `.log`

Limite importante:

- a etapa opcional de `GitHub Secrets/Variables` roda so depois da AWS validar com sucesso
- se essa etapa falhar, a infra AWS ja provisionada nao eh destruida automaticamente, porque secrets do GitHub nao permitem restauracao segura do valor anterior

