################################################################################
# 5️⃣ libhyprcursor v0.1.13
# Hyprland cursor format, library, and utilities
################################################################################

FROM base AS hyprcursor

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprcursor"

# --- Dependencies: hyprutils + hyprlang ---
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.1.13 https://github.com/hyprwm/hyprcursor.git
WORKDIR /build/hyprcursor

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ------------------------------------------------------------------------------
# Package 1️⃣: libhyprcursor0 (shared library)
# ------------------------------------------------------------------------------
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
    printf " hyprcursor provides the cursor format and utilities used by Hyprland.\n" >> /tmp/deb-lib/DEBIAN/control && \
    mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib /tmp/deb-lib/usr/ && \
    dpkg-deb --build /tmp/deb-lib /out/libhyprcursor0_0.1.13_amd64.deb

# ------------------------------------------------------------------------------
# Package 2️⃣: libhyprcursor-dev (headers + cmake)
# ------------------------------------------------------------------------------
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
    printf "Description: Hyprland cursor format (development headers)\n" >> /tmp/deb-dev/DEBIAN/control && \
    printf " Contains headers and CMake config for libhyprcursor.\n" >> /tmp/deb-dev/DEBIAN/control && \
    mkdir -p /tmp/deb-dev/usr && \
    cp -a /tmp/pkg/usr/include /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/pkgconfig /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib/cmake /tmp/deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build /tmp/deb-dev /out/libhyprcursor-dev_0.1.13_amd64.deb

# ------------------------------------------------------------------------------
# Package 3️⃣: hyprcursor-util (CLI tool)
# ------------------------------------------------------------------------------
RUN mkdir -p /tmp/deb-util/DEBIAN && \
    printf "Package: hyprcursor-util\n" > /tmp/deb-util/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Section: utils\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Depends: libhyprcursor0 (= 0.1.13)\n" >> /tmp/deb-util/DEBIAN/control && \
    printf "Description: Utility to manipulate Hyprcursor and Xcursor themes\n" >> /tmp/deb-util/DEBIAN/control && \
    mkdir -p /tmp/deb-util/usr/bin && \
    if [ -f /tmp/pkg/usr/bin/hyprcursor-util ]; then \
    cp /tmp/pkg/usr/bin/hyprcursor-util /tmp/deb-util/usr/bin/; \
    fi && \
    dpkg-deb --build /tmp/deb-util /out/hyprcursor-util_0.1.13_amd64.deb

# ------------------------------------------------------------------------------
# Package 4️⃣: hyprcursor (metapackage)
# ------------------------------------------------------------------------------
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    printf "Package: hyprcursor\n" > /tmp/deb-meta/DEBIAN/control && \
    printf "Version: 0.1.13\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Section: misc\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Architecture: all\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprcursor\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Depends: libhyprcursor0 (= 0.1.13)\n" >> /tmp/deb-meta/DEBIAN/control && \
    printf "Description: Metapackage for Hyprcursor runtime\n" >> /tmp/deb-meta/DEBIAN/control && \
    dpkg-deb --build /tmp/deb-meta /out/hyprcursor_0.1.13_all.deb

RUN echo "✅ Built and packaged libhyprcursor v0.1.13"
