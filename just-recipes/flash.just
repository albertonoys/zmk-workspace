# flash firmware to the keyboard
[group('ZMK')]
flash:
    #!/usr/bin/env bash
    set -euo pipefail

    # Detect OS and set mount point
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MOUNT_POINT="/Volumes/NICENANO"
    else
        MOUNT_POINT="/media/$USER/NICENANO"
    fi

    FIRMWARE_DIR="{{ out }}"

    # Check if firmware directory exists
    if [ ! -d "$FIRMWARE_DIR" ]; then
        gum style --foreground 196 "Error: Firmware directory not found at $FIRMWARE_DIR"
        exit 1
    fi

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

    # Function to copy firmware
    copy_firmware() {
        local firmware=$1
        local half=$2
        local error_output

        if ! gum confirm "Do you want to flash $firmware to the $half half?"; then
            gum style --foreground 212 "Skipping $half half firmware update"
            return
        fi

        error_output=$(gum spin --spinner dot --title "Copying $half half firmware..." -- bash -c "
            cp '$FIRMWARE_DIR/$firmware' '$MOUNT_POINT/$firmware' 2>&1
        ")
        if [ $? -eq 0 ]; then
            gum style --foreground 212 "✓ Copied $firmware to $MOUNT_POINT"
        else
            gum style --foreground 196 "Error copying $firmware"
            gum style --foreground 196 "Error details: $error_output"
            exit 1
        fi
    }

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

    # Main process
    gum style \
        --border normal \
        --margin "1" \
        --padding "1" \
        --border-foreground 212 \
        "Split keyboard firmware updater"

    # Find left and right firmware files
    LEFT_FIRMWARE=$(find_firmware "left")
    RIGHT_FIRMWARE=$(find_firmware "right")

    # Wait for initial mount
    wait_for_mount "mount" "Waiting for left half to be mounted..."

    # Copy left firmware
    copy_firmware "$LEFT_FIRMWARE" "left"

    # Wait for unmount
    wait_for_mount "unmount" "Waiting for left half to be unmounted..."

    # Wait for mount again
    wait_for_mount "mount" "Waiting for right half to be mounted..."

    # Copy right firmware
    copy_firmware "$RIGHT_FIRMWARE" "right"

    # Wait for final unmount
    wait_for_mount "unmount" "Waiting for final unmount..."

    gum style \
        --border normal \
        --margin "1" \
        --padding "1" \
        --border-foreground 212 \
        "Keeb flashed successfully! 🎉"
