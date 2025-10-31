################################################################################
# 🌀 Hyprland v${VERSION}
# Main compositor – built against all upstream Hypr libraries
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprland

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/Hyprland"

# ---- Version pins ----
ARG VERSION=0.49.0
ARG VERSION=${VERSION}

# ---- Bring in all Hypr dependencies ----
COPY --from=hyprutils           /out /deps
COPY --from=hyprlang            /out /deps
COPY --from=hyprcursor          /out /deps
COPY --from=hyprgraphics        /out /deps
COPY --from=aquamarine          /out /deps
COPY --from=hyprtoolkit         /out /deps
COPY --from=hyprwire            /out /deps
COPY --from=hyprland-protocols  /out /deps
COPY --from=hyprwayland-scanner	/out /deps

RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Fetch source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/Hyprland.git
WORKDIR /build/Hyprland

# ---- Environment sanity ----
ENV CMAKE_BUILD_PARALLEL_LEVEL="8" \
    CMAKE_GENERATOR="Ninja"

# ---- Build ----
RUN cmake -B build -S . \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package 1: runtime (hyprland binary + shared libs) ----
RUN mkdir -p /tmp/deb-bin/DEBIAN && \
    cat > /tmp/deb-bin/DEBIAN/control <<EOF
Package: hyprland-bin
Version: ${VERSION}
Section: x11
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/Hyprland
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libpixman-1-0, libxkbcommon0,
 libinput10, libdrm2, libudev1, libseat1, libhyprutils9 (>= 0.10.0),
 libhyprlang2 (>= 0.6.4), libhyprcursor1 (>= 0.1.11),
 libhyprgraphics1 (>= 0.2.0), libaquamarine8 (>= 0.9.5),
 libhyprtoolkit1 (>= 0.1.1), libhyprwire0 (>= 0.1.0)
Description: Hyprland Wayland compositor (runtime)
EOF


RUN mkdir -p /tmp/deb-bin/usr && \
    cp -a /tmp/pkg/usr/bin  /tmp/deb-bin/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-bin/usr/ 2>/dev/null || true && \
    # **ADD THIS LINE:** Copy the share directory (contains the assets)
    cp -a /tmp/pkg/usr/share /tmp/deb-bin/usr/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-bin /out/hyprland-bin_${VERSION}_amd64.deb

# ---- Package 2: development headers (if any installed by build) ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: hyprland-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/Hyprland
Depends: hyprland-bin (= ${VERSION})
Description: Development headers, CMake and pkg-config files for Hyprland
EOF

RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include        /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake     /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/hyprland-dev_${VERSION}_amd64.deb

# ---- Package 3: meta ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprland
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/Hyprland
Depends: hyprland-bin (= ${VERSION})
Description: Hyprland meta package
EOF

RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprland_${VERSION}_all.deb

RUN echo "✅ Built and packaged Hyprland ${VERSION} successfully."

