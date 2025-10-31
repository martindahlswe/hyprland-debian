###############################################################################
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

.PHONY: \
	all clean clean-out export-all \
	base hyprutils hyprlang hyprcursor hyprwayland-scanner \
	hyprland-protocols hyprgraphics hypridle hyprsunset \
	aquamarine hyprtoolkit hyprpaper hyprlock \
	xdg-desktop-portal-hyprland hyprwire hyprland-qtutils \
	hyprland hyprlauncher swaync
	
# --------------------------------------------------------------------------
# Global build chain (dependency-safe order)
# --------------------------------------------------------------------------
all: \
	base \
	hyprutils \
	hyprlang \
	hyprcursor \
	hyprwayland-scanner \
	hyprland-protocols \
	hyprgraphics \
	hypridle \
	hyprsunset \
	aquamarine \
	hyprtoolkit \
	hyprpaper \
	hyprlock \
	xdg-desktop-portal-hyprland \
	hyprwire \
	hyprland-qtutils \
	hyprland \
	hyprlauncher \
	swaync
	@echo "✅ All Hyprland components built successfully."

# ------------------------------------------------------------------------------
# Base image
# ------------------------------------------------------------------------------
base:
	$(call build_component,base)

# ------------------------------------------------------------------------------
# Core dependencies
# ------------------------------------------------------------------------------
hyprwayland-scanner: base
	$(call build_component,hyprwayland-scanner)

hyprutils: base
	$(call build_component,hyprutils)

hyprlang: hyprutils
	$(call build_component,hyprlang)

hyprcursor: hyprutils
	$(call build_component,hyprcursor)

# ------------------------------------------------------------------------------
# Mid-layer libraries
# ------------------------------------------------------------------------------
hyprgraphics: hyprcursor hyprutils
	$(call build_component,hyprgraphics)

hyprland-protocols: base
	$(call build_component,hyprland-protocols)

aquamarine: hyprgraphics hyprlang hyprutils hyprwayland-scanner hyprland-protocols
	$(call build_component,aquamarine)

hyprtoolkit: aquamarine hyprgraphics hyprlang hyprutils hyprwayland-scanner hyprland-protocols
	$(call build_component,hyprtoolkit)

# ------------------------------------------------------------------------------
# Runtime and applications
# ------------------------------------------------------------------------------
hypridle: hyprtoolkit hyprutils
	$(call build_component,hypridle)

hyprpaper: hyprtoolkit hyprutils
	$(call build_component,hyprpaper)

hyprwire: hyprtoolkit hyprutils
	$(call build_component,hyprwire)

hyprlock: hyprtoolkit hyprutils
	$(call build_component,hyprlock)

hyprland-qtutils: hyprtoolkit hyprutils
	$(call build_component,hyprland-qtutils)

hyprland: hyprtoolkit aquamarine hyprgraphics hyprutils hyprlang hyprwayland-scanner hyprland-protocols
	$(call build_component,hyprland)

hyprsunset: hyprtoolkit hyprutils
	$(call build_component,hyprsunset)

xdg-desktop-portal-hyprland: hyprtoolkit hyprutils hyprland
	$(call build_component,xdg-desktop-portal-hyprland)

hyprlauncher: hyprwayland-scanner hyprutils hyprlang hyprwire hyprtoolkit aquamarine hyprgraphics hyprcursor
	$(call build_component,hyprlauncher)

swaync: base
	$(call build_component,swaync)

# ------------------------------------------------------------------------------
# Utility targets
# ------------------------------------------------------------------------------

clean:
	@echo "🧹 Cleaning up containers and images..."
	-$(PODMAN) image prune -f
	-$(PODMAN) container prune -f

# Export all .deb files from built images into ./out/<component>/
export-all: \
	$(OUT_DIR)/base \
	$(OUT_DIR)/hyprutils \
	$(OUT_DIR)/hyprlang \
	$(OUT_DIR)/hyprcursor \
	$(OUT_DIR)/hyprwayland-scanner \
	$(OUT_DIR)/hyprland-protocols \
	$(OUT_DIR)/hyprgraphics \
	$(OUT_DIR)/hypridle \
	$(OUT_DIR)/hyprsunset \
	$(OUT_DIR)/aquamarine \
	$(OUT_DIR)/hyprtoolkit \
	$(OUT_DIR)/hyprpaper \
	$(OUT_DIR)/hyprlock \
	$(OUT_DIR)/xdg-desktop-portal-hyprland \
	$(OUT_DIR)/hyprwire \
	$(OUT_DIR)/hyprland-qtutils \
	$(OUT_DIR)/hyprland \
	$(OUT_DIR)/hyprlauncher \
	$(OUT_DIR)/swaync

$(OUT_DIR)/%:
	@echo "📦 Exporting .deb files for $*..."
	@mkdir -p $(OUT_DIR)/$*
	@id=$$($(PODMAN) create $*); \
	$(PODMAN) cp $$id:/out $(OUT_DIR)/$*; \
	$(PODMAN) rm $$id >/dev/null
	@echo "✅ Exported artifacts to $(OUT_DIR)/$*/"

clean-out:
	@echo "🧹 Removing exported output directories..."
	rm -rf $(OUT_DIR)

# ------------------------------------------------------------------------------
# Order visualization
# ------------------------------------------------------------------------------
show-order:
	@echo "🔧 Build dependency order:"
	@echo " 1. base"
	@echo " 2. hyprutils"
	@echo " 3. hyprlang"
	@echo " 4. hyprcursor"
	@echo " 5. hyprwayland-scanner"
	@echo " 6. hyprland-protocols"
	@echo " 7. hyprgraphics"
	@echo " 8. hypridle"
	@echo " 9. hyprsunset"
	@echo "10. aquamarine"
	@echo "11. hyprtoolkit"
	@echo "12. hyprpaper"
	@echo "13. hyprlock"
	@echo "14. xdg-desktop-portal-hyprland"
	@echo "15. hyprwire"
	@echo "16. hyprland-qtutils"
	@echo "17. hyprland"
	@echo "18. hyprlauncher"
	@echo "19. swaync" 

