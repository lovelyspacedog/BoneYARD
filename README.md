# 🐾 BoneYARD: Yappy Archive and Retrieval Database

![BoneYARD Logo](https://img.shields.io/badge/Project-BoneYARD-brown?style=for-the-badge&logo=dog)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

Welcome to **BoneYARD**, a powerful, interactive TUI system for burying (tagging) and fetching (searching) your files using a dog-themed motif. Built for those who want a playful yet robust way to organize their digital litter.

---

## 🐕 Terminologies

BoneYARD uses dumb doggo terminology, such as:
- **Bone**: A file you want to track.
- **Scent**: A tag or keyword assigned to a bone.
- **Kennel**: A directory containing bones.
- **Yard**: Your entire database of buried treasures.
- **Sniffing**: Searching or filtering through your bones.
- **Litter**: A group of bones/files to batch process.
- **Pack**: The collection of bones or user community.
- **Doggy Bag**: A temporary session mode for safe experimentation.

---

## ✨ Main Features

- **🎾 Fetch Bones**: Highly flexible search system. Filter by scent, bone name, kennel, or date range. Advanced boolean scent queries (AND, OR, NOT) supported. (Now #1 priority in the main menu).
- **🦴 Bury New Bone**: Pick a file using `ranger` and assign searchable scents.
- **🐕 Bury Entire Litter**: Batch-tag an entire kennel with interactive copy, undo, skip, and "all" functionality. Now features **Smart Tagging** (duplicate detection) and a **Session Scents Tracker**.
- **👃 Update Scents**: Quickly update or add new scents to any bone already in the yard.
- **🦴 Organize Bones**: Batch-organize your files into a new folder based on scent frequency.
- **🧹 Clean Up the Yard**: Remove bones, entire kennels, or date ranges from your database.
- **🏘️ Switch Yard**: Move the pack to a different JSON database file.
- **🐾 Cache Bones (Snapshots)**: New management suite for yard backups. Bury snapshots, fetch from the cache, paw through them, or clean them up.
- **📤 Export Yard**: Export your yard data to CSV or HTML files for external analysis and sharing.
- **👜 Doggy Bag Mode**: A non-persistent session mode. Make changes safely and only "bury" them in the yard when you exit.
- **📊 Pack Stats**: View comprehensive statistics, including scent frequency and recent burial activity.
- **🚀 Rebuild Doghouse**: Automatic background version check with one-click update. Now includes connectivity awareness to prevent offline hangs.
- **🖼️ Bone Previews**: Automatic image and video previews for Kitty terminal users.
- **🚨 Health Checks**: Automatic corruption detection and interactive repair tools on launch.
- **🌋 Incinerate the Yard**: A high-security database wipe featuring a 12-word pass-phrase confirmation.
- **📜 Kennel Rules & Changelog**: Integrated viewer for the GPLv3 license and project history.

---

## 🛠️ Requirements

To run BoneYARD, you'll need the following "toys" installed:

### Mandatory:
- **`jq`**: The JSON processor (the brains of the operation).
- **`ranger`**: Terminal file manager for bone selection.
- **`gum`**: For the beautiful TUI menus and styling.
- **`shuf`**: For security phrases and variety.
- **`file`**: For identifying bone types (MIME detection).
- **`curl`**: To check for and download updates.
- **`git`**: To pull the latest version from the repository.

### Optional (Recommended):
- **`kitty`**: For terminal graphics support (bone previews).
- **`ffmpeg`**: For generating video thumbnails in previews.
- **`ImageMagick` (`magick`)**: For high-quality image thumbnails in previews.
- **`sox` (`play`)**: For subtle menu audio feedback.
- **`nvim`**, **`nano`**, or **`less`**: Your preferred pager for reading rules.
- **`/usr/share/dict/words`**: Standard Linux dictionary for pass-phrases (fallback provided by `wordlist.txt`).

---

## 🚀 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lovelyspacedog/BoneYARD.git
   cd boneyard
   ```

2. **Make the scripts executable**:
   ```bash
   chmod +x boneyard BoneYARD.sh
   ```

3. **(Optional) Add to your PATH**:
   Link the `boneyard` launcher to your local bin:
   ```bash
   ln -s "$(pwd)/boneyard" ~/.local/bin/boneyard
   ```

---

## 📂 Project Structure

- `VERSION`: Current version for reliable update checking.
- `boneyard`: A lightweight launcher script.
- `BoneYARD.sh`: The main launcher that loads the modular scripts.
- `modules/`: Feature modules sourced by `BoneYARD.sh`:
  - `core.sh`: Shared utilities, update logic, database helpers.
  - `cli.sh`: CLI parsing and help output.
  - `tagging.sh`: Bury/update/edit flows.
  - `search.sh`: Fetch/list flows.
  - `organize.sh`: Batch organize flows.
  - `remove.sh`: Clean-up and incineration flows.
  - `stats.sh`: Pack statistics.
  - `yard.sh`: Yard switching.
  - `export.sh`: CSV/HTML export.
  - `backups.sh`: Snapshot/cache management.
  - `pager.sh`: License/changelog/pager views.
  - `menu.sh`: Main menu and app entrypoint.
- `boneyard.json`: The default database file (created automatically if missing).
- `wordlist.txt`: A local fallback wordlist for pass-phrase generation.
- `LICENSE`: Full GNU General Public License v3 text.
- `CHANGELOG.md`: Detailed history of project changes.
- `README.md`: The file you are currently reading!

> **Note on Standalone Operation**: BoneYARD now ships as a modular project. Use `--generate-standalone` to build a single-file script for portability. Updates are disabled in the standalone file, so regenerate it when you want new versions.

---

## 🎾 Usage

### Interactive TUI Mode
Simply run the launcher to enter the main menu:
```bash
./boneyard
```

### CLI Quick Fetch
You can also sniff out scents directly from the terminal:
```bash
# Get scents for a specific bone
./boneyard --tags "report.pdf"

# Find scents for bones containing 'script' and include kennel info
./boneyard -t "script" --contains --with-dir use " | "
```

### Help Information Output
Running `./boneyard --help` provides the following reference:

```text
🐾 BoneYARD v1.4.0 (Yappy Archive and Retrieval Database)
A powerful, interactive TUI system for burying and fetching bones using JSON.

USAGE:
  BoneYARD.sh [options]

OPTIONS:
  -d, --database FILE    Specify a custom BoneYARD JSON file.
                         Defaults to: boneyard.json
  -b, --doggy-bag        Enable "Doggy Bag" mode. No changes are written to the 
                         main database until you exit the TUI.
  -t, --tags FILE        Output comma-delimited scents for a specific bone.
                         Accepts full path or just a bone name.
                         Exit codes: 0=found, 1=not found, N=match count.
  --with-dir [use SEP]  When used with --tags, appends kennel components
                         and the bone name to the output scents.
                         Optionally use 'use SEP' to set a custom separator 
                         (e.g., --with-dir use ":") between the kennel branch
                         and the scents. (Default: comma).
  --contains             When used with --tags, enables case-insensitive 
                         "contains" searching instead of exact matching.
  --pager PAGER          Force a specific pager (nvim, nano, less) for the rules.
                         Use 'safe' for the built-in 5-line-at-a-time viewer.
  --generate-standalone [FILE]
                         Build a single-file BoneYARD script with all modules
                         embedded. Defaults to: BoneYARD-standalone.sh
                         Updates are disabled in the generated file.
  -h, -?, --help         Show this comprehensive help message.

MAIN FEATURES:
  Fetch Bones         Filter by scent, bone name (contains), kennel, or date.
                     Scent search supports AND, OR, NOT (e.g. bash AND script).
  Bury New Bone       Pick a bone using ranger and assign searchable scents.
  Bury Entire Litter  Batch-bury an entire kennel with interactive 
                      copy/undo/skip/all functionality.
  Update Scents       Quickly update scents for any bone in the yard.
  Organize Bones      Batch-move/rename bones based on scent frequency.
  Clean Up the Yard   Remove specific bones or entire kennels from the yard.
  Switch Yard         Open a different JSON database file (bones are not moved).
  Cache Bones         Snapshot suite: bury, fetch, paw through, or clean up.
  Export Yard         Export the yard to CSV or HTML for external use.
  Doggy Bag Mode      Run a non-persistent session with save-on-exit safety.
  Show Pack Stats     View scent frequency, kennel counts, and recent activity.
  Rebuild Doghouse    Install the latest version from GitHub (Update Available!).
  Incinerate Yard     Permanently wipe the yard with high-security 
                      phrase confirmation and fuzzy-match recovery.
  Kennel Rules        View the license and project history (Changelog).

BONE PREVIEWS:
  Users in the Kitty terminal will see automatic previews of images 
  and videos (via thumbnails) during the tagging process.

EXAMPLES:
  # Launch interactive TUI (default)
  BoneYARD.sh

  # Launch with a specific boneyard file
  BoneYARD.sh --database ~/backups/boneyard.json

  # Get scents for a bone (exact match)
  BoneYARD.sh --tags "report.pdf"

  # Find scents for all bones containing 'script' and include kennel info
  BoneYARD.sh -t "script" --contains --with-dir use " | "

  # View rules using the built-in safe pager
  BoneYARD.sh --pager safe

ENVIRONMENT:
  Requires: jq, ranger, gum, shuf, file, curl, git
  Optional: play (from sox) for menu audio feedback.

Copyright (c) 2025-2026 Pup Tony under GPLv3.
```

## 🎒 New in v1.2.0: Doggy Bag Mode
You can now run BoneYARD in "Doggy Bag" mode using the `-b` flag. This allows you to explore, tag, and modify your yard without committing anything to disk until you are finished. Upon exit, you'll be prompted to either "Bury" the changes (save them) or "Abandon the scent" (discard them). This is perfect for batch processing large litters where you might want to double-check your work before making it permanent.

---

## 🛡️ Security Bypass
For the "Incinerate" function, developers and advanced pups can use the **debug bypass**:
`debug PUPPY [initials] [captured_minute]`
*Note: The [initials] are the lowercase first initials of the 1st, 5th, and 9th words in the pass-phrase grid.*
*Note: The minute is the local system minute captured exactly when the prompt appears!*

---

## 📜 License
BoneYARD is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License as published by the Free Software Foundation, version 3**.

The full text of the license can be found in the [LICENSE](./LICENSE) file included with this project.

*Copyright (c) 2025-2026 Pup Tony*