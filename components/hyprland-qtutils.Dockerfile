################################################################################
# 9️⃣ hyprland-qtutils v0.1.5
# Qt6 utilities for Hyprland-based tools
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprland-qtutils

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprland-qtutils"

ARG VERSION=0.1.5

# --- Dependencies ---
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps

# --- Install dependencies (Qt6 + Hypr libraries) ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprland-qtutils.git
WORKDIR /build/hyprland-qtutils

# --- Patch for missing Qt6::WaylandClientPrivate include paths on Debian ---
RUN sed -i 's/Qt6::WaylandClientPrivate//g' CMakeLists.txt utils/*/CMakeLists.txt || true

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: hyprland-qtutils\n' > /tmp/deb/DEBIAN/control && \
    printf "Version: ${VERSION}\n" >> /tmp/deb/DEBIAN/control && \
    printf 'Section: libs\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/hyprland-qtutils\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4), qt6-base-dev, qt6-declarative-dev, qt6-wayland-dev, libqt6core6, libqt6gui6, libqt6widgets6, libqt6quick6, libqt6waylandclient6\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: Qt6 utilities for Hyprland tools\n' >> /tmp/deb/DEBIAN/control && \
    printf ' Provides helper components and abstractions used by Hyprland Qt-based tools.\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland-qtutils_${VERSION}_amd64.deb

RUN echo "✅ Built and packaged hyprland-qtutils v${VERSION}"
