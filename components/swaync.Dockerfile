FROM docker.io/martindahlswe/hyprland-debian-base:0.49.0 AS swaync

ARG VERSION=0.12.2
ARG ARCH=amd64
ARG MAINTAINER="Martin Dahl <martindahl16@icloud.com>"

# --- Build dependencies (unchanged from your version) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    meson \
    ninja-build \
    git \
    pkg-config \
    scdoc \
    gettext \
    valac \
    libgtk-3-dev \
    libgee-0.8-dev \
    libjson-glib-dev \
    libnotify-dev \
    libpulse-dev \
    libglib2.0-dev \
    libgdk-pixbuf-2.0-dev \
    libwayland-dev \
    libdbus-1-dev \
    libsystemd-dev \
    wayland-protocols \
    sassc \
    blueprint-compiler \
    libadwaita-1-dev \
    librust-gtk4-layer-shell-dev \
    libgranite-7-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Clone tagged release ---
WORKDIR /build
RUN git clone --branch v${VERSION} https://github.com/ErikReider/SwayNotificationCenter.git swaync && \
    cd swaync && git submodule update --init --recursive

# --- Build ---
RUN cd swaync && \
    meson setup build --prefix=/usr --buildtype=release && \
    ninja -C build

# --- Install into temporary staging root for packaging ---
RUN cd swaync && DESTDIR=/pkg/swaync ninja -C build install

# --- Ensure runtime integration files exist ---
RUN set -eux; \
    mkdir -p /pkg/swaync/usr/share/dbus-1/services; \
    mkdir -p /pkg/swaync/usr/share/glib-2.0/schemas; \
    mkdir -p /pkg/swaync/usr/share/applications; \
    mkdir -p /pkg/swaync/usr/share/icons/hicolor; \
    \
    # Fix D-Bus service file if missing
    if [ ! -f /pkg/swaync/usr/share/dbus-1/services/org.erikreider.swaync.service ]; then \
      echo "[D-BUS Service]" > /pkg/swaync/usr/share/dbus-1/services/org.erikreider.swaync.service; \
      echo "Name=org.erikreider.swaync" >> /pkg/swaync/usr/share/dbus-1/services/org.erikreider.swaync.service; \
      echo "Exec=/usr/bin/swaync" >> /pkg/swaync/usr/share/dbus-1/services/org.erikreider.swaync.service; \
    fi; \
    \
    # Compile GLib schemas if they exist
    if [ -d /pkg/swaync/usr/share/glib-2.0/schemas ]; then \
      glib-compile-schemas /pkg/swaync/usr/share/glib-2.0/schemas; \
    fi

# --- Package as Debian .deb ---
RUN set -eux; \
    mkdir -p /pkg/swaync/DEBIAN; \
    { \
      echo "Package: swaync"; \
      echo "Version: ${VERSION}"; \
      echo "Section: x11"; \
      echo "Priority: optional"; \
      echo "Architecture: ${ARCH}"; \
      echo "Maintainer: ${MAINTAINER}"; \
      echo "Depends: libgtk-3-0, libgee-0.8-2, libjson-glib-1.0-0, libnotify4, libpulse0, libglib2.0-0, libgdk-pixbuf-2.0-0, libwayland-client0, libdbus-1-3, libgtk4-layer-shell0, libadwaita-1-0, libsystemd0"; \
      echo "Description: Sway/Wayland notification center compatible with mako and dunst."; \
    } > /pkg/swaync/DEBIAN/control; \
    mkdir -p /out; \
    dpkg-deb --build /pkg/swaync /out; \
    echo "Built package:"; ls -lh /out

