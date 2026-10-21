FROM --platform=$BUILDPLATFORM debian:13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS build
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64 || { echo 'Only linux/amd64 is supported' >&2; exit 1; }
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl
ARG ASPIRE_VERSION
RUN set -eu; \
    curl -fsSL "https://github.com/microsoft/aspire/releases/download/v${ASPIRE_VERSION}/aspire-cli-linux-x64-${ASPIRE_VERSION}.tar.gz" -o /aspire.tar.gz; \
    mkdir -p "/out/opt/sandbox-kits/aspire/$ASPIRE_VERSION"; \
    tar -xzf /aspire.tar.gz -C "/out/opt/sandbox-kits/aspire/$ASPIRE_VERSION"; \
    chown -R 0:0 /out
FROM scratch
ARG ASPIRE_VERSION
COPY --from=build /out/ /
ENV ASPIRE_ROOT=/opt/sandbox-kits/aspire/${ASPIRE_VERSION}
