################################################################################
# 7️⃣ aquamarine v$0.9.5
# Hyprland's rendering + composition backend (EGL/DRM abstraction layer)
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS aquamarine

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/aquamarine"

# ---- Bring in previously built dependencies (.deb packages) ----
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils            /out /deps
COPY --from=hyprlang             /out /deps
COPY --from=hyprgraphics         /out /deps
COPY --from=hyprcursor		/out /deps

ARG VERSION=0.9.5

# ---- Install dependencies ----
RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Clone source (latest tag) ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/aquamarine.git
WORKDIR /build/aquamarine

# ---- Build ----
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package 1: runtime (libaquamarine8) ----
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libaquamarine8
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/aquamarine
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4), libhyprgraphics1 (>= 0.2.0), hyprwayland-scanner (>= 0.4.5)
Description: Aquamarine rendering + composition backend (runtime library)
 EGL/DRM abstractions and rendering utilities used by Hyprland.
EOF

RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libaquamarine8_${VERSION}_amd64.deb

# ---- Package 2: dev (libaquamarine-dev) ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libaquamarine-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/aquamarine
Depends: libaquamarine8 (= ${VERSION}), libhyprutils-dev (>= 0.10.0), libhyprlang-dev (>= 0.6.4), libhyprgraphics-dev (>= 0.2.0)
Provides: aquamarine-dev
Description: Development files for libaquamarine
 Headers, pkg-config and CMake files to build against libaquamarine.
EOF
RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include        /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake     /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libaquamarine-dev_${VERSION}_amd64.deb

# ---- Package 3: meta (aquamarine) ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: aquamarine
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/aquamarine
Depends: libaquamarine8 (= ${VERSION})
Description: Aquamarine meta package
 Pulls in the Aquamarine runtime library used by Hyprland.
EOF
RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/aquamarine_${VERSION}_all.deb

RUN echo "✅ Built and packaged aquamarine ${VERSION} (SONAME libaquamarine.so.8)"

