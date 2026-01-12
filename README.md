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

---

## ✨ Main Features

- **🦴 Bury New Bone**: Pick a file using `ranger` and assign searchable scents.
- **🐕 Bury Entire Litter**: Batch-tag an entire kennel with interactive copy, undo, and skip functionality.
- **👃 Update Scents**: Quickly update or add new scents to any bone already in the yard.
- **🎾 Fetch Bones**: Highly flexible search system. Filter by scent, bone name, or kennel.
- **📊 Pack Stats**: View comprehensive statistics, including scent frequency and recent burial activity.
- **🌋 Incinerate the Yard**: A high-security database wipe featuring a 12-word pass-phrase confirmation.
- **📜 Kennel Rules**: Integrated viewer for the GPLv3 license.

---

## 🛠️ Requirements

To run BoneYARD, you'll need the following "toys" installed:

### Mandatory:
- **`jq`**: The JSON processor (the brains of the operation).
- **`ranger`**: Terminal file manager for bone selection.
- **`gum`**: For the beautiful TUI menus and styling.
- **`shuf`**: For security phrases and variety.

### Optional (Recommended):
- **`sox` (`play`)**: For subtle menu audio feedback.
- **`curl`** or **`wget`**: To fetch the full license text from online mirrors.
- **`nvim`**, **`nano`**, or **`less`**: Your preferred pager for reading rules.
- **`/usr/share/dict/words`**: Standard Linux dictionary for pass-phrases (fallback provided by `wordlist.txt`).

---

## 🚀 Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lovelyspacedog/boneyard.git
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

- `boneyard`: A lightweight launcher script.
- `BoneYARD.sh`: The main Bash script containing all core logic and TUI.
- `boneyard.json`: The default database file (created automatically if missing).
- `wordlist.txt`: A local fallback wordlist for pass-phrase generation.
- `LICENSE`: Full GNU General Public License v3 text.
- `README.md`: The file you are currently reading!

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
🐾 BoneYARD v1.0.1 (Yappy Archive and Retrieval Database)
A powerful, interactive TUI system for burying and fetching bones using JSON.

USAGE:
  BoneYARD.sh [options]

OPTIONS:
  -d, --database FILE    Specify a custom BoneYARD JSON file.
                         Defaults to: boneyard.json
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
  -h, -?, --help         Show this comprehensive help message.

MAIN FEATURES:
  Bury New Bone       Pick a bone using ranger and assign searchable scents.
  Bury Entire Litter  Batch-bury an entire kennel with interactive 
                      copy/undo/skip functionality.
  Update Scents       Quickly update scents for any bone in the yard.
  Fetch Bones         Filter by scent, bone name (contains), or kennel.
  Show Pack Stats     View scent frequency, kennel counts, and recent activity.
  Incinerate Yard     Permanently wipe the yard with high-security 
                      phrase confirmation and fuzzy-match recovery.

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
  Requires: jq, ranger, gum, shuf
  Optional: play (from sox) for menu audio feedback.

Copyright (c) 2025-2026 Pup Tony under GPLv3.
```

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