################################################################################
# 6️⃣ hyprland-protocols v0.7.0
# Hyprland-specific Wayland protocol definitions
################################################################################

FROM hyprland-base AS hyprland-protocols

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprland-protocols"

# --- Dependencies ---
RUN apt-get update && \
    apt-get install -y git meson ninja-build wayland-protocols && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.7.0 https://github.com/hyprwm/hyprland-protocols.git
WORKDIR /build/hyprland-protocols

# --- Build and install ---
RUN meson setup build && \
    meson install -C build --destdir /tmp/pkg

# --- Package as Debian .deb ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprland-protocols\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.7.0\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: x11\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: all\n" >> /tmp/deb/DEBIAN/control && \
    printf "Multi-Arch: foreign\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprland-protocols\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: wayland-protocols (>= 1.31)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Hyprland-specific Wayland protocol definitions\n" >> /tmp/deb/DEBIAN/control && \
    printf " Hyprland-protocols provides additional Wayland XML protocol files\n" >> /tmp/deb/DEBIAN/control && \
    printf " used by the Hyprland compositor and related utilities.\n" >> /tmp/deb/DEBIAN/control && \
    printf " These extend standard Wayland interfaces with Hyprland-specific\n" >> /tmp/deb/DEBIAN/control && \
    printf " functionality such as decorations, animations, and workspace handling.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland-protocols_0.7.0_all.deb

RUN echo "✅ Built and packaged hyprland-protocols v0.7.0"
