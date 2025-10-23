################################################################################
# Base builder image with shared dependencies
################################################################################
FROM --platform=linux/amd64 debian:trixie AS base
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git wget curl make pkg-config fakeroot dpkg-dev devscripts equivs \
    build-essential cmake cmake-extras ninja-build meson \
    gettext gettext-base fontconfig libfontconfig-dev \
    libffi-dev libxml2-dev libdrm-dev libmagic-dev \
    libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev \
    libpixman-1-dev libudev-dev libseat-dev seatd \
    libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev \
    glslang-tools libinput-bin libinput-dev \
    libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev \
    libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev \
    libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev \
    libtomlplusplus3 libre2-dev xdg-desktop-portal-wlr \
    wayland-protocols libdisplay-info-dev libxcursor-dev libxcb-errors-dev \
    hwdata libwayland-client0 libgbm-dev libwayland-dev \
    libzip-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev \
    libpugixml-dev libre2-dev \
    # Qt6 base + Quick + Wayland
    qt6-base-dev qt6-base-dev-tools qt6-tools-dev qt6-tools-dev-tools \
    qt6-declarative-dev qt6-declarative-dev-tools qt6-wayland-dev \
    qt6-l10n-tools \
    libqt6core6 libqt6gui6 libqt6widgets6 libqt6opengl6 libqt6quick6 libqt6waylandclient6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir -p /out

################################################################################
# 1️⃣ hyprwayland-scanner v0.4.5
################################################################################
FROM base AS hyprwayland-scanner

# Clone source
RUN git clone --depth=1 --branch v0.4.5 https://github.com/hyprwm/hyprwayland-scanner.git
WORKDIR /build/hyprwayland-scanner

# Build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# Package metadata based on Ubuntu/Debian official source
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
    dpkg-deb --build /tmp/deb /out/hyprwayland-scanner_0.4.5_amd64.deb


################################################################################
# 2️⃣ hyprutils v0.10.0
################################################################################
FROM base AS hyprutils

# Prepare workspace
RUN mkdir -p /build /out
WORKDIR /build

# Clone source
RUN git clone --depth=1 --branch v0.10.0 https://github.com/hyprwm/hyprutils.git

# Build
WORKDIR /build/hyprutils
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -S . -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

################################################################################
# --- Runtime package: libhyprutils6 ---
################################################################################
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    printf "Package: libhyprutils6\n" > /tmp/deb-lib/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libpixman-1-0 (>= 0.42)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Description: Utilities used across the Hyprland ecosystem (library)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " Hyprutils is a small C++ library for utilities used across the Hyprland\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " window manager ecosystem.\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprutils6_0.10.0_amd64.deb

################################################################################
# --- Development package: libhyprutils-dev ---
################################################################################
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    printf "Package: libhyprutils-dev\n" > /tmp/deb-dev/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Section: libdevel\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Depends: libhyprutils6 (= 0.10.0)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Description: Utilities used across the Hyprland ecosystem (development files)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " Hyprutils is a small C++ library for utilities used across the Hyprland\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " window manager ecosystem.\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprutils-dev_0.10.0_amd64.deb

################################################################################
# --- Metapackage: hyprutils ---
################################################################################
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    printf "Package: hyprutils\n" > /tmp/deb-meta/DEBIAN/control && \
    printf "Version: 0.10.0\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Section: misc\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Architecture: all\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprutils\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Depends: libhyprutils6 (= 0.10.0)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Description: Utilities used across the Hyprland ecosystem (metapackage)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf " Hyprutils is a small C++ library for utilities used across the Hyprland\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf " window manager ecosystem. This metapackage pulls in the runtime library.\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprutils_0.10.0_all.deb


################################################################################
# 3️⃣ aquamarine
################################################################################
FROM base AS aquamarine
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
RUN dpkg -i /deps/*.deb
RUN git clone --depth=1 --branch v0.9.5 https://github.com/hyprwm/aquamarine.git
WORKDIR /build/aquamarine

RUN cmake -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: aquamarine\n' > /tmp/deb/DEBIAN/control && \
    printf 'Version: 0.9.5\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Section: libs\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/aquamarine\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprutils6 (>= 0.10.0), hyprwayland-scanner (>= 0.4.5)\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: Aquamarine - rendering and composition backend for Hyprland\n' >> /tmp/deb/DEBIAN/control && \
    printf ' Aquamarine provides EGL/DRM abstractions and rendering utilities\n' >> /tmp/deb/DEBIAN/control && \
    printf ' used internally by the Hyprland compositor for managing graphics and buffers.\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/aquamarine_0.9.5_amd64.deb


################################################################################
# 4️⃣ hyprlang v0.6.4
################################################################################
FROM base AS hyprlang

# hyprlang depends on hyprutils
COPY --from=hyprutils /out /deps
RUN dpkg -i /deps/*.deb

# Clone and build
RUN git clone --depth=1 --branch v0.6.4 https://github.com/hyprwm/hyprlang.git
WORKDIR /build/hyprlang

RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ───────────────────────────────────────────────────────────────────────────────
# Package 1️⃣: libhyprlang2 (runtime library)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    printf "Package: libhyprlang2\n" > /tmp/deb-lib/DEBIAN/control && \
    printf "Version: 0.6.4\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprlang\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Description: Fast and user-friendly configuration language (library files)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " The hypr configuration language is an extremely efficient, yet easy to\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " work with, configuration language for Linux applications.\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " .\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " It's user-friendly, easy to grasp, and easy to implement.\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprlang2_0.6.4_amd64.deb

# ───────────────────────────────────────────────────────────────────────────────
# Package 2️⃣: libhyprlang-dev (development headers)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    printf "Package: libhyprlang-dev\n" > /tmp/deb-dev/DEBIAN/control && \
    printf "Version: 0.6.4\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Section: libdevel\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprlang\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Depends: libhyprlang2 (= 0.6.4), libhyprutils-dev (>= 0.10.0)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Description: Fast and user-friendly configuration language (development files)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " The hypr configuration language is an extremely efficient, yet easy to\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " work with, configuration language for Linux applications.\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " .\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " This package contains the development headers and CMake files.\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprlang-dev_0.6.4_amd64.deb

# ───────────────────────────────────────────────────────────────────────────────
# Package 3️⃣: hyprlang (meta-package, optional convenience)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    printf "Package: hyprlang\n" > /tmp/deb-meta/DEBIAN/control && \
    printf "Version: 0.6.4\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Section: misc\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprlang\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Depends: libhyprlang2 (= 0.6.4)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Description: Fast and user-friendly configuration language (metapackage)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf " The hypr configuration language for Linux applications.\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf " This metapackage pulls in the runtime shared library.\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprlang_0.6.4_amd64.deb


################################################################################
# 5️⃣ libhyprcursor v0.1.13
################################################################################
FROM base AS hyprcursor

# Dependencies: hyprutils + hyprlang
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps

# Install local deps safely (resolves missing libs like libzip-dev automatically)
RUN apt-get update && apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone source
RUN git clone --depth=1 --branch v0.1.13 https://github.com/hyprwm/hyprcursor.git
WORKDIR /build/hyprcursor

# Build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ───────────────────────────────────────────────────────────────────────────────
# Package 1️⃣: libhyprcursor0 (shared library)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    printf "Package: libhyprcursor0\n" > /tmp/deb-lib/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libcairo2 (>= 1.16), librsvg2-2 (>= 2.50), libzip-dev (>= 1.7), libtomlplusplus3 (>= 3.0.0), libhyprlang2 (>= 0.6.4)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf "Description: Hyprland cursor format, library and utilities (shared library)\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " hyprcursor is the cursor format, and associated files and utilities\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " for Hyprland.\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " .\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " This package contains the shared object library for hyprcursor.\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprcursor0_0.1.13_amd64.deb


# ───────────────────────────────────────────────────────────────────────────────
# Package 2️⃣: libhyprcursor-dev (headers + cmake files)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    printf "Package: libhyprcursor-dev\n" > /tmp/deb-dev/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Section: libdevel\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Depends: libhyprcursor0 (= 0.1.13)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf "Description: Hyprland cursor format, library and utilities (development headers)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " hyprcursor is the cursor format, and associated files and utilities\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " for Hyprland.\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " .\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " This package contains header files and build metadata for hyprcursor.\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprcursor-dev_0.1.13_amd64.deb

# ───────────────────────────────────────────────────────────────────────────────
# Package 3️⃣: hyprcursor-util (binary CLI tool)
# ───────────────────────────────────────────────────────────────────────────────
# Package 4️⃣: hyprcursor (meta package)
# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    printf "Package: hyprcursor\n" > /tmp/deb-meta/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Section: misc\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Architecture: all\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Depends: libhyprcursor0 (= 0.1.13)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Description: Meta package for Hyprcursor runtime\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf " This meta package satisfies dependencies on 'hyprcursor' by providing libhyprcursor0.\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprcursor_0.1.13_all.deb

# ───────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /tmp/deb-util/DEBIAN && \
    printf "Package: hyprcursor-util\n" > /tmp/deb-util/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Depends: libhyprcursor0 (= 0.1.13)\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Description: Utility to manipulate hyprcursor and xcursor themes\n" >> /tmp/deb-util/DEBIAN/control && \
    printf " hyprcursor is the cursor format, and associated files and utilities\n" >> /tmp/deb-util/DEBIAN/control && \
    printf " for Hyprland.\n" >> /tmp/deb-util/DEBIAN/control && \
    printf " .\n" >> /tmp/deb-util/DEBIAN/control && \
    printf " This package contains hyprcursor-util, a CLI tool to compile, pack,\n" >> /tmp/deb-util/DEBIAN/control && \
    printf " and unpack Hyprcursor and Xcursor themes.\n" >> /tmp/deb-util/DEBIAN/control && \
    mkdir -p /tmp/deb-util/usr/bin && \
    if [ -f /tmp/pkg/usr/bin/hyprcursor-util ]; then \
        cp /tmp/pkg/usr/bin/hyprcursor-util /tmp/deb-util/usr/bin/; \
    fi && \
    dpkg-deb --build /tmp/deb-util /out/hyprcursor-util_0.1.13_amd64.deb


################################################################################
# 6️⃣ hyprland-protocols v0.7.0
################################################################################
FROM base AS hyprland-protocols
RUN git clone --depth=1 --branch v0.7.0 https://github.com/hyprwm/hyprland-protocols.git
WORKDIR /build/hyprland-protocols

RUN meson setup build && meson install -C build --destdir /tmp/pkg && \
    mkdir -p /tmp/deb/DEBIAN && \
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
    printf " used by the Hyprland compositor and its related utilities.\n" >> /tmp/deb/DEBIAN/control && \
    printf " These protocols extend standard Wayland interfaces with Hyprland-specific\n" >> /tmp/deb/DEBIAN/control && \
    printf " functionality such as decorations, animations, and workspace handling.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland-protocols_0.7.0_all.deb


################################################################################
# 7️⃣ hyprgraphics v0.2.0
################################################################################
FROM base AS hyprgraphics
COPY --from=hyprutils /out /deps
COPY --from=hyprland-protocols /out /deps

# Use apt-based install to resolve dependencies cleanly
RUN apt-get update && apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 --branch v0.2.0 https://github.com/hyprwm/hyprgraphics.git
WORKDIR /build/hyprgraphics

RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: hyprgraphics\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.2.0\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprgraphics\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libdrm2 (>= 2.4.120), libgbm1 (>= 23.0), libegl1, libgl1, libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4), hyprland-protocols (>= 0.7.0), libmagic1 (>= 5.45)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: GPU abstraction and rendering utilities for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " hyprgraphics provides GPU device abstraction and rendering helpers\n" >> /tmp/deb/DEBIAN/control && \
    printf " used by Hyprland and related tools to manage framebuffers, shaders,\n" >> /tmp/deb/DEBIAN/control && \
    printf " and GPU memory in a backend-agnostic way.\n" >> /tmp/deb/DEBIAN/control && \
    printf " .\n" >> /tmp/deb/DEBIAN/control && \
    printf " This package installs the runtime shared library for hyprgraphics.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprgraphics_0.2.0_amd64.deb


################################################################################
# 8️⃣ Hyprland
################################################################################
FROM base AS hyprland
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=aquamarine /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprland-protocols /out /deps
COPY --from=hyprgraphics /out /deps
RUN dpkg -i /deps/*.deb
RUN git clone --recursive --depth=1 --branch v0.49.0 https://github.com/hyprwm/Hyprland.git
WORKDIR /build/Hyprland
RUN make subprojects && make all -j"$(nproc)" && DESTDIR=/tmp/pkg make install && \
    mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: hyprland\n' > /tmp/deb/DEBIAN/control && \
    printf 'Version: 0.49.0\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Section: x11\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/Hyprland\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libhyprcursor0 (>= 0.1.13), libhyprlang2 (>= 0.6.4), libhyprutils6 (>= 0.10.0), aquamarine (>= 0.9.5), hyprwayland-scanner (>= 0.4.5), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0), libxcb-icccm4, libxcb-composite0, libxcb-res0, libxcb-errors-dev, libxkbcommon0, libxcursor1, libinput10, libre2-11, libgles2-mesa-dev, libopengl0, libseat1, libdisplay-info2, libdrm2, libpixman-1-0, libwayland-client0, libwayland-server0, libc6 (>= 2.34), libstdc++6 (>= 12)\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: Hyprland - dynamic tiling Wayland compositor\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland_0.49.0_amd64.deb


################################################################################
# 9️⃣ hyprland-qtutils
################################################################################
FROM base AS hyprland-qtutils
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
RUN dpkg -i /deps/*.deb
RUN git clone --depth=1 --branch v0.1.5 https://github.com/hyprwm/hyprland-qtutils.git
WORKDIR /build/hyprland-qtutils
# Patch for missing Qt6::WaylandClientPrivate include paths on Debian
RUN sed -i 's/Qt6::WaylandClientPrivate//g' CMakeLists.txt utils/*/CMakeLists.txt || true
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    printf 'Package: hyprland-qtutils\n' > /tmp/deb/DEBIAN/control && \
    printf 'Version: 0.1.5\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Section: libs\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Priority: optional\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Architecture: amd64\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Maintainer: Martin Dahl <martindahl16@icloud.com>\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Homepage: https://github.com/hyprwm/hyprland-qtutils\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Depends: libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4), qt6-base-dev, qt6-declarative-dev, qt6-wayland-dev, libqt6core6, libqt6gui6, libqt6widgets6, libqt6quick6, libqt6waylandclient6\n' >> /tmp/deb/DEBIAN/control && \
    printf 'Description: Qt6 utilities for Hyprland tools\n' >> /tmp/deb/DEBIAN/control && \
    printf ' Provides helper components and abstractions used by Hyprland Qt-based tools.\n' >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprland-qtutils_0.1.5_amd64.deb


################################################################################
# 🔟 hyprpaper v0.7.6
################################################################################
FROM base AS hyprpaper
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps
RUN dpkg -i /deps/*.deb
RUN git clone --depth=1 --branch v0.7.6 https://github.com/hyprwm/hyprpaper.git
WORKDIR /build/hyprpaper
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    echo "Package: hyprpaper" > /tmp/deb/DEBIAN/control && \
    echo "Version: 0.7.6" >> /tmp/deb/DEBIAN/control && \
    echo "Section: utils" >> /tmp/deb/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/deb/DEBIAN/control && \
    echo "Architecture: amd64" >> /tmp/deb/DEBIAN/control && \
    echo "Maintainer: Martin Dahl (martindahl16@icloud.com" >> /tmp/deb/DEBIAN/control && \
    echo "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libhyprcursor0 (>= 0.1.13), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0)" >> /tmp/deb/DEBIAN/control && \
    echo "Description: Hyprpaper - wallpaper daemon for Hyprland" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprpaper_0.7.6_amd64.deb

################################################################################
# 1️⃣1️⃣ hyprlock v0.5.0
################################################################################
FROM base AS hyprlock
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps

# Extra system deps for Hyprlock
RUN apt-get update && apt-get install -y \
    libpam0g-dev libxkbcommon-dev libinput-dev libsdbus-c++-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN dpkg -i /deps/*.deb

RUN git clone --depth=1 --branch v0.5.0 https://github.com/hyprwm/hyprlock.git
WORKDIR /build/hyprlock

RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    echo "Package: hyprlock" > /tmp/deb/DEBIAN/control && \
    echo "Version: 0.5.0" >> /tmp/deb/DEBIAN/control && \
    echo "Section: utils" >> /tmp/deb/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/deb/DEBIAN/control && \
    echo "Architecture: amd64" >> /tmp/deb/DEBIAN/control && \
    echo "Maintainer: Martin Dahl <martindahl16@icloud.com>" >> /tmp/deb/DEBIAN/control && \
    echo "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libhyprcursor0 (>= 0.1.13), hyprgraphics (>= 0.2.0), hyprland-protocols (>= 0.7.0), libpam0g, libxkbcommon0, libinput10, libwayland-client0, libsdbus-c++2" >> /tmp/deb/DEBIAN/control && \
    echo "Description: Hyprlock - modern lock screen utility for Hyprland" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprlock_0.5.0_amd64.deb

################################################################################
# 1️⃣2️⃣ hypridle v0.1.7
################################################################################
FROM base AS hypridle
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprcursor /out /deps
COPY --from=hyprgraphics /out /deps
COPY --from=hyprland-protocols /out /deps

# Install dependencies
RUN apt-get update && apt-get install -y \
    libxkbcommon-dev libinput-dev libsdbus-c++-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN dpkg -i /deps/*.deb

# Clone and build Hypridle
RUN git clone --depth=1 --branch v0.1.7 https://github.com/hyprwm/hypridle.git
WORKDIR /build/hypridle

RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    mkdir -p /tmp/deb/DEBIAN && \
    echo "Package: hypridle" > /tmp/deb/DEBIAN/control && \
    echo "Version: 0.1.7" >> /tmp/deb/DEBIAN/control && \
    echo "Section: utils" >> /tmp/deb/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/deb/DEBIAN/control && \
    echo "Architecture: amd64" >> /tmp/deb/DEBIAN/control && \
    echo "Maintainer: Martin Dahl <martindahl16@icloud.com>" >> /tmp/deb/DEBIAN/control && \
    echo "Depends: hyprutils (>= 0.10.0), hyprlang (>= 0.6.4), libsdbus-c++2, libwayland-client0, libxkbcommon0, libinput10" >> /tmp/deb/DEBIAN/control && \
    echo "Description: Hypridle - idle management daemon for Hyprland (triggers Hyprlock etc.)" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hypridle_0.1.7_amd64.deb

################################################################################
# 1️⃣3️⃣ hyprsunset v0.3.1
################################################################################
FROM base AS hyprsunset
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprland-protocols /out /deps

# Install runtime and build dependencies
RUN apt-get update && apt-get install -y \
    libwayland-dev wayland-protocols pkg-config cmake ninja-build git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Hyprland dependencies from previous stages
RUN dpkg -i /deps/*.deb || apt-get -fy install

# Clone and build hyprsunset
WORKDIR /build
RUN git clone --depth=1 --branch v0.3.1 https://github.com/hyprwm/hyprsunset.git
WORKDIR /build/hyprsunset

RUN cmake -B build -S . -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build && \
    install -Dm644 LICENSE /tmp/pkg/usr/share/licenses/hyprsunset/LICENSE && \
    mkdir -p /tmp/deb/DEBIAN && \
    echo "Package: hyprsunset" > /tmp/deb/DEBIAN/control && \
    echo "Version: 0.3.1" >> /tmp/deb/DEBIAN/control && \
    echo "Section: utils" >> /tmp/deb/DEBIAN/control && \
    echo "Priority: optional" >> /tmp/deb/DEBIAN/control && \
    echo "Architecture: amd64" >> /tmp/deb/DEBIAN/control && \
    echo "Maintainer: Martin Dahl <martindahl16@icloud.com>" >> /tmp/deb/DEBIAN/control && \
    echo "Depends: hyprlang (>= 0.6.4), hyprutils (>= 0.2.3), wayland-protocols, libwayland-client0" >> /tmp/deb/DEBIAN/control && \
    echo "Description: Hyprsunset - blue-light filter for Hyprland" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprsunset_0.3.1_amd64.deb


################################################################################
# Export all .deb files
################################################################################
FROM scratch AS export
COPY --from=hyprwayland-scanner /out /out
COPY --from=hyprutils /out /out
COPY --from=aquamarine /out /out
COPY --from=hyprlang /out /out
COPY --from=hyprcursor /out /out
COPY --from=hyprland-protocols /out /out
COPY --from=hyprgraphics /out /out
COPY --from=hyprland /out /out
COPY --from=hyprland-qtutils /out /out
COPY --from=hyprpaper /out /out
COPY --from=hyprlock /out /out
COPY --from=hypridle /out /out
COPY --from=hyprsunset /out /out
