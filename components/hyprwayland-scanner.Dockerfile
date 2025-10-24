################################################################################
# 1️⃣ hyprwayland-scanner v0.4.5
# Builds the Hyprland C++ Wayland protocol scanner and packages it as a .deb
################################################################################

# Start from your previously built base image
FROM base AS hyprwayland-scanner

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprwayland-scanner"

WORKDIR /build

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    libpugixml-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
RUN git clone --depth=1 --branch v0.4.5 https://github.com/hyprwm/hyprwayland-scanner.git
WORKDIR /build/hyprwayland-scanner

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package as .deb ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprwayland-scanner\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.4.5\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: libdevel\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Multi-Arch: foreign\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprwayland-scanner\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libpugixml1v5 (>= 1.4)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Implementation of wayland-scanner for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " hyprwayland-scanner is a Hyprland implementation of wayland-scanner,\n" >> /tmp/deb/DEBIAN/control && \
    printf " in and for C++.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    mkdir -p /out && \
    dpkg-deb --build /tmp/deb /out/hyprwayland-scanner_0.4.5_amd64.deb

# --- Done ---
RUN echo "✅ Built and packaged hyprwayland-scanner v0.4.5"
