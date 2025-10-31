##############################################################
# hyprwire v0.1.1
# A fast and consistent wire protocol for IPC 
##############################################################
FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprwire

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprwire"

ARG VERSION=0.1.1
ENV DEBIAN_FRONTEND=noninteractive

# --- Bring in hyprutils build artifacts from prior stage ---
COPY --from=hyprutils /out /deps
COPY --from=hyprutils /build/hyprutils/include /usr/include/hyprutils

# --- Install build deps from Trixie + sid toolchain ---
RUN set -eux; \
    echo 'deb http://deb.debian.org/debian sid main' > /etc/apt/sources.list.d/sid.list; \
    printf 'Package: *\nPin: release a=sid\nPin-Priority: 100\n\n' > /etc/apt/preferences.d/99sid; \
    printf 'Package: gcc-15 g++-15 libstdc++-15-dev\nPin: release a=sid\nPin-Priority: 990\n' >> /etc/apt/preferences.d/99sid; \
    apt-get update; \
    apt-get install -y --no-install-recommends gcc-15 g++-15 libstdc++-15-dev pkg-config cmake ninja-build git dpkg-dev; \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 50; \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-15 50; \
    dpkg -i /deps/*.deb || apt-get -fy install; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprwire.git

WORKDIR /build/hyprwire

# --- Build Hyprwire ---
RUN cmake -B build -S . \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ------------------------------------------------------------
# Split into proper Debian binary packages
# ------------------------------------------------------------
RUN bash -c 'mkdir -p /tmp/{lib,dev,main}/DEBIAN'

# 1️⃣ Library package (libhyprwire0)
RUN mkdir -p /tmp/lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/lib/usr/ && \
    rm -f /tmp/lib/usr/lib/pkgconfig/*.pc || true && \
    cat > /tmp/lib/DEBIAN/control <<EOF
Package: libhyprwire0
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprwire
Description: Hyprwire shared library for Hyprland components
Depends: libc6 (>= 2.38), libstdc++6 (>= 13)
EOF

# 2️⃣ Development headers (libhyprwire-dev)
RUN mkdir -p /tmp/dev/usr && \
    cp -a /tmp/pkg/usr/include /tmp/dev/usr/ && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/dev/usr/lib/ || true && \
    cat > /tmp/dev/DEBIAN/control <<EOF
Package: libhyprwire-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Depends: libhyprwire0 (= ${VERSION}), libhyprutils-dev (>= 0.10.0)
Description: Development headers and pkg-config for Hyprwire
EOF

# 3️⃣ Main runtime package (hyprwire)
# Move only binaries, docs, etc.
RUN mkdir -p /tmp/main/usr && \
    cp -a /tmp/pkg/usr/bin /tmp/main/usr/ && \
    # Remove from library package if duplicated
    rm -f /tmp/lib/usr/bin/hyprwire-scanner || true && \
    cat > /tmp/main/DEBIAN/control <<EOF
Package: hyprwire
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Description: Hyprwire runtime utilities and CLI tools
Depends: libhyprwire0 (= ${VERSION}), libc6 (>= 2.38)
Replaces: libhyprwire0 (<= 0.1.0)
Breaks: libhyprwire0 (<= 0.1.0)
EOF

# --- Build all .debs ---
RUN mkdir -p /out && \
    dpkg-deb --build --root-owner-group /tmp/lib /out/libhyprwire0_${VERSION}_amd64.deb && \
    dpkg-deb --build --root-owner-group /tmp/dev /out/libhyprwire-dev_${VERSION}_amd64.deb && \
    dpkg-deb --build --root-owner-group /tmp/main /out/hyprwire_${VERSION}_amd64.deb

CMD ["bash", "-c", "ls -lh /out"]

