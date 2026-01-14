#!/usr/bin/env bash

# This application will allow you to bury bones (files) with scents (tags) for later fetching.
# Scents will be stored in a simple json BoneYARD database.

# Copyright (c) 2025-2026 Pup Tony under GPLv3
# This software is free to use and modify, but must be distributed the same license
# Made with all the love I'm legally allowed to give!

set -euo pipefail

# Global Variables
SOFTWARE_VERSION="1.0.3"
# This is the version of the database schema. 
# Backwards compatibility is maintained within the same major version (X.0.0).
# Software will refuse to run if the major version differs, or if the database 
# version is newer than the software version.
# BoneYARD (Yappy Archive and Retrieval Database)
DATABASE_VERSION="$SOFTWARE_VERSION" 
REMOTE_VERSION=""
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DATABASE_FILE="$SCRIPT_DIR/boneyard.json"
DIR_CACHE_FILE="/tmp/boneyard_dirs.txt"
FORCED_PAGER=""
WITH_DIR=false
WITH_DIR_SEP=","
CONTAINS_SEARCH=false

# Goodbye phrases; yeah I know they're cheesy, but I'm a dog person.
declare -a goodbye_text=(
    "Woof woof! (Goodbye!)"
    "Tail wags for now!"
    "Catch you at the park!"
    "See you later, pup!"
    "Bone-voyage!"
    "Stay paw-sitive!"
    "Paws out!"
    "Fur-well!"
    "Un-leash the fun until next time!"
    "Stop, drop, and roll over!"
    "Hope your day is paw-some!"
    "Bark at you later!"
    "Have a howling good time!"
    "Don't work too hard, stay ruff!"
    "Keep your tail held high!"
    "Stay furry, my friend!"
    "A round of a-paws for your work today!"
    "Fur-ever yours!"
    "Sniff you soon!"
    "Be the good boy I know you are!"
    "Time to go for a walkies!"
    "Back to the kennel!"
    "Rest your paws!"
    "Stay fetching!"
    "Don't stop re-triever-ing!"
    "Paws and reflect on a job well done!"
    "You're the leader of the pack!"
    "Wag more, bark less!"
    "Life is ruff, but you're doing great!"
    "Everything is paw-sible!"
    "You're a real treat!"
    "No more digging for today!"
    "Go fetch some rest!"
    "Stay paws-ed until we meet again!"
    "A-woooooo! (See ya!)"
    "Keep on wagging!"
    "Hope your dreams are full of squirrels!"
    "Keep your nose to the ground!"
    "Stay loyal to the yard!"
    "You've earned a gold medal in fetching!"
    "Quit hounding me and go play!"
    "See you in the dog days!"
    "You're the top dog!"
    "Don't let the cat get your tongue!"
    "Pawsitively finished for now!"
    "Time to curl up and nap!"
    "Lick you later!"
    "Sniff out some fun!"
    "Keep your ears up!"
    "Stay paw-some!"
    "Woofing you all the best!"
    "Catch you on the flip-flop (or the flip-paw)!"
    "Happy trails and wagging tails!"
    "Don't bark up the wrong tree!"
    "You're a fur-midable human!"
    "Stay dogged in your pursuits!"
    "A wagging tail is a happy heart!"
    "Chew on that until next time!"
    "Paws for thought!"
)

# Argument Parsing
show_help() {
    cat <<EOF
🐾 BoneYARD v$SOFTWARE_VERSION (Yappy Archive and Retrieval Database)
A powerful, interactive TUI system for burying and fetching bones using JSON.

USAGE:
  $(basename "$0") [options]

OPTIONS:
  -d, --database FILE    Specify a custom BoneYARD JSON file.
                         Defaults to: $SCRIPT_DIR/boneyard.json
  -t, --tags FILE        Output comma-delimited scents for a specific bone.
                         Accepts full path or just a bone name.
                         Exit codes: 0=found, 1=not found, N=match count.
  --with-dir [use SEP]  When used with --tags, appends kennel components
                         and the bone name to the output scents.
                         Optionally use 'use SEP' to set a custom separator 
                         (e.g., --with-dir use ":") between the kennel branch
                         and the scents. (Default: comma).
  --contains             When used with --tags, enables case-insensitive 
                         "contains" searching instead of exact matching.
  --pager PAGER          Force a specific pager (nvim, nano, less) for the rules.
                         Use 'safe' for the built-in 5-line-at-a-time viewer.
  -h, -?, --help         Show this comprehensive help message.

MAIN FEATURES:
  Bury New Bone       Pick a bone using ranger and assign searchable scents.
  Bury Entire Litter  Batch-bury an entire kennel with interactive 
                      copy/undo/skip/all functionality.
  Update Scents       Quickly update scents for any bone in the yard.
  Fetch Bones         Filter by scent, bone name (contains), or kennel.
  Show Pack Stats     View scent frequency, kennel counts, and recent activity.
  Switch Yard         Open a different JSON database file (bones are not moved).
  Rebuild Doghouse    Install the latest version from GitHub (Update Available!).
  Incinerate Yard     Permanently wipe the yard with high-security 
                      phrase confirmation and fuzzy-match recovery.

BONE PREVIEWS:
  Users in the Kitty terminal will see automatic previews of images 
  and videos (via thumbnails) during the tagging process.

EXAMPLES:
  # Launch interactive TUI (default)
  $(basename "$0")

  # Launch with a specific boneyard file
  $(basename "$0") --database ~/backups/boneyard.json

  # Get scents for a bone (exact match)
  $(basename "$0") --tags "report.pdf"

  # Find scents for all bones containing 'script' and include kennel info
  $(basename "$0") -t "script" --contains --with-dir use " | "

  # View rules using the built-in safe pager
  $(basename "$0") --pager safe

ENVIRONMENT:
  Requires: jq, ranger, gum, shuf, file, curl, git
  Optional: play (from sox) for menu audio feedback.

Copyright (c) 2025$([[ $(date +%Y) != "2025" ]] && echo "-$(date +%Y)") Pup Tony under GPLv3.
EOF
}

double_bark_sfx() {
    command -v play &> /dev/null || return 0
    # Sequence two distinct barks in the background
    (
        # First Bark: Higher and sharper
        play -q -n synth 0.12 sine 500:150 vol 0.4 < /dev/null > /dev/null 2>&1
        # Second Bark: Slightly lower and deeper
        play -q -n synth 0.12 sine 450:100 vol 0.4 < /dev/null > /dev/null 2>&1
    ) &
}

# Output tags for a specific file and exit
get_tags_for_file() {
    local target="$1"
    local matches

    if [[ "$target" == *"/"* ]]; then
        # It's a path
        local full_path
        full_path=$(realpath "$target" 2>/dev/null || echo "$target")
        local name=$(basename "$full_path")
        local path=$(dirname "$full_path")
        
        if [[ "$CONTAINS_SEARCH" == "true" ]]; then
            matches=$(jq -c --arg name "$name" --arg path "$path" \
                '.files[] | select((.name | ascii_downcase | contains($name | ascii_downcase)) and (.path | ascii_downcase | contains($path | ascii_downcase)))' \
                "$DATABASE_FILE")
        else
            matches=$(jq -c --arg name "$name" --arg path "$path" \
                '.files[] | select(.name == $name and .path == $path)' "$DATABASE_FILE")
        fi
    else
        # It's just a bone name
        if [[ "$CONTAINS_SEARCH" == "true" ]]; then
            matches=$(jq -c --arg name "$target" \
                '.files[] | select(.name | ascii_downcase | contains($name | ascii_downcase))' "$DATABASE_FILE")
        else
            matches=$(jq -c --arg name "$target" \
                '.files[] | select(.name == $name)' "$DATABASE_FILE")
        fi
    fi

    if [[ -z "$matches" ]]; then
        echo "Error: Bone not found in BoneYARD: $target" >&2
        exit 1
    fi

    local count
    count=$(echo "$matches" | jq -s 'length')
    
    if [[ "$WITH_DIR" == "true" ]]; then
        echo "$matches" | jq -r --arg sep "$WITH_DIR_SEP" \
            '((.path | split("/") | map(select(. != ""))) + [.name] | join(",")) + $sep + (.tags | join(","))'
    else
        echo "$matches" | jq -r '.tags | join(",")'
    fi

    if [[ $count -eq 1 ]]; then
        exit 0
    else
        exit "$count"
    fi
}

parse_arguments() {
    local tag_query_file=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--database)
                if [[ -n "${2:-}" ]]; then
                    DATABASE_FILE=$(realpath "$2")
                    shift 2
                else
                    echo "Error: --database requires a file path argument."
                    exit 1
                fi
                ;;
            -t|--tags)
                if [[ -n "${2:-}" ]]; then
                    tag_query_file="$2"
                    shift 2
                else
                    echo "Error: --tags requires a file argument."
                    exit 1
                fi
                ;;
            --with-dir)
                WITH_DIR=true
                if [[ "${2:-}" == "use" && -n "${3:-}" ]]; then
                    WITH_DIR_SEP="$3"
                    shift 3
                else
                    shift
                fi
                ;;
            --contains)
                CONTAINS_SEARCH=true
                shift
                ;;
            --pager)
                if [[ -n "${2:-}" ]]; then
                    FORCED_PAGER="$2"
                    shift 2
                else
                    echo "Error: --pager requires an argument (e.g. nvim, less, or 'safe')."
                    exit 1
                fi
                ;;
            -h|-\?|--help)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # Execute Tag Query if requested
    if [[ -n "$tag_query_file" ]]; then
        if [[ ! -f "$DATABASE_FILE" ]]; then
            echo "Error: Database file not found: $DATABASE_FILE" >&2
            exit 1
        fi
        get_tags_for_file "$tag_query_file"
    fi

    # Validate Database File Path for TUI mode
    if [[ ! -f "$DATABASE_FILE" ]]; then
        local db_dir
        db_dir=$(dirname "$DATABASE_FILE")
        if [[ ! -w "$db_dir" ]]; then
            echo "Error: Database file does not exist and directory is not writable: $db_dir"
            exit 1
        fi
    fi
}

# Check if dependencies are installed
check_dependencies() {
    local missing_deps=()
    for dep in jq ranger gum shuf file curl git; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        typewrite "Error: The following dependencies are required but not installed:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        typewrite "Install them with: sudo pacman -S ${missing_deps[*]} (Arch Linux)"
        exit 1
    fi
}

# Typewriter effect for text
typewrite() {
    local text="$1"
    local delay="${2:-0.03}"
    local i
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "\n"
    sleep 0.5
}

# Display a preview of the bone if it's an image or video (Kitty only)
display_bone_preview() {
    local file_path="$1"
    
    # Use kitty's own detection to see if graphics are supported
    if ! command -v kitty &> /dev/null; then
        return 0
    fi
    
    if ! kitty +kitten icat --detect-support &>/dev/null; then
        return 0
    fi

    local mime_type
    mime_type=$(file --mime-type -b "$file_path" 2>/dev/null || echo "")

    if [[ "$mime_type" == image/* ]] || [[ "$mime_type" == video/* ]]; then
        echo ""
        gum style --foreground 212 "  🖼️  Bone Preview:"
    fi

    if [[ "$mime_type" == image/* ]]; then
        # Display image using kitty icat
        if command -v magick &> /dev/null; then
            local thumb_path="/tmp/boneyard_img_thumb.png"
            if magick "$file_path" -resize 400x400\> "$thumb_path" 2>/dev/null && [[ -f "$thumb_path" ]]; then
                kitty +kitten icat --silent --transfer-mode stream --align left "$thumb_path"
                rm -f "$thumb_path"
            else
                # Fallback if magick fails
                kitty +kitten icat --silent --transfer-mode stream --align left "$file_path"
            fi
        else
            kitty +kitten icat --silent --transfer-mode stream --align left "$file_path"
        fi
    elif [[ "$mime_type" == video/* ]]; then
        # Check for ffmpeg to generate a thumbnail
        if command -v ffmpeg &> /dev/null; then
            local thumb_path="/tmp/boneyard_preview_thumb.jpg"
            # Try to grab a frame at 10 seconds, fallback to 0 if video is shorter
            if ffmpeg -hide_banner -loglevel error -ss 10 -i "$file_path" -frames:v 1 -vf "scale=400:-1" "$thumb_path" -y || \
               ffmpeg -hide_banner -loglevel error -i "$file_path" -frames:v 1 -vf "scale=400:-1" "$thumb_path" -y; then
                
                if [[ -f "$thumb_path" ]]; then
                    kitty +kitten icat --silent --transfer-mode stream --align left "$thumb_path"
                    rm -f "$thumb_path"
                fi
            fi
        fi
    fi
    # Give the terminal a tiny moment to render the image before the next command
    sleep 0.05
}

# Compare two semantic versions
# Returns: 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
version_compare() {
    if [[ "$1" == "$2" ]]; then return 0; fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<3; i++)); do ver1[i]=0; done
    # fill empty fields in ver2 with zeros
    for ((i=${#ver2[@]}; i<3; i++)); do ver2[i]=0; done
    for ((i=0; i<3; i++)); do
        if ((10#${ver1[i]} > 10#${ver2[i]})); then return 1; fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then return 2; fi
    done
    return 0
}

# Fetch the latest version from the remote repository
grab_remote_version() {
    local remote_file="https://raw.githubusercontent.com/lovelyspacedog/BoneYARD/main/BoneYARD.sh"
    local temp_file
    temp_file=$(mktemp /tmp/boneyard_ver_XXXXXX)
    
    if curl -s --connect-timeout 2 "$remote_file" -o "$temp_file"; then
        local remote_v
        remote_v=$(grep -m 1 'SOFTWARE_VERSION=' "$temp_file" | cut -d'"' -f2)
        echo "$remote_v" > "/tmp/boneyard_remote_version"
    fi
    rm -f "$temp_file"
}

# Perform the update handoff
perform_update() {
    local remote_v="$1"
    local update_dir="$SCRIPT_DIR"
    
    clear
    gum style --foreground 212 --border double --padding "1 2" "🚀 BoneYARD Update Center"
    echo "🐾 A new doghouse has been built! BoneYARD $remote_v is available."
    echo "The pack will move into the kennel at: $update_dir"
    echo ""
    
    if ! gum confirm "Would you like to fetch the new doghouse now?"; then
        echo "Barking up the wrong tree? No update performed."
        pause
        return 0
    fi

    echo "Fetching the new yard files..."
    local download_dir="/tmp/boneyard-update-$(date +%s)"
    
    if ! git clone --depth 1 https://github.com/lovelyspacedog/BoneYARD.git "$download_dir" &>/dev/null; then
        echo "Error: Failed to fetch the new yard files. Check your connection."
        rm -rf "$download_dir"
        pause
        return 1
    fi

    # Safety Check: Check for clutter in the script directory
    local project_files=("BoneYARD.sh" "boneyard" "boneyard.json" "LICENSE" "README.md" "CHANGELOG.md" "wordlist.txt" ".gitignore")
    local foreign_count=0
    for f in "$update_dir"/*; do
        [[ -d "$f" ]] && continue # Skip directories
        local fname=$(basename "$f")
        local is_proj=false
        for p in "${project_files[@]}"; do
            if [[ "$fname" == "$p" ]]; then is_proj=true; break; fi
        done
        [[ "$is_proj" == "false" ]] && ((foreign_count++))
    done

    local update_mode="full"
    if (( foreign_count > 2 )); then
        echo ""
        gum style --foreground 208 "⚠️  CLUTTER WARNING: This directory contains $foreign_count non-project files."
        echo "It looks like you might have saved BoneYARD in a shared folder (like Downloads)."
        echo ""
        if gum confirm "Would you like to perform a Minimal Update? (Copies ONLY BoneYARD.sh to avoid clutter)"; then
            update_mode="minimal"
        fi
    fi

    # Generate a script in /tmp that handles the move
    local updater_script
    updater_script=$(mktemp /tmp/boneyard_updater_XXXXXX.sh)
    
    cat <<EOF > "$updater_script"
#!/usr/bin/env bash
# BoneYARD Automatic Updater Script

TARGET_DIR="$update_dir"
SOURCE_DIR="$download_dir"
UPDATE_MODE="$update_mode"

echo "Applying the new coat of paint to the kennel..."
sleep 1

# Explicit check for boneyard.json to ensure buried treasures are safe
if [[ "\$UPDATE_MODE" == "minimal" ]]; then
    echo "Minimal Update: Only moving BoneYARD.sh..."
    if cp -rf "\$SOURCE_DIR/BoneYARD.sh" "\$TARGET_DIR/"; then
        echo "  [Updated] BoneYARD.sh"
    else
        echo "  [Error] Failed to update BoneYARD.sh"
        exit 1
    fi
else
    for file in "\$SOURCE_DIR"/*; do
        filename=\$(basename "\$file")
        
        # Never overwrite the database file
        if [[ "\$filename" == "boneyard.json" ]]; then
            echo "  [Skipped] \$filename (Your database is safe)"
            continue
        fi
        
        # Overwrite the rest of the software files
        if cp -rf "\$file" "\$TARGET_DIR/"; then
            echo "  [Updated] \$filename"
        else
            echo "  [Error] Failed to update \$filename"
            exit 1
        fi
    done
fi

echo ""
echo "✓ The move is complete! The kennel is now at version $remote_v."
echo "Cleaning up the loose fur..."
rm -rf "\$SOURCE_DIR"
rm -- "\$0"

echo "Relaunching BoneYARD..."
sleep 1
clear
exec "\$TARGET_DIR/BoneYARD.sh"
EOF

    chmod +x "$updater_script"
    
    echo "Starting the handoff... Woof!"
    # Execute the updater and replace the current process
    exec "$updater_script"
}

# Check if the software is compatible with the loaded database
check_compatibility() {
    if [[ ! -f "$DATABASE_FILE" ]]; then return 0; fi
    
    local db_version
    db_version=$(jq -r '.version' "$DATABASE_FILE" 2>/dev/null || echo "0.0.0")
    
    # Handle legacy integer versions (e.g. "1" -> "1.0.0")
    if [[ "$db_version" =~ ^[0-9]+$ ]]; then
        db_version="$db_version.0.0"
    fi

    local sw_major=$(echo "$SOFTWARE_VERSION" | cut -d. -f1)
    local db_major=$(echo "$db_version" | cut -d. -f1)

    # Rule 1: Major versions must match
    if [[ "$sw_major" != "$db_major" ]]; then
        echo "Error: Database major version mismatch!"
        echo "Software expects major version $sw_major.x.x, but database is $db_major.x.x."
        typewrite "Compatibility breaks between major releases."
        exit 1
    fi

    # Rule 2: Software version must be >= Database version
    local res=0
    version_compare "$SOFTWARE_VERSION" "$db_version" || res=$?
    if [[ $res -eq 2 ]]; then
        echo "Error: Database version ($db_version) is newer than software version ($SOFTWARE_VERSION)!"
        typewrite "Please update BoneYARD to the latest version to use this database."
        exit 1
    elif [[ $res -eq 1 ]]; then
        echo ""
        gum style --foreground 212 "🐾 Database Version Update"
        echo "Current Database: $db_version"
        echo "Software Version: $SOFTWARE_VERSION"
        echo ""
        if gum confirm "Would you like to update the database version to match the software?"; then
            jq --arg ver "$SOFTWARE_VERSION" '.version = $ver' "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
            mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
            typewrite "✓ Database version updated to $SOFTWARE_VERSION."
            echo ""
        fi
    fi
    return 0
}

# Select a timezone offset
select_timezone_offset() {
    play_menu_sound
    local current_offset="${1:-0}"
    local is_new_db="${2:-false}"
    local selection
    
    echo ""
    local header="Select your timezone offset:"
    [[ "$is_new_db" == "true" ]] && header="No database found. Select initial timezone offset:"
    
    local options=(
        "🌍 UTC (+0)"
        "🌇 EST (-5 Hours) - Eastern Standard"
        "🌅 EDT (-4 Hours) - Eastern Daylight"
        "🌆 CST (-6 Hours) - Central Standard"
        "🌇 CDT (-5 Hours) - Central Daylight"
        "🏔️ MST (-7 Hours) - Mountain Standard"
        "⛰️ MDT (-6 Hours) - Mountain Daylight"
        "🌊 PST (-8 Hours) - Pacific Standard"
        "🏄 PDT (-7 Hours) - Pacific Daylight"
        "🏰 BST (+1 Hour) - British Summer"
        "🏛️ CEST (+2 Hours) - Central European"
        "🕌 IST (+5:30) - India Standard"
        "⌨️ Type Manually"
    )
    
    if [[ "$is_new_db" == "false" ]]; then
        selection=$(gum choose --header "$header" "🔄 Keep Current ($current_offset)" "${options[@]}" || echo "Keep current")
    else
        selection=$(gum choose --header "$header" "${options[@]}" || echo "🌍 UTC (+0)")
    fi

    case "$selection" in
        "🌍 UTC (+0)") echo 0 ;;
        "🌇 EST (-5 Hours)"*) echo -18000 ;;
        "🌅 EDT (-4 Hours)"*) echo -14400 ;;
        "🌆 CST (-6 Hours)"*) echo -21600 ;;
        "🌇 CDT (-5 Hours)"*) echo -18000 ;;
        "🏔️ MST (-7 Hours)"*) echo -25200 ;;
        "⛰️ MDT (-6 Hours)"*) echo -21600 ;;
        "🌊 PST (-8 Hours)"*) echo -28800 ;;
        "🏄 PDT (-7 Hours)"*) echo -25200 ;;
        "🏰 BST (+1 Hour)"*) echo 3600 ;;
        "🏛️ CEST (+2 Hours)"*) echo 7200 ;;
        "🕌 IST (+5:30)"*) echo 19800 ;;
        "⌨️ Type Manually")
            local manual
            manual=$(gum input --placeholder "Enter offset in seconds (e.g., -18000 for EST)" || echo "$current_offset")
            if [[ "$manual" =~ ^-?[0-9]+$ ]]; then
                echo "$manual"
            else
                echo "$current_offset"
            fi
            ;;
        *) echo "$current_offset" ;;
    esac
}

# Initialize the database file
init_database() {
    local force="${1:-false}"
    local offset="${2:-}"
    
    if [[ ! -f "$DATABASE_FILE" ]]; then
        # New database - ask for offset
        offset=$(select_timezone_offset "0" "true")
    elif [[ -z "$offset" ]]; then
        # Force re-init but no offset provided, use existing
        offset=$(jq -r '."timezone-offset" // 0' "$DATABASE_FILE")
    fi

    if [[ ! -f "$DATABASE_FILE" || "$force" == "true" ]]; then
        cat <<EOF | jq '.' > "$DATABASE_FILE"
{
  "version": "$DATABASE_VERSION",
  "timezone-offset": $offset,
  "_comment": {
    "1": "This is the timezone offset for the BoneYARD. It is used to convert the modified timestamp to the local timezone.",
    "2": "Use a timezone offset of -18000 for EST (-5 hours), or -14400 for EDT (-4 hours).",
    "3": "Units are seconds since epoch."
  },
  "files": []
}
EOF
        echo "BoneYARD initialized at $DATABASE_FILE with offset $offset"
    fi
}

# Update the directory cache file
update_dir_cache() {
    jq -r '.files[].path' "$DATABASE_FILE" | sort -u > "$DIR_CACHE_FILE"
}

# Robust pause function to wait for user input
pause() {
    echo ""
    read -rp "Press Enter to continue..." _ < /dev/tty
}

# Play a subtle menu sound if 'play' (sox) is available
play_menu_sound() {
    command -v play &> /dev/null && play -q -n synth 0.1 sine 600 fade 0 0.1 0.05 vol 0.25 < /dev/null > /dev/null 2>&1 &
}

# Get the next unique ID
get_next_id() {
    local max_id
    max_id=$(jq '[.files[].unique_id] | max // 0' "$DATABASE_FILE")
    echo $((max_id + 1))
}

# Add a new file to the database
add_file() {
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🦴 Bury New Bone"
    
    # Use ranger to select file
    local temp_file="/tmp/ranger_chosen_file.txt"
    rm -f "$temp_file"
    
    echo "Sniffing around for a bone (launching ranger)..."
    ranger --choosefile="$temp_file" "$HOME"
    
    if [[ ! -s "$temp_file" ]]; then
        echo "No bone found."
        pause
        main_menu
        return
    fi
    
    local file_path
    file_path=$(cat "$temp_file")
    rm -f "$temp_file"
    
    # Get absolute path
    file_path=$(realpath "$file_path")
    local file_name=$(basename "$file_path")
    local dir_path=$(dirname "$file_path")
    
    # Check if file already exists in database
    local existing_id
    existing_id=$(jq -r --arg path "$file_path" --arg name "$file_name" \
        '.files[] | select(.path == $path and .name == $name) | .unique_id' "$DATABASE_FILE")
    
    if [[ -n "$existing_id" ]]; then
        echo "Woof! This bone is already buried in the yard (ID: $existing_id)"
        if gum confirm "Do you want to update its scents (tags)?"; then
            update_file_tags "$existing_id"
        fi
        pause
        main_menu
        return
    fi
    
    # Get tags
    local tags_input
    tags_input=$(gum input --placeholder "Enter scents (comma-separated, e.g., bash,script,utility)" || true)
    
    if [[ -z "$tags_input" ]]; then
        echo "No scents entered. Operation cancelled."
        pause
        main_menu
        return
    fi
    
    # Convert comma-separated tags to JSON array
    IFS=',' read -ra tags_array <<< "$tags_input"
    local tags_json='[]'
    for tag in "${tags_array[@]}"; do
        # Trim whitespace
        tag=$(echo "$tag" | xargs)
        if [[ -n "$tag" ]]; then
            tags_json=$(echo "$tags_json" | jq --arg tag "$tag" '. += [$tag]')
        fi
    done
    
    # Get current timestamp
    local timestamp
    timestamp=$(date +%s)
    
    # Get next ID
    local next_id
    next_id=$(get_next_id)
    
    # Add file to database
    local new_entry
    new_entry=$(jq -n \
        --arg name "$file_name" \
        --arg path "$dir_path" \
        --argjson tags "$tags_json" \
        --argjson id "$next_id" \
        --argjson ts "$timestamp" \
        '{name: $name, path: $path, tags: $tags, unique_id: $id, modified_timestamp: $ts}')
    
    jq --argjson entry "$new_entry" '.files += [$entry]' "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
    mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
    update_dir_cache
    double_bark_sfx
    
    echo ""
    echo "✓ Bone buried successfully (ID: $next_id)"
    echo "  Name: $file_name"
    echo "  Path: $dir_path"
    echo "  Scents: ${tags_array[*]}"
    echo ""
    pause
    main_menu
}

# Tag all files in a directory
tag_entire_directory() {
    echo ""
    gum style --foreground 212 --border double --padding "1 2" "🐕 Bury Entire Litter"
    echo "Instructions:"
    echo "  1. Navigate INTO the kennel (directory) you want to bury."
    echo "  2. Press 'q' to select this kennel and exit ranger."
    echo ""
    gum style --foreground 208 "⚠️  Note: Pressing Enter on a bone (file) will try to CHEW (open) it."
    echo ""
    echo "Press any key to start sniffing with ranger..."
    read -n 1 -s < /dev/tty
    
    local temp_dir="/tmp/ranger_chosen_dir.txt"
    rm -f "$temp_dir"
    
    ranger --choosedir="$temp_dir" "$HOME"
    
    if [[ ! -s "$temp_dir" ]]; then
        echo "No kennel selected."
        pause
        main_menu
        return
    fi
    
    local dir_path
    dir_path=$(realpath "$(cat "$temp_dir")")
    rm -f "$temp_dir"
    
    # Get all regular, non-empty files in the directory
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$dir_path" -maxdepth 1 -type f -size +0c -print0 | sort -z)
    
    local total_files=${#files[@]}
    if [[ "$total_files" -eq 0 ]]; then
        echo "No bones found in $dir_path"
        pause
        main_menu
        return
    fi
    
    echo "Found $total_files bones to bury."
    
    local buffered_json_file="/tmp/boneyard_buffer.json"
    echo "[]" > "$buffered_json_file"
    
    local i=0
    local last_tags_json="[]"
    local last_tags_string=""
    
    while (( i < total_files )); do
        local current_file="${files[$i]}"
        local file_name=$(basename "$current_file")
        
        clear
        gum style --foreground 212 --border double --padding "0 1" "🐕 Burying Litter in: $dir_path"
        
        # Progress and File Info
        gum style --foreground 208 --bold "  🦴 Bone $((i + 1)) of $total_files"
        gum style --foreground 255 --margin "0 2" "  $file_name"
        
        if [[ -n "$last_tags_string" ]]; then
            gum style --foreground 251 --italic --margin "0 2" "  (Last: $last_tags_string)"
        fi

        # Show preview for images/videos if in Kitty
        display_bone_preview "$current_file"
        
        echo ""
        gum style --foreground 250 "  Keys: 'v' (repeat) | 'vvv' (all) | 'undo' (back) | 'q' (save)"
        gum style --foreground 212 --italic "  (Press Enter to submit scents)"
        
        local tags_input
        tags_input=$(gum input --prompt "  👃 Scents: " --prompt.foreground 212 --placeholder "comma,separated,tags..." --placeholder.foreground 255 || true)
        
        # Handle keywords and empty input
        if [[ -z "$tags_input" ]]; then
            echo "Scents cannot be empty. Use keywords if needed."
            sleep 1
            continue
        fi

        case "${tags_input,,}" in
            "q"|"quit")
                if gum confirm "Are you sure you want to stop burying this litter?"; then
                    break
                else
                    continue
                fi
                ;;
            "undo"|"back"|"-")
                if [[ $i -gt 0 ]]; then
                    i=$((i - 1))
                    # Remove the last entry from buffer
                    jq 'del(.[-1])' "$buffered_json_file" > "$buffered_json_file.tmp"
                    mv "$buffered_json_file.tmp" "$buffered_json_file"
                    # Reset last_tags if we undo
                    last_tags_json="[]"
                    last_tags_string=""
                    continue
                else
                    echo "Already at the first bone."
                    sleep 1
                    continue
                fi
                ;;
            "v"|"same"|"copy"|"cp")
                if [[ "$last_tags_json" == "[]" ]]; then
                    echo "No previous scents to copy."
                    sleep 1
                    continue
                fi
                # Use last_tags_json
                tags_json="$last_tags_json"
                ;;
            "vvv"|"all")
                if [[ "$last_tags_json" == "[]" ]]; then
                    echo "No previous scents to copy."
                    sleep 1
                    continue
                fi
                
                local remaining=$((total_files - i))
                if gum confirm "Apply scents '$last_tags_string' to ALL $remaining remaining bones?"; then
                    # Apply to previous entries if requested
                    if [[ $i -gt 0 ]]; then
                        if gum confirm "Would you also like to apply these scents to the $i PREVIOUS bones in this litter?"; then
                            jq --argjson tags "$last_tags_json" 'map(.tags = $tags)' "$buffered_json_file" > "$buffered_json_file.tmp"
                            mv "$buffered_json_file.tmp" "$buffered_json_file"
                        fi
                    fi

                    # Apply to current and all remaining
                    while (( i < total_files )); do
                        local current_file="${files[$i]}"
                        local file_name=$(basename "$current_file")
                        local timestamp=$(date +%s)
                        local next_id=$(($(get_next_id) + i))
                        
                        local new_entry
                        new_entry=$(jq -n \
                            --arg name "$file_name" \
                            --arg path "$dir_path" \
                            --argjson tags "$last_tags_json" \
                            --argjson id "$next_id" \
                            --argjson ts "$timestamp" \
                            '{name: $name, path: $path, tags: $tags, unique_id: $id, modified_timestamp: $ts}')
                            
                        jq --argjson entry "$new_entry" '. += [$entry]' "$buffered_json_file" > "$buffered_json_file.tmp"
                        mv "$buffered_json_file.tmp" "$buffered_json_file"
                        i=$((i + 1))
                    done
                    break
                else
                    continue
                fi
                ;;
            *)
                if [[ -z "$tags_input" ]]; then
                    echo "Scents cannot be empty. Use keywords if needed."
                    sleep 1
                    continue
                fi
                
                # Process new tags
                IFS=',' read -ra tags_array <<< "$tags_input"
                tags_json='[]'
                local cleaned_tags=()
                for tag in "${tags_array[@]}"; do
                    tag=$(echo "$tag" | xargs)
                    if [[ -n "$tag" ]]; then
                        tags_json=$(echo "$tags_json" | jq --arg tag "$tag" '. += [$tag]')
                        cleaned_tags+=("$tag")
                    fi
                done
                last_tags_json="$tags_json"
                last_tags_string="${cleaned_tags[*]}"
                ;;
        esac
        
        # Create entry
        local next_id=$(($(get_next_id) + i)) # Approximate ID, will be recalculated on save
        local timestamp=$(date +%s)
        local new_entry
        new_entry=$(jq -n \
            --arg name "$file_name" \
            --arg path "$dir_path" \
            --argjson tags "$tags_json" \
            --argjson id "$next_id" \
            --argjson ts "$timestamp" \
            '{name: $name, path: $path, tags: $tags, unique_id: $id, modified_timestamp: $ts}')
            
        # Add to buffer
        jq --argjson entry "$new_entry" '. += [$entry]' "$buffered_json_file" > "$buffered_json_file.tmp"
        mv "$buffered_json_file.tmp" "$buffered_json_file"
        
        i=$((i + 1))
    done
    
    local completed_count=$(jq '. | length' "$buffered_json_file")
    if [[ $completed_count -gt 0 ]]; then
        echo ""
        echo "Burying $completed_count bones."
        if gum confirm "Save these bones to the BoneYARD?"; then
            # We need to assign real unique IDs now to avoid collisions if multiple files were added
            local current_max_id=$(jq '[.files[].unique_id] | max // 0' "$DATABASE_FILE")
            
            # Map over buffered entries to assign correct IDs
            jq --argjson start_id "$current_max_id" \
               'to_entries | map(.value + {unique_id: ($start_id + .key + 1)})' \
               "$buffered_json_file" > "$buffered_json_file.tmp"
            
            # Append to database
            jq --argjson new_files "$(cat "$buffered_json_file.tmp")" \
               '.files += $new_files' "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
            mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
            update_dir_cache
            double_bark_sfx
            
            echo "✓ Successfully saved $completed_count bones to BoneYARD."
        else
            echo "Changes discarded. Litter remains unburied."
        fi
    else
        echo "No bones were buried."
    fi
    
    rm -f "$buffered_json_file"
    pause
    main_menu
}

# Update tags for an existing file
update_file_tags() {
    local file_id=$1
    
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "👃 Update Scents"
    
    # Get current tags
    local current_tags
    current_tags=$(jq -r --argjson id "$file_id" '.files[] | select(.unique_id == $id) | .tags | join(", ")' "$DATABASE_FILE")
    echo "Current scents: $current_tags"
    
    # Get new tags
    local tags_input
    tags_input=$(gum input --placeholder "Enter new scents (comma-separated)" || true)
    
    if [[ -z "$tags_input" ]]; then
        echo "No scents entered. Update cancelled."
        return
    fi
    
    # Convert comma-separated tags to JSON array
    IFS=',' read -ra tags_array <<< "$tags_input"
    local tags_json='[]'
    for tag in "${tags_array[@]}"; do
        tag=$(echo "$tag" | xargs)
        if [[ -n "$tag" ]]; then
            tags_json=$(echo "$tags_json" | jq --arg tag "$tag" '. += [$tag]')
        fi
    done
    
    # Update timestamp
    local timestamp
    timestamp=$(date +%s)
    
    # Update the file in database
    jq --argjson id "$file_id" --argjson tags "$tags_json" --argjson ts "$timestamp" \
        '(.files[] | select(.unique_id == $id) | .tags) = $tags | 
         (.files[] | select(.unique_id == $id) | .modified_timestamp) = $ts' \
        "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
    mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
    update_dir_cache
    
    echo ""
    echo "✓ Scents updated successfully"
}

# Edit tags for an existing file
edit_tags() {
    play_menu_sound
    echo ""
    local edit_choice
    edit_choice=$(gum choose --header "👃 Update Scents" \
        "🏷️ Find By Scent" \
        "📝 Find By Bone Name" \
        "📁 Filter By Kennel (Directory)" \
        "📋 List All Bones" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$edit_choice" || "$edit_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $edit_choice in
        "🏷️ Find By Scent") edit_by_tag;;
        "📝 Find By Bone Name") edit_by_name;;
        "📁 Filter By Kennel (Directory)") edit_filter_by_directory;;
        "📋 List All Bones") edit_list_all_files;;
    esac
}

# Sub-function to handle selecting and updating a file from search results
select_and_update_file() {
    local results_json="$1"
    local count
    count=$(echo "$results_json" | jq -s 'length')
    
    if [[ "$count" -eq 0 ]]; then
        echo "No bones found."
        pause
        return 1
    fi
    
    local file_id
    if [[ "$count" -eq 1 ]]; then
        file_id=$(echo "$results_json" | jq -r '.unique_id')
    else
        play_menu_sound
        local selection
        selection=$(echo "$results_json" | jq -r '"\(.unique_id): \(.name) (\(.path)) [\(.tags | join(", "))]"' | gum choose --header "🔍 Select A Bone To Update Scents:" || true)
        
        if [[ -z "$selection" ]]; then
            return 1
        fi
        
        file_id=$(echo "$selection" | cut -d':' -f1)
    fi
    
    update_file_tags "$file_id"
    pause
}

# Edit by tag
edit_by_tag() {
    local dir_filter="${1:-}"
    echo ""
    local search_tag
    search_tag=$(gum input --placeholder "Enter scent to find for updating" || true)
    [[ -z "$search_tag" ]] && { edit_tags; return; }
    
    local matches
    matches=$(jq -c --arg tag "$search_tag" --arg dir "$dir_filter" \
        '.files[] | select(($dir == "" or .path == $dir) and (.tags[] | ascii_downcase == ($tag | ascii_downcase)))' \
        "$DATABASE_FILE")
    
    select_and_update_file "$matches" || true
    
    if [[ -n "$dir_filter" ]]; then
        edit_directory_menu "$dir_filter"
    else
        edit_tags
    fi
}

# Edit by name
edit_by_name() {
    local dir_filter="${1:-}"
    echo ""
    local search_name
    search_name=$(gum input --placeholder "Enter bone name to find for updating (* for all)" || true)
    
    if [[ "$search_name" == "*" ]]; then
        search_name=""
    elif [[ -z "$search_name" ]]; then
        if [[ -n "$dir_filter" ]]; then
            edit_directory_menu "$dir_filter"
        else
            edit_tags
        fi
        return
    fi
    
    local matches
    matches=$(jq -c --arg name "$search_name" --arg dir "$dir_filter" \
        '.files[] | select(($dir == "" or .path == $dir) and (($name == "") or (.name | ascii_downcase | contains($name | ascii_downcase))))' \
        "$DATABASE_FILE")
    
    select_and_update_file "$matches" || true
    
    if [[ -n "$dir_filter" ]]; then
        edit_directory_menu "$dir_filter"
    else
        edit_tags
    fi
}

# Edit list all
edit_list_all_files() {
    local dir_filter="${1:-}"
    local matches
    matches=$(jq -c --arg dir "$dir_filter" '.files[] | select($dir == "" or .path == $dir)' "$DATABASE_FILE")
    
    select_and_update_file "$matches" || true
    
    if [[ -n "$dir_filter" ]]; then
        edit_directory_menu "$dir_filter"
    else
        edit_tags
    fi
}

# Edit filter by directory
edit_filter_by_directory() {
    play_menu_sound
    if [[ ! -s "$DIR_CACHE_FILE" ]]; then
        echo "No directories found in database."
        pause
        edit_tags
        return
    fi
    
    local selected_dir
    selected_dir=$(gum choose --header "📁 Select A Directory To Filter For Editing:" < "$DIR_CACHE_FILE" || true)
    
    if [[ -z "$selected_dir" ]]; then
        edit_tags
        return
    fi
    
    edit_directory_menu "$selected_dir"
}

# Sub-menu for directory filtering in edit mode
edit_directory_menu() {
    play_menu_sound
    local selected_dir="$1"
    echo ""
    local choice
    choice=$(gum choose --header "📁 Editing In: $selected_dir" \
        "🏷️ Find By Tag" \
        "📝 Find By Filename" \
        "📋 List All Files" \
        "❌ Remove Directory Filter" || true)
    
    if [[ -z "$choice" || "$choice" == "❌ Remove Directory Filter" ]]; then
        edit_tags
        return
    fi
    
    case $choice in
        "🏷️ Find By Tag") edit_by_tag "$selected_dir";;
        "📝 Find By Filename") edit_by_name "$selected_dir";;
        "📋 List All Files") edit_list_all_files "$selected_dir";;
    esac
}

# Search for files by tag
search_file() {
    play_menu_sound
    echo ""
    local search_choice
    search_choice=$(gum choose --header "🎾 Fetch Bones" \
        "🏷️ Search By Scent" \
        "📝 Search By Bone Name" \
        "📁 Filter By Kennel (Directory)" \
        "📋 List All Bones" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$search_choice" || "$search_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $search_choice in
        "🏷️ Search By Scent") search_by_tag;;
        "📝 Search By Bone Name") search_by_name;;
        "📁 Filter By Kennel (Directory)") filter_by_directory;;
        "📋 List All Bones") list_all_files;;
    esac
}

# Search files by tag
search_by_tag() {
    local dir_filter="${1:-}"
    echo ""
    local search_tag
    search_tag=$(gum input --placeholder "Enter scent to fetch" || true)
    
    if [[ -z "$search_tag" ]]; then
        if [[ -n "$dir_filter" ]]; then
            directory_search_menu "$dir_filter"
        else
            search_file
        fi
        return
    fi
    
    echo ""
    if [[ -n "$dir_filter" ]]; then
        gum style --foreground 212 "🎾 Fetch Results In: $dir_filter"
    else
        gum style --foreground 212 "🎾 Fetch Results"
    fi
    
    local results
    results=$(jq -r --arg tag "$search_tag" --arg dir "$dir_filter" \
        '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
         select(($dir == "" or .path == $dir) and (.tags[] | ascii_downcase == ($tag | ascii_downcase))) | 
         "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
        "$DATABASE_FILE")
    
    if [[ -z "$results" ]]; then
        echo "No bones found with scent: $search_tag"
    else
        echo "$results"
    fi
    
    echo ""
    pause
    
    if [[ -n "$dir_filter" ]]; then
        directory_search_menu "$dir_filter"
    else
        search_file
    fi
}

# Search files by name
search_by_name() {
    local dir_filter="${1:-}"
    echo ""
    local search_name
    search_name=$(gum input --placeholder "Enter bone name to fetch (* for all)" || true)
    
    if [[ "$search_name" == "*" ]]; then
        search_name=""
    elif [[ -z "$search_name" ]]; then
        if [[ -n "$dir_filter" ]]; then
            directory_search_menu "$dir_filter"
        else
            search_file
        fi
        return
    fi
    
    echo ""
    if [[ -n "$dir_filter" ]]; then
        gum style --foreground 212 "🎾 Fetch Results In: $dir_filter"
    else
        gum style --foreground 212 "🎾 Fetch Results"
    fi
    
    local results
    results=$(jq -r --arg name "$search_name" --arg dir "$dir_filter" \
        '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
         select(($dir == "" or .path == $dir) and (($name == "") or (.name | ascii_downcase | contains($name | ascii_downcase)))) | 
         "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
        "$DATABASE_FILE")
    
    if [[ -z "$results" ]]; then
        if [[ -z "$search_name" ]]; then
            echo "No bones found."
        else
            echo "No bones found matching: $search_name"
        fi
    else
        echo "$results"
    fi
    
    echo ""
    pause
    
    if [[ -n "$dir_filter" ]]; then
        directory_search_menu "$dir_filter"
    else
        search_file
    fi
}

# List all files in the database
list_all_files() {
    local dir_filter="${1:-}"
    echo ""
    if [[ -n "$dir_filter" ]]; then
        gum style --foreground 212 "📋 Bones In Kennel: $dir_filter"
    else
        gum style --foreground 212 "📋 All Buried Bones"
    fi
    
    local total_files
    total_files=$(jq --arg dir "$dir_filter" '[.files[] | select($dir == "" or .path == $dir)] | length' "$DATABASE_FILE")
    
    if [[ "$total_files" -eq 0 ]]; then
        echo "No bones found."
    else
        jq -r --arg dir "$dir_filter" '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
            select($dir == "" or .path == $dir) | 
            "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
            "$DATABASE_FILE"
        echo ""
        echo "Total bones: $total_files"
    fi
    
    echo ""
    pause
    
    if [[ -n "$dir_filter" ]]; then
        directory_search_menu "$dir_filter"
    else
        search_file
    fi
}

# Filter by directory
filter_by_directory() {
    play_menu_sound
    if [[ ! -s "$DIR_CACHE_FILE" ]]; then
        echo "No directories found in database."
        pause
        search_file
        return
    fi
    
    local selected_dir
    selected_dir=$(gum choose --header "📁 Select A Directory To Filter By:" < "$DIR_CACHE_FILE" || true)
    
    if [[ -z "$selected_dir" ]]; then
        search_file
        return
    fi
    
    directory_search_menu "$selected_dir"
}

# Sub-menu for directory filtering
directory_search_menu() {
    play_menu_sound
    local selected_dir="$1"
    echo ""
    local choice
    choice=$(gum choose --header "🔍 Searching In: $selected_dir" \
        "🏷️ Search By Tag" \
        "📝 Search By Filename" \
        "📋 List All Files" \
        "❌ Remove Directory Filter" || true)
    
    if [[ -z "$choice" || "$choice" == "❌ Remove Directory Filter" ]]; then
        search_file
        return
    fi
    
    case $choice in
        "🏷️ Search By Tag") search_by_tag "$selected_dir";;
        "📝 Search By Filename") search_by_name "$selected_dir";;
        "📋 List All Files") list_all_files "$selected_dir";;
    esac
}

# Remove a file or directory from the database
remove_file() {
    play_menu_sound
    echo ""
    gum style --foreground 196 --border double --padding "0 1" "🧹 Clean Up the Yard"
    echo "NOTE: Digging up bones here only removes them from this database,"
    echo "it does NOT delete the actual files from your system."
    echo ""
    
    local remove_choice
    remove_choice=$(gum choose \
        "🆔 Remove By ID" \
        "📝 Remove By Bone Name" \
        "📁 Remove By Kennel (Directory)" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$remove_choice" || "$remove_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $remove_choice in
        "🆔 Remove By ID") remove_by_id;;
        "📝 Remove By Bone Name") remove_by_name;;
        "📁 Remove By Kennel (Directory)") remove_by_directory;;
    esac
}

# Remove all entries for a specific directory
remove_by_directory() {
    play_menu_sound
    echo ""
    
    if [[ ! -s "$DIR_CACHE_FILE" ]]; then
        echo "No kennels found in BoneYARD."
        pause
        remove_file
        return
    fi
    
    echo "Select a kennel to clean up, or type a path manually:"
    local selected_dir
    selected_dir=$(echo -e "⌨️ Type Path Manually\n$(cat "$DIR_CACHE_FILE")" | gum choose --header "📁 Select Kennel To Clean Up:" || true)
    
    if [[ -z "$selected_dir" ]]; then
        remove_file
        return
    fi

    if [[ "$selected_dir" == "⌨️ Type Path Manually" ]]; then
        selected_dir=$(gum input --placeholder "Enter full path to kennel" || true)
    fi
    
    if [[ -z "$selected_dir" ]]; then
        remove_file
        return
    fi
    
    # Normalize path (remove trailing slash if present)
    selected_dir="${selected_dir%/}"
    
    # Check if directory exists in database
    local file_count
    file_count=$(jq --arg dir "$selected_dir" '[.files[] | select(.path == $dir)] | length' "$DATABASE_FILE")
    
    if [[ "$file_count" -eq 0 ]]; then
        echo "No bones found in BoneYARD for kennel: $selected_dir"
        pause
        remove_file
        return
    fi
    
    echo ""
    echo "Found $file_count bones in: $selected_dir"
    
    if [[ "$file_count" -lt 10 ]]; then
        echo "Bones to be dug up:"
        jq -r --arg dir "$selected_dir" '.files[] | select(.path == $dir) | "  - \(.name)"' "$DATABASE_FILE"
        echo ""
    fi

    if gum confirm "Dig up ALL $file_count bones for this kennel from the BoneYARD?"; then
        jq --arg dir "$selected_dir" 'del(.files[] | select(.path == $dir))' \
            "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
        mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
        update_dir_cache
        echo "✓ Successfully dug up $file_count bones."
    else
        echo "Clean up cancelled."
    fi
    
    echo ""
    pause
    main_menu
}

# Remove file by its unique ID
remove_by_id() {
    echo ""
    local file_id
    file_id=$(gum input --placeholder "Enter bone ID to dig up" || true)
    [[ -z "$file_id" ]] && { remove_file; return; }
    
    if [[ ! "$file_id" =~ ^[0-9]+$ ]]; then
        echo "Error: ID must be a number"
        pause
        remove_file
        return
    fi

    # Check if file exists
    local file_exists
    file_exists=$(jq --argjson id "$file_id" '.files[] | select(.unique_id == $id)' "$DATABASE_FILE")
    
    if [[ -z "$file_exists" ]]; then
        echo "Error: Bone with ID $file_id not found"
        pause
        remove_file
        return
    fi
    
    # Show file details
    echo ""
    gum style --foreground 196 "🦴 Bone To Dig Up:"
    jq -r --argjson id "$file_id" \
        '.files[] | select(.unique_id == $id) | 
         "  Name: \(.name)\n  Kennel: \(.path)\n  Scents: \(.tags | join(", "))"' \
        "$DATABASE_FILE"
    
    if gum confirm "Dig up this bone from BoneYARD?"; then
        jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
            "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
        mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
        update_dir_cache
        echo "✓ Bone dug up successfully"
    else
        echo "Clean up cancelled"
    fi
    
    echo ""
    pause
    main_menu
}

# Remove file by searching for its name
remove_by_name() {
    echo ""
    local search_name
    search_name=$(gum input --placeholder "Enter bone name to search for clean up (* for all)" || true)
    
    if [[ "$search_name" == "*" ]]; then
        search_name=""
    elif [[ -z "$search_name" ]]; then
        remove_file
        return
    fi
    
    # Find matching files
    local matches
    matches=$(jq -c --arg name "$search_name" \
        '.files[] | select(($name == "") or (.name | ascii_downcase | contains($name | ascii_downcase)))' \
        "$DATABASE_FILE")
    
    if [[ -z "$matches" ]]; then
        echo "No bones found matching: $search_name"
        pause
        remove_file
        return
    fi
    
    local match_count
    match_count=$(echo "$matches" | wc -l)
    
    if [[ "$match_count" -eq 1 ]]; then
        # Only one match found
        local file_id
        file_id=$(echo "$matches" | jq -r '.unique_id')
        
        echo ""
        gum style --foreground 212 "✅ Match Found:"
        echo "$matches" | jq -r '"  ID: \(.unique_id) | Name: \(.name) | Kennel: \(.path)"'
        
        echo ""
        if gum confirm "Dig up this bone from BoneYARD?"; then
            jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
                "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
            mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
            echo "✓ Bone dug up successfully"
        else
            echo "Clean up cancelled"
        fi
    else
        # Multiple matches found
        echo ""
        gum style --foreground 212 "👯 Multiple Matches Found For '$search_name':"
        echo "$matches" | jq -r '"  ID: \(.unique_id) | Name: \(.name) | Kennel: \(.path)"'
        echo ""
        local file_id
        file_id=$(gum input --placeholder "Enter ID to dig up (or leave blank to cancel)" || true)
        
        if [[ -z "$file_id" ]]; then
            echo "Clean up cancelled"
        elif [[ ! "$file_id" =~ ^[0-9]+$ ]]; then
            echo "Error: ID must be a number"
        else
            # Check if entered ID is in the matches
            local selected_match
            selected_match=$(echo "$matches" | jq -c --argjson id "$file_id" 'select(.unique_id == $id)')
            
            if [[ -n "$selected_match" ]]; then
                echo ""
                gum style --foreground 196 "🦴 Bone To Dig Up:"
                echo "$selected_match" | jq -r '"  Name: \(.name)\n  Kennel: \(.path)\n  Scents: \(.tags | join(", "))"'
                
                echo ""
                if gum confirm "Dig up this bone from BoneYARD?"; then
                    jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
                        "$DATABASE_FILE" > "$DATABASE_FILE.tmp"
                    mv "$DATABASE_FILE.tmp" "$DATABASE_FILE"
                    update_dir_cache
                    echo "✓ Bone dug up successfully"
                else
                    echo "Clean up cancelled"
                fi
            else
                echo "Error: ID $file_id was not in the search results."
            fi
        fi
    fi
    
    echo ""
    pause
    remove_file
}

# Delete the entire database with double confirmation
delete_entire_database() {
    echo ""
    gum style --foreground 196 --border double --padding "1 2" "🌋 DANGER: INCINERATE THE BONEYARD"
    typewrite "This will permanently remove ALL buried bones from your yard."
    typewrite "Target: $DATABASE_FILE"
    echo ""
    
    if ! gum confirm "Are you absolutely sure you want to incinerate the entire yard?"; then
        typewrite "Incineration cancelled. The pack survives another day."
        sleep 1.5
        exit 0
    fi
    
    # Second confirmation: type 12 random words in 3 lines of 4
    local -a words=()
    local dict_file="/usr/share/dict/words"
    local local_wordlist="$SCRIPT_DIR/wordlist.txt"
    
    if [[ -f "$dict_file" ]]; then
        # Generate 12 random words (max 9 chars), strip non-alphanumeric (including accents), and capitalize the first letter of each
        while read -r word; do
            words+=("$word")
        done < <(LC_ALL=C sed 's/[^a-zA-Z0-9]//g' "$dict_file" | LC_ALL=C grep -E '^.{1,9}$' | shuf -n 12 | sed 's/./\U&/')
    elif [[ -f "$local_wordlist" ]]; then
        # Use local wordlist fallback
        while read -r word; do
            words+=("$word")
        done < <(LC_ALL=C sed 's/[^a-zA-Z0-9]//g' "$local_wordlist" | LC_ALL=C grep -E '^.{1,9}$' | shuf -n 12 | sed 's/./\U&/')
    else
        # Fallback if dictionary doesn't exist (words max 9 chars)
        words=("Lorem" "Ipsum" "Dolor" "Sit" "Amet" "Lectus" "Semper" "Elit" "Phasellus" "At" "Lorem" "Erat")
    fi
    
    local line1="${words[0]} ${words[1]} ${words[2]} ${words[3]}"
    local line2="${words[4]} ${words[5]} ${words[6]} ${words[7]}"
    local line3="${words[8]} ${words[9]} ${words[10]} ${words[11]}"
    local full_pass_phrase="$line1 $line2 $line3"
    
    local visual_grid
    visual_grid=$(printf "%-15s %-15s %-15s %-15s\n" "${words[0]}" "${words[1]}" "${words[2]}" "${words[3]}"
                  printf "%-15s %-15s %-15s %-15s\n" "${words[4]}" "${words[5]}" "${words[6]}" "${words[7]}"
                  printf "%-15s %-15s %-15s %-15s"   "${words[8]}" "${words[9]}" "${words[10]}" "${words[11]}")
    
    clear
    gum style --foreground 196 "💀 FINAL CONFIRMATION REQUIRED"
    echo "To confirm deletion, please type the following 12 words across 3 lines (4 words per line):"
    typewrite "Note: The Words Are Case-Sensitive. You can NOT revert lines once submitted."
    echo ""
    gum style --foreground 212 --border double --border-foreground 212 --padding "1 2" "$visual_grid"
    echo ""
    
    local user_line1 user_line2="" user_line3=""
    local captured_minute=$(date +%M)
    user_line1=$(gum input --placeholder "Type Line 1 here" || true)
    [[ -n "$user_line1" ]] && typewrite "$user_line1" 0.015
    
    local bypass_active=false
    local bypass_word3=$(echo "${words[0]:0:1}${words[4]:0:1}${words[8]:0:1}" | tr '[:upper:]' '[:lower:]')
    
    # Check for bypass in line 1
    local -a line1_arr=()
    read -ra line1_arr <<< "$(echo "$user_line1" | xargs || echo "")"
    if [[ "${line1_arr[0]:-}" == "debug" && \
          "${line1_arr[1]:-}" == "PUPPY" && \
          "${line1_arr[2]:-}" == "$bypass_word3" && \
          "${line1_arr[3]:-}" == "$captured_minute" ]]; then
        bypass_active=true
        #typewrite "✨ Bypass code detected. Skipping remaining lines..."
        typewrite "🐶✨🐕‍🦺🦴🦮🐾🎾 わんわん！(U・ᴥ・U) ~ワフワフ~ RARF!! RARF!! (∪＾ェ＾∪)💖🐩🐕🌟 ૮₍•ᴥ•₎ა 🍖🐾ฅ^•ﻌ•^ฅ ワンワン！"
    else
        user_line2=$(gum input --placeholder "Type Line 2 here" || true)
        [[ -n "$user_line2" ]] && typewrite "$user_line2" 0.015
        user_line3=$(gum input --placeholder "Type Line 3 here" || true)
        [[ -n "$user_line3" ]] && typewrite "$user_line3" 0.015
    fi
    
    # Normalize whitespace (trim ends and collapse multiple spaces)
    user_line1=$(echo "${user_line1:-}" | xargs || echo "")
    user_line2=$(echo "${user_line2:-}" | xargs || echo "")
    user_line3=$(echo "${user_line3:-}" | xargs || echo "")
    
    local user_full_input="$user_line1 $user_line2 $user_line3"
    
    # Split user input into an array for comparison
    local -a user_words_arr=()
    read -ra user_words_arr <<< "$user_full_input"
    local match_count=0
    local mismatches=()
    
    if [[ "$bypass_active" == "true" ]]; then
        match_count=10
    else
        # We compare up to 12 words
        local j
        for ((j=0; j<12; j++)); do
            local target_word="${words[$j]}"
            local input_word="${user_words_arr[$j]:-}"
            if [[ "$input_word" == "$target_word" ]]; then
                match_count=$((match_count + 1))
            else
                mismatches+=("Word $((j+1)): Expected '$target_word', got '${input_word:-[nothing]}'")
            fi
        done
    fi

    local proceed_deletion=false
    if [[ $match_count -eq 12 ]]; then
        proceed_deletion=true
    elif [[ $match_count -ge 10 ]]; then
        [[ "$bypass_active" == "true" ]] && match_count="🐾🐾"
        echo ""
        gum style --foreground 212 "Fuzzy match detected ($match_count/12 words correct)."
    if gum confirm "Would you like to proceed with the deletion anyway?"; then
        proceed_deletion=true
        echo "Proceeding with fuzzy match..."
    else
        echo "Fuzzy match rejected."
    fi
    fi

    if [[ "$proceed_deletion" != "true" ]]; then
        echo ""
        gum style --foreground 196 "Input did not match sufficiently ($match_count/12)."
        if [[ ${#mismatches[@]} -gt 0 ]]; then
            echo "Mismatches found:"
            local msg
            for msg in "${mismatches[@]}"; do
                echo "  - $msg"
            done
        fi
        echo ""
        typewrite "Deletion aborted. Exiting script for safety."
        sleep 2
        exit 1
    fi
    
    # Perform deletion
    local current_offset
    current_offset=$(jq -r '."timezone-offset" // -18000' "$DATABASE_FILE" || echo "-18000")
    
    local new_offset
    echo ""
    if gum confirm "Would you like to reuse your current timestamp offset ($current_offset)?"; then
        new_offset="$current_offset"
    else
        new_offset=$(select_timezone_offset "$current_offset" || echo "$current_offset")
    fi

    if [[ -z "$new_offset" ]]; then new_offset="$current_offset"; fi

    init_database "true" "$new_offset"
    update_dir_cache
    echo ""
    typewrite "✓ BoneYARD at $DATABASE_FILE has been completely reinitialized."
    typewrite "Restarting script with original arguments..."
    sleep 1.5
    exec "$0" "$@"
}

# Display statistics
show_stats() {
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "📊 BoneYARD Statistics"
    
    echo "🏘️ Loaded BoneYARD: $DATABASE_FILE"
    
    local total_files
    total_files=$(jq '.files | length' "$DATABASE_FILE")
    
    local total_tags
    total_tags=$(jq '[.files[].tags[]] | unique | length' "$DATABASE_FILE")
    
    echo "🦴 Total Bones: $total_files"
    echo "👃 Unique Scents: $total_tags"
    
    local total_dirs
    total_dirs=$(jq '[.files[].path] | unique | length' "$DATABASE_FILE")
    echo "🏘️ Unique Kennels: $total_dirs"

    if [[ "$total_files" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "🕒 Recent Sniffs (Last 5 Buried):"
        jq -r '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[0:5] | .[] | 
            "  - \(.name) (Buried: \((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M")))"' \
            "$DATABASE_FILE"
    fi

    if [[ "$total_dirs" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "🏘️ Bones Per Kennel:"
        jq -r '.files[].path' "$DATABASE_FILE" | sort | uniq -c | sort -rn | \
            while read -r count path; do
                printf "  - %-30s : %s bones\n" "$path" "$count"
            done
    fi
    
    if [[ "$total_tags" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "👃 Scent Frequency (Strongest First):"
        jq -r '.files[].tags[]' "$DATABASE_FILE" | sort | uniq -c | sort -rn | \
            while read -r count tag; do
                printf "  - %-15s : %s sniffs\n" "$tag" "$count"
            done
    fi
    
    echo ""
    pause
    main_menu
}

# Switch to a different yard (database file) and restart
switch_yard() {
    play_menu_sound
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🏘️ Switch Yard"
    
    local temp_file="/tmp/ranger_chosen_db.txt"
    rm -f "$temp_file"
    
    echo "Sniffing for a different BoneYARD JSON (launching ranger)..."
    sleep 2
    ranger --choosefile="$temp_file" "$HOME"
    
    if [[ ! -s "$temp_file" ]]; then
        echo "No yard selected."
        pause
        main_menu
        return
    fi
    
    local new_db
    new_db=$(realpath "$(cat "$temp_file")")
    rm -f "$temp_file"
    
    if [[ ! -f "$new_db" ]]; then
        echo "Error: Selected file is not valid."
        pause
        main_menu
        return
    fi

    # Basic JSON validation to ensure it's at least a JSON file
    if ! jq '.' "$new_db" &>/dev/null; then
        echo "Error: Selected file is not a valid JSON BoneYARD."
        pause
        main_menu
        return
    fi

    echo ""
    typewrite "Switching to: $new_db"
    typewrite "The pack is moving to a new yard! (No bones will be transferred.)"
    sleep 1.5

    # Prepare arguments: remove existing --database/-d and add the new one
    local -a new_args=()
    local skip_next=false
    for arg in "$@"; do
        if [[ "$skip_next" == "true" ]]; then
            skip_next=false
            continue
        fi
        case "$arg" in
            -d|--database)
                skip_next=true
                ;;
            *)
                new_args+=("$arg")
                ;;
        esac
    done

    exec "$0" "--database" "$new_db" "${new_args[@]}"
}

# Display the license
read_license() {
    play_menu_sound
    clear
    local short_license
    short_license=$(cat << 'EOF'
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
)
    typewrite "$short_license" 0.001
    echo ""
    
    local choice
    choice=$(gum choose "Read More" "Go Back To Main Menu" || echo "Go Back To Main Menu")
    
    if [[ "$choice" == "Go Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    # Read More logic
    local local_license="$SCRIPT_DIR/LICENSE"
    local temp_license="/tmp/gpl_full.txt"
    local pulled=false
    local used_url=""
    
    if [[ -f "$local_license" ]]; then
        cp "$local_license" "$temp_license"
        pulled=true
        used_url="local file"
    else
        local license_urls=(
            "https://www.gnu.org/licenses/gpl-3.0.txt"
            "https://raw.githubusercontent.com/oss-collections/licenses/refs/heads/master/gpl-3.0.txt"
            "https://raw.githubusercontent.com/github/choosealicense.com/gh-pages/_licenses/gpl-3.0.txt"
            "https://archive.org/download/GPL3.0/GPL-3.0.txt"
            "https://pastebin.com/raw/HL2BPZ5w"
        )
        
        echo ""
        gum style --foreground 212 "⏳ Checking for online version (trying mirrors)..."
        
        for url in "${license_urls[@]}"; do
            if command -v curl &> /dev/null; then
                if curl -s --connect-timeout 2 --max-time 5 "$url" > "$temp_license"; then
                    if [[ -s "$temp_license" ]]; then
                        pulled=true
                        used_url="$url"
                        break
                    fi
                fi
            elif command -v wget &> /dev/null; then
                if wget -qO "$temp_license" --connect-timeout=2 --timeout=5 "$url"; then
                    if [[ -s "$temp_license" ]]; then
                        pulled=true
                        used_url="$url"
                        break
                    fi
                fi
            fi
        done
    fi
    
    if [[ "$pulled" == "false" ]]; then
        gum style --foreground 250 "⚠️  Online version unavailable. Using embedded text."
        sleep 1.5
        # Fallback version includes the critical warranty/liability clauses
        cat <<EOF > "$temp_license"
--- EMBEDDED LICENSE PREVIEW ---

$short_license

---

15. Disclaimer of Warranty.

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. Limitation of Liability.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
EOF
    else
        if [[ "$used_url" == "local file" ]]; then
            gum style --foreground 212 "✅ Full license loaded from local LICENSE file"
        else
            local domain
            domain=$(echo "$used_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
            gum style --foreground 212 "✅ Full license downloaded from $domain"
        fi
        sleep 1.5
    fi
    
    # Pager logic
    if [[ "$FORCED_PAGER" == "safe" ]]; then
        read_license_safe_pager "$temp_license"
    elif [[ -n "$FORCED_PAGER" ]]; then
        if command -v "$FORCED_PAGER" &> /dev/null; then
            "$FORCED_PAGER" "$temp_license"
        else
            echo "Error: Forced pager '$FORCED_PAGER' not found. Falling back to default detection."
            sleep 2
            read_license_auto_pager "$temp_license"
        fi
    else
        read_license_auto_pager "$temp_license"
    fi
    
    rm -f "$temp_license"
    clear
    main_menu
}

# Safe line-by-line pager
read_license_safe_pager() {
    local temp_license="$1"
    local lines_per_page=10
    local current_page=1
    
    # Calculate total pages
    local total_lines
    total_lines=$(wc -l < "$temp_license")
    local total_pages=$(( (total_lines + lines_per_page - 1) / lines_per_page ))
    
    while true; do
        clear
        local line_count=0
        local restart=false
        
        # Display header
        gum style --foreground 250 "=== LICENSE TEXT ==="
        echo ""
        
        while IFS= read -r line; do
            echo "$line"
            line_count=$((line_count + 1))
            
            if (( line_count % lines_per_page == 0 )); then
                echo ""
                echo -n "-- Page $current_page of $total_pages (q: quit, n: restart, any key: next) --"
                local key
                read -n 1 -s key < /dev/tty
                echo -ne "\r\033[K" # Clear the prompt line
                
                case "${key,,}" in
                    "q")
                        echo "Exiting..."
                        sleep 0.5
                        return
                        ;;
                    "n")
                        restart=true
                        break  # Break inner loop to restart from top
                        ;;
                    *)
                        current_page=$((current_page + 1))
                        ;;
                esac
            fi
        done < "$temp_license"
        
        # If we finished reading the file without restarting
        if [[ "$restart" != "true" ]]; then
            echo ""
            echo "----------------------------------------"
            typewrite "End of license. Press any key to continue..."
            read -n 1 -s < /dev/tty
            return
        fi
        
        # Reset for restart
        current_page=1
    done
}

# Auto-detect pager for license
read_license_auto_pager() {
    local temp_license="$1"
    if command -v nvim &> /dev/null; then
        nvim --clean -R "$temp_license"
    elif command -v nano &> /dev/null; then
        nano -v "$temp_license" # -v for view mode
    elif command -v less &> /dev/null; then
        less "$temp_license"
    else
        read_license_safe_pager "$temp_license"
    fi
}

# Main menu
main_menu() {
    if [[ "${1:-}" != "--no-sound" ]]; then
        play_menu_sound
    fi
    clear
    
    # Check if a new version was found by the background process
    if [[ -f "/tmp/boneyard_remote_version" ]]; then
        REMOTE_VERSION=$(cat "/tmp/boneyard_remote_version")
    fi

    local update_badge=""
    local res=0
    if [[ -n "$REMOTE_VERSION" ]]; then
        version_compare "$SOFTWARE_VERSION" "$REMOTE_VERSION" || res=$?
        if [[ $res -eq 2 ]]; then
            update_badge=" [🚀 UPDATE AVAILABLE: $REMOTE_VERSION]"
        fi
    fi

    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 70 --margin "1 2" --padding "1 2" \
        "BoneYARD $SOFTWARE_VERSION$update_badge" "Yappy Archive and Retrieval Database" \
        "Database: $DATABASE_FILE"

    local choice_list=()
    [[ -n "$update_badge" ]] && choice_list+=("🚀 Rebuild Doghouse (New Update Available!)")
    choice_list+=(
        "🦴 Bury New Bone"
        "🐕 Bury Entire Litter"
        "👃 Update Scents (Edit)"
        "🎾 Fetch Bones (Search)"
        "🧹 Clean Up the Yard (Remove)"
        "📊 Pack Stats"
        "🏘️ Switch Yard"
        "🌋 Incinerate the Yard"
        "📜 Kennel Rules (License)"
        "🚪 Kennel Sleep (Exit)"
    )

    local choice
    choice=$(printf "%s\n" "${choice_list[@]}" | gum choose --height 15 || true)
    
    if [[ -z "$choice" ]]; then
        double_bark_sfx
        rm -f "/tmp/boneyard_remote_version"
        typewrite "$(printf "%s\n" "${goodbye_text[@]}" | shuf -n 1)"
        exit 0
    fi

    case $choice in
        "🚀 Rebuild Doghouse (New Update Available!)") perform_update "$REMOTE_VERSION";;
        "🦴 Bury New Bone") add_file;;
        "🐕 Bury Entire Litter") tag_entire_directory;;
        "👃 Update Scents (Edit)") edit_tags;;
        "🎾 Fetch Bones (Search)") search_file;;
        "🧹 Clean Up the Yard (Remove)") remove_file;;
        "📊 Pack Stats") show_stats;;
        "🏘️ Switch Yard") switch_yard "$@";;
        "🌋 Incinerate the Yard") delete_entire_database;;
        "📜 Kennel Rules (License)") read_license;;
        "🚪 Kennel Sleep (Exit)") 
            double_bark_sfx
            rm -f "/tmp/boneyard_remote_version"
            typewrite "$(printf "%s\n" "${goodbye_text[@]}" | shuf -n 1)"
            exit 0
            ;;
        *) main_menu;;
    esac
}

# Main script execution
main() {
    parse_arguments "$@"
    check_dependencies
    
    # Cleanup stale update info and check for updates
    rm -f "/tmp/boneyard_remote_version"
    grab_remote_version
    
    check_compatibility
    init_database
    update_dir_cache
    double_bark_sfx
    main_menu --no-sound
}

main "$@"
