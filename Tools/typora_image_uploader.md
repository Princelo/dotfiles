# Typora image uploader (custom command)

This repo includes `typora_image_uploader.py` for Typora:

- **Preferences → Image → Image Upload Setting → Custom Command**

## What it does

- Copies each input image into the first writable location from:
  - `~/Pictures/Typora/typora-assets/YYYY/MM/`
  - `~/Documents/Typora/typora-assets/YYYY/MM/`
  - `/private/tmp/typora-assets/YYYY/MM/` (fallback)
  - `/tmp/typora-assets/YYYY/MM/` (fallback)
- Prints the new `file://...` URL back to Typora (one per line)
- Tries to delete the original image afterwards
  - If deletion fails, logs the path to:
    - macOS: `~/Library/Logs/typora-image-uploader/delete-failures.log`
    - Linux: `~/.local/state/typora-image-uploader/delete-failures.log` (or `$XDG_STATE_HOME/...`)
    - Windows: `%LOCALAPPDATA%\\typora-image-uploader\\delete-failures.log`
    - One file path per line (easy to clean up later)
    - The log file is created only if deletions fail

## Typora command

- `python3 /absolute/path/to/typora_image_uploader.py`
