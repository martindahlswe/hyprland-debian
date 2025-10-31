################################################################################
# hyprlock v0.9.2
# Modern lock screen utility for Hyprland
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprlock

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprlock"

ARG VERSION=0.9.2

# --- Dependencies from other Hyprland components ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps

# --- System dependencies ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprlock.git
WORKDIR /build/hyprlock

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprlock\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: ${VERSION}\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprlock\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libhyprcursor1 (>= 0.1.11), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0), libpam0g, libxkbcommon0, libinput10, libwayland-client0, libsdbus-c++2\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Hyprlock - modern lock screen utility for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " Hyprlock is a sleek, modern lock screen designed for the Hyprland compositor.\n" >> /tmp/deb/DEBIAN/control && \
    printf " It integrates tightly with the Hypr ecosystem and provides PAM authentication,\n" >> /tmp/deb/DEBIAN/control && \
    printf " dynamic theming, and Wayland-native rendering.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprlock_${VERSION}_amd64.deb

RUN echo "✅ Built and packaged hyprlock v${VERSION}"
