#!/usr/bin/env bash

# This script is used to test the upgrade process of the software.

declare -A available_versions=(
    [1.5.8]="f3c4cf6"
    [1.5.7]="65edf83"
    [1.5.6]="1dca5c9"
    [1.5.5]="eb5b823"
    [1.5.4]="9d6928b"
    [1.5.1]="c774cd9"
    [1.4.2]="de1118f"
    [1.4.1]="efd28da"
    [1.3.0]="3875053"
    [1.2.0]="bc96d4e"
    [1.1.1]="d98d299"
    [1.0.5]="e87a8ca"
    [1.0.4]="06b6734"
    [1.0.3]="b134d05"
    [1.0.2]="29844d5"
)
declare -A version_blurbs=(
    [1.5.8]="Added BONEYARD_UPGRADE_COMMIT environment variable support for testing."
    [1.5.7]="Implemented database resilience overhaul and bulk scent editing."
    [1.5.6]="Overhauled bulk update engine for speed and stability."
    [1.5.5]="Fixed critical Bash syntax error in tagging module."
    [1.5.4]="Fixed bulk scent selection bugs in tagging menu."
    [1.5.1]="Added Fuzzy Scent Matching feature for easier bone discovery."
    [1.4.2]="Optimized standalone script generation."
    [1.4.1]="Enhanced goodbye messages with holiday awareness and cultural inclusivity."
    [1.3.0]="Enhanced search, export functionality, and date operations."
    [1.2.0]="Doggy Bag mode, Snapshot management, and Health checks."
    [1.1.1]="Session Scents tracker and UI refinements for bulk tagging."
    [1.0.5]="Smart directory tagging and polished UI."
    [1.0.4]="Integrated Changelog viewer and robust updater fixes."
    [1.0.3]="Integrated 'Rebuild Doghouse' updater and background version check."
    [1.0.2]="Update BoneYARD to v1.0.2"
)

clear
gum style --foreground 212 --border double --padding "1 2" "🐾 BoneYARD Upgrade Testing"
echo "This script will test the upgrade process of the software."
echo ""

# Create formatted options array combining version and blurb, sorted newest to oldest
formatted_options=()
# Sort versions from newest to oldest (version sort, reverse order)
sorted_versions=$(printf '%s\n' "${!available_versions[@]}" | sort -V -r)
for version in $sorted_versions; do
    blurb="${version_blurbs[$version]:-No description available}"
    formatted_options+=("$version - $blurb")
done

selected_formatted=$(gum choose --header "Select a version to test FROM" "${formatted_options[@]}")
selected_version=$(echo "$selected_formatted" | cut -d' ' -f1)
selected_commit=${available_versions[$selected_version]}

selected_upgrade_formatted=$(gum choose --header "Select a version to test TO" "${formatted_options[@]}")
selected_upgrade_version=$(echo "$selected_upgrade_formatted" | cut -d' ' -f1)
selected_upgrade_commit=${available_versions[$selected_upgrade_version]}

echo "Testing upgrade from $selected_version ($selected_commit) to $selected_upgrade_version ($selected_upgrade_commit)"

# Check if the FROM version supports specific commit upgrades
# Only versions 1.5.7 and later support BONEYARD_UPGRADE_COMMIT
if [[ "$selected_version" != "1.5.7" ]]; then
    echo ""
    gum style --foreground 208 --border double --padding "1 2" "⚠️  VERSION COMPATIBILITY WARNING"
    echo "The selected FROM version ($selected_version) does not support upgrading to specific commits."
    echo "Instead of upgrading to $selected_upgrade_version, it will upgrade to the latest available version."
    echo ""
    echo "This is because older versions don't recognize the BONEYARD_UPGRADE_COMMIT environment variable."
    echo ""
    if ! gum confirm "Continue with upgrade test anyway?"; then
        echo "Upgrade test cancelled."
        exit 0
    fi
fi

# Export variables for the subshell
export SELECTED_FROM_COMMIT="$selected_commit"
export SELECTED_TO_COMMIT="$selected_upgrade_commit"

echo "Launching BoneYARD at version $selected_version for upgrade testing..."
echo "It will attempt to upgrade to version $selected_upgrade_version"
echo ""

# Check if we have a display available for GUI terminals
if [[ -n "$DISPLAY" ]] || [[ -n "$WAYLAND_DISPLAY" ]]; then
    # GUI environment available, use kitty
    kitty --class "floating-windows" -e bash -c "
        timestamp=\$(date +%s)
        echo 'Setting up test environment...'
        git clone https://github.com/lovelyspacedog/BoneYARD.git \"/tmp/boneyard-upgrade-test-\$timestamp\"
        cd \"/tmp/boneyard-upgrade-test-\$timestamp\"
        echo \"Checking out FROM version: \$SELECTED_FROM_COMMIT\"
        git checkout \"\$SELECTED_FROM_COMMIT\"
        echo \"Setting upgrade target to: \$SELECTED_TO_COMMIT\"
        export BONEYARD_UPGRADE_COMMIT=\"\$SELECTED_TO_COMMIT\"
        echo 'Launching BoneYARD...'
        bash BoneYARD.sh
        echo ''
        read -p 'Press Enter to close this test window...'
        echo 'Cleaning up test environment...'
        rm -rf \"/tmp/boneyard-upgrade-test-\$timestamp\"
        echo 'Cleanup complete.'
    "
else
    # No GUI available, run directly in current terminal
    echo "No GUI display detected. Running upgrade test in current terminal..."
    timestamp=$(date +%s)
    echo 'Setting up test environment...'
    git clone https://github.com/lovelyspacedog/BoneYARD.git "/tmp/boneyard-upgrade-test-$timestamp"
    cd "/tmp/boneyard-upgrade-test-$timestamp"
    echo "Checking out FROM version: $SELECTED_FROM_COMMIT"
    git checkout "$SELECTED_FROM_COMMIT"
    echo "Setting upgrade target to: $SELECTED_TO_COMMIT"
    export BONEYARD_UPGRADE_COMMIT="$SELECTED_TO_COMMIT"
    echo 'Launching BoneYARD...'
    bash BoneYARD.sh
    echo ''
    read -p 'Press Enter to close this test window...'
    echo 'Cleaning up test environment...'
    rm -rf "/tmp/boneyard-upgrade-test-$timestamp"
    echo 'Cleanup complete.'
fi