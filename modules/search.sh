# Search and listing flows.

# Search for files by tag
search_file() {
    play_menu_sound
    echo ""
    local search_choice
    search_choice=$(gum choose --header "🎾 Fetch Bones" \
        "🏷️ Search By Scent" \
        "🐾 Fuzzy Scent Match" \
        "📝 Search By Bone Name" \
        "📅 Search By Date Range" \
        "📁 Filter By Kennel (Directory)" \
        "📋 List All Bones" \
        "⬅️ Back To Main Menu" || true)
    
    if [[ -z "$search_choice" || "$search_choice" == "⬅️ Back To Main Menu" ]]; then
        main_menu
        return
    fi
    
    case $search_choice in
        "🏷️ Search By Scent") search_by_tag;;
        "🐾 Fuzzy Scent Match") search_by_fuzzy_tag;;
        "📝 Search By Bone Name") search_by_name;;
        "📅 Search By Date Range") search_by_date_range;;
        "📁 Filter By Kennel (Directory)") filter_by_directory;;
        "📋 List All Bones") list_all_files;;
    esac
}

# Search files by tag
search_by_tag() {
    local dir_filter="${1:-}"
    local search_tag="${2:-}"
    echo ""
    
    if [[ -z "$search_tag" ]]; then
        search_tag=$(gum input --placeholder "Enter scents to fetch (supports AND, OR, NOT, e.g. bash AND script)" || true)
    fi
    
    if [[ -z "$search_tag" ]]; then
        if [[ -n "$dir_filter" ]]; then
            directory_search_menu "$dir_filter"
        else
            search_file
        fi
        return
    fi
    
    local jq_filter
    jq_filter=$(build_tag_query_filter "$search_tag")
    
    echo ""
    if [[ -n "$dir_filter" ]]; then
        gum style --foreground 212 "🎾 Fetch Results In: $dir_filter"
    else
        gum style --foreground 212 "🎾 Fetch Results"
    fi
    
    local results
    results=$(jq -r --arg dir "$dir_filter" --arg q "$search_tag" \
        ". as \$root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
         select((\$dir == \"\" or .path == \$dir) and ($jq_filter)) | 
         \"[\((.modified_timestamp + (\$root[\"timezone-offset\"] // 0)) | strftime(\"%Y-%m-%d %H:%M\"))] ID: \(.unique_id | tostring | if length < 4 then (4 - length) * \"0\" + . else . end) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(\", \"))\"" \
        <<< "$DB_CACHE")
    
    if [[ -z "$results" ]]; then
        echo "No bones found with scents matching: $search_tag"
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

# Fuzzy search files by tag
search_by_fuzzy_tag() {
    local dir_filter="${1:-}"
    echo ""
    
    # Get all tags
    local all_tags
    all_tags=$(get_all_tags)
    
    if [[ -z "$all_tags" ]]; then
        echo "No scents found in the yard."
        pause
        if [[ -n "$dir_filter" ]]; then
            directory_search_menu "$dir_filter"
        else
            search_file
        fi
        return
    fi
    
    local selected_tag
    selected_tag=$(echo "$all_tags" | gum filter --placeholder "Fuzzy find a scent..." --indicator "🦴" --match.foreground 212 || true)
    
    if [[ -z "$selected_tag" ]]; then
        if [[ -n "$dir_filter" ]]; then
            directory_search_menu "$dir_filter"
        else
            search_file
        fi
        return
    fi
    
    # Call search_by_tag with the selected tag
    search_by_tag "$dir_filter" "$selected_tag"
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
         "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
        <<< "$DB_CACHE")
    
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

# Search files by date range
search_by_date_range() {
    local dir_filter="${1:-}"
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "📅 Search By Date Range"
    echo "Enter dates in YYYY-MM-DD format (or leave blank for all)."
    
    local start_date
    start_date=$(gum input --placeholder "From (YYYY-MM-DD)" || true)
    
    local end_date
    end_date=$(gum input --placeholder "To (YYYY-MM-DD)" || true)
    [[ "$end_date" == "-" ]] && end_date="$start_date"
    
    local start_ts=0
    local end_ts=2147483647 # Far in the future
    
    if [[ -n "$start_date" ]]; then
        start_ts=$(date -d "$start_date" +%s 2>/dev/null || echo "error")
        if [[ "$start_ts" == "error" ]]; then
            echo "Error: Invalid start date format."
            pause
            search_file
            return
        fi
    fi
    
    if [[ -n "$end_date" ]]; then
        # For the end date, we want the end of the day (23:59:59)
        end_ts=$(date -d "$end_date 23:59:59" +%s 2>/dev/null || echo "error")
        if [[ "$end_ts" == "error" ]]; then
            echo "Error: Invalid end date format."
            pause
            search_file
            return
        fi
    fi
    
    echo ""
    if [[ -n "$dir_filter" ]]; then
        gum style --foreground 212 "🎾 Fetch Results In: $dir_filter"
    else
        gum style --foreground 212 "🎾 Fetch Results"
    fi
    
    local results
    results=$(jq -r --argjson start "$start_ts" --argjson end "$end_ts" --arg dir "$dir_filter" \
        '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
         select(($dir == "" or .path == $dir) and (.modified_timestamp >= $start and .modified_timestamp <= $end)) | 
         "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
        <<< "$DB_CACHE")
    
    if [[ -z "$results" ]]; then
        echo "No bones found in that date range."
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
    total_files=$(jq --arg dir "$dir_filter" '[.files[] | select($dir == "" or .path == $dir)] | length' <<< "$DB_CACHE")
    
    if [[ "$total_files" -eq 0 ]]; then
        echo "No bones found."
    else
        jq -r --arg dir "$dir_filter" '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
            select($dir == "" or .path == $dir) | 
            "[\((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M"))] ID: \(.unique_id | tostring | if length < 4 then (4 - length) * "0" + . else . end) | \(.name) | Kennel: \(.path) | Scents: \(.tags | join(", "))"' \
            <<< "$DB_CACHE"
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
        "🐾 Fuzzy Scent Match" \
        "📝 Search By Filename" \
        "📅 Search By Date Range" \
        "📋 List All Files" \
        "❌ Remove Directory Filter" || true)
    
    if [[ -z "$choice" || "$choice" == "❌ Remove Directory Filter" ]]; then
        search_file
        return
    fi
    
    case $choice in
        "🏷️ Search By Tag") search_by_tag "$selected_dir";;
        "🐾 Fuzzy Scent Match") search_by_fuzzy_tag "$selected_dir";;
        "📝 Search By Filename") search_by_name "$selected_dir";;
        "📅 Search By Date Range") search_by_date_range "$selected_dir";;
        "📋 List All Files") list_all_files "$selected_dir";;
    esac
}
