################################################################################
# components/base.Dockerfile
# Hyprland Base Build Environment
################################################################################
FROM debian:trixie AS base

LABEL maintainer="Martin Dahl <martindahl16@icloud.com>"
LABEL org.opencontainers.image.source="https://github.com/hyprwm/hyprland"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    # build tools
    git wget curl make pkg-config fakeroot dpkg-dev devscripts equivs \
    build-essential cmake ninja-build meson gettext-base \
    # aquamarine
    libseat-dev \
    # hyprwayland-scanner & hyprwire & hyprtoolkit
    libpugixml-dev \
    # hyprcursor
    libzip-dev libtomlplusplus-dev librsvg2-dev libcairo2-dev \
    # aquamarine & hyprland-protocols
    wayland-protocols \
    # hyprgraphics
    libegl-dev libgl1-mesa-dev libmagic-dev libheif-dev \
    # hyprgraphics & hyprtoolkit
    libgbm-dev \
    # hyprgraphics & hyprtoolkit & xdg-desktop-portal-hyprland
    libdrm-dev \
    # hyprland
    libxcb-icccm4 libxcb-composite0 libxcb-res0 libxcb-errors-dev \
    libxkbcommon0 libxcursor1 libinput10 libre2-11 libnotify-dev libudis86-dev \
    libgles2-mesa-dev libopengl0 libseat1 libdisplay-info2 libjxl-dev libjxl-devtools libjxl-tools\
    libdrm2 libpixman-1-0 libwayland-client0 libwayland-server0 libre2-dev \
    # hyprland-qtutils
    qt6-base-dev qt6-base-dev-tools qt6-tools-dev qt6-tools-dev-tools \
    qt6-declarative-dev qt6-declarative-dev-tools qt6-wayland-dev \
    qt6-l10n-tools libqt6core6 libqt6gui6 libqt6widgets6 libqt6quick6 libqt6waylandclient6 \
    # aquamarine & hyprpaper & hyprsunset & hyprtoolkit & xdg-desktop-portal-hyprland
    libwayland-dev \
    # aquamarine & hyprlock 6 hypridle
    libinput-dev \
    # hyprlock
    libpam0g-dev \
    # hyprlock & hypridle & hyprtoolkit
    libxkbcommon-dev \
    # hyprlock & hypridle
    libsdbus-c++-dev \
    # hyprwire
    libffi-dev \
    # hyprtoolkit
    libpixman-1-dev libpango1.0-dev libiniparser-dev \
    # xdg-desktop-portal-hyprland
    libdbus-1-dev libpipewire-0.3-dev libwlroots-0.18-dev \
    # The rest
    fontconfig libfontconfig-dev libxml2-dev \
    seatd \
    glslang-tools \
    libxcb-composite0-dev libxcb-ewmh-dev libxcb-present-dev \
    libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev hwdata \
    libdisplay-info-dev libxcursor-dev \
    xdg-desktop-portal-wlr \
    ca-certificates locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir -p /out

ENV HYPRLAND_BASE_BUILT=1

RUN echo "✅ Base image built successfully (Debian Trixie)" && \
    g++ --version || true
