#!/usr/bin/env bash
set -euo pipefail

# Optional: use a GitHub token to increase rate limits
TOKEN="${GITHUB_TOKEN:-}"

# Base folder containing Dockerfiles
COMPONENTS_DIR="./components"

# Function: fetch latest release tag for a repo
get_latest_release() {
  local repo="$1"
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local auth_header=()
  [[ -n "$TOKEN" ]] && auth_header=(-H "Authorization: Bearer $TOKEN")

  local response
  response=$(curl -sSL -H "Accept: application/vnd.github+json" "${auth_header[@]}" "$api_url")
  echo "$response" | grep -Po '"tag_name":\s*"\K[^"]+' || echo "none"
}

# Mapping: component name → GitHub repo
declare -A REPOS=(
  [aquamarine]="hyprwm/aquamarine"
  [hyprcursor]="hyprwm/hyprcursor"
  [hyprgraphics]="hyprwm/hyprgraphics"
  [hypridle]="hyprwm/hypridle"
  [hyprland]="hyprwm/hyprland"
  [hyprland-protocols]="hyprwm/hyprland-protocols"
  [hyprland-qtutils]="hyprwm/hyprland-qtutils"
  [hyprlang]="hyprwm/hyprlang"
  [hyprlauncher]="hyprwm/hyprlauncher"
  [hyprlock]="hyprwm/hyprlock"
  [hyprpaper]="hyprwm/hyprpaper"
  [hyprsunset]="hyprwm/hyprsunset"
  [hyprtoolkit]="hyprwm/hyprtoolkit"
  [hyprutils]="hyprwm/hyprutils"
  [hyprwayland-scanner]="hyprwm/hyprwayland-scanner"
  [hyprwire]="hyprwm/hyprwire"
  [swaync]="ErikReider/SwayNotificationCenter"
  [xdg-desktop-portal-hyprland]="hyprwm/xdg-desktop-portal-hyprland"
)

printf "%-30s %-15s %-15s %-10s\n" "COMPONENT" "CONFIGURED" "LATEST" "STATUS"
printf "%-30s %-15s %-15s %-10s\n" "---------" "----------" "-------" "------"

for dockerfile in "$COMPONENTS_DIR"/*.Dockerfile; do
  [[ -f "$dockerfile" ]] || continue

  component=$(basename "$dockerfile" .Dockerfile)
  repo="${REPOS[$component]:-}"
  [[ -z "$repo" ]] && { echo "⚠️  No repo mapping for $component"; continue; }

  version=$(grep -Po '^ARG VERSION=\K[^\s]+' "$dockerfile" || echo "none")
  latest=$(get_latest_release "$repo")

  # Normalize versions by stripping leading "v"
  version_norm="${version#v}"
  latest_norm="${latest#v}"

  if [[ "$version_norm" == "$latest_norm" ]]; then
    status="✅ up-to-date"
  else
    status="⬆ update"
  fi

  printf "%-30s %-15s %-15s %-10s\n" "$component" "$version" "$latest" "$status"
done

