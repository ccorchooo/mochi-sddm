#!/usr/bin/env bash
# mochi SDDM theme installer
#
#   ./install.sh                              install + enable with defaults
#   ./install.sh -w ~/Pictures/wall.jpg       use your wallpaper (colors adapt to it)
#   ./install.sh -a ~/me.png                  set your profile picture
#   ./install.sh -c squishy -v vibrant        clock style + color variant
#   ./install.sh --test [options]             preview in a window, installs nothing
#   ./install.sh --uninstall
set -euo pipefail

THEME=mochi
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sddm/themes/$THEME"
CONF_D="/etc/sddm.conf.d"
CONF_FILE="$CONF_D/zz-$THEME-theme.conf"

c_b=$'\e[1m'; c_g=$'\e[32m'; c_y=$'\e[33m'; c_r=$'\e[31m'; c_0=$'\e[0m'
say()  { printf '%s==>%s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%s!!%s  %s\n' "$c_y" "$c_0" "$*" >&2; }
die()  { printf '%sxx%s  %s\n' "$c_r" "$c_0" "$*" >&2; exit 1; }

usage() {
    cat <<EOF
${c_b}mochi SDDM theme installer${c_0}

Usage: $0 [options]

  -w, --wallpaper FILE   wallpaper to use (copied into the theme)
  -a, --avatar FILE      profile picture for the user (see --user)
  -u, --user NAME        user the avatar belongs to (default: ${SUDO_USER:-$USER})
  -c, --clock STYLE      flex | squishy | mono | dots | serif | thin | wide
  -v, --variant NAME     tonalspot | vibrant | expressive | fidelity | neutral | monochrome
      --accent COLOR     fixed seed color like '#7aa2f7' instead of the wallpaper's
      --light            light color scheme
      --12h              12-hour clock
      --no-fonts         don't download the bundled fonts
      --no-enable        install but don't make it the active SDDM theme
      --test             preview with sddm-greeter-qt6 --test-mode (no root, installs nothing)
      --uninstall        remove the theme and its SDDM config
  -h, --help             this help
EOF
}

# ---------------------------------------------------------------- args
WALLPAPER="" AVATAR="" AVATAR_USER="${SUDO_USER:-$USER}" CLOCK="" VARIANT="" ACCENT=""
MODE="" FORMAT="" FONTS=1 ENABLE=1 TEST=0 UNINSTALL=0
ORIG_ARGS=("$@")
abs() { [ -e "$1" ] || die "file not found: $1"; realpath "$1"; }

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--wallpaper) WALLPAPER="$(abs "$2")"; shift 2 ;;
        -a|--avatar)    AVATAR="$(abs "$2")"; shift 2 ;;
        -u|--user)      AVATAR_USER="$2"; shift 2 ;;
        -c|--clock)     CLOCK="$2"; shift 2 ;;
        -v|--variant)   VARIANT="$2"; shift 2 ;;
        --accent)       ACCENT="$2"; shift 2 ;;
        --light)        MODE=light; shift ;;
        --12h)          FORMAT=12h; shift ;;
        --no-fonts)     FONTS=0; shift ;;
        --no-enable)    ENABLE=0; shift ;;
        --test)         TEST=1; shift ;;
        --uninstall)    UNINSTALL=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *) usage; die "unknown option: $1" ;;
    esac
done

case "$CLOCK" in ""|flex|squishy|mono|dots|serif|thin|wide) ;; *) die "unknown clock style: $CLOCK" ;; esac
case "$VARIANT" in ""|tonalspot|vibrant|expressive|fidelity|neutral|monochrome) ;; *) die "unknown variant: $VARIANT" ;; esac
[ -z "$ACCENT" ] || [[ "$ACCENT" =~ ^#[0-9a-fA-F]{6}$ ]] || die "accent must look like #rrggbb"

# ---------------------------------------------------------------- helpers
# set_conf FILE KEY VALUE  — upsert a key in the [General] section of an ini file
set_conf() {
    local file="$1" key="$2" val="$3"
    [ -f "$file" ] || printf '[General]\n' > "$file"
    grep -q '^\[General\]' "$file" || sed -i '1i [General]' "$file"
    if grep -q "^$key=" "$file"; then
        local esc; esc=$(printf '%s' "$val" | sed 's/[&|\\]/\\&/g')
        sed -i "s|^$key=.*|$key=$esc|" "$file"
    else
        sed -i "/^\[General\]/a $key=$val" "$file"
    fi
}

GF="https://raw.githubusercontent.com/google/fonts/main/ofl"
FONT_URLS=(
    "GoogleSansFlex.ttf|$GF/googlesansflex/GoogleSansFlex%5BROND,opsz,slnt,wdth,wght%5D.ttf"
    "Fredoka.ttf|$GF/fredoka/Fredoka%5Bwdth,wght%5D.ttf"
    "JetBrainsMono.ttf|$GF/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
    "Doto.ttf|$GF/doto/Doto%5BROND,wght%5D.ttf"
    "DMSerifDisplay.ttf|$GF/dmserifdisplay/DMSerifDisplay-Regular.ttf"
    "Outfit.ttf|$GF/outfit/Outfit%5Bwght%5D.ttf"
    "MaterialSymbolsRounded.ttf|https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"
)

# fetch_fonts DIR — download the OFL/Apache fonts the clock styles use (skips ones already there)
fetch_fonts() {
    local dir="$1"; mkdir -p "$dir"
    local sys_icons
    sys_icons=$(ls /usr/share/fonts/*/MaterialSymbolsRounded*.ttf 2>/dev/null | head -n1 || true)
    if [ ! -s "$dir/MaterialSymbolsRounded.ttf" ] && [ -n "$sys_icons" ]; then
        cp "$sys_icons" "$dir/MaterialSymbolsRounded.ttf"
    fi
    command -v curl >/dev/null || { warn "curl not found, skipping font download (system fonts will be used)"; return 0; }
    local entry name url
    for entry in "${FONT_URLS[@]}"; do
        name="${entry%%|*}"; url="${entry#*|}"
        [ -s "$dir/$name" ] && continue
        printf '    %-28s' "$name"
        if curl -fsSL --retry 2 -o "$dir/$name.part" "$url"; then
            mv "$dir/$name.part" "$dir/$name"; echo "ok"
        else
            rm -f "$dir/$name.part"; echo "failed (fallback font will be used)"
        fi
    done
}

# apply_options THEME_DIR — write the chosen options into theme.conf.user
apply_options() {
    local dir="$1" user_conf="$1/theme.conf.user"
    if [ -n "$WALLPAPER" ]; then
        local ext="${WALLPAPER##*.}"; ext="${ext,,}"
        rm -f "$dir"/backgrounds/wallpaper.*
        install -m 644 "$WALLPAPER" "$dir/backgrounds/wallpaper.$ext"
        set_conf "$user_conf" background "backgrounds/wallpaper.$ext"
    fi
    [ -n "$CLOCK" ]   && set_conf "$user_conf" clockStyle "$CLOCK"
    [ -n "$VARIANT" ] && set_conf "$user_conf" colorVariant "$VARIANT"
    [ -n "$ACCENT" ]  && set_conf "$user_conf" accentColor "$ACCENT"
    [ -n "$MODE" ]    && set_conf "$user_conf" colorMode "$MODE"
    [ -n "$FORMAT" ]  && set_conf "$user_conf" clockFormat "$FORMAT"
    return 0
}

check_deps() {
    command -v sddm >/dev/null || warn "sddm is not installed"
    command -v sddm-greeter-qt6 >/dev/null || warn "sddm-greeter-qt6 not found — mochi needs SDDM built with Qt 6 (sddm >= 0.20)"
    local qtv=""
    if command -v qtpaths6 >/dev/null; then qtv=$(qtpaths6 --qt-version 2>/dev/null || true)
    elif command -v pacman >/dev/null; then qtv=$(pacman -Q qt6-declarative 2>/dev/null | awk '{print $2}' | cut -d- -f1)
    fi
    if [ -n "$qtv" ]; then
        local maj min; maj=${qtv%%.*}; min=$(echo "$qtv" | cut -d. -f2)
        if [ "$maj" -lt 6 ] || { [ "$maj" -eq 6 ] && [ "$min" -lt 7 ]; }; then
            warn "Qt $qtv found; mochi needs Qt >= 6.7 (variable font axes, MultiEffect)"
        fi
    fi
}

# ---------------------------------------------------------------- test mode
if [ "$TEST" -eq 1 ]; then
    command -v sddm-greeter-qt6 >/dev/null || die "sddm-greeter-qt6 not found"
    [ "$FONTS" -eq 1 ] && [ -w "$SRC" ] && { say "Fetching fonts into $SRC/fonts"; fetch_fonts "$SRC/fonts"; }
    TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
    cp -r "$SRC" "$TMP/$THEME"
    apply_options "$TMP/$THEME"
    say "Launching preview (close the window or press Ctrl+C to quit)"
    sddm-greeter-qt6 --test-mode --theme "$TMP/$THEME"
    exit 0
fi

# ---------------------------------------------------------------- root
if [ "$(id -u)" -ne 0 ]; then
    say "Root is needed to install into $DEST — re-running with sudo"
    # pass resolved absolute paths so relative files still work
    args=()
    [ -n "$WALLPAPER" ] && args+=(--wallpaper "$WALLPAPER")
    [ -n "$AVATAR" ] && args+=(--avatar "$AVATAR")
    exec sudo SUDO_USER="${SUDO_USER:-$USER}" bash "$SRC/install.sh" "${ORIG_ARGS[@]}" "${args[@]}"
fi

# ---------------------------------------------------------------- uninstall
if [ "$UNINSTALL" -eq 1 ]; then
    [ -d "$DEST" ] && rm -rf "$DEST" && say "Removed $DEST"
    [ -f "$CONF_FILE" ] && rm -f "$CONF_FILE" && say "Removed $CONF_FILE"
    say "Done. SDDM will fall back to its default theme."
    exit 0
fi

# ---------------------------------------------------------------- install
check_deps

USER_CONF_BACKUP=""
if [ -f "$DEST/theme.conf.user" ]; then
    USER_CONF_BACKUP=$(mktemp); cp "$DEST/theme.conf.user" "$USER_CONF_BACKUP"
fi
KEEP_WALL=""
if ls "$DEST"/backgrounds/wallpaper.* >/dev/null 2>&1; then
    KEEP_WALL=$(mktemp -d); cp "$DEST"/backgrounds/wallpaper.* "$KEEP_WALL/"
fi

say "Installing theme to $DEST"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SRC"/. "$DEST"/
[ -n "$USER_CONF_BACKUP" ] && mv "$USER_CONF_BACKUP" "$DEST/theme.conf.user"
[ -n "$KEEP_WALL" ] && cp "$KEEP_WALL"/* "$DEST/backgrounds/" && rm -rf "$KEEP_WALL"

if [ "$FONTS" -eq 1 ]; then
    say "Fetching fonts (Google Sans Flex, Fredoka, JetBrains Mono, Doto, DM Serif Display, Outfit, Material Symbols)"
    fetch_fonts "$DEST/fonts"
fi

apply_options "$DEST"

# ---- avatar
if [ -n "$AVATAR" ]; then
    id "$AVATAR_USER" >/dev/null 2>&1 || die "no such user: $AVATAR_USER"
    say "Setting profile picture for $AVATAR_USER"
    install -d -m 755 /var/lib/AccountsService/icons /usr/share/sddm/faces
    install -m 644 "$AVATAR" "/var/lib/AccountsService/icons/$AVATAR_USER"
    install -m 644 "$AVATAR" "/usr/share/sddm/faces/$AVATAR_USER.face.icon"
    ufile="/var/lib/AccountsService/users/$AVATAR_USER"
    install -d -m 700 /var/lib/AccountsService/users
    if [ -f "$ufile" ]; then
        if grep -q '^Icon=' "$ufile"; then
            sed -i "s|^Icon=.*|Icon=/var/lib/AccountsService/icons/$AVATAR_USER|" "$ufile"
        else
            grep -q '^\[User\]' "$ufile" || printf '[User]\n' >> "$ufile"
            sed -i "/^\[User\]/a Icon=/var/lib/AccountsService/icons/$AVATAR_USER" "$ufile"
        fi
    else
        printf '[User]\nIcon=/var/lib/AccountsService/icons/%s\nSystemAccount=false\n' "$AVATAR_USER" > "$ufile"
        chmod 600 "$ufile"
    fi
    # SDDM prefers ~/.face.icon when it can read it; drop a stale one out of the way
    home=$(getent passwd "$AVATAR_USER" | cut -d: -f6)
    if [ -n "$home" ] && [ -e "$home/.face.icon" ]; then
        warn "$home/.face.icon exists and may override this picture; remove it if the old one still shows"
    fi
fi

chmod -R u=rwX,go=rX "$DEST"

# ---- enable
if [ "$ENABLE" -eq 1 ]; then
    mkdir -p "$CONF_D"
    printf '[Theme]\nCurrent=%s\n' "$THEME" > "$CONF_FILE"
    say "Enabled via $CONF_FILE"
    if [ -f /etc/sddm.conf ] && grep -Eq '^\s*Current\s*=' /etc/sddm.conf && ! grep -Eq "^\s*Current\s*=\s*$THEME\s*$" /etc/sddm.conf; then
        warn "/etc/sddm.conf sets a different [Theme] Current= and takes precedence — change it to Current=$THEME"
    fi
fi

cat <<EOF

${c_b}mochi is installed.${c_0}
  Preview:   sddm-greeter-qt6 --test-mode --theme $DEST
  Settings:  $DEST/theme.conf  (put overrides in theme.conf.user)
  Re-run this script any time to change wallpaper, avatar, clock style or colors.
EOF
