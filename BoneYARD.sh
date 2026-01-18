#!/usr/bin/env bash

# This application will allow you to bury bones (files) with scents (tags) for later fetching.
# Scents will be stored in a simple json BoneYARD database.

# Copyright (c) 2025-2026 Pup Tony under GPLv3
# This software is free to use and modify, but must be distributed the same license
# Made with all the love I'm legally allowed to give!

set -euo pipefail

# For a future implementation:
# Restructure the script into separate files for each module/feature.
# This will make the script more readable and maintainable.
# Provide a flag in the main script that allows you to generate a standalone
# script with all the modules/features combined into a single file.
# Ensure that update mode is disabled when generating a standalone script.
# Name the standalone script "BoneYARD-standalone.sh" and make it executable.
# Check if the updater will copy over the new project scripts that will soon be added.
# Update README.md; this script is no longer going to be mainly standalone. You must
# generate it using the flag and, then, updates will be disabled.

# === GLOBALS START ===
# Doggy Bag Mode: No changes are written to the database until the user exits the TUI.
DOGGY_BAG_MODE=false
WORKING_DATABASE_FILE=""
SESSION_MODIFIED=false
DB_CACHE=""
CURRENT_LOCK_FILE=""
# Standalone flag (disables updater and module sourcing when true).
BONEYARD_STANDALONE=${BONEYARD_STANDALONE:-false}

# Global goodbye text array (empty by default, populated by module)
goodbye_text=()

# Global Variables
SOFTWARE_VERSION="1.5.0"
# This is the version of the database schema. 
# Backwards compatibility is maintained within the same major version (X.0.0).
# Software will refuse to run if the major version differs, or if the database 
# version is newer than the software version.
# BoneYARD (Yappy Archive and Retrieval Database)
DATABASE_VERSION="$SOFTWARE_VERSION" 
REMOTE_VERSION=""
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DATABASE_FILE="$SCRIPT_DIR/boneyard.json"
WORKING_DATABASE_FILE="$DATABASE_FILE"
DEFAULT_BACKUP_DIR="$HOME/Documents/boneyard_backups"
DIR_CACHE_FILE="/tmp/boneyard_dirs.txt"
FORCED_PAGER=""
WITH_DIR=false
WITH_DIR_SEP=","
CONTAINS_SEARCH=false

# === GLOBALS END ===

BONEYARD_MODULE_DIR="$SCRIPT_DIR/modules"

load_modules() {
    local missing=()
    local module
    for module in \
        "core.sh" \
        "cli.sh" \
        "tagging.sh" \
        "search.sh" \
        "organize.sh" \
        "remove.sh" \
        "stats.sh" \
        "yard.sh" \
        "export.sh" \
        "backups.sh" \
        "pager.sh" \
        "menu.sh"; do
        if [[ ! -f "$BONEYARD_MODULE_DIR/$module" ]]; then
            missing+=("$module")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing module files in $BONEYARD_MODULE_DIR:"
        printf "  - %s\n" "${missing[@]}"
        exit 1
    fi

    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/core.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/cli.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/tagging.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/search.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/organize.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/remove.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/stats.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/yard.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/export.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/backups.sh"
    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/pager.sh"

    # Load goodbye.sh with fallback (before menu.sh since menu.sh references goodbye_text)
    if [[ -f "$BONEYARD_MODULE_DIR/goodbye.sh" ]]; then
        # shellcheck source=/dev/null
        source "$BONEYARD_MODULE_DIR/goodbye.sh"
    else
        # Fallback goodbye messages if module not found (global array)
        goodbye_text=(
            "Woof woof! (Goodbye!)"
            "Tail wags for now!"
            "Stay paw-sitive!"
            "Bark at you later!"
            "Paws for thought!"
        )
    fi

    # shellcheck source=/dev/null
    source "$BONEYARD_MODULE_DIR/menu.sh"
}

generate_standalone() {
    local output="$1"

    if [[ "${BONEYARD_STANDALONE:-false}" == "true" ]]; then
        echo "This file is already standalone. Use the modular project to generate updates."
        return 1
    fi

    # If output is a directory, append the default filename
    if [[ -d "$output" ]]; then
        output="$output/BoneYARD-standalone.sh"
    fi

    local temp_output
    temp_output=$(mktemp /tmp/boneyard_standalone_XXXXXX.sh)

    {
        echo "#!/usr/bin/env bash"
        echo ""
        echo "set -euo pipefail"
        echo ""
        echo "BONEYARD_STANDALONE=true"
        echo "SCRIPT_DIR=\"\$(dirname \"\$(realpath \"\$0\")\")\""
        echo ""
        awk '/^# === GLOBALS START ===/{flag=1;next} /^# === GLOBALS END ===/{flag=0} flag{print}' "$SCRIPT_DIR/BoneYARD.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/core.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/cli.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/tagging.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/search.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/organize.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/remove.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/stats.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/yard.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/export.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/backups.sh"
        echo ""
        cat "$BONEYARD_MODULE_DIR/pager.sh"
        echo ""

        # Use simple fallback goodbye messages for standalone builds (before menu.sh)
        cat << 'EOF'
# Fallback goodbye messages for standalone builds (global array)
goodbye_text=(
    "Woof woof! (Goodbye!)"
    "Tail wags for now!"
    "Stay paw-sitive!"
    "Bark at you later!"
    "Paws for thought!"
)
EOF
        echo ""

        cat "$BONEYARD_MODULE_DIR/menu.sh"
        echo ""
        awk '/^# === MAIN START ===/{flag=1;next} /^# === MAIN END ===/{flag=0} flag{print}' "$SCRIPT_DIR/BoneYARD.sh"
    } > "$temp_output"

    mv "$temp_output" "$output"
    chmod +x "$output"
    echo "✓ Standalone script generated at: $output"
}

if [[ "${BONEYARD_STANDALONE:-false}" != "true" ]]; then
    load_modules
fi

# === MAIN START ===
main "$@"
# === MAIN END ===
