# Network and resource binding for Rivo

Este documento existe só como referência do que o script único cria e vincula.

Executável AWS único:

- [provision-routing-stack.ps1](/E:/014-routing/rivo/infra/aws/provision-routing-stack.ps1)

## Comando único

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 -DbPassword 'SUA_SENHA_FORTE'
```

## O que ele cria e vincula

- `rivo-vpc`
- `rivo-igw`
- `rivo-public-a`, `rivo-public-b`
- `rivo-app-a`, `rivo-app-b`
- `rivo-db-a`, `rivo-db-b`
- `rivo-rt-public`, `rivo-rt-app`, `rivo-rt-db`
- `rivo-nat`
- `rivo-rds-sg`
- `rivo-codebuild-sg`
- `rivo-app-sg`
- `rivo-alb-sg`
- `rivo-rds-subnet-group`
- `rivo-routing-db`
- `routing-data`
- `codebuild-routing-role`
- `osm-postgis-import`
- `/routing/rds/host`
- `/routing/rds/dbname`
- `/routing/rds/user`
- `/routing/rds/password`

## Como os vínculos ficam

- `rivo-igw` anexa em `rivo-vpc`
- `rivo-rt-public` associa em `rivo-public-a/b`
- `rivo-rt-app` associa em `rivo-app-a/b`
- `rivo-rt-db` associa em `rivo-db-a/b`
- `rivo-nat` fica em `rivo-public-a`
- `rivo-rds-subnet-group` usa `rivo-db-a/b`
- `rivo-routing-db` usa `rivo-rds-subnet-group` + `rivo-rds-sg`
- `osm-postgis-import` usa `rivo-vpc` + `rivo-app-a/b` + `rivo-codebuild-sg`
- backend `rivo`, se rodar na AWS, deve usar `rivo-app-a/b` + `rivo-app-sg`
- `ALB`, se existir, deve usar `rivo-public-a/b` + `rivo-alb-sg`

## Opcional: GitHub no mesmo fluxo

```powershell
cd E:\014-routing\rivo
.\infra\aws\provision-routing-stack.ps1 `
  -DbPassword 'SUA_SENHA_FORTE' `
  -ConfigureGitHubSecrets `
  -GitHubRepo 'OWNER/REPO' `
  -GitHubAwsAccessKeyId 'AKIA...' `
  -GitHubAwsSecretAccessKey '...'
```