# syntax=docker/dockerfile:1

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS xdg-desktop-portal-hyprland
LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/xdg-desktop-portal-hyprland"

ARG VERSION=1.3.11

# ---- Bring in dependency .debs ----
COPY --from=hyprutils            /out /deps
COPY --from=hyprlang             /out /deps
COPY --from=hyprwayland-scanner  /out /deps
COPY --from=hyprland-protocols   /out /deps

# ---- Install dependencies ----
RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Ensure pkg-config can find Hyprland libraries ----
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:$PKG_CONFIG_PATH

# ---- Fetch source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/xdg-desktop-portal-hyprland.git
WORKDIR /build/xdg-desktop-portal-hyprland

# ---- Configure & Build ----
RUN cmake -B build -S . \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=None \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_INSTALL_LIBEXECDIR=lib && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package runtime ----
RUN mkdir -p /tmp/deb-bin/DEBIAN && \
    cat > /tmp/deb-bin/DEBIAN/control <<EOF
Package: xdg-desktop-portal-hyprland
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/xdg-desktop-portal-hyprland
Depends: libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4), libsdbus-c++2 (>= 2.0.0), libqt6core6, libqt6gui6, libqt6widgets6, wayland-protocols
Description: xdg-desktop-portal backend for Hyprland
EOF

RUN mkdir -p /tmp/deb-bin/usr && \
    cp -a /tmp/pkg/usr/bin  /tmp/deb-bin/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-bin/usr/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-bin /out/xdg-desktop-portal-hyprland_${VERSION}_amd64.deb

RUN echo "✅ Built xdg-desktop-portal-hyprland ${VERSION}"

