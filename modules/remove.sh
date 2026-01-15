# Clean up and delete flows.

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
        "📅 Remove By Date Range" \
        "📁 Remove By Kennel (Directory)" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$remove_choice" || "$remove_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $remove_choice in
        "🆔 Remove By ID") remove_by_id;;
        "📝 Remove By Bone Name") remove_by_name;;
        "📅 Remove By Date Range") remove_by_date_range;;
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
    file_count=$(jq --arg dir "$selected_dir" '[.files[] | select(.path == $dir)] | length' <<< "$DB_CACHE")
    
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
        jq -r --arg dir "$selected_dir" '.files[] | select(.path == $dir) | "  - \(.name)"' <<< "$DB_CACHE"
        echo ""
    fi

    if gum confirm "Dig up ALL $file_count bones for this kennel from the BoneYARD?"; then
        DB_CACHE=$(jq --arg dir "$selected_dir" 'del(.files[] | select(.path == $dir))' \
            <<< "$DB_CACHE")
        sync_db_to_disk
        SESSION_MODIFIED=true
        update_dir_cache
        echo "✓ Successfully dug up $file_count bones."
    else
        echo "Clean up cancelled."
    fi
    
    echo ""
    pause
    main_menu
}

# Remove entries by date range
remove_by_date_range() {
    play_menu_sound
    echo ""
    gum style --foreground 196 --border double --padding "0 1" "📅 Remove By Date Range"
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
            pause; remove_file; return
        fi
    fi
    if [[ -n "$end_date" ]]; then
        end_ts=$(date -d "$end_date 23:59:59" +%s 2>/dev/null || echo "error")
        if [[ "$end_ts" == "error" ]]; then
            echo "Error: Invalid end date format."
            pause; remove_file; return
        fi
    fi
    
    local file_count
    file_count=$(jq --argjson start "$start_ts" --argjson end "$end_ts" '[.files[] | select(.modified_timestamp >= $start and .modified_timestamp <= $end)] | length' <<< "$DB_CACHE")
    
    if [[ "$file_count" -eq 0 ]]; then
        echo "No bones found in that date range."
        pause
        remove_file
        return
    fi
    
    echo ""
    echo "Found $file_count bones in the selected date range."
    
    if [[ "$file_count" -lt 10 ]]; then
        echo "Bones to be dug up:"
        jq -r --argjson start "$start_ts" --argjson end "$end_ts" '.files[] | select(.modified_timestamp >= $start and .modified_timestamp <= $end) | "  - \(.name)"' <<< "$DB_CACHE"
        echo ""
    fi

    if gum confirm "Dig up ALL $file_count bones in this date range from the BoneYARD?"; then
        DB_CACHE=$(jq --argjson start "$start_ts" --argjson end "$end_ts" 'del(.files[] | select(.modified_timestamp >= $start and .modified_timestamp <= $end))' \
            <<< "$DB_CACHE")
        sync_db_to_disk
        SESSION_MODIFIED=true
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
    file_exists=$(jq --argjson id "$file_id" '.files[] | select(.unique_id == $id)' <<< "$DB_CACHE")
    
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
        <<< "$DB_CACHE"
    
    if gum confirm "Dig up this bone from BoneYARD?"; then
        DB_CACHE=$(jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
            <<< "$DB_CACHE")
        sync_db_to_disk
        SESSION_MODIFIED=true
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
        <<< "$DB_CACHE")
    
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
        echo "$matches" | jq -r '"  ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | Name: \(.name) | Kennel: \(.path)"'
        
        echo ""
        if gum confirm "Dig up this bone from BoneYARD?"; then
            DB_CACHE=$(jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
                <<< "$DB_CACHE")
            sync_db_to_disk
            SESSION_MODIFIED=true
            echo "✓ Bone dug up successfully"
        else
            echo "Clean up cancelled"
        fi
    else
        # Multiple matches found
        echo ""
        gum style --foreground 212 "👯 Multiple Matches Found For '$search_name':"
        echo "$matches" | jq -r '"  ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | Name: \(.name) | Kennel: \(.path)"'
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
                    DB_CACHE=$(jq --argjson id "$file_id" 'del(.files[] | select(.unique_id == $id))' \
                        <<< "$DB_CACHE")
                    sync_db_to_disk
                    SESSION_MODIFIED=true
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
    local captured_minute
    captured_minute=$(date +%M)
    user_line1=$(gum input --placeholder "Type Line 1 here" || true)
    [[ -n "$user_line1" ]] && typewrite "$user_line1" 0.015
    
    local bypass_active=false
    local bypass_word3
    bypass_word3=$(echo "${words[0]:0:1}${words[4]:0:1}${words[8]:0:1}" | tr '[:upper:]' '[:lower:]')
    
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
    current_offset=$(jq -r '."timezone-offset" // -18000' <<< "$DB_CACHE" || echo "-18000")
    
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
    
    if [[ "$DOGGY_BAG_MODE" == "true" ]]; then
        typewrite "Changes are held in your doggy bag. Bury them upon exit to make it permanent."
        pause
        main_menu
        return
    fi

    typewrite "Restarting script with original arguments..."
    sleep 1.5
    exec "$0" "$@"
}
