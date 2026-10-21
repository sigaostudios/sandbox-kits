ARG UPSTREAM_WORKLOAD
FROM ${UPSTREAM_WORKLOAD}
ARG TARGETARCH
USER root
COPY packages.txt /usr/share/sandbox-kits/native-dependencies.requested
COPY verify-packages.py /usr/share/sandbox-kits/verify-packages.py
RUN set -eu; \
    . /etc/os-release; \
    [ "$ID:$VERSION_ID:$TARGETARCH" = debian:13:amd64 ] || { echo 'This kit requires Debian 13 linux/amd64' >&2; exit 1; }; \
    python3 --version; \
    cp /var/lib/dpkg/status /usr/share/sandbox-kits/dpkg-status.before; \
    apt-get -o APT::Update::Error-Mode=any update; \
    xargs -r apt-get install -y --no-install-recommends --no-upgrade --no-remove < /usr/share/sandbox-kits/native-dependencies.requested; \
    python3 /usr/share/sandbox-kits/verify-packages.py; \
    test -z "$(dpkg --audit)"; \
    xargs dpkg-query -W -f='${binary:Package}\t${Version}\t${Status}\n' < /usr/share/sandbox-kits/native-dependencies.requested > /usr/share/sandbox-kits/native-dependencies.installed; \
    dpkg-query -W -f='${binary:Package}\t${Version}\t${Status}\n' > /usr/share/sandbox-kits/dpkg-installed-at-build; \
    sha256sum /var/lib/dpkg/status > /usr/share/sandbox-kits/dpkg-status.sha256; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb
