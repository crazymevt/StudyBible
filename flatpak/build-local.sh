#!/usr/bin/env bash
# Build and install the Study Bible Flatpak locally for testing.
#
# Prerequisites (one-time):
#   flatpak install -y flathub org.gnome.Platform//47 org.gnome.Sdk//47
#   # and flatpak-builder itself, e.g. `sudo apt install flatpak-builder`
#
# Usage (from the repo root or this dir):
#   flatpak/build-local.sh            # build + install --user, then you can run it
#   flatpak/build-local.sh --run      # also launch it afterwards
set -euo pipefail

APP_ID="io.github.crazymevt.StudyBible"
# Resolve repo root from this script's location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "==> Building Flutter Linux bundle (release)"
flutter build linux --release

echo "==> Building + installing Flatpak (--user)"
cd "$SCRIPT_DIR"
flatpak-builder --user --install --force-clean build-dir "$APP_ID.yml"

echo "==> Done. Run with:  flatpak run $APP_ID"
if [[ "${1:-}" == "--run" ]]; then
  exec flatpak run "$APP_ID"
fi
