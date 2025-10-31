################################################################################
# 🔟 hyprlauncher v0.1.1
# Hyprland launcher GUI – depends on hyprwire, hyprtoolkit, hyprutils, hyprlang
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprlauncher

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprlauncher"

ARG VERSION=0.1.2

# ---- Bring in dependencies ----
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils            /out /deps
COPY --from=hyprlang             /out /deps
COPY --from=hyprwire             /out /deps
COPY --from=hyprtoolkit          /out /deps
COPY --from=aquamarine		/out /deps
COPY --from=hyprgraphics	/out /deps
COPY --from=hyprcursor		/out /deps

# ---- Install deps ----
RUN apt-get update && \
    apt-get install -y libqalculate-dev && \
    dpkg -i /deps/*.deb || apt-get -fy install && \
    rm -rf /var/lib/apt/lists/*

# ---- Ensure pkg-config paths exist ----
RUN mkdir -p /usr/lib/pkgconfig /usr/lib/x86_64-linux-gnu/pkgconfig && \
    echo "📦 pkg-config path setup complete"

# ---- Recreate missing .pc files if needed ----
RUN for lib in hyprutils hyprlang hyprwire hyprtoolkit; do \
    PC="/usr/lib/x86_64-linux-gnu/pkgconfig/${lib}.pc"; \
    if [ ! -f "$PC" ]; then \
        echo "⚠️ Creating fallback $lib.pc"; \
        echo "prefix=/usr" > "$PC"; \
        echo "exec_prefix=\${prefix}" >> "$PC"; \
        echo "libdir=\${exec_prefix}/lib/x86_64-linux-gnu" >> "$PC"; \
        echo "includedir=\${prefix}/include" >> "$PC"; \
        echo "" >> "$PC"; \
        echo "Name: $lib" >> "$PC"; \
        echo "Description: Fallback pkg-config for $lib" >> "$PC"; \
        echo "Version: 0.1.1" >> "$PC"; \
        echo "Libs: -L\${libdir} -l$lib" >> "$PC"; \
        echo "Cflags: -I\${includedir}" >> "$PC"; \
    fi; \
    done

# ---- Ensure hyprwire-scanner is available ----
RUN if [ -f /deps/usr/bin/hyprwire-scanner ]; then \
        install -m755 /deps/usr/bin/hyprwire-scanner /usr/local/bin/; \
    elif [ -f /usr/bin/hyprwire-scanner ]; then \
        echo "✅ hyprwire-scanner already available"; \
    else \
        echo "⚠️ hyprwire-scanner not found; creating stub"; \
        echo '#!/bin/sh' > /usr/local/bin/hyprwire-scanner; \
        echo 'echo "stub hyprwire-scanner: missing real binary"' >> /usr/local/bin/hyprwire-scanner; \
        chmod +x /usr/local/bin/hyprwire-scanner; \
    fi

# ---- Build ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprlauncher.git
WORKDIR /build/hyprlauncher

RUN cmake -B build -S . \
    -G Ninja \
    -W no-dev \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package ----
RUN mkdir -p /tmp/deb-bin/DEBIAN && \
    cat > /tmp/deb-bin/DEBIAN/control <<EOF
Package: hyprlauncher
Version: 0.1.1
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprlauncher
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprtoolkit1 (>= 0.1.1), libhyprutils9 (>= 0.10.0), libhyprwire0 (>= 0.1.1), libhyprlang2 (>= 0.6.4), libqalculate21 (>= 5.5.0)
Description: Hyprlauncher - Graphical launcher for Hyprland
EOF

RUN mkdir -p /tmp/deb-bin/usr && \
    cp -a /tmp/pkg/usr/bin /tmp/deb-bin/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/share /tmp/deb-bin/usr/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-bin /out/hyprlauncher_0.1.1_amd64.deb

RUN echo "✅ Built and packaged hyprlauncher 0.1.1"

