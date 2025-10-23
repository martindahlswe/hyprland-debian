################################################################################
# 🔟 hyprpaper v0.7.6
# Wallpaper daemon for Hyprland
################################################################################

FROM hyprland-base AS hyprpaper

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprpaper"

# --- Copy built dependencies from previous components ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y git cmake ninja-build pkg-config libwayland-dev && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.7.6 https://github.com/hyprwm/hyprpaper.git
WORKDIR /build/hyprpaper

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprpaper\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.7.6\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprpaper\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libhyprcursor0 (>= 0.1.13), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Hyprpaper - wallpaper daemon for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " Hyprpaper provides a wallpaper management daemon for the Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " compositor, supporting multiple monitors and dynamic configuration.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprpaper_0.7.6_amd64.deb

RUN echo "✅ Built and packaged hyprpaper v0.7.6"
