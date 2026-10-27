#!/bin/sh
# Install the aetheric daemon and CLI (Linux, macOS).
#
#   curl -fsSL https://raw.githubusercontent.com/<releases-repo>/main/install.sh | sh
#
# Downloads this machine's aetheric binary from the public releases repo,
# checks it against the release's SHA256SUMS, and puts it in ~/.local/bin
# (AETHERIC_INSTALL_DIR to choose). AETHERIC_VERSION=0.2.0 pins a version;
# by default the newest published release.
set -eu

REPO="${AETHERIC_RELEASES_REPO:-Castle-Software-LLC/aetheric-releases}"
API="${AETHERIC_GITHUB_API:-https://api.github.com}"
DEST="${AETHERIC_INSTALL_DIR:-$HOME/.local/bin}"

fail() { echo "aetheric install: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "needs $1"; }
need curl

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) fail "unsupported OS $(uname -s); on Windows use install.ps1" ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=x64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) fail "unsupported CPU $(uname -m)" ;;
esac
target="$os-$arch"

if [ -n "${AETHERIC_VERSION:-}" ]; then
  version="${AETHERIC_VERSION#v}"
else
  # The newest release that isn't a draft (prereleases included while there is no stable one).
  version=$(curl -fsSL "$API/repos/$REPO/releases?per_page=1" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1)
  [ -n "$version" ] || fail "no release found in $REPO"
fi

asset="aetheric-$version-$target"
base="${AETHERIC_DOWNLOAD_BASE:-https://github.com/$REPO/releases/download/v$version}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "downloading aetheric $version for $target"
curl -fsSL -o "$tmp/$asset" "$base/$asset" || fail "no $asset in release v$version"
curl -fsSL -o "$tmp/SHA256SUMS" "$base/SHA256SUMS" || fail "release v$version has no SHA256SUMS"

expected=$(awk -v f="$asset" '$2 == f { print $1 }' "$tmp/SHA256SUMS")
[ -n "$expected" ] || fail "SHA256SUMS has no entry for $asset"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp/$asset" | awk '{ print $1 }')
else
  actual=$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')
fi
[ "$actual" = "$expected" ] || fail "checksum mismatch for $asset; nothing installed"

mkdir -p "$DEST"
chmod 755 "$tmp/$asset"
mv "$tmp/$asset" "$DEST/aetheric"
echo "installed $DEST/aetheric"

case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "note: $DEST is not on your PATH; add it, e.g. echo 'export PATH=\"$DEST:\$PATH\"' >> ~/.profile" ;;
esac

cat <<NEXT

Next:
  aetheric doctor --fix                 check this machine; downloads Claude Code
  aetheric service install              run the daemon with your session
  aetheric remote enable --tailscale    let your phone reach it over Tailscale
  aetheric pair                         pair the phone
NEXT
