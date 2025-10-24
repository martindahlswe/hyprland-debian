################################################################################
# 3️⃣ aquamarine v0.9.5
# Hyprland's rendering and composition backend (EGL/DRM abstraction layer)
################################################################################

# Start from the common base image
FROM base AS aquamarine

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/aquamarine"

# --- Bring in previously built dependencies (.deb packages) ---
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils /out /deps

# --- Install dependencies ---
RUN apt-get update && \
    apt-get install -y libpugixml1v5 libegl-dev libgles2-mesa-dev libdrm-dev libgbm-dev libffi-dev libpixman-1-dev libwayland-dev && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# --- Clone source ---
WORKDIR /build
RUN git clone --depth=1 --branch v0.9.5 https://github.com/hyprwm/aquamarine.git
WORKDIR /build/aquamarine

# --- Build ---
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# --- Package as .deb ---
RUN mkdir -p /tmp/deb/DEBIAN && \
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
    mkdir -p /out && \
    dpkg-deb --build /tmp/deb /out/aquamarine_0.9.5_amd64.deb

RUN echo "✅ Built and packaged aquamarine v0.9.5"
