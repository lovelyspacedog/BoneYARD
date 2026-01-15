# Pager, license, and changelog views.

# Display the license
read_license() {
    play_menu_sound
    clear
    local short_license
    short_license=$(cat << 'EOF'
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
)
    typewrite "$short_license" 0.001
    echo ""
    
    local choice
    choice=$(gum choose "📜 Read Full License" "📜 View Changelog" "🐾 Go Back To Main Menu" || echo "🐾 Go Back To Main Menu")
    
    if [[ "$choice" == "🐾 Go Back To Main Menu" ]]; then
        main_menu
        return
    fi

    if [[ "$choice" == "📜 View Changelog" ]]; then
        view_changelog
        return
    fi
    
    # Read Full License logic
    local local_license="$SCRIPT_DIR/LICENSE"
    local temp_license="/tmp/gpl_full.txt"
    local pulled=false
    local used_url=""
    
    if [[ -f "$local_license" ]]; then
        cp "$local_license" "$temp_license"
        pulled=true
        used_url="local file"
    else
        local license_urls=(
            "https://www.gnu.org/licenses/gpl-3.0.txt"
            "https://raw.githubusercontent.com/oss-collections/licenses/refs/heads/master/gpl-3.0.txt"
            "https://raw.githubusercontent.com/github/choosealicense.com/gh-pages/_licenses/gpl-3.0.txt"
            "https://archive.org/download/GPL3.0/GPL-3.0.txt"
            "https://pastebin.com/raw/HL2BPZ5w"
        )
        
        echo ""
        gum style --foreground 212 "⏳ Checking for online version (trying mirrors)..."
        
        for url in "${license_urls[@]}"; do
            if command -v curl &> /dev/null; then
                if curl -s --connect-timeout 2 --max-time 5 "$url" > "$temp_license"; then
                    if [[ -s "$temp_license" ]]; then
                        pulled=true
                        used_url="$url"
                        break
                    fi
                fi
            elif command -v wget &> /dev/null; then
                if wget -qO "$temp_license" --connect-timeout=2 --timeout=5 "$url"; then
                    if [[ -s "$temp_license" ]]; then
                        pulled=true
                        used_url="$url"
                        break
                    fi
                fi
            fi
        done
    fi
    
    if [[ "$pulled" == "false" ]]; then
        gum style --foreground 250 "⚠️  Online version unavailable. Using embedded text."
        sleep 1.5
        # Fallback version includes the critical warranty/liability clauses
        cat <<EOF > "$temp_license"
--- EMBEDDED LICENSE PREVIEW ---

$short_license

---

15. Disclaimer of Warranty.

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. Limitation of Liability.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
EOF
    else
        if [[ "$used_url" == "local file" ]]; then
            gum style --foreground 212 "✅ Full license loaded from local LICENSE file"
        else
            local domain
            domain=$(echo "$used_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
            gum style --foreground 212 "✅ Full license downloaded from $domain"
        fi
        sleep 1.5
    fi
    
    # Pager logic
    if [[ "$FORCED_PAGER" == "safe" ]]; then
        boneyard_safe_pager "$temp_license" "LICENSE TEXT"
    elif [[ -n "$FORCED_PAGER" ]]; then
        if command -v "$FORCED_PAGER" &> /dev/null; then
            "$FORCED_PAGER" "$temp_license"
        else
            echo "Error: Forced pager '$FORCED_PAGER' not found. Falling back to default detection."
            sleep 2
            boneyard_auto_pager "$temp_license" "LICENSE TEXT"
        fi
    else
        boneyard_auto_pager "$temp_license" "LICENSE TEXT"
    fi
    
    rm -f "$temp_license"
    clear
    main_menu
}

# View the project changelog
view_changelog() {
    play_menu_sound
    clear
    local changelog_file="$SCRIPT_DIR/CHANGELOG.md"
    
    if [[ ! -f "$changelog_file" ]]; then
        gum style --foreground 196 "❌ Error: CHANGELOG.md not found in $SCRIPT_DIR"
        pause
        read_license
        return
    fi

    # Pager logic
    if [[ "$FORCED_PAGER" == "safe" ]]; then
        boneyard_safe_pager "$changelog_file" "CHANGELOG"
    elif [[ -n "$FORCED_PAGER" ]]; then
        if command -v "$FORCED_PAGER" &> /dev/null; then
            "$FORCED_PAGER" "$changelog_file"
        else
            echo "Error: Forced pager '$FORCED_PAGER' not found. Falling back to default detection."
            sleep 2
            boneyard_auto_pager "$changelog_file" "CHANGELOG"
        fi
    else
        boneyard_auto_pager "$changelog_file" "CHANGELOG"
    fi
    
    clear
    read_license
}

# Safe line-by-line pager
boneyard_safe_pager() {
    local target_file="$1"
    local header_text="${2:-FILE TEXT}"
    local lines_per_page=10
    local current_page=1
    
    # Calculate total pages
    local total_lines
    total_lines=$(wc -l < "$target_file")
    local total_pages=$(( (total_lines + lines_per_page - 1) / lines_per_page ))
    
    while true; do
        clear
        local line_count=0
        local restart=false
        
        # Display header
        gum style --foreground 250 "=== $header_text ==="
        echo ""
        
        while IFS= read -r line; do
            echo "$line"
            line_count=$((line_count + 1))
            
            if (( line_count % lines_per_page == 0 )); then
                echo ""
                echo -n "-- Page $current_page of $total_pages (q: quit, n: restart, any key: next) --"
                local key
                read -n 1 -s key < /dev/tty
                echo -ne "\r\033[K" # Clear the prompt line
                
                case "${key,,}" in
                    "q")
                        echo "Exiting..."
                        sleep 0.5
                        return
                        ;;
                    "n")
                        restart=true
                        break  # Break inner loop to restart from top
                        ;;
                    *)
                        current_page=$((current_page + 1))
                        ;;
                esac
            fi
        done < "$target_file"
        
        # If we finished reading the file without restarting
        if [[ "$restart" != "true" ]]; then
            echo ""
            echo "----------------------------------------"
            typewrite "End of $header_text. Press any key to continue..."
            read -n 1 -s < /dev/tty
            return
        fi
        
        # Reset for restart
        current_page=1
    done
}

# Automatic pager detection
boneyard_auto_pager() {
    local target_file="$1"
    local header_text="${2:-FILE TEXT}"
    if command -v nvim &> /dev/null; then
        nvim --clean -R "$target_file"
    elif command -v nano &> /dev/null; then
        nano -v "$target_file" # -v for view mode
    elif command -v less &> /dev/null; then
        less "$target_file"
    else
        boneyard_safe_pager "$target_file" "$header_text"
    fi
}
