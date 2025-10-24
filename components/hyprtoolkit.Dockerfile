################################################################################
# 🧩 hyprtoolkit (git master)
# Modern C++ Wayland-native GUI toolkit for Hyprland
################################################################################

FROM base AS hyprtoolkit

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprtoolkit"

# --- Dependencies ---
# Pull prebuilt deps from other stages
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprwayland-scanner /out /deps
COPY --from=aquamarine /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Install system dependencies ---
RUN apt-get update && \
    apt-get install -y git cmake ninja-build pkg-config \
    libdrm-dev libegl-dev libgbm-dev libxkbcommon-dev \
    libpixman-1-dev libpango1.0-dev libwayland-dev libiniparser-dev && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source (latest master) ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.1.1 https://github.com/hyprwm/hyprtoolkit.git
WORKDIR /build/hyprtoolkit

# --- Apply GCC14 compatibility patch ---
COPY ../../patches/hyprtoolkit.patch /tmp/hyprtoolkit.patch
RUN cd /build/hyprtoolkit && \
    echo "Applying patch..." && \
    patch -p1 < /tmp/hyprtoolkit.patch || (echo "❌ Patch failed!" && exit 1) && \
    echo "✅ Patch applied. Verifying:" && \
    grep -n "value_or" src/element/scrollArea/ScrollArea.cpp | head -n3

# --- Build ---
RUN cmake -B build -S . \
    -G Ninja \
    -W no-dev \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: libhyprtoolkit0\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.1.1\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprtoolkit\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libpango-1.0-0 (>= 1.50), libpixman-1-0 (>= 0.42), libwayland-client0 (>= 1.22), libxkbcommon0 (>= 1.5.0), libegl1, libgbm1, libdrm2, libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4), libhyprgraphics0 (>= 0.2.0), hyprwayland-scanner (>= 0.4.0), aquamarine (>= 0.2.0)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Modern C++ Wayland-native GUI toolkit for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " hyprtoolkit provides a lightweight GUI abstraction layer for Wayland,\n" >> /tmp/deb/DEBIAN/control && \
    printf " using the Hyprland ecosystem libraries (hyprutils, hyprgraphics, etc.).\n" >> /tmp/deb/DEBIAN/control && \
    printf " .\n" >> /tmp/deb/DEBIAN/control && \
    printf " This package installs the shared library for hyprtoolkit.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/libhyprtoolkit_0.1.1_amd64.deb

RUN echo "✅ Built and packaged hyprtoolkit v0.1.1"
