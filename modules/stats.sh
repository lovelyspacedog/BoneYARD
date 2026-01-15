# Statistics display.

# Display statistics
show_stats() {
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "📊 BoneYARD Statistics"
    
    echo "🏘️ Loaded BoneYARD: $DATABASE_FILE"
    
    local total_files
    total_files=$(jq '.files | length' <<< "$DB_CACHE")
    
    local total_tags
    total_tags=$(jq '[.files[].tags[]] | unique | length' <<< "$DB_CACHE")
    
    echo "🦴 Total Bones: $total_files"
    echo "👃 Unique Scents: $total_tags"
    
    local total_dirs
    total_dirs=$(jq '[.files[].path] | unique | length' <<< "$DB_CACHE")
    echo "🏘️ Unique Kennels: $total_dirs"

    if [[ "$total_files" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "🕒 Recent Sniffs (Last 5 Buried):"
        jq -r '. as $root | .files | sort_by(.modified_timestamp) | reverse | .[0:5] | .[] | 
            "  - \(.name) (Buried: \((.modified_timestamp + ($root["timezone-offset"] // 0)) | strftime("%Y-%m-%d %H:%M")))"' \
            <<< "$DB_CACHE"
    fi

    if [[ "$total_dirs" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "🏘️ Bones Per Kennel:"
        jq -r '.files[].path' <<< "$DB_CACHE" | sort | uniq -c | sort -rn | \
            while read -r count path; do
                printf "  - %-30s : %s bones\n" "$path" "$count"
            done
    fi
    
    if [[ "$total_tags" -gt 0 ]]; then
        echo ""
        gum style --foreground 212 "👃 Scent Frequency (Strongest First):"
        jq -r '.files[].tags[]' <<< "$DB_CACHE" | sort | uniq -c | sort -rn | \
            while read -r count tag; do
                printf "  - %-15s : %s sniffs\n" "$tag" "$count"
            done
    fi
    
    echo ""
    pause
    main_menu
}
