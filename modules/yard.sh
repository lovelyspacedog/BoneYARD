# Yard switching.

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
    if ! jq -e '.' "$new_db" &>/dev/null; then
        echo "Error: Selected file is not a valid JSON BoneYARD."
        pause
        main_menu
        return
    fi

    echo ""
    typewrite "Switching to: $new_db"
    
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
            gum style --foreground 212 --border double --padding "1 2" "🐾 Empty the Doggy Bag before moving?"
            echo "You have changes in your doggy bag. Would you like to bury them in the current yard before moving to the next?"
            if gum confirm "Empty the doggy bag into the yard?"; then
                cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE"
                typewrite "✓ Doggy bag emptied! Changes buried in the yard."
            else
                typewrite "Abandoning the scent... Changes discarded."
            fi
        fi
    fi

    typewrite "The pack is moving to a new yard! (No bones will be transferred.)"
    sleep 1.5

    # Reconstruct arguments to preserve state (flags)
    reconstruct_cli_args
    
    # Release old lock before exec
    release_db_lock
    # Append new database argument (overrides any existing one in RECONSTRUCTED_ARGS)
    exec "$0" "${RECONSTRUCTED_ARGS[@]}" "--database" "$new_db"
}
