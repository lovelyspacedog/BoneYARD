# Main menu and app entry.

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

    if [[ "${BONEYARD_STANDALONE:-false}" == "true" ]]; then
        REMOTE_VERSION=""
    fi

    local update_badge=""
    local res=0
    if [[ -n "$REMOTE_VERSION" ]]; then
        version_compare "$SOFTWARE_VERSION" "$REMOTE_VERSION" || res=$?
        if [[ $res -eq 2 ]]; then
            update_badge=" [🚀 UPDATE AVAILABLE: $REMOTE_VERSION]"
        fi
    fi

    local db_label="$DATABASE_FILE"
    [[ "$DOGGY_BAG_MODE" == "true" ]] && db_label="$DATABASE_FILE [👜 DOGGY BAG ACTIVE]"

    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 70 --margin "1 2" --padding "1 2" \
        "BoneYARD $SOFTWARE_VERSION$update_badge" "Yappy Archive and Retrieval Database" \
        "Database: $db_label"

    local choice_list=()
    [[ -n "$update_badge" ]] && choice_list+=("🚀 Rebuild Doghouse (New Update Available!)")
    [[ "$DOGGY_BAG_MODE" == "false" && "$SESSION_MODIFIED" == "false" ]] && choice_list+=("👜 Use a Doggy Bag (Save on Exit)")
    choice_list+=(
        "🎾 Fetch Bones (Search)"
        "🦴 Bury New Bone"
        "🐕 Bury Entire Litter"
        "👃 Update Scents (Edit)"
        "🦴 Organize Bones (Batch)"
        "🧹 Clean Up the Yard (Remove)"
        "🏘️ Switch Yard"
        "🐾 Cache Bones (Snapshots)"
        "📤 Export Yard (CSV/HTML)"
        "📊 Pack Stats"
        "📜 Kennel Rules & Changelog"
        "🌋 Incinerate the Yard"
        "🚪 Kennel Sleep (Exit)"
    )

    local choice
    choice=$(printf "%s\n" "${choice_list[@]}" | gum choose --height 15 || true)
    
    if [[ -z "$choice" ]]; then
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
                gum style --foreground 212 --border double --padding "1 2" "🐾 Empty the Doggy Bag?"
                echo "You have changes in your doggy bag. Would you like to bury them in the yard?"
                if gum confirm "Empty the doggy bag into the yard?"; then
                    cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE"
                    typewrite "✓ Doggy bag emptied! Changes buried in the yard."
                else
                    typewrite "Abandoning the scent... Changes discarded."
                fi
            fi
        fi
        double_bark_sfx
        rm -f "/tmp/boneyard_remote_version"
        typewrite "$(printf "%s\n" "${goodbye_text[@]}" | shuf -n 1)"
        exit 0
    fi

    case $choice in
        "🚀 Rebuild Doghouse (New Update Available!)") 
            perform_update "$REMOTE_VERSION"
            main_menu
            ;;
        "👜 Use a Doggy Bag (Save on Exit)")
            # Relaunch with -b added
            release_db_lock
            exec "$0" "-b" "$@"
            ;;
        "🎾 Fetch Bones (Search)") search_file;;
        "🦴 Bury New Bone") add_file;;
        "🐕 Bury Entire Litter") tag_entire_directory;;
        "👃 Update Scents (Edit)") edit_tags;;
        "🦴 Organize Bones (Batch)") organize_bones;;
        "🧹 Clean Up the Yard (Remove)") remove_file;;
        "🏘️ Switch Yard") switch_yard "$@";;
        "🐾 Cache Bones (Snapshots)") manage_backups;;
        "📤 Export Yard (CSV/HTML)") export_database;;
        "📊 Pack Stats") show_stats;;
        "📜 Kennel Rules & Changelog") read_license;;
        "🌋 Incinerate the Yard") delete_entire_database;;
        "🚪 Kennel Sleep (Exit)") 
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
                    gum style --foreground 212 --border double --padding "1 2" "🐾 Empty the Doggy Bag?"
                    echo "You have changes in your doggy bag. Would you like to bury them in the yard?"
                    if gum confirm "Empty the doggy bag into the yard?"; then
                        cp "$WORKING_DATABASE_FILE" "$DATABASE_FILE"
                        typewrite "✓ Doggy bag emptied! Changes buried in the yard."
                    else
                        typewrite "Abandoning the scent... Changes discarded."
                    fi
                fi
            fi
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
    
    # Acquire lock on the yard to prevent concurrent access
    acquire_db_lock "$DATABASE_FILE"
    # Ensure lock is released on exit
    trap 'release_db_lock' EXIT

    # Cleanup stale update info and check for updates
    rm -f "/tmp/boneyard_remote_version"
    if [[ "${BONEYARD_STANDALONE:-false}" != "true" ]]; then
        grab_remote_version
    fi
    
    if [[ "$DOGGY_BAG_MODE" == "true" ]]; then
        WORKING_DATABASE_FILE=$(mktemp /tmp/boneyard_doggy_bag_XXXXXX.json)
        if [[ -f "$DATABASE_FILE" ]]; then
            cp "$DATABASE_FILE" "$WORKING_DATABASE_FILE"
        fi
        # Ensure cleanup on exit (adding to existing trap)
        trap 'rm -f "$WORKING_DATABASE_FILE"; release_db_lock' EXIT
    fi
    
    load_db_to_memory
    check_database_health
    check_compatibility
    init_database
    update_dir_cache
    check_auto_snapshot
    double_bark_sfx
    main_menu --no-sound
}
