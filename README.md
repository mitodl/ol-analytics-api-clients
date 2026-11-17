# ol-analytics-api clients

This repo contains the generated TypeScript clients for [ol-analytics-api](https://github.com/mitodl/ol-analytics-api). Each tenant of that service publishes its own OpenAPI spec under `openapi/specs/`, and each spec is packaged separately:

| Spec                       | Package                                          |
| -------------------------- | ------------------------------------------------ |
| `b2b_dashboard.yaml`       | `@mitodl/ol-analytics-dashboard-api-axios`       |
| `b2b_learner_records.yaml` | `@mitodl/ol-analytics-learner-records-api-axios` |

The two tenants have different auth and audiences (an org-manager dashboard vs. a machine-to-machine partner integration), so a consumer of one does not pull in the other's types.

Generated paths already carry the tenant's mount prefix (e.g. `/api/v1/analytics/...`), so configure the client's `basePath` (or the axios instance's `baseURL`) as the service host only.

## Releases

Clients are generated and published by the `ol-analytics-api-api-client` pipeline, defined in [ol-infrastructure](https://github.com/mitodl/ol-infrastructure) (`src/ol_concourse/pipelines/libraries/api_clients_pipeline.py`). It runs when an ol-analytics-api release reaches Production, on the release's `production/<version>` tag, so a published version is one that is ready to use, and a release that is cut and then abandoned publishes nothing. It publishes only when the regenerated client differs from the one committed here; a release that leaves the client as it was publishes nothing.

The client version is the release's, not the date it was published. Both packages share the repo-root `VERSION`, which the pipeline sets from the release tag, together with each `package.json`, before committing the regenerated sources. The minor is the month followed by the two-digit day:

| Release tag    | Client version |
| -------------- | -------------- |
| `2026.11.16.1` | `2026.1116.1`  |
| `2026.11.16.2` | `2026.1116.2`  |
| `2027.1.5.1`   | `2027.105.1`   |

These sort above the `YYYY.M.D` versions published before (`2026.11.12` < `2026.1116.1`). A release that does not change the client has no client version, so the published versions skip releases.

Each generator config in `config/` maps one spec to one package. A new tenant needs a config here, a package directory under `src/typescript/` (with its sources committed, since the pipeline only stages files it already tracks), and the package name added to `client_repo_subpath` in ol-infrastructure's `PIPELINE_CONFIGS`.

## Development

Code checks run with [prek](https://prek.j178.dev/), which reads `.pre-commit-config.yaml`. The `prek` check runs the same hooks on pull requests, and [autofix.ci](https://autofix.ci/) pushes a commit with any fixes they make.

```sh
uv tool install prek==0.5.3
prek install -f
prek run --all-files
```

To generate the clients locally, run `./scripts/local-generate.sh`. It generates from the newest ol-analytics-api release tag unless `SOURCE_REF` names another ref (a branch or a SHA works), and uses the openapi-generator version recorded in `src/typescript/ol-analytics-dashboard-api-axios/src/.openapi-generator/VERSION` on `origin/main` unless `GENERATOR_VERSION` is set.
