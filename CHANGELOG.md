# Changelog

All notable changes to this project will be documented in this file.

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

