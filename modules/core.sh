# Core helpers, database utilities, and update logic.

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

# Check if github.com is reachable
check_github_connectivity() {
    curl -Is --connect-timeout 2 https://github.com &>/dev/null
}

# Load the database into memory
load_db_to_memory() {
    if [[ -f "$WORKING_DATABASE_FILE" ]]; then
        DB_CACHE=$(<"$WORKING_DATABASE_FILE")
    else
        DB_CACHE=""
    fi
}

# Sync the memory cache to disk
sync_db_to_disk() {
    echo "$DB_CACHE" > "$WORKING_DATABASE_FILE"
}

# Parse a tag query string into a jq select expression
# Supports AND, OR, NOT and parentheses
build_tag_query_filter() {
    local input="$1"
    [[ -z "${input// }" ]] && return

    # Helper to format a tag for jq
    _format_tag() {
        local tag="$1"
        # Escape double quotes for jq string
        local escaped
        escaped=$(echo "$tag" | sed 's/"/\\"/g')
        echo "(.tags | map(ascii_downcase) | contains([\"$escaped\" | ascii_downcase]))"
    }

    # If no boolean operators or parentheses, keep simple exact match
    if [[ ! "$input" =~ [[:space:]](AND|OR|NOT)[[:space:]] && ! "$input" =~ ^NOT[[:space:]] && ! "$input" =~ "(" ]]; then
        _format_tag "$input"
        return
    fi

    set -f # Disable globbing for tokenization
    local tokens=( $(echo "$input" | sed 's/(/ ( /g; s/)/ ) /g') )
    set +f # Re-enable globbing
    
    local jq_expr=""
    local last_was_operand=false
    
    for ((i=0; i<${#tokens[@]}; i++)); do
        local token="${tokens[i]}"
        local upper_token="${token^^}"
        
        case "$upper_token" in
            "AND") jq_expr+=" and "; last_was_operand=false ;;
            "OR")  jq_expr+=" or "; last_was_operand=false ;;
            "NOT")
                [[ "$last_was_operand" == "true" ]] && jq_expr+=" and "
                local next_token="${tokens[i+1]:-}"
                if [[ "$next_token" == "(" ]]; then
                     jq_expr+=" not "
                else
                     jq_expr+=" (not$(_format_tag "$next_token")) "
                     ((i++))
                fi
                last_was_operand=true
                ;;
            "(")   
                [[ "$last_was_operand" == "true" ]] && jq_expr+=" and "
                jq_expr+=" ( "; last_was_operand=false ;;
            ")")   jq_expr+=" ) "; last_was_operand=true ;;
            *)     
                [[ "$last_was_operand" == "true" ]] && jq_expr+=" and "
                jq_expr+=" $(_format_tag "$token") "
                last_was_operand=true
                ;;
        esac
    done
    echo "$jq_expr"
}

# Fetch the latest version from the remote repository
grab_remote_version() {
    check_github_connectivity || return 0
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
    if [[ "${BONEYARD_STANDALONE:-false}" == "true" ]]; then
        echo ""
        gum style --foreground 208 "⚠️  Updates are disabled in standalone mode."
        echo "Generate a new standalone file from the modular project to update."
        pause
        return 0
    fi

    if ! check_github_connectivity; then
        echo ""
        gum style --foreground 196 "❌ Error: github.com is unreachable."
        echo "Please check your internet connection or try again later."
        pause
        return 1
    fi

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
    
    # Don't hide git errors; the user needs to see why it failed (e.g., network, proxy)
    if ! git clone --depth 1 https://github.com/lovelyspacedog/BoneYARD.git "$download_dir"; then
        echo ""
        gum style --foreground 196 "❌ Error: Failed to fetch the new yard files."
        echo "Please check your internet connection or git configuration."
        rm -rf "$download_dir"
        pause
        main_menu
        return 1
    fi

    # Safety Check: Check for clutter in the script directory
    local project_files=("BoneYARD.sh" "boneyard" "boneyard.json" "LICENSE" "README.md" "CHANGELOG.md" "wordlist.txt" ".gitignore")
    local foreign_count=0
    
    # Enable nullglob so an empty directory doesn't return '*'
    shopt -s nullglob
    for f in "$update_dir"/*; do
        [[ -d "$f" ]] && continue # Skip directories
        local fname
        fname=$(basename "$f")
        local is_proj=false
        for p in "${project_files[@]}"; do
            if [[ "$fname" == "$p" ]]; then is_proj=true; break; fi
        done
        if [[ "$is_proj" == "false" ]]; then
            foreign_count=$((foreign_count + 1))
        fi
    done
    shopt -u nullglob

    local update_mode="full"
    if (( foreign_count > 2 )); then
        echo ""
        gum style --foreground 208 "⚠️  CLUTTER WARNING: This directory contains $foreign_count non-project files."
        echo "It looks like you might have saved BoneYARD in a shared folder (like Downloads)."
        echo ""
        if gum confirm "Would you like to perform a Minimal Update? (Copies BoneYARD.sh and core modules only)"; then
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
    echo "Minimal Update: Moving BoneYARD.sh and modules..."
    if cp -rf "\$SOURCE_DIR/BoneYARD.sh" "\$TARGET_DIR/"; then
        echo "  [Updated] BoneYARD.sh"
    else
        echo "  [Error] Failed to update BoneYARD.sh"
        exit 1
    fi

    if [[ -d "\$SOURCE_DIR/modules" ]]; then
        if cp -rf "\$SOURCE_DIR/modules" "\$TARGET_DIR/"; then
            echo "  [Updated] modules/"
        else
            echo "  [Error] Failed to update modules/"
            exit 1
        fi
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
    
    if [[ "$DOGGY_BAG_MODE" == "true" ]]; then
        # Check if changes were made
        local changes_made=false
        if [[ ! -f "$DATABASE_FILE" ]]; then
            [[ -f "$WORKING_DATABASE_FILE" ]] && changes_made=true
        else
            if ! diff -q "$DATABASE_FILE" "$WORKING_DATABASE_FILE" &>/dev/null; then
                changes_made=true
            fi
        fi

        if [[ "$changes_made" == "true" ]]; then
            echo ""
            gum style --foreground 212 --border double --padding "1 2" "🐾 Empty the Doggy Bag before updating?"
            echo "You have changes in your doggy bag. Would you like to bury them in the yard before installing the new doghouse?"
            if gum confirm "Empty the doggy bag into the yard?"; then
                cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE"
                typewrite "✓ Doggy bag emptied! Changes buried in the yard."
            else
                typewrite "Abandoning the scent... Changes discarded."
            fi
        fi
    fi

    echo "Starting the handoff... Woof!"
    # Release lock before handover
    release_db_lock
    # Execute the updater and replace the current process
    exec "$updater_script"
}

# Check if the software is compatible with the loaded database
check_compatibility() {
    if [[ ! -f "$WORKING_DATABASE_FILE" ]]; then return 0; fi
    
    # Ensure it's valid JSON before proceeding
    if ! jq -e '.' <<< "$DB_CACHE" &>/dev/null; then
        echo "Error: Cannot check compatibility - Database is not valid JSON."
        exit 1
    fi

    local db_version
    db_version=$(jq -r '.version' <<< "$DB_CACHE" 2>/dev/null || echo "0.0.0")
    
    # Handle legacy integer versions (e.g. "1" -> "1.0.0")
    if [[ "$db_version" =~ ^[0-9]+$ ]]; then
        db_version="$db_version.0.0"
    fi

    local sw_major
    sw_major=$(echo "$SOFTWARE_VERSION" | cut -d. -f1)
    local db_major
    db_major=$(echo "$db_version" | cut -d. -f1)

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
        
        # Check if a newer version is available online
        local remote_v=""
        [[ -f "/tmp/boneyard_remote_version" ]] && remote_v=$(cat "/tmp/boneyard_remote_version")
        
        if [[ -n "$remote_v" ]]; then
            local remote_res=0
            version_compare "$remote_v" "$db_version" || remote_res=$?
            # If remote version is newer than or equal to database version
            if [[ $remote_res -ne 2 ]]; then
                echo "A new doghouse ($remote_v) is available that supports this database."
                if gum confirm "Would you like to fetch the new doghouse now?"; then
                    perform_update "$remote_v"
                fi
            fi
        fi

        typewrite "Please update BoneYARD to the latest version to use this database."
        exit 1
    elif [[ $res -eq 1 ]]; then
        echo ""
        gum style --foreground 212 "🐾 Database Version Update"
        echo "Current Database: $db_version"
        echo "Software Version: $SOFTWARE_VERSION"
        echo ""
        if gum confirm "Would you like to update the database version to match the software?"; then
            DB_CACHE=$(jq --arg ver "$SOFTWARE_VERSION" '.version = $ver' <<< "$DB_CACHE")
            sync_db_to_disk
            SESSION_MODIFIED=true
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

# Acquire a lock on the database file to prevent concurrent access
acquire_db_lock() {
    local db_path="$1"
    local lock_file="${db_path}.lock"
    
    if [[ -f "$lock_file" ]]; then
        local lock_pid
        lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")
        # If PID is not empty and refers to a running process that isn't US
        if [[ -n "$lock_pid" ]] && [[ "$lock_pid" != "$$" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            echo ""
            gum style --foreground 196 --border double --padding "1 2" "🚨 DATABASE LOCKED"
            echo "The database at $(basename "$db_path") is currently in use by another pup (PID: $lock_pid)."
            echo "To prevent yard corruption, only one pup can dig in the same yard at once."
            echo ""
            exit 1
        else
            # Stale lock or it's us (from an exec)
            rm -f "$lock_file"
        fi
    fi
    
    echo $$ > "$lock_file"
    CURRENT_LOCK_FILE="$lock_file"
}

# Release the currently held database lock
release_db_lock() {
    if [[ -n "$CURRENT_LOCK_FILE" && -f "$CURRENT_LOCK_FILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$CURRENT_LOCK_FILE" 2>/dev/null || echo "")
        if [[ "$lock_pid" == "$$" ]]; then
            rm -f "$CURRENT_LOCK_FILE"
        fi
    fi
    CURRENT_LOCK_FILE=""
}

# Check if the database is corrupted and offer repair or re-init
check_database_health() {
    if [[ ! -f "$WORKING_DATABASE_FILE" ]]; then return 0; fi
    
    if ! jq -e '.' "$WORKING_DATABASE_FILE" &>/dev/null; then
        echo ""
        gum style --foreground 196 --border double --padding "1 2" "🚨 CORRUPTED DATABASE DETECTED"
        echo "The BoneYARD database at $DATABASE_FILE appears to be corrupted."
        echo ""
        
        local choice
        choice=$(gum choose "🛠️ Attempt Repair (Basic)" "🆕 Start Fresh (Delete & Re-init)" "🚪 Exit" || echo "Exit")
        
        case "$choice" in
            "🛠️ Attempt Repair (Basic)")
                echo "Attempting to salvage the database structure..."
                local salvaged_file="/tmp/boneyard_salvaged.json"
                if jq -e '.' "$WORKING_DATABASE_FILE" > "$salvaged_file" 2>/dev/null; then
                    mv "$salvaged_file" "$WORKING_DATABASE_FILE"
                    load_db_to_memory
                    typewrite "✓ Database structure salvaged and repaired."
                else
                    rm -f "$salvaged_file"
                    typewrite "❌ Automatic repair failed. The corruption is too severe."
                    if gum confirm "Would you like to start fresh instead? (Your current database will be backed up as .bak)"; then
                        cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE.bak"
                        init_database "true"
                    else
                        exit 1
                    fi
                fi
                ;;
            "🆕 Start Fresh (Delete & Re-init)")
                if gum confirm "Are you sure? This will delete all your buried bones! (A backup .bak will be created)"; then
                    cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE.bak"
                    init_database "true"
                else
                    exit 1
                fi
                ;;
            *)
                exit 1
                ;;
        esac
    fi
}

# Initialize the database file
init_database() {
    local force="${1:-false}"
    local offset="${2:-}"
    
    if [[ ! -f "$WORKING_DATABASE_FILE" ]]; then
        # New database - ask for offset
        offset=$(select_timezone_offset "0" "true")
    elif [[ -z "$offset" ]]; then
        # Force re-init but no offset provided, use existing
        offset=$(jq -r '."timezone-offset" // 0' <<< "$DB_CACHE" 2>/dev/null || echo "0")
    fi

    if [[ ! -f "$WORKING_DATABASE_FILE" || "$force" == "true" ]]; then
        cat <<EOF | jq '.' > "$WORKING_DATABASE_FILE"
{
  "version": "$DATABASE_VERSION",
  "timezone-offset": $offset,
  "_comment": {
    "1": "This is the timezone offset for the BoneYARD. It is used to convert the modified timestamp to the local timezone.",
    "2": "Use a timezone offset of -18000 for EST (-5 hours), or -14400 for EDT (-4 hours).",
    "3": "Units are seconds since epoch."
  },
  "files": [],
  "auto-snapshot": {
    "enabled": false,
    "interval": "1d",
    "last-run": 0
  }
}
EOF
        echo "BoneYARD initialized at $DATABASE_FILE with offset $offset"
        SESSION_MODIFIED=true
        load_db_to_memory
    fi
}

# Check if auto-snapshot is due and perform it
check_auto_snapshot() {
    # Don't auto-snapshot in Doggy Bag mode to avoid confusion
    [[ "$DOGGY_BAG_MODE" == "true" ]] && return

    local enabled
    enabled=$(jq -r '."auto-snapshot".enabled // false' <<< "$DB_CACHE")
    [[ "$enabled" != "true" ]] && return

    local interval
    interval=$(jq -r '."auto-snapshot".interval // "1d"' <<< "$DB_CACHE")
    local last_run
    last_run=$(jq -r '."auto-snapshot"."last-run" // 0' <<< "$DB_CACHE")
    local current_ts
    current_ts=$(date +%s)
    
    # Convert interval to seconds
    local interval_secs=86400 # Default 1 day
    case "$interval" in
        *h) interval_secs=$((${interval%h} * 3600)) ;;
        *d) interval_secs=$((${interval%d} * 86400)) ;;
        *w) interval_secs=$((${interval%w} * 604800)) ;;
        *m) interval_secs=$((${interval%m} * 2592000)) ;; # Approx 30 days
    esac

    if (( current_ts - last_run >= interval_secs )); then
        echo ""
        gum style --foreground 212 "🕒 Auto-Snapshot due. Burying a background snapshot..."
        
        mkdir -p "$DEFAULT_BACKUP_DIR"
        local timestamp
        timestamp=$(date +%Y-%m-%d_%H-%M-%S)
        local backup_file="$DEFAULT_BACKUP_DIR/auto_snapshot_$timestamp.json"
        
        if cp "$DATABASE_FILE" "$backup_file"; then
            echo "✓ Auto-snapshot buried: $(basename "$backup_file")"
            # Update last-run in memory and disk
            DB_CACHE=$(jq --argjson ts "$current_ts" '."auto-snapshot"."last-run" = $ts' <<< "$DB_CACHE")
            sync_db_to_disk
        else
            echo "❌ Failed to perform auto-snapshot."
        fi
        sleep 1
    fi
}

# Configure auto-snapshot settings
manage_auto_snapshot_config() {
    play_menu_sound
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🕒 Auto-Snapshot Configuration"
    
    local enabled
    enabled=$(jq -r '."auto-snapshot".enabled // false' <<< "$DB_CACHE")
    local interval
    interval=$(jq -r '."auto-snapshot".interval // "1d"' <<< "$DB_CACHE")
    
    echo "Current Status: $( [[ "$enabled" == "true" ]] && echo "✅ Enabled" || echo "❌ Disabled" )"
    echo "Current Interval: $interval"
    echo ""
    
    local choice
    choice=$(gum choose "Toggle Status" "Change Interval" "⬅️ Back To Cache Menu" || echo "⬅️ Back To Cache Menu")
    
    case "$choice" in
        "Toggle Status")
            local new_status="true"
            [[ "$enabled" == "true" ]] && new_status="false"
            DB_CACHE=$(jq --argjson status "$new_status" '."auto-snapshot".enabled = $status' <<< "$DB_CACHE")
            sync_db_to_disk
            SESSION_MODIFIED=true
            echo "✓ Auto-snapshot status updated."
            sleep 1
            manage_auto_snapshot_config
            ;;
        "Change Interval")
            local new_interval
            new_interval=$(gum choose "1h" "6h" "12h" "1d" "2d" "1w" "2w" "1m" || echo "$interval")
            DB_CACHE=$(jq --arg interval "$new_interval" '."auto-snapshot".interval = $interval' <<< "$DB_CACHE")
            sync_db_to_disk
            SESSION_MODIFIED=true
            echo "✓ Auto-snapshot interval updated to $new_interval."
            sleep 1
            manage_auto_snapshot_config
            ;;
        *)
            manage_backups
            ;;
    esac
}

# Update the directory cache file
update_dir_cache() {
    jq -r '.files[].path' <<< "$DB_CACHE" | sort -u > "$DIR_CACHE_FILE"
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
    max_id=$(jq '[.files[].unique_id] | max // 0' <<< "$DB_CACHE")
    echo $((max_id + 1))
}
