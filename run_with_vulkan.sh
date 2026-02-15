#!/bin/bash
# Try running Godot with Vulkan instead of Metal (workaround for gray screen on macOS)
# Use this if the game shows a gray screen when launched normally.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Try to find Godot - common locations
GODOT=""
for path in "/Applications/Godot.app/Contents/MacOS/Godot" \
            "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
            "/Applications/Godot_mono.app/Contents/MacOS/Godot"; do
    if [ -f "$path" ]; then
        GODOT="$path"
        break
    fi
done

if [ -z "$GODOT" ]; then
    echo "Godot not found. Install Godot or add its path to this script."
    echo "Then run: $GODOT --path . --rendering-driver vulkan"
    exit 1
fi

exec "$GODOT" --path . --rendering-driver vulkan "$@"
