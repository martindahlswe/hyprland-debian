################################################################################
# hyprsunset v0.3.3
# Blue-light filter / night mode utility for Hyprland
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprsunset

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprsunset"

ARG VERSION=0.3.3

# --- Dependencies from other Hyprland components ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Build dependencies ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprsunset.git
WORKDIR /build/hyprsunset

# --- Build ---
RUN cmake -B build -S . -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN install -Dm644 LICENSE /tmp/pkg/usr/share/licenses/hyprsunset/LICENSE && \
    mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprsunset\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: ${VERSION}\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprsunset\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: hyprlang (>= 0.6.4), hyprutils (>= 0.10.0), wayland-protocols, libwayland-client0\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Hyprsunset - blue-light filter for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " Hyprsunset is a lightweight blue-light filter daemon designed for Hyprland.\n" >> /tmp/deb/DEBIAN/control && \
    printf " It adjusts screen color temperature automatically based on time of day,\n" >> /tmp/deb/DEBIAN/control && \
    printf " providing a comfortable night-time viewing experience.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprsunset_${VERSION}_amd64.deb

RUN echo "✅ Built and packaged hyprsunset v${VERSION}"
