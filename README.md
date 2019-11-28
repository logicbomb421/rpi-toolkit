# Raspberry Pi Toolkit

All Bash scripts were written on macOS, but should work on most Linux distros.

## Creating Images

Images will be created with SSH enabled and `newpi.sh` copied to the `/boot` directory.

### Prerequisites

GNU Coreutils 8.24+ must be installed (uses the `status` param added to `dd`)

### Running

Run `./flash-sd-card.sh` with desired options:

|Option|Description|Required|Default|
|---|---|---|---|
|`-d`|The device (e.g SD Card) to write to.|Yes||
|`-i`|The `img` file to write to the device.|Yes||
|`-E`|Don't eject the device when complete.|No|`False`|
|`-p`|The partition on the device to unmount before writing the image.|No||

