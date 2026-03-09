# Post-deploy checklist

## 1. S3

- Bucket `routing-data` existe.
- Prefixos `osm/` e `graphhopper/` existem ou serao criados pelos workflows.
- Depois do `graphhopper-build`, existe `graphhopper/brazil-latest/` com arquivos do grafo.
- Depois do `osm-postgis-full-import`, o upload temporario de `osm/brazil-latest.osm.pbf` foi consumido e removido.

## 2. Parameter Store

Confirme os parametros:

- `/routing/rds/host`
- `/routing/rds/dbname`
- `/routing/rds/user`
- `/routing/rds/password`

## 3. IAM

- Role `codebuild-routing-role` existe.
- A role tem trust policy para `codebuild.amazonaws.com`.
- A role tem policy com acesso a S3, SSM, CloudWatch Logs e ENI/VPC.
- O usuario/role do GitHub Actions tem policy para S3 e CodeBuild.

## 4. CodeBuild

- Projeto `osm-postgis-import` existe.
- Projeto esta na mesma VPC do RDS.
- Projeto usa subnet com acesso ao RDS.
- Projeto usa SG proprio.
- Timeout esta em `180` minutos.
- Compute type esta em `BUILD_GENERAL1_LARGE`.

## 5. RDS / Rede

- SG do RDS permite entrada na `5432` a partir do SG do CodeBuild.
- O banco possui `postgis` e `pg_trgm` habilitados.
- O usuario do banco informado no Parameter Store consegue conectar.

## 6. GitHub

- Secret `AWS_ACCESS_KEY_ID` configurado.
- Secret `AWS_SECRET_ACCESS_KEY` configurado.
- Variable `AWS_REGION=sa-east-1` configurada.
- Workflows na raiz do repo existem em `.github/workflows`.

## 7. Primeira execucao manual

Rode nesta ordem:

1. `rivo-graphhopper-build`
2. `rivo-osm-postgis-full-import`

## 8. Validacao funcional

- No S3, existe `graphhopper/brazil-latest/`.
- No CodeBuild, o build terminou com `SUCCEEDED`.
- No RDS, as tabelas `geo.osm_*` foram populadas.
- O backend sobe com `routing.graphhopper.local=false` e carrega o grafo do S3.