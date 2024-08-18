# flash firmware to the keyboard
[group('ZMK')]
flash:
    #!/usr/bin/env bash

    # Detect OS and set mount point
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MOUNT_POINT="/Volumes/NICENANO"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MOUNT_POINT="/media/$USER/NICENANO"
    else
        echo "Error: Unsupported operating system: $OSTYPE" >&2
        exit 1
    fi

    firmware_dir="{{ out }}"
    left_firmware=$(find "$firmware_dir" -name "*left*.uf2")
    right_firmware=$(find "$firmware_dir" -name "*right*.uf2")

    # Check if firmware directory exists
    if [ ! -d "$FIRMWARE_DIR" ]; then
        gum style --foreground 196 "Error: Firmware directory not found at $FIRMWARE_DIR"
        exit 1
    else
        left_firmware_name=$(basename "$left_firmware")
        right_firmware_name=$(basename "$right_firmware")
    fi

    echo "Found firmware files:"
    echo "Left: $left_firmware_name"
    echo "Right: $right_firmware_name"

    flash_side() {
        local side=$1
        local firmware_file=$2
        local firmware_name=$3
        echo "Waiting for ${side} half to be mounted..."
        while [ ! -d "$MOUNT_POINT" ]; do
            sleep 1
        done

        echo "Copying ${side} firmware..."
        sleep 2

        cp "$firmware_file" "$MOUNT_POINT/" > /dev/null 2>&1

        while [ -d "$MOUNT_POINT" ]; do
            sleep 1
        done

        echo "✓ Successfully flashed ${side} half"
    }

    flash_side "left" "$left_firmware" "$left_firmware_name"
    flash_side "right" "$right_firmware" "$right_firmware_name"

    echo "Firmware flashing process completed successfully! 🎉"
