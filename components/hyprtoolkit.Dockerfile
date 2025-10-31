################################################################################
# 9️⃣ hyprtoolkit v${VERSION}
# Hyprland UI toolkit – depends on hyprgraphics v${VERSION} and aquamarine v0.9.5
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprtoolkit

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprtoolkit"

ARG VERSION=0.2.0

# ---- Bring in dependency packages ----
COPY --from=hyprwayland-scanner /out /deps
COPY --from=hyprutils            /out /deps
COPY --from=hyprlang             /out /deps
COPY --from=hyprgraphics         /out /deps
COPY --from=aquamarine           /out /deps
COPY --from=hyprcursor           /out /deps


# ---- Install all dependencies (force configuration of dev/runtime pkgs) ----
RUN apt-get update && \
    dpkg -i /deps/*.deb || true && \
    apt-get -fy install && \
    dpkg --configure -a && \
    rm -rf /var/lib/apt/lists/*

# Reinstall all local packages, resolving dependency chain
RUN find /deps -maxdepth 1 -type f -name '*.deb' -print0 | xargs -0 dpkg -i || true && \
    apt-get -fy install && dpkg --configure -a && \
    echo "✅ Verified packages:" && dpkg -l | grep -E 'hypr(graphics|cursor|lang|utils|aquamarine)'

# ---- Fetch source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprtoolkit.git
WORKDIR /build/hyprtoolkit

# --- Apply patch for GCC 14 / C++23 optional deduction ---
RUN sed -i 's|\.value_or({99999999, 99999999})|.value_or(Vector2D{99999999, 99999999})|' \
    src/element/scrollArea/ScrollArea.cpp && \
    sed -i 's|\.value_or({200, 200})|.value_or(Vector2D{200, 200})|g' \
    src/window/WaylandPopup.cpp

# --- Ensure shader directory exists before CMake runs ---
RUN mkdir -p src/render/shaders

# ---- Build ----
RUN cmake -B build -S . \
    -G Ninja \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr && \
    cmake --build build -j"$(nproc)" && \
    DESTDIR=/tmp/pkg cmake --install build

# ---- Package 1: runtime ----
RUN mkdir -p /tmp/deb-lib/DEBIAN && \
    cat > /tmp/deb-lib/DEBIAN/control <<EOF
Package: libhyprtoolkit1
Version: ${VERSION}
Section: libs
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprtoolkit
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libhyprgraphics1 (>= ${VERSION}), libaquamarine8 (>= 0.9.5), libhyprutils9 (>= 0.10.0), libhyprlang2 (>= 0.6.4)
Description: Hyprtoolkit - Hyprland UI toolkit (runtime)
EOF
RUN mkdir -p /tmp/deb-lib/usr && \
    cp -a /tmp/pkg/usr/lib* /tmp/deb-lib/usr/ && \
    dpkg-deb --build --root-owner-group /tmp/deb-lib /out/libhyprtoolkit1_${VERSION}_amd64.deb

# ---- Package 2: dev ----
RUN mkdir -p /tmp/deb-dev/DEBIAN && \
    cat > /tmp/deb-dev/DEBIAN/control <<EOF
Package: libhyprtoolkit-dev
Version: ${VERSION}
Section: libdevel
Priority: optional
Architecture: amd64
Multi-Arch: same
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprtoolkit
Depends: libhyprtoolkit1 (= ${VERSION}), libhyprgraphics-dev (>= ${VERSION}), libaquamarine-dev (>= 0.9.5)
Description: Development headers and pkg-config files for Hyprtoolkit
EOF
RUN mkdir -p /tmp/deb-dev/usr/lib && \
    cp -a /tmp/pkg/usr/include        /tmp/deb-dev/usr/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/pkgconfig /tmp-deb-dev/usr/lib/ 2>/dev/null || true && \
    cp -a /tmp/pkg/usr/lib*/cmake     /tmp-deb-dev/usr/lib/ 2>/dev/null || true && \
    dpkg-deb --build --root-owner-group /tmp/deb-dev /out/libhyprtoolkit-dev_${VERSION}_amd64.deb

# ---- Meta ----
RUN mkdir -p /tmp/deb-meta/DEBIAN && \
    cat > /tmp/deb-meta/DEBIAN/control <<EOF
Package: hyprtoolkit
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprtoolkit
Depends: libhyprtoolkit1 (= ${VERSION})
Description: Hyprtoolkit meta package
EOF
RUN dpkg-deb --build --root-owner-group /tmp/deb-meta /out/hyprtoolkit_${VERSION}_all.deb

RUN echo "✅ Built and packaged hyprtoolkit ${VERSION} (SONAME libhyprtoolkit.so.1)"

