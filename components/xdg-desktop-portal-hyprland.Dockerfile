################################################################################
# 5️⃣ xdg-desktop-portal-hyprland v1.3.11
# XDG desktop portal implementation for Hyprland (Wayland integration layer)
################################################################################

# Start from the shared base image
FROM base AS xdg-desktop-portal-hyprland

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/xdg-desktop-portal-hyprland"

# --- Bring in previously built dependencies (.deb packages) ---
COPY --from=hyprlang /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Install build dependencies ---
RUN apt-get update && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v1.3.11 https://github.com/hyprwm/xdg-desktop-portal-hyprland.git
WORKDIR /build/xdg-desktop-portal-hyprland

# --- Build ---
RUN meson setup build --prefix=/usr --buildtype=release && \
    ninja -C build && \
    DESTDIR=/tmp/pkg ninja -C build install

# --- Package as .deb ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: xdg-desktop-portal-hyprland\n' > /tmp/deb/DEBIAN/control && \
    printf 'Version: 1.3.11\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Section: utils\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/xdg-desktop-portal-hyprland\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libwayland-client0 (>= 1.21), libdbus-1-3 (>= 1.12), libpipewire-0.3-0 (>= 0.3.65), libdrm2 (>= 2.4.110), libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4)\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: XDG desktop portal for Hyprland\n' >> /tmp/deb/DEBIAN/control && \
    printf ' Provides integration between sandboxed applications (Flatpak, etc.)\n' >> /tmp/deb/DEBIAN/control && \
    printf ' and the Hyprland compositor via the XDG desktop portal interface.\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    mkdir -p /out && \
    dpkg-deb --build /tmp/deb /out/xdg-desktop-portal-hyprland_1.3.11_amd64.deb

RUN echo "✅ Built and packaged xdg-desktop-portal-hyprland v1.3.11"
