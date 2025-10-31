################################################################################
# hyprutils v0.10.0
# Hyprland utilities library used across the ecosystem
###############################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprutils
LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprutils"

ARG VERSION=0.10.0

# ---- Build from source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprutils.git
WORKDIR /build/hyprutils

RUN cmake -B build -S . \
      -G Ninja \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package runtime ----
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libhyprutils9
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprutils
Description: Utilities used across the Hyprland ecosystem (runtime library)
EOF

RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libhyprutils9_${VERSION}_amd64.deb

# ---- Package -dev ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libhyprutils-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprutils
Depends: libhyprutils9 (= ${VERSION})
Description: Development files for libhyprutils
EOF

RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include        /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libhyprutils-dev_${VERSION}_amd64.deb

# ---- Meta package ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprutils
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprutils
Depends: libhyprutils9 (= ${VERSION})
Description: Hyprutils meta package for Hyprland ecosystem
EOF

RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprutils_${VERSION}_all.deb

