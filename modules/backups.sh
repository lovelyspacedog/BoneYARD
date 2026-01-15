# Snapshot/cache management.

# Backup and restore management
manage_backups() {
    play_menu_sound
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🐾 Cache Bones (Snapshots)"
    
    local choice
    choice=$(gum choose "🦴 Bury New Snapshot" "🎾 Fetch From The Cache" "🐾 Paw Through The Cache" "🧹 Clean Up the Cache" "🕒 Auto-Snapshot Config" "⬅️ Back To Main Menu" || echo "⬅️ Back To Main Menu")
    
    case "$choice" in
        "🦴 Bury New Snapshot") create_backup ;;
        "🎾 Fetch From The Cache") restore_backup ;;
        "🐾 Paw Through The Cache") list_backups ;;
        "🧹 Clean Up the Cache") delete_backup ;;
        "🕒 Auto-Snapshot Config") manage_auto_snapshot_config ;;
        *) main_menu ;;
    esac
}

list_backups() {
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🐾 Paw Through The Cache"

    if [[ ! -d "$DEFAULT_BACKUP_DIR" ]]; then
        echo "Default backup directory does not exist: $DEFAULT_BACKUP_DIR"
    else
        echo "Yards cached in: $DEFAULT_BACKUP_DIR"
        echo ""

        # Calculate total directory size
        local total_dir_size
        total_dir_size=$(du -sh "$DEFAULT_BACKUP_DIR" 2>/dev/null | cut -f1)
        echo "📏 Total cache size: $total_dir_size"
        echo ""

        local files=()
        while IFS= read -r f; do
            files+=("$f")
        done < <(ls "$DEFAULT_BACKUP_DIR"/{backup,auto_snapshot}_*.json 2>/dev/null | sort -r)

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No snapshots found in the default cache."
        else
            for f in "${files[@]}"; do
                local fname
                fname=$(basename "$f")
                local ftime
                ftime=$(date -r "$f" "+%Y-%m-%d %H:%M:%S")
                local fsize
                fsize=$(du -h "$f" | cut -f1)
                # Count bones in snapshot
                local bone_count
                bone_count=$(jq '.files | length' "$f" 2>/dev/null || echo "0")
                printf "  🏘️  %-30s | %s | %s | %s bones\n" "$fname" "$ftime" "$fsize" "$bone_count"
            done
            echo ""
            echo "Total snapshots: ${#files[@]}"
        fi
    fi

    pause
    manage_backups
}

create_backup() {
    echo ""
    local backup_dir
    local choice
    choice=$(gum choose "📁 Use Default ($DEFAULT_BACKUP_DIR)" "📂 Select Other Directory" || echo "Cancel")
    
    if [[ "$choice" == "📂 Select Other Directory" ]]; then
        local temp_dir="/tmp/boneyard_backup_dir.txt"
        rm -f "$temp_dir"
        echo "Select yard snapshot destination (launching ranger)..."
        ranger --choosedir="$temp_dir" "$HOME"
        if [[ -s "$temp_dir" ]]; then
            backup_dir=$(realpath "$(cat "$temp_dir")")
        else
            echo "No directory selected. Operation cancelled."
            pause
            manage_backups
            return
        fi
        rm -f "$temp_dir"
    elif [[ "$choice" == "📁 Use Default"* ]]; then
        backup_dir="$DEFAULT_BACKUP_DIR"
    else
        manage_backups
        return
    fi
    
    mkdir -p "$backup_dir"
    local timestamp
    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    local backup_file="$backup_dir/backup_$timestamp.json"
    
    if cp "$WORKING_DATABASE_FILE" "$backup_file"; then
        typewrite "✓ Yard snapshot buried successfully at:"
        echo "  $backup_file"
    else
        echo "Error: Failed to bury yard snapshot."
    fi
    
    pause
    manage_backups
}

restore_backup() {
    echo ""
    local backup_file
    local choice
    choice=$(gum choose "📁 From Default ($DEFAULT_BACKUP_DIR)" "📂 Select Other File (Ranger)" || echo "Cancel")
    
    if [[ "$choice" == "📂 Select Other File (Ranger)" ]]; then
        local temp_file="/tmp/boneyard_restore_file.txt"
        rm -f "$temp_file"
        echo "Select yard snapshot to fetch (launching ranger)..."
        ranger --choosefile="$temp_file" "$HOME"
        if [[ -s "$temp_file" ]]; then
            backup_file=$(realpath "$(cat "$temp_file")")
        else
            echo "No snapshot selected. Fetch cancelled."
            pause
            manage_backups
            return
        fi
        rm -f "$temp_file"
    elif [[ "$choice" == "📁 From Default"* ]]; then
        if [[ ! -d "$DEFAULT_BACKUP_DIR" ]]; then
            echo "Default cache directory does not exist."
            pause
            manage_backups
            return
        fi
        
        # List json files in default backup dir
        local files=()
        while IFS= read -r f; do
            files+=("$f")
        done < <(ls "$DEFAULT_BACKUP_DIR"/{backup,auto_snapshot}_*.json 2>/dev/null | sort -r)
        
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No snapshots found in $DEFAULT_BACKUP_DIR"
            pause
            manage_backups
            return
        fi
        
        backup_file=$(printf "%s\n" "${files[@]}" | gum choose --header "Select a yard snapshot to fetch:" || echo "")
        if [[ -z "$backup_file" ]]; then
            manage_backups
            return
        fi
    else
        manage_backups
        return
    fi
    
    # Confirm restore
    echo ""
    gum style --foreground 196 "⚠️  WARNING: This will OVERWRITE your current yard!"
    echo "Current Yard:    $DATABASE_FILE"
    echo "Yard Snapshot:   $backup_file"
    echo ""
    
    if gum confirm "Are you sure you want to fetch this yard snapshot?"; then
        if cp "$backup_file" "$WORKING_DATABASE_FILE"; then
            load_db_to_memory
            typewrite "✓ Yard fetched and restored successfully."
            SESSION_MODIFIED=true
            
            if gum confirm "Would you like to delete the snapshot from the cache now?"; then
                rm -f "$backup_file"
                typewrite "✓ Snapshot removed from cache."
            fi
        else
            echo "Error: Failed to fetch snapshot."
        fi
    else
        echo "Fetch cancelled."
    fi
    
    pause
    manage_backups
}

delete_backup() {
    echo ""
    gum style --foreground 196 --border double --padding "0 1" "🧹 Clean Up the Cache"
    
    if [[ ! -d "$DEFAULT_BACKUP_DIR" ]]; then
        echo "Default cache directory does not exist: $DEFAULT_BACKUP_DIR"
        pause
        manage_backups
        return
    fi
    
    local files=()
    while IFS= read -r f; do
        files+=("$f")
    done < <(ls "$DEFAULT_BACKUP_DIR"/{backup,auto_snapshot}_*.json 2>/dev/null | sort -r)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No snapshots found in $DEFAULT_BACKUP_DIR"
        pause
        manage_backups
        return
    fi
    
    local backup_file
    backup_file=$(printf "%s\n" "${files[@]}" | gum choose --header "Select a yard snapshot to incinerate:" || echo "")
    
    if [[ -z "$backup_file" ]]; then
        manage_backups
        return
    fi
    
    if gum confirm "Are you sure you want to permanently delete this snapshot?"; then
        if rm -f "$backup_file"; then
            typewrite "✓ Snapshot removed from cache."
        else
            echo "Error: Failed to delete snapshot."
        fi
    else
        echo "Clean up cancelled."
    fi
    
    pause
    manage_backups
}
