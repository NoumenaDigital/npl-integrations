FROM ghcr.io/noumenadigital/packages/engine:2024.1.7

LABEL org.opencontainers.image.source = "https://github.com/noumenadigital/npl-integrations"

ENV ENGINE_NPL_MIGRATION_DIRECTORY_PATH="/npl" \
    FEATURE_APPLY_NPL_MIGRATIONS_AT_STARTUP="true"

COPY src/main/yaml /npl/yaml
COPY src/main/npl  /npl/npl-1.0
