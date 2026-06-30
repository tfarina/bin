#!/usr/bin/env bash
#
# gnome-terminal-palette-to-xresources
#
# Author: Thiago
# Initial version developed with assistance from ChatGPT.
#
# Export the currently configured GNOME Terminal ANSI color palette as a
# series of Xresources-style #define directives.
#
# The script reads the palette directly from the user's GNOME Terminal
# profile via GSettings (dconf) and converts each RGB color to hexadecimal.
#
# The output is intended to be copied into an Xresources color scheme so the
# same palette can be reused by terminals such as rxvt-unicode (urxvt).
#
# Notes:
#   - GNOME Terminal stores only the 16 RGB color values, not the original
#     palette name (e.g. "Tango" or "XTerm").
#   - The exported colors therefore represent the profile's current palette,
#     regardless of whether it originated from a built-in palette or has
#     been customized by the user.
#
# Example:
#
#   $ ./gnome-terminal-palette-to-xresources
#   ! GNOME Terminal palette exported for profile: Regular
#   ! UUID: b1dcc9dd-5262-4d8d-a863-c897e6d979b9
#
#   #define BLACK          #000000
#   #define RED            #800000
#   ...

set -euo pipefail

names=(
    BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE
    BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW
    BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE
)

rgb_to_comment() {
    local rgb=$1

    rgb=${rgb#rgb(}   # Remove leading "rgb("
    rgb=${rgb%)}      # Remove trailing ")"
    rgb=${rgb//,/, }  # Add a space after each comma

    printf '%s' "$rgb"
}

rgb_to_hex() {
        awk -F'[(),]' '
    {
        printf "#%02X%02X%02X\n", $2, $3, $4
    }' <<<"$1"
}

uuid=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# get visible-name for nicer filename; fallback to uuid if missing
name=$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${uuid}/" visible-name 2>/dev/null || echo "''")
# strip quotes
name="${name//\'/}"
name="${name//\"/}"
if [[ -z "$name" ]]; then
  name="$uuid"
fi

echo "! GNOME Terminal palette exported for profile: $name"
echo "! UUID: $uuid"
echo

palette=$(gsettings get \
    "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$uuid/" \
    palette)

mapfile -t palette_rgb < <(
    grep -o 'rgb([^)]*)' <<<"$palette"
)

echo "! RGB table"
echo "! ---------"
echo

for i in "${!palette_rgb[@]}"; do
    printf '! %-14s = %s\n' \
	   "${names[i]}" \
	   "$(rgb_to_comment "${palette_rgb[i]}")"
done

echo

echo "! Hexadecimal values"
echo "! ------------------"
echo

for i in "${!palette_rgb[@]}"; do
    printf "#define %-14s %s\n" \
	   "${names[i]}" \
	   "$(rgb_to_hex "${palette_rgb[i]}")"
done
