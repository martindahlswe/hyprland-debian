################################################################################
# 8️⃣ Hyprland v0.49.0
# Dynamic tiling Wayland compositor for Linux
################################################################################

FROM base AS hyprland

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/Hyprland"

# --- Copy built dependency artifacts from previous stages ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=aquamarine /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprland-protocols /out /deps
COPY --from=hyprgraphics /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y \
    git cmake meson ninja-build make pkg-config \
    libxcb-icccm4 libxcb-composite0 libxcb-res0 libxcb-errors-dev \
    libxkbcommon0 libxcursor1 libinput10 libre2-11 \
    libgles2-mesa-dev libopengl0 libseat1 libdisplay-info2 \
    libdrm2 libpixman-1-0 libwayland-client0 libwayland-server0 libre2-dev && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --recursive --depth=1 --branch v0.49.0 https://github.com/hyprwm/Hyprland.git
WORKDIR /build/Hyprland

# --- Build ---
RUN make subprojects && \
    make all -j"$(nproc)" && \
    DESTDIR=/tmp/pkg make install

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: hyprland\n' > /tmp/deb/DEBIAN/control && \
    printf 'Version: 0.49.0\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Section: x11\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/Hyprland\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libhyprcursor0 (>= 0.1.13), libhyprlang2 (>= 0.6.4), libhyprutils6 (>= 0.10.0), aquamarine (>= 0.9.5), hyprwayland-scanner (>= 0.4.5), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0), libxcb-icccm4, libxcb-composite0, libxcb-res0, libxcb-errors-dev, libxkbcommon0, libxcursor1, libinput10, libre2-11, libgles2-mesa-dev, libopengl0, libseat1, libdisplay-info2, libdrm2, libpixman-1-0, libwayland-client0, libwayland-server0, libc6 (>= 2.34), libstdc++6 (>= 12)\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: Hyprland - dynamic tiling Wayland compositor\n' >> /tmp/deb/DEBIAN/control && \
    printf ' Hyprland is a dynamic tiling Wayland compositor focused on simplicity,\n' >> /tmp/deb/DEBIAN/control && \
    printf ' performance, and modern graphics. It integrates its own rendering,\n' >> /tmp/deb/DEBIAN/control && \
    printf ' input, and protocol stack for a cohesive desktop experience.\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland_0.49.0_amd64.deb

RUN echo "✅ Built and packaged Hyprland v0.49.0"
