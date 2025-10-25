################################################################################
# hyprlauncher v0.1.0
################################################################################

FROM base AS hyprlauncher

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprlauncher"

# --- Dependencies ---
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprwire /out /deps
COPY --from=hyprtoolkit /out /deps

# --- Install build/runtime deps ---
RUN apt-get update && \
    apt-get install -y git cmake ninja-build libicu-dev libdrm-dev libqalculate-dev libpixman-1-dev && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Inject fake pkg-config files for internal Hypr* libs ---
RUN mkdir -p /usr/lib/pkgconfig && \
    for lib in hyprutils hyprlang hyprwire hyprtoolkit; do \
    echo "prefix=/usr" > /usr/lib/pkgconfig/$lib.pc && \
    echo "exec_prefix=\${prefix}" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "libdir=\${exec_prefix}/lib" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "includedir=\${prefix}/include" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "Name: $lib" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "Description: Fake pkg-config entry for $lib" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "Version: 0.1.0" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "Libs: -L\${libdir} -l$lib" >> /usr/lib/pkgconfig/$lib.pc && \
    echo "Cflags: -I\${includedir}" >> /usr/lib/pkgconfig/$lib.pc; \
    done

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.1.0 https://github.com/hyprwm/hyprlauncher.git
WORKDIR /build/hyprlauncher

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
    printf "Package: hyprlauncher\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.1.0\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprlauncher\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libicu72 (>= 72.1), libdrm2 (>= 2.4.120), libpixman-1-0 (>= 0.44.0), libqalculate22 (>= 5.1.0), libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4), libhyprtoolkit1 (>= 0.1.1), libhyprwire1 (>= 0.1.0)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: Multipurpose launcher and picker for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " hyprlauncher provides an extensible launcher/picker GUI built\n" >> /tmp/deb/DEBIAN/control && \
    printf " on Hyprtoolkit and Hyprwire for seamless Wayland-native integration.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/hyprlauncher_0.1.0_amd64.deb

RUN echo "✅ Built and packaged hyprlauncher v0.1.0"
