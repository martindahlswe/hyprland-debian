#!/bin/bash
set -euo pipefail

# === Configuration ===
DEB_CODENAME="trixie"
ARCH="amd64"
REPO_NAME="hyprland-debian"
GPG_KEY="6BFB61BEFEEE5D25A2A71C6AEEBB2A37D2A1E1FF"

DIST_DIR="$(pwd)/dists/${DEB_CODENAME}"
POOL_DIR="$(pwd)/pool/main"

echo "🧹 Cleaning old repo structure..."
rm -rf dists pool
mkdir -p "${DIST_DIR}/main/binary-${ARCH}" "${POOL_DIR}"

# === 1. Sort .deb files into pool/ ===
echo "📦 Sorting .deb packages into pool..."
find out -type f -name "*.deb" | while read -r deb; do
  pkg=$(basename "$deb")
  first_letter=$(echo "$pkg" | cut -c1 | tr '[:upper:]' '[:lower:]')
  mkdir -p "${POOL_DIR}/${first_letter}"
  cp -v "$deb" "${POOL_DIR}/${first_letter}/"
done

# === 2. Generate Packages + Packages.gz ===
echo "🧾 Generating Packages files..."
PKG_DIR="${DIST_DIR}/main/binary-${ARCH}"
mkdir -p "${PKG_DIR}"

apt-ftparchive packages "${POOL_DIR}" \
  | sed -E "s|^Filename: .*/pool/|Filename: pool/|" \
  > "${PKG_DIR}/Packages"

gzip -fk "${PKG_DIR}/Packages"

# === 3. Generate Release file ===
echo "📄 Generating Release file..."
RELEASE_CONF="${DIST_DIR}/release.conf"
cat > "${RELEASE_CONF}" <<EOF
APT::FTPArchive::Release {
  Origin "Hyprland Debian Repo";
  Label "Hyprland Debian Repo";
  Suite "${DEB_CODENAME}";
  Codename "${DEB_CODENAME}";
  Architectures "${ARCH}";
  Components "main";
  Description "Hyprland ecosystem packages for Debian ${DEB_CODENAME}";
};
EOF

apt-ftparchive -c "${RELEASE_CONF}" release "${DIST_DIR}" > "${DIST_DIR}/Release"

# === 4. Sign the repo ===
echo "🔏 Signing repository with key ${GPG_KEY}..."
gpg --batch --yes --default-key "${GPG_KEY}" \
    --clearsign -o "${DIST_DIR}/InRelease" "${DIST_DIR}/Release"

gpg --batch --yes --default-key "${GPG_KEY}" \
    -abs -o "${DIST_DIR}/Release.gpg" "${DIST_DIR}/Release"

# === 5. Export public key if not present ===
if [[ ! -f public.gpg ]]; then
  echo "📤 Exporting public key..."
  gpg --armor --export "${GPG_KEY}" > public.gpg
fi

echo "✅ Repository successfully rebuilt!"
echo "👉 Commit and push to 'gh-pages' to publish."

