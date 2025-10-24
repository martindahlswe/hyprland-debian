################################################################################
# 🧩 hyprwire v0.1.0
# IPC and protocol communication library for Hyprland
################################################################################

FROM base AS hyprwire

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprwire"

# --- Dependencies ---
COPY --from=hyprutils /out /deps
COPY --from=hyprlang /out /deps
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprland-protocols /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y git cmake pkg-config libffi-dev libpugixml-dev && \
    apt-get install -y /deps/*.deb || apt-get -f install -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.1.0 https://github.com/hyprwm/hyprwire.git
WORKDIR /build/hyprwire

# --- Apply local patch for GCC14 append_range issue ---
# Pulls patch from the repo-level ./patches directory
COPY ../../patches/hyprwire.patch /tmp/hyprwire.patch
RUN patch -p1 < /tmp/hyprwire.patch || echo "No patch applied (already patched)"

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package ---
RUN mkdir -p /tmp/deb/DEBIAN && \
    printf "Package: libhyprwire0\n" > /tmp/deb/DEBIAN/control && \
    printf "Version: 0.1.0\n" >> /tmp/deb/DEBIAN/control && \
    printf "Section: libs\n" >> /tmp/deb/DEBIAN/control && \
    printf "Priority: optional\n" >> /tmp/deb/DEBIAN/control && \
    printf "Architecture: amd64\n" >> /tmp/deb/DEBIAN/control && \
    printf "Multi-Arch: same\n" >> /tmp/deb/DEBIAN/control && \
    printf "Maintainer: Martin Dahl <martindahl16@icloud.com>\n" >> /tmp/deb/DEBIAN/control && \
    printf "Homepage: https://github.com/hyprwm/hyprwire\n" >> /tmp/deb/DEBIAN/control && \
    printf "Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libffi8 (>= 3.4), libpugixml1v5 (>= 1.14), libhyprutils6 (>= 0.10.0), libhyprlang2 (>= 0.6.4), hyprwayland-scanner (>= 0.4.0), hyprland-protocols (>= 0.7.0)\n" >> /tmp/deb/DEBIAN/control && \
    printf "Description: IPC and protocol communication library for Hyprland\n" >> /tmp/deb/DEBIAN/control && \
    printf " hyprwire provides the inter-process and inter-module communication layer\n" >> /tmp/deb/DEBIAN/control && \
    printf " used by Hyprland components. It defines a structured wire protocol\n" >> /tmp/deb/DEBIAN/control && \
    printf " and serialization system for efficient IPC between clients and server.\n" >> /tmp/deb/DEBIAN/control && \
    printf " .\n" >> /tmp/deb/DEBIAN/control && \
    printf " This package installs the runtime shared library for hyprwire.\n" >> /tmp/deb/DEBIAN/control && \
    cp -a /tmp/pkg/usr /tmp/deb/ && \
    dpkg-deb --build /tmp/deb /out/libhyprwire_0.1.0_amd64.deb

RUN echo "✅ Built and packaged hyprwire v0.1.0"
