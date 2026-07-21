# legion-go-2-gyro-dsu

DSU motion server for Lenovo Legion Go devices on SteamOS-style Linux systems.

This project reads gyro and accelerometer data through Linux IIO and exposes it
through the DSU protocol, so emulators and other DSU-compatible clients can use
the device motion sensors as controller input.

This repository is a fork of `LegionGoSGyroDSU`. The current service, binary and
installation directory still use the upstream `LegionGoSGyroDSU` naming
internally.

## Credits

This project is based on the original
[LegionGoSGyroDSU](https://github.com/Sooly890/LegionGoSGyroDSU) project by
[Sooly890](https://github.com/Sooly890). Thanks to the upstream author and
contributors for the initial implementation.

## Features

- Reads gyroscope and accelerometer data from IIO devices
- Serves motion data over the DSU protocol
- Runs as a `systemd` service
- Supports configurable bind IP, port and sensor orientation matrices
- Includes an IIO sensor-hub module-load workaround for systems where the
  motion devices do not appear reliably

## Installation

Make sure your user has a password set first. If not, run:

```bash
passwd
```

Then run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/christopherl/legion-go-2-gyro-dsu/main/scripts/install.sh | bash
```

The installer places the project in:

```text
/LegionGoSGyroDSU
```

After installation, reboot so the IIO sensor devices are initialized correctly.

The release archive URL is defined in `scripts/install.sh`. If you publish your
own releases from this fork, update that script to point at this repository.

## Configuration

Configuration is currently done through environment variables in the `systemd`
service file:

```bash
sudo nano /etc/systemd/system/lgsdsu.service
```

| Environment variable  | Default     | Description                                           |
| --------------------- | ----------- | ----------------------------------------------------- |
| `LGSDSU_PORT`         | `26760`     | DSU server UDP port                                   |
| `LGSDSU_IP`           | `127.0.0.1` | Bind IP. Use `0.0.0.0` to allow external clients.     |
| `LGSDSU_GYRO_MATRIX`  | `-x,-y,z`   | Orientation matrix for the gyroscope                  |
| `LGSDSU_ACCEL_MATRIX` | `x,z,-y`    | Orientation matrix for the accelerometer              |

After editing the service file, reload and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart lgsdsu.service
```

Updates may overwrite manual edits to the service file.

## Sensor Orientation

If motion directions feel wrong in a client, adjust the gyro and accelerometer
matrices in `lgsdsu.service`.

Matrix values map to DSU axes like this:

| Value | Motion axis |
| ----- | ----------- |
| `x`   | Pitch       |
| `y`   | Roll        |
| `z`   | Yaw         |

Use a minus sign to invert an axis, for example `-x`.

The accelerometer matters too: it can affect gyro calibration because gravity is
part of the accelerometer reading. If gyro movement looks correct but still
drifts or calibrates strangely, check the accelerometer matrix as well.

## Troubleshooting

### IIO devices are missing

The gyro and accelerometer are exposed as IIO devices. If they do not appear,
run the bundled check script:

```bash
sudo /LegionGoSGyroDSU/check.sh
```

The installer also installs `fix-iio-sensor-hub.conf`, which forces the
`hid_sensor_hub` module to load early. This works around systems where the
sensor hub is claimed too late and the IIO devices never appear.

### Service does not work

Stop the background service and run the binary directly to see its output:

```bash
sudo systemctl stop lgsdsu.service
sudo /LegionGoSGyroDSU/LegionGoSGyroDSU
sudo systemctl start lgsdsu.service
```

### Port already in use

The default DSU port is `26760`. If another DSU server is already using that
port, such as SteamDeckDSU, stop it or change `LGSDSU_PORT` in the service file.

## Uninstallation

```bash
sudo /LegionGoSGyroDSU/uninstall.sh
```

## Development

Building directly on the handheld is not recommended. Use another Arch Linux
machine or a compatible Arch-based environment.

Install dependencies:

```bash
sudo pacman -S base-devel cmake asio libiio
```

Clone and build:

```bash
git clone https://github.com/christopherl/legion-go-2-gyro-dsu.git
cd legion-go-2-gyro-dsu
scripts/build.sh Release
```

Create a release archive:

```bash
scripts/package.sh
```

This creates:

```text
LegionGoSGyroDSU.tar.gz
```

The archive name is kept for compatibility with the current installer.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
