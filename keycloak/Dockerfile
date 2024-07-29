# XXX: https://github.com/keycloak/keycloak/issues/17606 -- Keycloak v21+ removes SHA-1 support.
# The certificate check is enforced via ?sslmode=verify-full in KC_DB_URL.

# https://github.com/keycloak/keycloak/blob/d70dd9db67ae4a803dd270f2941af1a3cffe9503/docs/guides/server/containers.adoc#installing-additional-rpm-packages
# curl is necessary for health checks run inside the container by nomad/docker-compose
FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y; dnf --installroot /mnt/rootfs clean all

FROM quay.io/keycloak/keycloak:23.0.2

COPY --from=ubi-micro-build /mnt/rootfs /
# Restore the keycloak user and group created by the base container and overwritten during copying rootfs
USER root
RUN /bin/sh -c echo "keycloak:x:0:root" >> /etc/group && echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd
USER keycloak

ADD --chmod=644 --chown=root:root https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem /opt/keycloak/.postgresql/root.crt

ARG BUILD_DATE
ARG GIT_REV
ARG VERSION

LABEL org.opencontainers.image.source = "https://github.com/NoumenaDigital/npl-integrations" \
    org.label-schema.name="keycloak" \
    org.label-schema.vendor="Noumena Digital" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.vcs-ref="${GIT_REV}" \
    org.label-schema.version="${VERSION}"

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]
