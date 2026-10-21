FROM --platform=$BUILDPLATFORM debian:13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS build
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64 || { echo 'Only linux/amd64 is supported' >&2; exit 1; }
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils
ARG DOTNET_VERSION
RUN set -eu; \
    curl -fsSL "https://builds.dotnet.microsoft.com/dotnet/Sdk/${DOTNET_VERSION}/dotnet-sdk-${DOTNET_VERSION}-linux-x64.tar.gz" -o /sdk.tar.gz; \
    mkdir -p /out/opt/sandbox-kits/dotnet/$DOTNET_VERSION; \
    tar -xzf /sdk.tar.gz -C /out/opt/sandbox-kits/dotnet/$DOTNET_VERSION; \
    chown -R 0:0 /out
FROM scratch
ARG DOTNET_VERSION
COPY --from=build /out/ /
ENV DOTNET_ROOT=/opt/sandbox-kits/dotnet/${DOTNET_VERSION}
