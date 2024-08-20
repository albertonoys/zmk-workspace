# flash firmware to the keyboard
[group('ZMK')]
flash:
    #!/usr/bin/env bash

    FIRMWARE_DIR="{{ out }}"

    # Detect OS and set mount point
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MOUNT_POINT="/Volumes/NICENANO"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        MOUNT_POINT="/media/$USER/NICENANO"
    else
        echo "Error: Unsupported operating system: $OSTYPE" >&2
        exit 1
    fi

    # Function to find firmware file
    find_firmware() {
        local side=$1
        local firmware=$(find "$FIRMWARE_DIR" -name "*$side*.uf2" -printf "%f\n")
        if [ -z "$firmware" ]; then
            gum style --foreground 196 "Error: No $side firmware found in $FIRMWARE_DIR"
            exit 1
        fi
        echo "$firmware"
    }

    # Function to wait for mount/unmount with timeout
    wait_for_mount() {
        local action=$1
        local message=$2
        local timeout=60
        gum spin --spinner dot --title "$message" -- bash -c "
            start_time=\$(date +%s)
            while true; do
                current_time=\$(date +%s)
                if [ \$((current_time - start_time)) -ge $timeout ]; then
                    echo 'timeout'
                    exit 1
                fi
                if [ '$action' = 'mount' ] && [ -d '$MOUNT_POINT' ]; then
                    break
                elif [ '$action' = 'unmount' ] && [ ! -d '$MOUNT_POINT' ]; then
                    break
                fi
                sleep 1
            done
        "
        if [ $? -ne 0 ]; then
            gum style --foreground 196 "Timeout waiting for $action"
            exit 1
        fi
    }

    flash_firmware() {
        local firmware_file=$1
        local side=$2
        local firmware_name=$3

        gum spin --spinner dot --title "Copying $half half firmware..." -- bash -c "
            cp "$firmware_file" "$MOUNT_POINT/" > /dev/null 2>&1 && sleep 2"

        gum style --foreground 212 "✓ Successfully flashed ${firmware_name} to ${side} half"
    }

    # Check if firmware directory exists
    if [ ! -d "$FIRMWARE_DIR" ]; then
        gum style --foreground 196 "Error: Firmware directory not found at $FIRMWARE_DIR"
        exit 1
    fi

    # Find left and right firmware files
    LEFT_FIRMWARE=$(find_firmware "left")
    RIGHT_FIRMWARE=$(find_firmware "right")
    LEFT_FIRMWARE_NAME=$(basename $LEFT_FIRMWARE)
    RIGHT_FIRMWARE_NAME=$(basename $RIGHT_FIRMWARE)

    # Wait for initial mount
    wait_for_mount "mount" "Waiting for left half to be mounted..."

    # Flash left firmware
    flash_firmware "$LEFT_FIRMWARE" "left" "$LEFT_FIRMWARE_NAME"

    # Wait for unmount
    wait_for_mount "unmount" "Waiting for left half to be unmounted..."

    # Wait for mount again
    wait_for_mount "mount" "Waiting for right half to be mounted..."

    # Copy right firmware
    flash_firmware "$RIGHT_FIRMWARE" "right" "$RIGHT_FIRMWARE_NAME"

    # Wait for final unmount
    wait_for_mount "unmount" "Waiting for final unmount..."

    gum style --padding "1" "Firmware flashing process completed successfully! 🎉"
