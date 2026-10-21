FROM --platform=$BUILDPLATFORM debian:13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS build
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64 || { echo 'Only linux/amd64 is supported' >&2; exit 1; }
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils libatomic1
ARG NODE_VERSION
ARG COREPACK_VERSION
RUN set -eu; \
    prefix=/out/opt/sandbox-kits/node/$NODE_VERSION; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /node.tar.xz; \
    mkdir -p "$prefix"; tar -xJf /node.tar.xz -C "$prefix" --strip-components=1; \
    rm -rf "$prefix/lib/node_modules/corepack"; \
    curl -fsSL "https://registry.npmjs.org/corepack/-/corepack-${COREPACK_VERSION}.tgz" -o /corepack.tgz; \
    mkdir -p "$prefix/lib/node_modules/corepack"; \
    tar -xzf /corepack.tgz -C "$prefix/lib/node_modules/corepack" --strip-components=1; \
    ln -sfn ../lib/node_modules/corepack/dist/corepack.js "$prefix/bin/corepack"; \
    PATH="$prefix/bin:$PATH" "$prefix/bin/node" "$prefix/bin/corepack" enable --install-directory "$prefix/bin"; \
    test "$("$prefix/bin/node" --version)" = "v$NODE_VERSION"; \
    test "$(PATH="$prefix/bin:$PATH" "$prefix/bin/corepack" --version)" = "$COREPACK_VERSION"; \
    chown -R 0:0 /out
FROM scratch
ARG NODE_VERSION
COPY --from=build /out/ /
ENV NODE_ROOT=/opt/sandbox-kits/node/${NODE_VERSION}
