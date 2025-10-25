################################################################################
# 7️⃣ hyprgraphics v0.2.0
# GPU abstraction and rendering utilities for Hyprland
################################################################################

FROM base AS hyprgraphics

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprgraphics"

# --- Dependencies ---
COPY --from=hyprutils /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.2.0 https://github.com/hyprwm/hyprgraphics.git
WORKDIR /build/hyprgraphics

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
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

RUN echo "✅ Built and packaged hyprgraphics v0.2.0"
