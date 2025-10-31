################################################################################
# 5️⃣ hyprgraphics v${VERSION}
# GPU/Color utilities used across Hyprland stack
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprgraphics

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprgraphics"

# ---- Bring in deps built earlier ----
# hyprutils:   common helpers (CMake, headers)
# hyprlang:    config / parsing utilities
# hyprcursor:  required in recent hyprgraphics
# hyprwayland-scanner: protocol scanner used by projects in the stack
# hyprland-protocols: XML protocol files
COPY --from=hyprutils            /out /deps
COPY --from=hyprlang             /out /deps
COPY --from=hyprcursor           /out /deps
COPY --from=hyprwayland-scanner  /out /deps
COPY --from=hyprland-protocols   /out /deps

ARG VERSION=0.2.0

# ---- Install deps ----
RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Clone source (latest tag) ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprgraphics.git
WORKDIR /build/hyprgraphics

# ---- Build ----
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package 1: runtime (libhyprgraphics1) ----
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libhyprgraphics1
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprgraphics
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4), libhyprcursor1 (>= 0.1.10)
Description: Hyprgraphics - graphics/color helpers for Hyprland (runtime)
 Provides GPU/color utilities used across the Hyprland ecosystem.
EOF
RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libhyprgraphics1_${VERSION}_amd64.deb

# ---- Package 2: dev (libhyprgraphics-dev) ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libhyprgraphics-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprgraphics
Depends: libhyprgraphics1 (= ${VERSION}), libhyprutils-dev (>= 0.10.0), libhyprlang-dev (>= 0.6.4), libhyprcursor-dev (>= 0.1.10)
Description: Development files for libhyprgraphics
 Headers, pkg-config and CMake files to build against libhyprgraphics.
EOF
RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake     /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libhyprgraphics-dev_${VERSION}_amd64.deb

# ---- Package 3: meta (hyprgraphics) ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprgraphics
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprgraphics
Depends: libhyprgraphics1 (= ${VERSION})
Description: Hyprgraphics meta package
 Pulls in the libhyprgraphics runtime library.
EOF
RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprgraphics_${VERSION}_all.deb

RUN echo "✅ Built and packaged hyprgraphics ${VERSION} (SONAME libhyprgraphics.so.1)"

