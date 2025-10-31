################################################################################
# 6️⃣ hyprcursor v0.1.11
# Cursor management and theme library for Hyprland
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprcursor

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprcursor"

ARG VERSION=0.1.13

# ---- Bring in dependency packages ----
COPY --from=hyprutils /out /deps
COPY --from=hyprlang  /out /deps

RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Fetch source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprcursor.git
WORKDIR /build/hyprcursor

# ---- Build ----
RUN cmake -B build -S . \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package 1: runtime ----
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libhyprcursor1
Version: 0.1.11
Section: libs
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprcursor
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4)
Description: Hyprcursor - Cursor management and theme library for Hyprland (runtime)
EOF

RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libhyprcursor1_${VERSION}_amd64.deb

# ---- Package 2: development ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libhyprcursor-dev
Version: 0.1.11
Section: libdevel
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprcursor
Depends: libhyprcursor1 (= 0.1.11)
Description: Development headers and pkg-config files for Hyprcursor
EOF

RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include        /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake     /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libhyprcursor-dev_${VERSION}_amd64.deb

# ---- Meta package ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprcursor
Version: 0.1.11
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprcursor
Depends: libhyprcursor1 (= 0.1.11)
Description: Hyprcursor meta package
EOF

RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprcursor_${VERSION}_all.deb

RUN echo "✅ Built and packaged hyprcursor ${VERSION} (SONAME libhyprcursor.so.1)"

