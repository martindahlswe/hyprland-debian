################################################################################
# Hyprland Modular Build System
# Builds modular Debian packages using Podman and multi-stage Dockerfiles
################################################################################

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

PODMAN      ?= podman
BUILD_DIR   ?= components
OUT_DIR     ?= out

# Helper macro: build a component by name
# Example: $(call build_component,hyprutils)
define build_component
	@echo "🚧 Building component: $(1)"
	$(PODMAN) build \
		-f $(BUILD_DIR)/$(1).Dockerfile \
		-t $(1) .
	@echo "✅ Built image: $(1)"
endef


# ------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

.PHONY: all clean base hyprwayland-scanner hyprutils aquamarine hyprlang

# Default target builds everything
all: base hyprwayland-scanner hyprutils aquamarine hyprlang

# ------------------------------------------------------------------------------
# Base image
# ------------------------------------------------------------------------------
base:
	$(call build_component,base)

# ------------------------------------------------------------------------------
# hyprwayland-scanner
# ------------------------------------------------------------------------------
hyprwayland-scanner: base
	$(call build_component,hyprwayland-scanner)

# ------------------------------------------------------------------------------
# hyprutils
# ------------------------------------------------------------------------------
hyprutils: base
	$(call build_component,hyprutils)

# ------------------------------------------------------------------------------
# aquamarine
# ------------------------------------------------------------------------------
aquamarine: base hyprutils hyprwayland-scanner
	$(call build_component,aquamarine)

# ------------------------------------------------------------------------------
# hyprlang
# ------------------------------------------------------------------------------
hyprlang: base hyprutils
	$(call build_component,hyprlang)

# ------------------------------------------------------------------------------
# hyprcursor
# ------------------------------------------------------------------------------
.PHONY: hyprcursor
hyprcursor: hyprutils hyprlang
	$(call build_component,hyprcursor)

# ------------------------------------------------------------------------------
# hyprland-protocols
# ------------------------------------------------------------------------------
.PHONY: hyprland-protocols
hyprland-protocols: base
	$(call build_component,hyprland-protocols)

# ------------------------------------------------------------------------------
# hyprgraphics
# ------------------------------------------------------------------------------
.PHONY: hyprgraphics
hyprgraphics: hyprutils hyprland-protocols
	$(call build_component,hyprgraphics)

# ------------------------------------------------------------------------------
# hyprland (final compositor)
# ------------------------------------------------------------------------------
.PHONY: hyprland
hyprland: hyprwayland-scanner hyprutils aquamarine hyprlang hyprcursor hyprland-protocols hyprgraphics
	$(call build_component,hyprland)

# ------------------------------------------------------------------------------
# hyprland-qtutils
# ------------------------------------------------------------------------------
.PHONY: hyprland-qtutils
hyprland-qtutils: hyprutils hyprlang
	$(call build_component,hyprland-qtutils)

# ------------------------------------------------------------------------------
# hyprpaper
# ------------------------------------------------------------------------------
.PHONY: hyprpaper
hyprpaper: hyprwayland-scanner hyprutils hyprlang hyprcursor hyprgraphics hyprland-protocols
	$(call build_component,hyprpaper)

# ------------------------------------------------------------------------------
# hyprlock
# ------------------------------------------------------------------------------
.PHONY: hyprlock
hyprlock: hyprwayland-scanner hyprutils hyprlang hyprcursor hyprgraphics hyprland-protocols
	$(call build_component,hyprlock)

# ------------------------------------------------------------------------------
# hypridle
# ------------------------------------------------------------------------------
.PHONY: hypridle
hypridle: hyprwayland-scanner hyprutils hyprlang hyprcursor hyprgraphics hyprland-protocols
	$(call build_component,hypridle)

# ------------------------------------------------------------------------------
# hyprsunset
# ------------------------------------------------------------------------------
.PHONY: hyprsunset
hyprsunset: hyprwayland-scanner hyprutils hyprlang hyprland-protocols
	$(call build_component,hyprsunset)

# ------------------------------------------------------------------------------
# Utility targets
# ------------------------------------------------------------------------------

# Clean up dangling images and containers
clean:
	@echo "🧹 Cleaning up containers and images..."
	-$(PODMAN) image prune -f
	-$(PODMAN) container prune -f

# Export all .deb files from built images into ./out/<component>/
export-all: \
	$(OUT_DIR)/base \
	$(OUT_DIR)/hyprwayland-scanner \
	$(OUT_DIR)/hyprutils \
	$(OUT_DIR)/aquamarine \
	$(OUT_DIR)/hyprlang \
	$(OUT_DIR)/hyprcursor \
	$(OUT_DIR)/hyprland-protocols \
	$(OUT_DIR)/hyprgraphics \
	$(OUT_DIR)/hyprland \
	$(OUT_DIR)/hyprland-qtutils \
	$(OUT_DIR)/hyprpaper \
	$(OUT_DIR)/hyprlock \
	$(OUT_DIR)/hypridle \
	$(OUT_DIR)/hyprsunset

$(OUT_DIR)/%:
	@echo "📦 Exporting .deb files for $*..."
	@mkdir -p $(OUT_DIR)/$*
	@id=$$($(PODMAN) create $*); \
	$(PODMAN) cp $$id:/out $(OUT_DIR)/$*; \
	$(PODMAN) rm $$id >/dev/null
	@echo "✅ Exported artifacts to $(OUT_DIR)/$*/"

# Clean all exported .deb files
clean-out:
	@echo "🧹 Removing exported output directories..."
	rm -rf $(OUT_DIR)
