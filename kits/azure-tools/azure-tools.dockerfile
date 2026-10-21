FROM --platform=$BUILDPLATFORM debian:13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS build
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64 || { echo 'Only linux/amd64 is supported' >&2; exit 1; }
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils
ARG AZURE_VERSION
ARG AZD_VERSION
ARG BICEP_VERSION
# Azure's package carries its own Python. Extract only that relocatable payload
# and notices; native Debian dependencies are installed on the composed base.
RUN set -eu; \
    curl -fsSL "https://packages.microsoft.com/repos/azure-cli/pool/main/a/azure-cli/azure-cli_${AZURE_VERSION}-1~bookworm_amd64.deb" -o /az.deb; \
    dpkg-deb -x /az.deb /extract; \
    mkdir -p /out/opt/sandbox-kits/azure/bin /out/opt/sandbox-kits/azure/notices /out/opt; \
    cp -a /extract/opt/az /out/opt/az; \
    cp -a /extract/usr/share/doc/azure-cli /out/opt/sandbox-kits/azure/notices/; \
    curl -fsSL "https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_${AZD_VERSION}/azd-linux-amd64.tar.gz" -o /azd.tar.gz; \
    mkdir /azd; tar -xzf /azd.tar.gz -C /azd; \
    cp /azd/azd-linux-amd64 /out/opt/sandbox-kits/azure/bin/azd; \
    cp /azd/NOTICE.txt /out/opt/sandbox-kits/azure/notices/azd-NOTICE.txt; \
    curl -fsSL "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-x64" -o /out/opt/sandbox-kits/azure/bin/bicep; \
    chmod 755 /out/opt/sandbox-kits/azure/bin/*; \
    chown -R 0:0 /out
COPY --chmod=755 az /out/opt/sandbox-kits/azure/bin/az
FROM scratch
COPY --from=build /out/ /
ENV AZURE_BICEP_USE_BINARY_FROM_PATH=true
ENV AZD_SKIP_UPDATE_CHECK=1
