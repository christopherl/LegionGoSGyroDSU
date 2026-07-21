# legion-go-2-gyro-dsu

A DSU motion server for the Lenovo Legion Go S and Legion Go 2 on Linux. It
publishes gyroscope and accelerometer data for applications that support the
DSU/Cemuhook protocol.

## Supported Devices

| Device | Motion backend | Selection with `auto` |
| ------ | -------------- | --------------------- |
| Legion Go S | Linux Industrial I/O (`gyro_3d` and `accel_3d`) | IIO |
| Legion Go 2 | Lenovo controller HID reports | Legion HID |

The Legion HID backend recognizes Lenovo vendor ID `0x17EF` with these product
IDs:

```text
0x6182  0x6183  0x6184  0x6185
0x61EB  0x61EC  0x61ED  0x61EE
```

## Credits

This repository is a fork of the original
[LegionGoSGyroDSU](https://github.com/Sooly890/LegionGoSGyroDSU) project by
[Sooly890](https://github.com/Sooly890). Thanks to the upstream author and
contributors for the initial implementation.

The current service, binary and installation directory still use the upstream
`LegionGoSGyroDSU` naming internally.

## Installation

Make sure your user has a password set first. If not, run:

```bash
passwd
```

Then run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/christopherl/legion-go-2-gyro-dsu/main/scripts/install.sh | bash
```

The project is installed to:

```text
/LegionGoSGyroDSU
```

The installed systemd service runs as root, which gives it access to both the
Legion Go S IIO devices and the Legion Go 2 `/dev/hidraw*` controller
interface.

The installer downloads the latest release archive from this repository. On the
Legion Go S, reboot after installation so the IIO driver configuration is
applied early. You can try to avoid a reboot by loading the module and
restarting the service manually:

```bash
sudo modprobe hid_sensor_hub
sudo systemctl restart lgsdsu.service
```

If the IIO devices still do not appear, reboot the device.

## Configuration

Configuration is currently done through environment variables in the `systemd`
service file:

```bash
sudo nano /etc/systemd/system/lgsdsu.service
```

| Environment variable  | Default value                             | Description                                           |
| --------------------- | ----------------------------------------- | ----------------------------------------------------- |
| `LGSDSU_PORT`         | `26760`                                   | DSU server UDP port                                   |
| `LGSDSU_IP`           | `127.0.0.1`                               | Bind IP. Use `0.0.0.0` to allow external clients.     |
| `LGSDSU_GYRO_MATRIX`  | `-x,-y,z` (IIO) / `x,z,y` (Legion HID)    | Orientation matrix for the gyroscope                  |
| `LGSDSU_ACCEL_MATRIX` | `x,z,-y` (IIO) / `x,y,z` (Legion HID)     | Orientation matrix for the accelerometer              |

The default matrix depends on which motion backend is active. The IIO backend's
kernel gyro driver and the Legion HID controller's IMU use different physical
axis layouts, so the same matrix does not orient both correctly. Override the
variable if your controller still needs adjustment.

### Motion Source

Motion-source selection defaults to `auto`:

1. Search `/dev/hidraw*` for a supported Lenovo controller interface.
2. Verify the vendor ID, product ID, and HID usage page.
3. Enable controller IMU reporting and use the Legion HID backend.
4. If no usable controller interface is found, use IIO.

This selects controller HID motion on the Legion Go 2 and IIO on the Legion Go
S without requiring a command-line option.

To select a backend explicitly, pass:

```bash
sudo /LegionGoSGyroDSU/LegionGoSGyroDSU --motion-source=iio
sudo /LegionGoSGyroDSU/LegionGoSGyroDSU --motion-source=legion-hid
```

`--motion-source=legion-hid` also falls back to IIO if no usable Legion HID
interface is found.

To set an explicit backend for the installed service, append the option to its
`ExecStart` line. For example:

```ini
ExecStart=/LegionGoSGyroDSU/LegionGoSGyroDSU --motion-source=legion-hid
```

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

### Checking the Selected Backend

Stop the service and run the program in a terminal to see which backend is
selected:

```bash
sudo systemctl stop lgsdsu.service
sudo /LegionGoSGyroDSU/LegionGoSGyroDSU --motion-source=auto
```

Successful HID selection prints the selected `/dev/hidraw*` path. If HID is not
available, the program reports that it is using IIO instead.

### Legion Go 2 HID Troubleshooting

List the available raw HID devices and their Lenovo identifiers:

```bash
for device in /sys/class/hidraw/hidraw*/device/uevent; do
    echo "$device"
    grep -E 'HID_ID|HID_NAME' "$device"
done
```

The controller must use vendor ID `17EF`, one of the supported product IDs
listed above, and expose the Lenovo vendor interface. When running the binary as
a regular user, permission to open the selected `/dev/hidraw*` device for both
reading and writing is required because initialization packets must be sent. The
installed root service already has this access.

If another controller-management daemon owns or continuously reconfigures the
same HID interface, stop it temporarily while testing.

### Legion Go S IIO Troubleshooting

The gyro and accelerometer are exposed as IIO devices. If they do not appear,
run the bundled check script:

```bash
sudo /LegionGoSGyroDSU/check.sh
```

The installer also installs `fix-iio-sensor-hub.conf`, which forces the
`hid_sensor_hub` module to load early. This works around systems where the
sensor hub is claimed too late and the IIO devices never appear.

### Root Access

The IIO backend requires root access to enable buffered high-speed sensor
access. The HID backend needs read/write access to its hidraw interface. The
provided service runs as root and satisfies both requirements.

### Additional Troubleshooting

If you cannot determine the error, run the application directly in a terminal.

```bash
sudo systemctl stop lgsdsu.service
sudo /LegionGoSGyroDSU/LegionGoSGyroDSU --motion-source=auto
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

Building directly on either handheld is not recommended. Use another Arch Linux
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

Run the protocol decoder tests with CTest:

```bash
ctest --test-dir build --output-on-failure
```

### Legion HID Protocol Status

The report ID, IMU byte layout, signed big-endian decoding, scaling factors,
side-specific axis signs, and supported identifiers are kept in
`src/legion_hid_protocol.cpp`. The axis signs normalize the different physical
orientations of the left and right controllers before the existing
user-configurable DSU matrices are applied.

The following protocol details still require confirmation across real
controller firmware versions and are deliberately isolated there:

- the high-quality report activation command;
- the assumption that one 8-bit timestamp step represents 8 milliseconds;
- the side-specific axis signs on Legion Go 2 production hardware.

Please include the controller product ID, firmware version, selected hidraw
path, and observed report rate when reporting Legion Go 2 HID problems.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
