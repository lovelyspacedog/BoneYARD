# Tagging and editing flows.

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
    local file_name
    file_name=$(basename "$file_path")
    local dir_path
    dir_path=$(dirname "$file_path")
    
    # Check if file already exists in database
    local existing_id
    existing_id=$(jq -r --arg path "$file_path" --arg name "$file_name" \
        '.files[] | select(.path == $path and .name == $name) | .unique_id' <<< "$DB_CACHE")
    
    if [[ -n "$existing_id" ]]; then
        printf "Woof! This bone is already buried in the yard (ID: %04d)\n" "$existing_id"
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
    
    DB_CACHE=$(jq --argjson entry "$new_entry" '.files += [$entry]' <<< "$DB_CACHE")
    sync_db_to_disk
    SESSION_MODIFIED=true
    update_dir_cache
    double_bark_sfx
    
    echo ""
    printf "✓ Bone buried successfully (ID: %04d)\n" "$next_id"
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
    echo "     (Tip: Press ':' then type 'mkdir <name>' to create a new folder)"
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
        local file_name
        file_name=$(basename "$current_file")
        
        clear
        gum style --foreground 212 --border double --padding "0 1" "🐕 Burying Litter in: $dir_path"
        
        # Progress Info
        gum style --foreground 208 --bold "  🦴 Bone $((i + 1)) of $total_files"

        # Session Tag Summary
        local session_tag_summary
        session_tag_summary=$(jq -r 'map(.tags[]) | group_by(.) | map({key: .[0], value: length}) | from_entries | to_entries | sort_by(-.value) | map("\(.key)(\(.value))") | join(", ")' "$buffered_json_file" 2>/dev/null || echo "")
        if [[ -n "$session_tag_summary" ]]; then
            local wrapped_summary
            wrapped_summary=$(echo "🐾 Session Scents: $session_tag_summary" | fmt -w 72)
            gum style --foreground 208 --italic --margin "0 2" "$wrapped_summary"
        fi
        
        echo ""
        gum style --foreground 255 --margin "0 2" "  $file_name"
        
        # Check for existing entry
        local existing_data
        existing_data=$(jq -c --arg path "$dir_path" --arg name "$file_name" \
            '.files[] | select(.path == $path and .name == $name) | {id: .unique_id, tags: .tags}' <<< "$DB_CACHE" | head -n 1)

        local is_existing=false
        local existing_id=""
        local existing_tags_json="[]"
        if [[ -n "$existing_data" ]]; then
            is_existing=true
            existing_id=$(echo "$existing_data" | jq -r '.id')
            existing_tags_json=$(echo "$existing_data" | jq -c '.tags')
            gum style --foreground 196 --bold --margin "0 2" "  ⚠️  This bone is already buried!"
            gum style --foreground 212 --margin "0 2" "  👃 Current scents: $(echo "$existing_tags_json" | jq -r 'join(", ")')"
        fi

        if [[ -n "$last_tags_string" ]]; then
            gum style --foreground 251 --italic --margin "0 2" "  (Last: $last_tags_string)"
        fi

        # Show preview for images/videos if in Kitty
        display_bone_preview "$current_file"
        
        echo ""
        gum style --foreground 250 "  Keys: 'v' (repeat) | 'vvv' (all) | 'undo' (back) | 'q' (save)"
        
        if [[ "$is_existing" == "true" ]]; then
            gum style --foreground 212 --italic "  (Press Enter to leave UNCHANGED and skip)"
        else
            gum style --foreground 212 --italic "  (Press Enter to submit scents)"
        fi
        
        local tags_input
        local placeholder="comma,separated,tags..."
        [[ "$is_existing" == "true" ]] && placeholder="[Enter] to skip or enter new scents..."

        tags_input=$(gum input --prompt "  👃 Scents: " --prompt.foreground 212 --placeholder "$placeholder" --placeholder.foreground 255 || true)
        
        # Handle keywords and empty input
        if [[ -z "$tags_input" ]]; then
            if [[ "$is_existing" == "true" ]]; then
                # Skip this file but pool its existing tags into the session summary
                local skip_entry
                skip_entry=$(jq -n \
                    --arg name "$file_name" \
                    --arg path "$dir_path" \
                    --argjson tags "$existing_tags_json" \
                    --argjson id "$existing_id" \
                    --argjson is_skip true \
                    '{name: $name, path: $path, tags: $tags, unique_id: $id, is_skip: $is_skip}')
                jq --argjson entry "$skip_entry" '. += [$entry]' "$buffered_json_file" > "$buffered_json_file.tmp"
                mv "$buffered_json_file.tmp" "$buffered_json_file"
                
                # Update last used tags so they can be copied to the next file
                last_tags_json="$existing_tags_json"
                last_tags_string=$(echo "$existing_tags_json" | jq -r 'join(" ")')
                
                i=$((i + 1))
                continue
            else
                echo "Scents cannot be empty. Use keywords if needed."
                sleep 1
                continue
            fi
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
                    # Remove the last entry from buffer if it matches the file we are undoing
                    local last_buffered_name
                    last_buffered_name=$(jq -r '.[-1].name' "$buffered_json_file" 2>/dev/null || echo "")
                    local last_buffered_path
                    last_buffered_path=$(jq -r '.[-1].path' "$buffered_json_file" 2>/dev/null || echo "")
                    local prev_file_name
                    prev_file_name=$(basename "${files[$i]}")
                    if [[ "$last_buffered_name" == "$prev_file_name" && "$last_buffered_path" == "$dir_path" ]]; then
                        jq 'del(.[-1])' "$buffered_json_file" > "$buffered_json_file.tmp"
                        mv "$buffered_json_file.tmp" "$buffered_json_file"
                    fi
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
                        local file_name
                        file_name=$(basename "$current_file")
                        local timestamp
                        timestamp=$(date +%s)
                        
                        # Check for existing entry
                        local existing_id
                        existing_id=$(jq -r --arg path "$dir_path" --arg name "$file_name" \
                            '.files[] | select(.path == $path and .name == $name) | .unique_id' <<< "$DB_CACHE" | head -n 1)

                        if [[ -n "$existing_id" && "$existing_id" != "null" ]]; then
                            # Buffer update instead of immediate update
                            local update_entry
                            update_entry=$(jq -n \
                                --arg name "$file_name" \
                                --arg path "$dir_path" \
                                --argjson tags "$last_tags_json" \
                                --argjson id "$existing_id" \
                                --argjson ts "$timestamp" \
                                --argjson is_update true \
                                '{name: $name, path: $path, tags: $tags, unique_id: $id, modified_timestamp: $ts, is_update: $is_update}')
                            jq --argjson entry "$update_entry" '. += [$entry]' "$buffered_json_file" > "$buffered_json_file.tmp"
                            mv "$buffered_json_file.tmp" "$buffered_json_file"
                        else
                            # Create new entry for buffer
                            local next_id
                            next_id=$(($(get_next_id) + i))
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
                        fi
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
        
        # Create/Update entry
        if [[ "$is_existing" == "true" ]]; then
            # Buffer update instead of immediate update
            local timestamp
            timestamp=$(date +%s)
            local update_entry
            update_entry=$(jq -n \
                --arg name "$file_name" \
                --arg path "$dir_path" \
                --argjson tags "$tags_json" \
                --argjson id "$existing_id" \
                --argjson ts "$timestamp" \
                --argjson is_update true \
                '{name: $name, path: $path, tags: $tags, unique_id: $id, modified_timestamp: $ts, is_update: $is_update}')
            jq --argjson entry "$update_entry" '. += [$entry]' "$buffered_json_file" > "$buffered_json_file.tmp"
            mv "$buffered_json_file.tmp" "$buffered_json_file"
        else
            # Add new entry to buffer
            local next_id
            next_id=$(($(get_next_id) + i)) # Approximate ID, will be recalculated on save
            local timestamp
            timestamp=$(date +%s)
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
        fi
        
        i=$((i + 1))
    done
    
    local total_buffered
    total_buffered=$(jq '. | length' "$buffered_json_file")
    if [[ $total_buffered -gt 0 ]]; then
        local new_count
        new_count=$(jq '[.[] | select(.is_update != true and .is_skip != true)] | length' "$buffered_json_file")
        local update_count
        update_count=$(jq '[.[] | select(.is_update == true)] | length' "$buffered_json_file")
        
        echo ""
        [[ $new_count -gt 0 ]] && echo "Burying $new_count NEW bones."
        [[ $update_count -gt 0 ]] && echo "Updating $update_count existing bones."
        
        if gum confirm "Save these changes to the BoneYARD?"; then
            # 1. Apply updates to existing files
            if [[ $update_count -gt 0 ]]; then
                while IFS= read -r update; do
                    local id
                    id=$(echo "$update" | jq -r '.unique_id')
                    local tags
                    tags=$(echo "$update" | jq -c '.tags')
                    local ts
                    ts=$(echo "$update" | jq -r '.modified_timestamp')
                    DB_CACHE=$(jq --argjson id "$id" --argjson tags "$tags" --argjson ts "$ts" \
                        '(.files[] | select(.unique_id == $id) | .tags) = $tags | 
                         (.files[] | select(.unique_id == $id) | .modified_timestamp) = $ts' \
                        <<< "$DB_CACHE")
                    SESSION_MODIFIED=true
                done < <(jq -c '.[] | select(.is_update == true)' "$buffered_json_file")
            fi

            # 2. Append new bones
            if [[ $new_count -gt 0 ]]; then
                # Assign real unique IDs now to avoid collisions
                local current_max_id
                current_max_id=$(jq '[.files[].unique_id] | max // 0' <<< "$DB_CACHE")
                
                # Map over buffered entries to assign correct IDs and remove temporary fields
                jq --argjson start_id "$current_max_id" \
                   '[.[] | select(.is_update != true and .is_skip != true)] | to_entries | map(.value | del(.is_update) | del(.is_skip) + {unique_id: ($start_id + .key + 1)})' \
                   "$buffered_json_file" > "$WORKING_DATABASE_FILE.tmp"
                
                # Append to memory cache
                DB_CACHE=$(jq --argjson new_files "$(cat "$WORKING_DATABASE_FILE.tmp")" \
                   '.files += $new_files' <<< "$DB_CACHE")
                SESSION_MODIFIED=true
            fi
            
            sync_db_to_disk
            update_dir_cache
            double_bark_sfx
            echo "✓ BoneYARD updated successfully."
        else
            echo "Changes discarded. Litter remains unburied."
        fi
    else
        echo "No bones were buried or modified."
    fi
    
    rm -f "$buffered_json_file"
    pause
    main_menu
}

# Update tags for an existing file
update_file_tags() {
    local file_id="${1:-}"
    if [[ -z "$file_id" ]]; then
        echo "Error: No bone ID provided for update."
        return 1
    fi
    
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "👃 Update Scents"
    
    # Get current tags
    local current_tags
    current_tags=$(jq -r --argjson id "$file_id" '.files[] | select(.unique_id == $id) | .tags | join(", ")' <<< "$DB_CACHE")
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
    DB_CACHE=$(jq --argjson id "$file_id" --argjson tags "$tags_json" --argjson ts "$timestamp" \
        '(.files[] | select(.unique_id == $id) | .tags) = $tags | 
         (.files[] | select(.unique_id == $id) | .modified_timestamp) = $ts' \
        <<< "$DB_CACHE")
    sync_db_to_disk
    SESSION_MODIFIED=true
    update_dir_cache
    
    echo ""
    echo "✓ Scents updated successfully"
}

# Mass update tags for multiple files
bulk_update_file_tags() {
    local results_json="$1"
    local count
    count=$(echo "$results_json" | jq -s 'length')

    echo ""
    gum style --foreground 212 --border double --padding "0 1" "🐕 Bulk Update Scents ($count Bones)"
    echo "Logic Keywords:"
    echo "  - 'KEEP' : Preserve original scents (e.g., KEEP,new_scent)"
    echo "  - 'NOT'  : Remove the next scent (e.g., KEEP,NOT,old_scent)"
    echo ""
    
    local logic_input
    logic_input=$(gum input --placeholder "Enter bulk scent logic (e.g., KEEP,tag1,NOT,tag2)" || true)
    
    if [[ -z "$logic_input" ]]; then
        echo "No input entered. Operation cancelled."
        return
    fi

    # Check for KEEP and warn if missing
    local has_keep=false
    IFS=',' read -ra check_tokens <<< "$logic_input"
    for token in "${check_tokens[@]}"; do
        local t=$(echo "$token" | xargs | tr '[:lower:]' '[:upper:]')
        if [[ "$t" == "KEEP" ]]; then
            has_keep=true
            break
        fi
    done

    if [[ "$has_keep" == "false" ]]; then
        echo ""
        gum style --foreground 196 --bold "⚠️  WARNING: 'KEEP' not found in logic."
        echo "This will OVERRIDE ALL existing scents for these $count bones."
        echo ""
        local warn_choice
        warn_choice=$(gum choose "Continue (Override All)" "Add 'KEEP' to Logic" "Cancel" || echo "Cancel")
        
        case "$warn_choice" in
            "Add 'KEEP' to Logic")
                logic_input="KEEP,$logic_input"
                ;;
            "Cancel")
                echo "Operation cancelled."
                return
                ;;
            *)
                # Continue (Override All)
                ;;
        esac
    fi

    echo "Sniffing out changes... This may take a moment for many bones."

    # Parse logic into arrays for faster processing
    local to_add=()
    local to_remove=()
    local keep_original=false
    
    IFS=',' read -ra tokens <<< "$logic_input"
    local i=0
    while [[ $i -lt ${#tokens[@]} ]]; do
        local token=$(echo "${tokens[$i]}" | xargs)
        local upper_token=$(echo "$token" | tr '[:lower:]' '[:upper:]')
        
        if [[ "$upper_token" == "KEEP" ]]; then
            keep_original=true
        elif [[ "$upper_token" == "NOT" ]]; then
            i=$((i + 1))
            if [[ $i -lt ${#tokens[@]} ]]; then
                to_remove+=($(echo "${tokens[$i]}" | xargs))
            fi
        elif [[ -n "$token" ]]; then
            to_add+=("$token")
        fi
        i=$((i + 1))
    done

    # Prepare jq arguments
    local add_json='[]'
    for tag in "${to_add[@]}"; do add_json=$(jq -c --arg tag "$tag" '. += [$tag]' <<< "$add_json"); done
    local rem_json='[]'
    for tag in "${to_remove[@]}"; do rem_json=$(jq -c --arg tag "$tag" '. += [$tag]' <<< "$rem_json"); done

    local timestamp
    timestamp=$(date +%s)
    
    # Process each file
    local updated_count=0
    while read -r file_obj; do
        local file_id=$(echo "$file_obj" | jq -r '.unique_id')
        
        # Process in JQ for robustness and case-insensitivity
        DB_CACHE=$(jq --argjson id "$file_id" \
                      --argjson add "$add_json" \
                      --argjson rem "$rem_json" \
                      --argjson keep "$keep_original" \
                      --argjson ts "$timestamp" '
            (.files[] | select(.unique_id == $id)) |= (
                .tags as $orig |
                (if $keep then $orig else [] end) as $base |
                (($base + $add) | unique) as $added |
                ($rem | map(ascii_downcase)) as $rem_low |
                ($added | map(select(. as $t | ($rem_low | index($t | ascii_downcase) | not)))) as $final |
                .tags = $final | .modified_timestamp = $ts
            )' <<< "$DB_CACHE")
        
        updated_count=$((updated_count + 1))
    done < <(echo "$results_json" | jq -c '.[]')

    sync_db_to_disk
    SESSION_MODIFIED=true
    update_dir_cache
    double_bark_sfx
    
    echo ""
    echo "✓ Successfully updated $updated_count bones in the yard!"
}

# Edit tags for an existing file
edit_tags() {
    play_menu_sound
    echo ""
    local edit_choice
    edit_choice=$(gum choose --header "👃 Update Scents" \
        "🏷️ Find By Scent" \
        "🐾 Fuzzy Scent Match" \
        "📝 Find By Bone Name" \
        "📅 Find By Date Range" \
        "📁 Filter By Kennel (Directory)" \
        "📋 List All Bones" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$edit_choice" || "$edit_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $edit_choice in
        "🏷️ Find By Scent") edit_by_tag;;
        "🐾 Fuzzy Scent Match") edit_by_fuzzy_tag;;
        "📝 Find By Bone Name") edit_by_name;;
        "📅 Find By Date Range") edit_by_date_range;;
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
        update_file_tags "$file_id"
    else
        play_menu_sound
        local selection
        # Safer: Pipe the choices into gum instead of passing them as arguments
        selection=$( {
            echo "🐕 Bulk Edit Scents (All $count Bones)"
            echo "───────────────────────────────────────"
            echo "$results_json" | jq -r --arg count "$count" '
                .unique_id as $id |
                (.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) as $padded_id |
                "\($padded_id): \(.name) (\(.path)) [\(.tags | join(", "))]"
            '
        } | gum choose --header "🔍 Found $count bones. Choose an action:" || true)
        
        if [[ -z "$selection" || "$selection" == "──"* ]]; then
            return 1
        fi
        
        if [[ "$selection" == "🐕 Bulk Edit Scents"* ]]; then
            bulk_update_file_tags "$results_json"
        else
            # Ensure we only extract the numeric ID and strip padding
            file_id=$(echo "$selection" | cut -d':' -f1 | sed 's/^0*//')
            [[ -z "$file_id" ]] && file_id=0
            update_file_tags "$file_id"
        fi
    fi
    
    pause
}

# Edit by tag
edit_by_tag() {
    local dir_filter="${1:-}"
    local search_tag="${2:-}"
    echo ""
    
    if [[ -z "$search_tag" ]]; then
        search_tag=$(gum input --placeholder "Enter scents to find for updating (supports AND, OR, NOT)" || true)
    fi
    
    if [[ -z "$search_tag" ]]; then
        if [[ -n "$dir_filter" ]]; then
            edit_directory_menu "$dir_filter"
        else
            edit_tags
        fi
        return
    fi
    
    local jq_filter
    jq_filter=$(build_tag_query_filter "$search_tag")
    
    local matches
    matches=$(jq -c --arg dir "$dir_filter" \
        ".files[] | select((\$dir == \"\" or .path == \$dir) and ($jq_filter))" \
        <<< "$DB_CACHE")
    
    select_and_update_file "$matches" || true
    
    if [[ -n "$dir_filter" ]]; then
        edit_directory_menu "$dir_filter"
    else
        edit_tags
    fi
}

# Edit by fuzzy tag
edit_by_fuzzy_tag() {
    local dir_filter="${1:-}"
    echo ""
    
    # Get all tags
    local all_tags
    all_tags=$(get_all_tags)
    
    if [[ -z "$all_tags" ]]; then
        echo "No scents found in the yard."
        pause
        if [[ -n "$dir_filter" ]]; then
            edit_directory_menu "$dir_filter"
        else
            edit_tags
        fi
        return
    fi
    
    local selected_tag
    selected_tag=$(echo "$all_tags" | gum filter --placeholder "Fuzzy find a scent to update..." --indicator "🦴" --match.foreground 212 || true)
    
    if [[ -z "$selected_tag" ]]; then
        if [[ -n "$dir_filter" ]]; then
            edit_directory_menu "$dir_filter"
        else
            edit_tags
        fi
        return
    fi
    
    # Call edit_by_tag with the selected tag
    edit_by_tag "$dir_filter" "$selected_tag"
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
        <<< "$DB_CACHE")
    
    select_and_update_file "$matches" || true
    
    if [[ -n "$dir_filter" ]]; then
        edit_directory_menu "$dir_filter"
    else
        edit_tags
    fi
}

# Edit by date range
edit_by_date_range() {
    local dir_filter="${1:-}"
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "📅 Find By Date Range For Updating"
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
            pause
            edit_tags
            return
        fi
    fi
    
    if [[ -n "$end_date" ]]; then
        end_ts=$(date -d "$end_date 23:59:59" +%s 2>/dev/null || echo "error")
        if [[ "$end_ts" == "error" ]]; then
            echo "Error: Invalid end date format."
            pause
            edit_tags
            return
        fi
    fi
    
    local matches
    matches=$(jq -c --argjson start "$start_ts" --argjson end "$end_ts" --arg dir "$dir_filter" \
        '.files[] | select(($dir == "" or .path == $dir) and (.modified_timestamp >= $start and .modified_timestamp <= $end))' \
        <<< "$DB_CACHE")
    
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
    matches=$(jq -c --arg dir "$dir_filter" '.files[] | select($dir == "" or .path == $dir)' <<< "$DB_CACHE")
    
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
        "🐾 Fuzzy Scent Match" \
        "📝 Find By Filename" \
        "📅 Find By Date Range" \
        "📋 List All Files" \
        "❌ Remove Directory Filter" || true)
    
    if [[ -z "$choice" || "$choice" == "❌ Remove Directory Filter" ]]; then
        edit_tags
        return
    fi
    
    case $choice in
        "🏷️ Find By Tag") edit_by_tag "$selected_dir";;
        "🐾 Fuzzy Scent Match") edit_by_fuzzy_tag "$selected_dir";;
        "📝 Find By Filename") edit_by_name "$selected_dir";;
        "📅 Find By Date Range") edit_by_date_range "$selected_dir";;
        "📋 List All Files") edit_list_all_files "$selected_dir";;
    esac
}
