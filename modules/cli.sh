# CLI parsing and dependency checks.

show_help() {
    cat <<EOF
🐾 BoneYARD v$SOFTWARE_VERSION (Yappy Archive and Retrieval Database)
A powerful, interactive TUI system for burying and fetching bones using JSON.

USAGE:
  $(basename "$0") [options]

OPTIONS:
  -d, --database FILE        Specify a custom BoneYARD JSON file.
                             Defaults to: $SCRIPT_DIR/boneyard.json

  -b, --doggy-bag            Enable "Doggy Bag" mode. No changes are written to
                             the main database until you exit the TUI.

  -t, --tags FILE            Output comma-delimited scents for a specific bone.
                             Accepts full path or just a bone name.
                             Supports boolean operators (AND, OR, NOT).
                             Exit codes: 0=found, 1=not found, N=match count.

  --with-dir [use SEP]       When used with --tags, appends kennel components
                             and the bone name to the output scents.
                             Optionally use 'use SEP' to set a custom separator
                             (e.g., --with-dir use ":") between the kennel branch
                             and the scents. (Default: comma).

  --contains                 When used with --tags, enables case-insensitive
                             "contains" searching instead of exact matching.

  --pager PAGER              Force a specific pager (nvim, nano, less) for the rules.
                             Use 'safe' for the built-in 5-line-at-a-time viewer.

  --generate-standalone [FILE]
                             Build a single-file BoneYARD script with all modules
                             embedded. Defaults to: $SCRIPT_DIR/BoneYARD-standalone.sh
                             Updates are disabled in the generated file.

  -h, -?, --help             Show this comprehensive help message.

MAIN FEATURES:
  🎾 Fetch Bones             Filter by scent, bone name, kennel, or date range.
                             Scent search supports AND, OR, NOT (e.g., bash AND script).

  🦴 Bury New Bone           Pick a file using ranger and assign searchable scents.

  🐕 Bury Entire Litter      Batch-bury an entire kennel with interactive
                             copy/undo/skip/all functionality.

  👃 Update Scents           Quickly update scents for any bone in the yard.

  🦴 Organize Bones          Batch-move/rename bones based on scent frequency.

  🧹 Clean Up the Yard       Remove specific bones, entire kennels, or date ranges
                             from your database.

  🏘️ Switch Yard             Open a different JSON database file (bones are not moved).

  🐾 Cache Bones             Snapshot suite: bury, fetch, paw through, or clean up.
                             Includes Auto-Snapshot protection.

  📤 Export Yard             Export the yard to a CSV or HTML file for external use.

  👜 Doggy Bag Mode          Run a non-persistent session with save-on-exit safety.

  📊 Show Pack Stats         View scent frequency, kennel counts, and recent activity.

  🚀 Rebuild Doghouse        Install the latest version from GitHub (Update Available!).

  🌋 Incinerate Yard         Permanently wipe the yard with high-security
                             phrase confirmation and fuzzy-match recovery.

  📜 Kennel Rules            View the license and project history (Changelog).

BONE PREVIEWS:
  Users in the Kitty terminal will see automatic previews of images and videos
  (via thumbnails) during the tagging process.

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

  # Generate a standalone script with embedded modules
  $(basename "$0") --generate-standalone

ENVIRONMENT:
  Requires: jq, ranger, gum, shuf, file, curl, git
  Optional: play (from sox) for menu audio feedback.

Copyright (c) 2025$([[ $(date +%Y) != "2025" ]] && echo "-$(date +%Y)") Pup Tony under GPLv3.
EOF
}

# Output tags for a specific file and exit
get_tags_for_file() {
    local target="$1"
    local matches

    load_db_to_memory

    if ! jq -e '.' <<< "$DB_CACHE" &>/dev/null; then
        echo "Error: BoneYARD database is corrupted or not valid JSON: $DATABASE_FILE" >&2
        exit 1
    fi

    if [[ "$target" == *"/"* ]]; then
        # It's a path
        local full_path
        full_path=$(realpath "$target" 2>/dev/null || echo "$target")
        local name
        name=$(basename "$full_path")
        local path
        path=$(dirname "$full_path")
        
        if [[ "$CONTAINS_SEARCH" == "true" ]]; then
            matches=$(jq -c --arg name "$name" --arg path "$path" \
                '.files[] | select((.name | ascii_downcase | contains($name | ascii_downcase)) and (.path | ascii_downcase | contains($path | ascii_downcase)))' \
                <<< "$DB_CACHE")
        else
            matches=$(jq -c --arg name "$name" --arg path "$path" \
                '.files[] | select(.name == $name and .path == $path)' <<< "$DB_CACHE")
        fi
    else
        # It's just a bone name
        if [[ "$CONTAINS_SEARCH" == "true" ]]; then
            matches=$(jq -c --arg name "$target" \
                '.files[] | select(.name | ascii_downcase | contains($name | ascii_downcase))' <<< "$DB_CACHE")
        else
            matches=$(jq -c --arg name "$target" \
                '.files[] | select(.name == $name)' <<< "$DB_CACHE")
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

# Reconstruct CLI arguments from current state
reconstruct_cli_args() {
    RECONSTRUCTED_ARGS=()
    
    # 1. Database (If not default)
    if [[ "$DATABASE_FILE" != "$SCRIPT_DIR/boneyard.json" ]]; then
        RECONSTRUCTED_ARGS+=("--database" "$DATABASE_FILE")
    fi
    
    # 2. Doggy Bag Mode
    if [[ "$DOGGY_BAG_MODE" == "true" ]]; then
        RECONSTRUCTED_ARGS+=("--doggy-bag")
    fi
    
    # 3. With Dir
    if [[ "$WITH_DIR" == "true" ]]; then
        RECONSTRUCTED_ARGS+=("--with-dir")
        if [[ "$WITH_DIR_SEP" != "," ]]; then
            RECONSTRUCTED_ARGS+=("use" "$WITH_DIR_SEP")
        fi
    fi
    
    # 4. Contains Search
    if [[ "$CONTAINS_SEARCH" == "true" ]]; then
        RECONSTRUCTED_ARGS+=("--contains")
    fi
    
    # 5. Pager
    if [[ -n "$FORCED_PAGER" ]]; then
        RECONSTRUCTED_ARGS+=("--pager" "$FORCED_PAGER")
    fi
}

parse_arguments() {
    local tag_query_file=""
    local standalone_output=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--database)
                if [[ -n "${2:-}" ]]; then
                    DATABASE_FILE=$(realpath "$2")
                    WORKING_DATABASE_FILE="$DATABASE_FILE"
                    shift 2
                else
                    echo "Error: --database requires a file path argument."
                    exit 1
                fi
                ;;
            -b|--doggy-bag)
                DOGGY_BAG_MODE=true
                shift
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
            --generate-standalone)
                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    standalone_output="$2"
                    shift 2
                else
                    standalone_output="$SCRIPT_DIR/BoneYARD-standalone.sh"
                    shift
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

    if [[ -n "$standalone_output" ]]; then
        if [[ "${BONEYARD_STANDALONE:-false}" == "true" ]]; then
            echo "This file is already standalone. Use the modular project to generate updates."
            exit 1
        fi
        generate_standalone "$standalone_output"
        exit 0
    fi

    # Execute Tag Query if requested
    if [[ -n "$tag_query_file" ]]; then
        if [[ ! -f "$WORKING_DATABASE_FILE" ]]; then
            echo "Error: Database file not found: $DATABASE_FILE" >&2
            exit 1
        fi
        get_tags_for_file "$tag_query_file"
    fi

    # Validate Database File Path for TUI mode
    if [[ ! -f "$WORKING_DATABASE_FILE" ]]; then
        local db_dir
        db_dir=$(dirname "$WORKING_DATABASE_FILE")
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
