################################################################################
# 4️⃣ hyprlang v${VERSION}
# Fast and user-friendly configuration language for the Hyprland ecosystem
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprlang

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprlang"

ARG VERSION=0.6.4

# --- Dependencies: hyprutils (for linking and CMake config) ---
COPY --from=hyprutils /out /deps
RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprlang.git
WORKDIR /build/hyprlang

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package 1️⃣: Runtime library (libhyprlang2) ---
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libhyprlang2
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprlang
Depends: libc6 (>= 2.34), libstdc++6 (>= 12)
Description: Fast and user-friendly configuration language (runtime library)
 Hyprlang provides an efficient and user-friendly configuration
 language parser used throughout the Hyprland ecosystem.
EOF
RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libhyprlang2_${VERSION}_amd64.deb

# --- Package 2️⃣: Development headers (libhyprlang-dev) ---
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libhyprlang-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprlang
Depends: libhyprlang2 (= ${VERSION}), libhyprutils-dev (>= 0.10.0)
Provides: hyprlang-dev
Description: Fast and user-friendly configuration language (development files)
 This package provides headers, CMake configuration and pkg-config
 files required to build software against the Hyprlang library.
EOF
RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake /tmp-deb/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libhyprlang-dev_${VERSION}_amd64.deb

# --- Package 3️⃣: Meta-package (hyprlang) ---
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprlang
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprlang
Depends: libhyprlang2 (= ${VERSION})
Description: Fast and user-friendly configuration language (metapackage)
 This metapackage depends on the Hyprlang runtime library required
 by other components of the Hyprland ecosystem.
EOF
RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprlang_${VERSION}_all.deb

RUN echo "✅ Built and packaged hyprlang v${VERSION}"
