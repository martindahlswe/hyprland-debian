################################################################################
# Root Dockerfile
# Purpose: convenience entrypoint to build the base image.
################################################################################

# syntax=docker/dockerfile:1.6

FROM debian:trixie-slim AS base

# Copy the base Dockerfile contents in-line so this file can build directly
COPY components/base.Dockerfile /tmp/base.Dockerfile

# Rebuild from that base definition
RUN --mount=type=bind,source=components,target=/components \
    bash -c 'cd / && podman build -f /components/base.Dockerfile -t hyprland-base . || true'

# Default stage — nothing else for now
CMD ["bash"]
