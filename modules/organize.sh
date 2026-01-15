# Organize flows.

# Organize bones into a directory
organize_bones() {
    play_menu_sound
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🦴 Organize Bones"
    
    # 1. Selection
    local organize_choice
    organize_choice=$(gum choose --header "Select bones to organize:" \
        "🏷️ By Scent" \
        "📝 By Bone Name" \
        "📅 By Date Range" \
        "📁 By Kennel (Directory)" \
        "📋 All Buried Bones" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$organize_choice" || "$organize_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    local matches_json=""
    case $organize_choice in
        "🏷️ By Scent")
            local search_tag
            search_tag=$(gum input --placeholder "Enter scents to organize (supports AND, OR, NOT)" || true)
            [[ -z "$search_tag" ]] && { organize_bones; return; }
            local jq_filter
            jq_filter=$(build_tag_query_filter "$search_tag")
            matches_json=$(jq -c ".files[] | select($jq_filter)" <<< "$DB_CACHE")
            ;;
        "📝 By Bone Name")
            local search_name
            search_name=$(gum input --placeholder "Enter bone name to organize (* for all)" || true)
            [[ "$search_name" == "*" ]] && search_name=""
            [[ -z "$search_name" ]] && { organize_bones; return; }
            matches_json=$(jq -c --arg name "$search_name" '.files[] | select(.name | ascii_downcase | contains($name | ascii_downcase))' <<< "$DB_CACHE")
            ;;
        "📅 By Date Range")
            echo "Enter dates in YYYY-MM-DD format (or leave blank for all)."
            local start_date
            start_date=$(gum input --placeholder "From (YYYY-MM-DD)" || true)
            local end_date
            end_date=$(gum input --placeholder "To (YYYY-MM-DD)" || true)
            [[ "$end_date" == "-" ]] && end_date="$start_date"
            
            local start_ts=0
            local end_ts=2147483647
            
            if [[ -n "$start_date" ]]; then
                start_ts=$(date -d "$start_date" +%s 2>/dev/null || echo "error")
                if [[ "$start_ts" == "error" ]]; then
                    echo "Error: Invalid start date format."
                    pause; organize_bones; return
                fi
            fi
            if [[ -n "$end_date" ]]; then
                end_ts=$(date -d "$end_date 23:59:59" +%s 2>/dev/null || echo "error")
                if [[ "$end_ts" == "error" ]]; then
                    echo "Error: Invalid end date format."
                    pause; organize_bones; return
                fi
            fi
            matches_json=$(jq -c --argjson start "$start_ts" --argjson end "$end_ts" '.files[] | select(.modified_timestamp >= $start and .modified_timestamp <= $end)' <<< "$DB_CACHE")
            ;;
        "📁 By Kennel (Directory)")
            if [[ ! -s "$DIR_CACHE_FILE" ]]; then
                echo "No kennels found in database."
                pause
                organize_bones
                return
            fi
            local selected_dir
            selected_dir=$(gum choose --header "Select Kennel to organize:" < "$DIR_CACHE_FILE" || true)
            [[ -z "$selected_dir" ]] && { organize_bones; return; }
            matches_json=$(jq -c --arg dir "$selected_dir" '.files[] | select(.path == $dir)' <<< "$DB_CACHE")
            ;;
        "📋 All Buried Bones")
            matches_json=$(jq -c '.files[]' <<< "$DB_CACHE")
            ;;
    esac
    
    local count
    count=$(echo "$matches_json" | jq -s 'length')
    if [[ "$count" -eq 0 ]]; then
        echo "No bones found matching selection."
        pause
        organize_bones
        return
    fi
    
    echo "Selected $count bones for organization."
    echo ""
    local offset
    offset=$(jq -r '.["timezone-offset"] // 0' <<< "$DB_CACHE")
    echo "$matches_json" | jq -r --arg offset "$offset" \
        '((.modified_timestamp + ($offset | tonumber)) | strftime("[%Y-%m-%d %H:%M]")) as $ts |
         "\($ts) ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"'
    echo ""
    
    # 2. Destination
    local temp_dest="/tmp/ranger_organize_dest.txt"
    rm -f "$temp_dest"
    
    echo "Instructions:"
    echo "  1. Navigate INTO the destination folder."
    echo "     (Tip: Press ':' then type 'mkdir <name>' to create a new folder)"
    echo "  2. Press 'q' to select this folder and exit ranger."
    echo ""
    echo "Press Enter to start sniffing with ranger..."
    read -n 1 -s < /dev/tty
    ranger --choosedir="$temp_dest" "$HOME"
    
    if [[ ! -s "$temp_dest" ]]; then
        echo "No destination selected."
        pause
        organize_bones
        return
    fi
    
    local dest_dir
    dest_dir=$(realpath "$(cat "$temp_dest")")
    rm -f "$temp_dest"

    # Confirm selection
    if ! gum confirm "Organize bones into: $dest_dir?"; then
        echo "Selection cancelled."
        organize_bones
        return
    fi
    
    # 3. Preferences
    local op_type
    op_type=$(gum choose --header "Operation type:" "Preserve original files (Copy)" "Delete original files after organizing (Move)" || echo "Copy")
    
    local db_sync="none"
    if [[ "$op_type" == *"Move"* ]]; then
        db_sync=$(gum choose --header "How to handle database entries?" "Update database with new locations" "Remove entries from database" "Keep original entries (Broken paths)" || echo "Update")
    fi
    
    local structure
    structure=$(gum choose --header "Directory structure:" "Subdirectories (Based on top scent)" "All in same directory" || echo "Subdirectories")
    
    # 4. Processing
    echo ""
    echo "Building frequency map..."
    local freq_map
    freq_map=$(jq -r '[.files[].tags[]] | group_by(.) | map({(.[0]): length}) | add' <<< "$DB_CACHE")
    
    local updated_files_json="[]"
    local removed_ids=()
    local processed_count=0
    local success_count=0
    
    while read -r file_obj; do
        local original_name
        original_name=$(echo "$file_obj" | jq -r '.name')
        local original_path
        original_path=$(echo "$file_obj" | jq -r '.path')
        local original_full_path="$original_path/$original_name"
        local file_id
        file_id=$(echo "$file_obj" | jq -r '.unique_id')
        local tags_json
        tags_json=$(echo "$file_obj" | jq -c '.tags')
        
        if [[ ! -f "$original_full_path" ]]; then
            echo "⚠️  Missing bone: $original_full_path (Skipping)"
            continue
        fi
        
        # Handle untagged case
        if [[ "$tags_json" == "[]" ]]; then
            if gum confirm "Bone '$original_name' has no scents. Add some now?"; then
                local new_tags_input
                new_tags_input=$(gum input --placeholder "Enter scents (comma-separated)" || true)
                if [[ -n "$new_tags_input" ]]; then
                    IFS=',' read -ra tags_array <<< "$new_tags_input"
                    tags_json='[]'
                    for tag in "${tags_array[@]}"; do
                        tag=$(echo "$tag" | xargs)
                        [[ -n "$tag" ]] && tags_json=$(echo "$tags_json" | jq --arg tag "$tag" '. += [$tag]')
                    done
                else
                    tags_json='["untagged"]'
                fi
            else
                tags_json='["untagged"]'
            fi
        fi
        
        # Sort and sanitize tags
        local sorted_tags
        sorted_tags=$(echo "$tags_json" | jq -r --argjson freq "$freq_map" '. | sort_by(-$freq[.]) | .[]')
        
        local top_scent
        top_scent=$(echo "$sorted_tags" | head -n 1)
        local top_5_tags
        top_5_tags=$(echo "$sorted_tags" | head -n 5)
        
        # Build sanitized filename
        local base_filename=""
        while read -r tag; do
            # Replace spaces with underscores, omit other special characters except . and _
            local sanitized
            sanitized=$(echo "$tag" | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9._]//g')
            [[ -n "$base_filename" ]] && base_filename+=" "
            base_filename+="$sanitized"
        done <<< "$top_5_tags"
        
        local extension="${original_name##*.}"
        [[ "$original_name" != *.* ]] && extension=""
        [[ -n "$extension" ]] && extension=".$extension"
        
        local final_filename="$base_filename$extension"
        local target_subdir="$dest_dir"
        [[ "$structure" == *"Subdirectories"* ]] && target_subdir="$dest_dir/$(echo "$top_scent" | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9._]//g')"
        
        mkdir -p "$target_subdir"
        
        # Collision handling
        local counter=1
        local check_path="$target_subdir/$final_filename"
        while [[ -f "$check_path" ]]; do
            final_filename="$base_filename #$counter$extension"
            check_path="$target_subdir/$final_filename"
            counter=$((counter + 1))
        done
        
        # Perform action
        local success=false
        if [[ "$op_type" == *"Copy"* ]]; then
            if cp -rf "$original_full_path" "$check_path"; then success=true; fi
        else
            if mv "$original_full_path" "$check_path"; then success=true; fi
        fi
        
        if [[ "$success" == "true" ]]; then
            echo "✅ Organized: $original_name -> $final_filename"
            success_count=$((success_count + 1))
            
            # DB Sync Prep
            if [[ "$db_sync" == *"Update"* ]]; then
                local new_entry
                new_entry=$(echo "$file_obj" | jq -c --arg name "$final_filename" --arg path "$target_subdir" --argjson tags "$tags_json" \
                    '.name = $name | .path = $path | .tags = $tags')
                updated_files_json=$(echo "$updated_files_json" | jq --argjson entry "$new_entry" '. += [$entry]')
            elif [[ "$db_sync" == *"Remove"* ]]; then
                removed_ids+=("$file_id")
            fi
        else
            echo "❌ Failed to organize: $original_name"
        fi
        
        processed_count=$((processed_count + 1))
    done < <(echo "$matches_json")
    
    # 5. DB Finalization
    if [[ "$db_sync" == *"Update"* && "$success_count" -gt 0 ]]; then
        echo "Updating database records..."
        # This is a bit complex: we need to replace existing entries with updated ones
        # For simplicity, we'll remove old ones and append new ones
        DB_CACHE=$(jq --argjson updates "$updated_files_json" '
            .files |= map(
                . as $old | 
                ($updates[] | select(.unique_id == $old.unique_id)) // $old
            )' <<< "$DB_CACHE")
        sync_db_to_disk
        SESSION_MODIFIED=true
        update_dir_cache
    elif [[ "$db_sync" == *"Remove"* && ${#removed_ids[@]} -gt 0 ]]; then
        echo "Removing database records..."
        local ids_json
        ids_json=$(printf '%s\n' "${removed_ids[@]}" | jq -R . | jq -s .)
        DB_CACHE=$(jq --argjson ids "$ids_json" '.files |= map(select(.unique_id as $id | ($ids | index($id) | not)))' <<< "$DB_CACHE")
        sync_db_to_disk
        SESSION_MODIFIED=true
        update_dir_cache
    fi
    
    echo ""
    gum style --foreground 212 "✓ Organization complete! $success_count/$processed_count bones moved/copied."
    
    if gum confirm "Would you like to open the destination folder?"; then
        (xdg-open "$dest_dir" > /dev/null 2>&1 &)
    fi

    pause
    main_menu
}
