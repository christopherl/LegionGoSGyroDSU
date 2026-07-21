#!/bin/bash
set -euo pipefail

# Unlock the SteamOS filesystem when that command is available. It returns an
# error on some systems when the filesystem is already writable, which is not
# an installation failure.
if command -v steamos-readonly >/dev/null 2>&1; then
    sudo steamos-readonly disable >/dev/null 2>&1 || true
fi

echo "Cleaning up a previous installation, if present..."

# Only contact systemd when this installer previously installed a unit. This
# keeps a first installation quiet while still stopping upgrades cleanly.
if sudo test -f /etc/systemd/system/lgsdsu.service; then
    sudo systemctl disable --now lgsdsu.service >/dev/null 2>&1 || true
    sudo rm -f /etc/systemd/system/lgsdsu.service
    sudo systemctl daemon-reload
fi

# These files are optional, including the legacy fix-iio.conf path.
sudo rm -f /etc/modprobe.d/fix-iio.conf
sudo rm -f /etc/modules-load.d/fix-iio-sensor-hub.conf
sudo rm -rf /LegionGoSGyroDSU

echo "Installing LegionGoSGyroDSU..."

sudo mkdir -p /LegionGoSGyroDSU
cd /LegionGoSGyroDSU

repo="christopherl/legion-go-2-gyro-dsu"
archive="LegionGoSGyroDSU.tar.gz"

if [ -n "${LGSDSU_DOWNLOAD_URL:-}" ]; then
    download_url="$LGSDSU_DOWNLOAD_URL"
else
    download_url=$(curl -fsSL "https://api.github.com/repos/${repo}/releases?per_page=1" | sed -n 's/.*"browser_download_url": "\(.*\/'"${archive}"'\)".*/\1/p' | head -n 1)
fi

if [ -z "$download_url" ]; then
    echo "Could not find ${archive} in the latest release for ${repo}."
    exit 1
fi

sudo wget --output-document "$archive" -- "$download_url"

sudo tar -xzvf "$archive"
sudo rm -f "$archive"

# Keep compatibility with archives that contain the upstream build output name.
if sudo test -f LegionGoSGyro; then
    sudo mv LegionGoSGyro LegionGoSGyroDSU
fi
sudo chmod +x LegionGoSGyroDSU

sudo cp lgsdsu.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now lgsdsu.service

sudo chmod +x check.sh uninstall.sh install.sh

sudo cp fix-iio-sensor-hub.conf /etc/modules-load.d/

echo "Installation complete. Please reboot your system."
