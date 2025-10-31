################################################################################
# hyprland-protocols v${VERSION} — Meson-based Debian build
################################################################################

FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS hyprland-protocols

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprland-protocols"

ARG VERSION=0.7.0

# ---- Fetch source ----
WORKDIR /build
RUN git clone --depth=1 --branch v${VERSION} https://github.com/hyprwm/hyprland-protocols.git
WORKDIR /build/hyprland-protocols

# ---- Configure & build ----
RUN meson setup build \
      --prefix=/usr \
      --libexecdir=lib \
      --buildtype=plain && \
    meson compile -C build

# ---- Install into package root ----
RUN DESTDIR=/tmp/pkg meson install -C build

# ---- Add Debian metadata ----
RUN mkdir -p /tmp/pkg/DEBIAN && \
    cat > /tmp/pkg/DEBIAN/control <<EOF
Package: hyprland-protocols
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: all
Maintainer: Martin Dahl <martindahl16@icloud.com>
Homepage: https://github.com/hyprwm/hyprland-protocols
Depends: wayland-protocols (>= 1.30)
Description: Hyprland-specific Wayland protocol definitions built via Meson
 Provides Wayland protocol XMLs and pkg-config files for Hyprland components.
EOF

RUN dpkg-deb --build --root-owner-group /tmp/pkg /out/hyprland-protocols_${VERSION}_all.deb
RUN echo "✅ Built hyprland-protocols ${VERSION} using Meson (XMLs included)"

