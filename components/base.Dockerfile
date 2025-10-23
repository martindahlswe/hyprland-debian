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
    git wget curl make pkg-config fakeroot dpkg-dev devscripts equivs \
    build-essential cmake ninja-build meson gettext-base \
    fontconfig libfontconfig-dev \
    libffi-dev libxml2-dev libdrm-dev libmagic-dev \
    libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd \
    libegl-dev libgles2-mesa-dev glslang-tools \
    libinput-dev libxcb-composite0-dev libxcb-ewmh-dev libxcb-present-dev \
    libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev \
    libxcb-errors-dev hwdata libwayland-client0 libwayland-dev wayland-protocols \
    libgbm-dev libdisplay-info-dev libxcursor-dev \
    libzip-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev \
    xdg-desktop-portal-wlr \
    ca-certificates locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir -p /out

ENV HYPRLAND_BASE_BUILT=1

RUN echo "✅ Base image built successfully (Debian Trixie)" && \
    g++ --version || true
