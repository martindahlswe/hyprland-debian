################################################################################
# 1️⃣2️⃣ hypridle v${VERSION}
# Idle management daemon for Hyprland (triggers Hyprlock etc.)
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hypridle

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hypridle"

# --- Dependencies from previous components ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps

ARG VERSION=0.1.7

# --- System dependencies ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hypridle.git
WORKDIR /build/hypridle

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hypridle\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: ${VERSION}\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hypridle\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libsdbus-c++2, libwayland-client0, libxkbcommon0, libinput10\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Hypridle - idle management daemon for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " Hypridle monitors user activity and triggers events like screen lock,\n" >> /tmp/deb/DEBIAN/control && \
    printf " suspend, or custom actions after idle timeouts. Designed to integrate\n" >> /tmp/deb/DEBIAN/control && \
    printf " tightly with Hyprlock and the Hyprland compositor.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hypridle_${VERSION}_amd64.deb

RUN echo "✅ Built and packaged hypridle v${VERSION}"
