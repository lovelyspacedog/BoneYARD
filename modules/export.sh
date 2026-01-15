# Export flows.

# Export the database to CSV or HTML
export_database() {
    play_menu_sound
    echo ""
    gum style --foreground 212 --border double --padding "0 1" "📤 Export BoneYARD"
    
    local format
    format=$(gum choose "📄 CSV (Spreadsheet)" "🌐 HTML (Web Page)" "⬅️ Back To Main Menu" || echo "⬅️ Back To Main Menu")
    
    [[ "$format" == "⬅️ Back To Main Menu" ]] && { main_menu; return; }
    
    local default_ext="csv"
    [[ "$format" == *"HTML"* ]] && default_ext="html"
    
    local default_name="boneyard_export_$(date +%Y%m%d_%H%M%S).$default_ext"
    local export_path
    export_path=$(gum input --placeholder "Enter destination path (e.g., ~/Documents/$default_name)" --value "$HOME/Documents/$default_name" || true)
    
    [[ -z "$export_path" ]] && { export_database; return; }
    
    # Expand tilde
    export_path="${export_path/#\~/$HOME}"
    
    # Ensure directory exists
    local export_dir
    export_dir=$(dirname "$export_path")
    if [[ ! -d "$export_dir" ]]; then
        if gum confirm "Directory $export_dir does not exist. Create it?"; then
            mkdir -p "$export_dir"
        else
            echo "Export cancelled."
            pause
            export_database
            return
        fi
    fi
    
    if [[ "$format" == *"CSV"* ]]; then
        # Export CSV
        if jq -r '.files[] | [.unique_id, .name, .path, (.tags | join(", ")), (.modified_timestamp | strftime("%Y-%m-%d %H:%M:%S"))] | @csv' <<< "$DB_CACHE" > "$export_path"; then
            # Add header
            sed -i '1i "ID","Name","Kennel","Scents","Buried Date"' "$export_path"
            echo "✓ BoneYARD exported to CSV: $export_path"
        else
            echo "❌ Failed to export CSV."
        fi
    else
        # Export HTML
        cat <<EOF > "$export_path"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BoneYARD Export</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f1ea; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: auto; background: white; padding: 30px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 4px double #d4a373; }
        h1 { color: #bc6c25; text-align: center; border-bottom: 2px solid #dda15e; padding-bottom: 10px; }
        .stats { display: flex; justify-content: space-around; margin-bottom: 30px; background: #fefae0; padding: 15px; border-radius: 10px; border: 1px solid #dda15e; }
        .stat-item { text-align: center; }
        .stat-value { font-size: 1.5em; font-weight: bold; color: #606c38; }
        .stat-label { font-size: 0.9em; color: #283618; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background-color: #dda15e; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        tr:hover { background-color: #fefae0; }
        .scents { font-style: italic; color: #606c38; }
        .id { font-family: monospace; color: #bc6c25; font-weight: bold; }
        .footer { margin-top: 30px; text-align: center; font-size: 0.8em; color: #999; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐾 BoneYARD: Exported Treasures</h1>
        <div class="stats">
            <div class="stat-item">
                <div class="stat-value">$(jq '.files | length' <<< "$DB_CACHE")</div>
                <div class="stat-label">Bones Buried</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$(jq '[.files[].tags[]] | unique | length' <<< "$DB_CACHE")</div>
                <div class="stat-label">Unique Scents</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">$(date "+%Y-%m-%d %H:%M")</div>
                <div class="stat-label">Export Date</div>
            </div>
        </div>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Bone Name</th>
                    <th>Kennel (Path)</th>
                    <th>Scents</th>
                    <th>Buried On</th>
                </tr>
            </thead>
            <tbody>
EOF
        
        jq -r 'def lpad(n; fill): (tostring | if length < n then (n - length) * fill + . else . end); 
            . as $root | .files | sort_by(.modified_timestamp) | reverse | .[] | 
            (.unique_id | lpad(4; "0")) as $id |
            (.tags | join(", ")) as $scents |
            (.modified_timestamp + ($root["timezone-offset"] // 0) | strftime("%Y-%m-%d %H:%M")) as $date |
            "                <tr>
                    <td class=\"id\">\($id)</td>
                    <td>\(.name)</td>
                    <td>\(.path)</td>
                    <td class=\"scents\">\($scents)</td>
                    <td>\($date)</td>
                </tr>"' <<< "$DB_CACHE" >> "$export_path"
        
        cat <<EOF >> "$export_path"
            </tbody>
        </table>
        <div class="footer">
            Generated by BoneYARD v$SOFTWARE_VERSION | Made with all the love I'm legally allowed to give!
        </div>
    </div>
</body>
</html>
EOF
        echo "✓ BoneYARD exported to HTML: $export_path"
    fi
    
    pause
    main_menu
}
