# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0] - 2026-01-14

### Added
- **🧩 Modular Script Layout**:
  - Split the full script into feature-focused modules (CLI, tagging, search, organize, remove, stats, yard, export, backups, pager, menu).
  - New `modules/` directory used by `BoneYARD.sh` at runtime.
- **📦 Standalone Builder**:
  - New `--generate-standalone` flag to embed modules into a single-file script.
  - Standalone builds disable auto-updates to avoid partial upgrades.
- **🔐 Enhanced Security**:
  - Improved database deletion passphrase generation with expanded 18-word pool.
  - Random word scrambling and selective capitalization to prevent automated attacks.

### Changed
- **🚀 Updater Safety**:
  - Minimal update mode now copies module files so upgrades include new scripts.
- **📚 Documentation**:
  - Updated README to reflect the modular architecture and standalone workflow.

## [1.3.0] - 2026-01-14

### Added
- **🔍 Enhanced Scent Search**:
  - Added boolean operators (AND, OR, NOT) to scent filtering for more powerful queries
  - Supports complex search expressions like "bash AND script" or "python NOT test"
  - Enhanced search-by-name functionality with contains matching
- **📤 Export Yard Data**:
  - New export functionality to save yard data as CSV or HTML files
  - External tool compatibility for data analysis and sharing
- **📅 Date-Based Operations**:
  - **Search by Date Range**: Filter bones by modification date ranges
  - **Edit by Date Range**: Bulk update scents for bones within date ranges
  - **Remove by Date Range**: Clean up bones from specific time periods
- **🔒 Database Safety Features**:
  - **Database Locking**: Prevents concurrent access corruption with file-based locks
  - **Memory Caching**: Improved performance through in-memory database operations
  - Enhanced health checks with automatic corruption detection and repair suggestions

### Changed
- **🌐 Connectivity Awareness**: Enhanced offline handling to prevent update check hangs
- **⚡ Performance Improvements**: Database operations now use cached in-memory copies for faster access
- **🎨 UI Refinements**: Improved menu organization and user experience consistency

### Fixed
- Improved error handling for corrupted database scenarios
- Enhanced timezone offset handling in edge cases

## [1.2.0] - 2026-01-14

### Added
- **👜 Doggy Bag Mode**: 
  - Introduced a non-persistent session mode using `-b` or `--doggy-bag`.
  - Redirects all writes to a temporary workspace; changes are only "buried" (saved) upon explicit confirmation on exit.
  - Integrated a "Use a Doggy Bag" option directly into the main menu for easy relaunching.
- **🏘️ Cache Bones (Snapshots)**:
  - Overhauled backup/restore into a logical "Cache" system.
  - **Bury New Snapshot**: Create timestamped yard backups in a default or custom directory.
  - **Fetch From The Cache**: Restore your yard from a previous snapshot with safety overwriting prompts.
  - **Paw Through The Cache**: New dedicated view to list and inspect cached snapshots (date, size, name).
  - **Clean Up the Cache**: Interactive tool to incinerate old snapshots from the cache.
- **🚨 Health Checks**: 
  - Automatic database corruption detection on launch using `jq` validation.
  - Interactive repair tools: "Attempt Repair" (salvages structure) or "Start Fresh" (re-initialization with backup).
- **🛡️ Connectivity Awareness**: Added `check_github_connectivity` to ensure offline users don't experience hangs during update checks.

### Changed
- **🎨 UX Lifecycle Reorganization**:
  - Reordered the main menu by functional lifecycle: Retrieval -> Acquisition -> Maintenance -> Safety -> System.
  - Consistently updated emojis and terminology (Bones for files, Yards for databases).
- **⚙️ Compatibility Logic**:
  - If a database is newer than the software, BoneYARD now offers to automatically update the software to a compatible version from GitHub.
  - Tightened JSON validity checks across all CLI and TUI entry points using `jq -e`.

### Fixed
- Improved robustness of timezone offset handling in corrupted database scenarios.
- Standardized "Back To Main Menu" navigation across all sub-menus.

## [1.1.1] - 2026-01-14

### Changed
- **🎨 UI Refinement**:
  - Reordered elements in "Bury Entire Litter" view for better readability: Header -> Bone Progress -> Session Scents -> Spacing -> Filename.

## [1.1.0] - 2026-01-14

### Changed
- **🐾 Multiline Session Tracker**:
  - The "Session Scents" summary in "Bury Entire Litter" mode now automatically wraps to multiple lines using `fmt` if many different tags are used.
  - Improved readability by ensuring the session summary stays within a standard width (72 chars).

## [1.0.7] - 2026-01-14

### Added
- **🐾 Session Scents Tracker**:
  - In "Bury Entire Litter" mode, the script now displays a running list of all scents used during the current session, along with a frequency count.
  - **Enhanced Pooling**: Skipping an already-buried bone (by pressing Enter) now correctly pools its existing scents into the session tracker.
  - **Smarter Copy**: Skipping a bone now also updates the "last used scents" buffer, allowing you to use `v` (repeat) to copy the skipped bone's scents to the next one.
  - Helps maintain consistency and quickly see which tags have already been applied to previous bones in the current folder.

## [1.0.6] - 2026-01-14

### Added
- **🐾 Session Scents Tracker**:
  - In "Bury Entire Litter" mode, the script now displays a running list of all scents used during the current session, along with a frequency count.
  - Helps maintain consistency and quickly see which tags have already been applied to previous bones in the current folder.

## [1.0.5] - 2026-01-14

### Added
- **🐕 Smart Directory Tagging**:
  - Integrated duplicate detection: The script now identifies if a bone is already in the yard.
  - In-place updates: Added the ability to update scents for existing bones directly during bulk tagging.
  - Enhanced UI: Displays current scents and a warning badge when encountering already buried bones.
- **🔢 Polished IDs**: Bone IDs are now zero-padded to 4 digits (e.g., `0001`) across all menus, searches, and lists for better alignment.

### Fixed
- **🛠️ Refined Undo**: Fixed a bug in the directory tagging undo feature to ensure the correct entry is removed from the buffer.
- **💾 Robust Saving**: Overhauled the save logic for bulk tagging to correctly handle a mix of new bones and scent updates in a single batch.

## [1.0.4] - 2026-01-13

### Fixed
- **🛠️ Robust Updater**:
  - Fixed a crash in the clutter check logic caused by Bash arithmetic exit codes when `set -e` is active.
  - Added `shopt -s nullglob` to correctly handle empty directories during the update safety check.
  - Improved `git clone` error reporting by allowing standard error to be visible to the user.
  - Added a return to the main menu after update attempts to ensure consistent script flow.

## [1.0.3] - 2026-01-13

### Added
- **🚀 Rebuild Doghouse**: Integrated updater with automatic background version check and one-click relaunch.
  - Added a clutter check that warns if BoneYARD is installed in a shared folder (like Downloads).
  - Added a "Minimal Update" option to only copy `BoneYARD.sh` to prevent directory clutter.
- **🛡️ New Dependencies**: Added `curl` and `git` to mandatory requirements for update functionality.

### Changed
- **🔔 Dynamic Update Badge**: Main menu now displays a `[🚀 UPDATE AVAILABLE]` badge when a new version is detected.
- **🕒 Background Check**: The software now performs a non-blocking version check on launch.

## [1.0.2] - 2026-01-13

### Added
- **🖼️ Bone Previews**: Integrated terminal graphics support for Kitty terminal users.
  - Automatic image previews using `icat`.
  - Video thumbnail generation using `ffmpeg`.
- **🏘️ Switch Yard**: New feature to switch between different JSON database files without restarting the script.
- **🔊 Double Bark SFX**: Added a realistic "Woof woof!" sound effect using `sox`.
  - SFX triggers on script launch, script exit, and successful bone burial.
- **🐕 Bulk Tagging**: Added `vvv` and `all` keywords in directory tagging mode to apply scents to all remaining files instantly.
- **⚙️ Database Migration**: Automatic prompt to update the version schema of older database files when opened.

### Changed
- **🎨 UI Overhaul**: 
  - Overhauled the directory tagging interface with enhanced colors and layout using `gum`.
  - Replaced generic goodbye messages with a randomized list of 50+ dog-themed puns.
  - Renamed "Select Different Yard" to "Switch Yard" for better terminology consistency.
- **🛠️ Refined Audio**: 
  - Menu beeps are now suppressed on initial launch to prevent interference with the opening barks.
  - Optimized SFX to run in the background (non-blocking).
- **📖 Documentation**: 
  - Fully updated `README.md` and internal help text to reflect 1.0.2 changes.
  - Clarified that "Switch Yard" opens files rather than transferring bones.

### Fixed
- Improved Bash arithmetic consistency and internal variable handling.
- Fixed `typewrite` function timing and formatting.

### Dependencies
- Added `file` to mandatory requirements for MIME type detection.
- Added optional recommendations for `kitty`, `ffmpeg`, and `ImageMagick`.

---

## [1.0.1] - 2025-10-15
- Initial release of the "Yappy Archive and Retrieval Database" (BoneYARD).

