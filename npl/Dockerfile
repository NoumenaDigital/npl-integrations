FROM ghcr.io/noumenadigital/packages/engine:2024.2.12

LABEL org.opencontainers.image.source = "https://github.com/noumenadigital/npl-integrations"

ENV ENGINE_NPL_MIGRATION_DIRECTORY_PATH="/npl"

COPY src/main/yaml /npl/yaml
COPY src/main/npl-1.0  /npl/npl-1.0
COPY npl-contrib /npl-contrib
COPY npl-contrib.properties /
