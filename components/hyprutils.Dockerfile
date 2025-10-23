################################################################################
# 2️⃣ hyprutils v0.10.0
# Core utilities library used across the Hyprland ecosystem
################################################################################

# Start from your previously built base image
FROM hyprland-base AS hyprutils

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprutils"

# --- Prepare workspace ---
RUN mkdir -p /build /out
WORKDIR /build

# --- Clone source ---
RUN git clone --depth=1 --branch v0.10.0 https://github.com/hyprwm/hyprutils.git
WORKDIR /build/hyprutils

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -S . -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package as .deb (runtime + dev + meta) ---
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    printf "Package: libhyprutils6\n" > /tmp/deb-lib/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libpixman-1-0 (>= 0.42)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Description: Utilities used across the Hyprland ecosystem (runtime library)\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprutils6_0.10.0_amd64.deb && \
    \
    mkdir -p /tmp/deb-dev/DEBIAN && \
    printf "Package: libhyprutils-dev\n" > /tmp/deb-dev/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Section: libdevel\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Depends: libhyprutils6 (= 0.10.0)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Description: Utilities used across the Hyprland ecosystem (development headers)\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprutils-dev_0.10.0_amd64.deb && \
    \
    mkdir -p /tmp/deb-meta/DEBIAN && \
    printf "Package: hyprutils\n" > /tmp/deb-meta/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Section: misc\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Architecture: all\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Depends: libhyprutils6 (= 0.10.0)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Description: Hyprutils meta package for Hyprland ecosystem\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprutils_0.10.0_all.deb

RUN echo "✅ Built and packaged hyprutils v0.10.0"
