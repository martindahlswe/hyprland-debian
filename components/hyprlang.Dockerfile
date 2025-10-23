################################################################################
# 4️⃣ hyprlang v0.6.4
# Fast and user-friendly configuration language for the Hyprland ecosystem
################################################################################

# Start from the shared base image
FROM hyprland-base AS hyprlang

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprlang"

# --- Dependencies: hyprutils (for linking and CMake config) ---
COPY --from=hyprutils /out /deps
RUN apt-get update && \
    apt-get install -y cmake git && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.6.4 https://github.com/hyprwm/hyprlang.git
WORKDIR /build/hyprlang

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package 1️⃣: Runtime library (libhyprlang2) ---
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
    printf " The hypr configuration language is an efficient, user-friendly, and\n" >> /tmp/deb-lib/DEBIAN/control && \
    printf " easy-to-implement configuration language for Linux applications.\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprlang2_0.6.4_amd64.deb

# --- Package 2️⃣: Development headers (libhyprlang-dev) ---
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
    printf " This package provides headers and CMake configuration files for developers.\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprlang-dev_0.6.4_amd64.deb

# --- Package 3️⃣: Meta-package (hyprlang) ---
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
    printf " This metapackage pulls in the runtime shared library.\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprlang_0.6.4_amd64.deb

RUN echo "✅ Built and packaged hyprlang v0.6.4"
