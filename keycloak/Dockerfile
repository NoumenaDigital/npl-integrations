# XXX: https://github.com/keycloak/keycloak/issues/17606 -- Keycloak v21+ removes SHA-1 support.
# The certificate check is enforced via ?sslmode=verify-full in KC_DB_URL.
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-update-client-certificates-java#updating-root-ca-certificates-for-other-clients-for-certificate-pinning-scenarios
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-ssl-tls#downloading-root-ca-certificates-and-updating-application-clients-in-certificate-pinning-scenarios
FROM alpine AS alpine
RUN \
	apk add openssl && \
	wget -O /tmp/DigiCertGlobalRootCA.crt.pem  https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem && \
	wget -O /tmp/ms.crt --user-agent="curl/8.1.2"  https://www.microsoft.com/pkiops/certs/Microsoft%20RSA%20Root%20Certificate%20Authority%202017.crt && \
	wget -O /tmp/ms2.crt --user-agent="curl/8.1.2" https://www.microsoft.com/pkiops/certs/Microsoft%20Azure%20RSA%20TLS%20Issuing%20CA%2003%20-%20xsign.crt && \
    wget -O /tmp/ms3.crt --user-agent="curl/8.1.2" https://www.microsoft.com/pkiops/certs/Microsoft%20Azure%20RSA%20TLS%20Issuing%20CA%2007%20-%20xsign.crt && \
	openssl x509 -outform PEM -in /tmp/ms.crt -out /tmp/ms.crt.pem && \
    openssl x509 -outform PEM -in /tmp/ms2.crt -out /tmp/ms2.crt.pem && \
    openssl x509 -outform PEM -in /tmp/ms3.crt -out /tmp/ms3.crt.pem && \
	cat /tmp/DigiCertGlobalRootCA.crt.pem /tmp/ms.crt.pem /tmp/ms2.crt.pem /tmp/ms3.crt.pem > /tmp/combined.pem

# https://github.com/keycloak/keycloak/blob/d70dd9db67ae4a803dd270f2941af1a3cffe9503/docs/guides/server/containers.adoc#installing-additional-rpm-packages
# curl is necessary for health checks run inside the container by nomad/docker-compose

FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y; dnf --installroot /mnt/rootfs clean all

FROM quay.io/keycloak/keycloak:25.0.4

COPY --from=ubi-micro-build /mnt/rootfs /
# Restore the keycloak user and group created by the base container and overwritten during copying rootfs
USER root
RUN /bin/sh -c echo "keycloak:x:0:root" >> /etc/group && echo "keycloak:x:1000:0:keycloak user:/opt/keycloak:/sbin/nologin" >> /etc/passwd
USER keycloak

COPY --chmod=644 --from=alpine /tmp/combined.pem /opt/keycloak/.postgresql/root.crt

RUN \
    mkdir -p /opt/keycloak/data/password-blacklists && cd /opt/keycloak/data/password-blacklists/ && \
    curl https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt > tmp.txt && \
    grep -E '^.{14,}$' /opt/keycloak/data/password-blacklists/tmp.txt > password_blacklist.txt && \
    rm -rf tmp.txt

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
