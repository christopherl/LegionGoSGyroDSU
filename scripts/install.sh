#!/bin/bash

# unlock the filesystem
sudo steamos-readonly disable

echo There may be errors, they do not matter, do not worry

sudo systemctl stop lgsdsu.service
sudo systemctl disable lgsdsu.service
sudo rm /etc/systemd/system/lgsdsu.service
sudo systemctl daemon-reload
sudo rm /etc/modprobe.d/fix-iio.conf # old, but in case anybody installed it from the era
sudo rm /etc/modules-load.d/fix-iio-sensor-hub.conf

sudo rm -rf /LegionGoSGyroDSU

echo Errors do matter from here, please make sure you have a password, you can run the "passwd" command if not.
sleep 2

sudo mkdir -p /LegionGoSGyroDSU
cd /LegionGoSGyroDSU

repo="christopherl/legion-go-2-gyro-dsu"
archive="LegionGoSGyroDSU.tar.gz"
download_url=$(curl -fsSL "https://api.github.com/repos/${repo}/releases?per_page=1" | sed -n 's/.*"browser_download_url": "\(.*\/'"${archive}"'\)".*/\1/p' | head -n 1)

if [ -z "$download_url" ]; then
    echo "Could not find ${archive} in the latest release for ${repo}."
    exit 1
fi

sudo wget "$download_url" -O "$archive" || exit 1

sudo tar -xzvf  LegionGoSGyroDSU.tar.gz || exit 1
sudo rm LegionGoSGyroDSU.tar.gz

# fix a mistake I made in packaging, probably will fix it later
sudo mv LegionGoSGyro LegionGoSGyroDSU > /dev/null 2>&1
sudo chmod +x LegionGoSGyroDSU || exit 1

sudo cp lgsdsu.service /etc/systemd/system/ || exit 1

sudo systemctl daemon-reload || exit 1
sudo systemctl enable lgsdsu.service || exit 1
sudo systemctl start lgsdsu.service

sudo chmod +x check.sh uninstall.sh install.sh || exit 1

sudo cp fix-iio-sensor-hub.conf /etc/modules-load.d/ || exit 1

echo Installation complete, please reboot your system!
