draw-watch:
    #!/usr/bin/env bash
    set -euo pipefail

    KEYMAP_FILE="{{ config }}/{{ draw_keymap }}.keymap"
    TIMESTAMP_FILE="{{ draw }}/.last_draw_timestamp"
    SVG_FILE="{{ draw }}/{{ draw_keymap }}.svg"

    # Create timestamp file if it doesn't exist
    touch -a "$TIMESTAMP_FILE"

    while true; do
        if [[ "$KEYMAP_FILE" -nt "$TIMESTAMP_FILE" ]]; then
            echo "Keymap file changed. Running draw command..."
            just draw
            echo "Keymap SVG generated. Waiting for at least 60 seconds..."
            sleep 60
        else
            sleep 1
        fi
    done
