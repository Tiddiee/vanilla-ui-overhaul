#!/usr/bin/env bash

set -Eeuo pipefail

readonly VERSION="v1.4.1b"
readonly ARCHIVE="Vanilla_UI_Overhaul_v1.4.1b.zip"
readonly BRANCH_ARCHIVE_URL="https://github.com/Tiddiee/vanilla-ui-overhaul/archive/refs/heads/test/1.4.1b.zip"
TMP_DIR=""

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
}
trap cleanup EXIT

pause_for_enter() {
    read -r -p "Press Enter to continue..." _ || true
}

usage() {
        cat <<'EOF'
Usage:
    bash install.sh                 Interactive menu
    bash install.sh -a              Silent standard install
    bash install.sh -A              Silent addons install
    bash install.sh -r              Silent uninstall
    bash install.sh -U -a           Silent standard update
    bash install.sh -U -A           Silent addons update

Options:
    -a, --install-standard  Install in standard mode
    -A, --install-addon     Install in the addons folder
    -r, --uninstall         Uninstall
    -U, --update            Update (combine with -a or -A to select a mode)
    -h, --help              Show this help

Set GMOD_DIR to the full garrysmod folder path if Steam detection cannot find it.
EOF
}

find_gmod() {
    local root library candidate
    local -a steam_roots=()

    if [[ -n "${STEAM_DIR:-}" ]]; then
        steam_roots+=("$STEAM_DIR")
    fi
    steam_roots+=(
        "$HOME/.steam/steam"
        "$HOME/.steam/root"
        "$HOME/.local/share/Steam"
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
        "/usr/lib/steam"
        "/usr/share/steam"
    )

    for root in "${steam_roots[@]}"; do
        [[ -d "$root" ]] || continue
        candidate="$root/steamapps/common/GarrysMod/garrysmod"
        if [[ -d "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi

        if [[ -f "$root/steamapps/libraryfolders.vdf" ]]; then
            while IFS= read -r library; do
                candidate="$library/steamapps/common/GarrysMod/garrysmod"
                if [[ -d "$candidate" ]]; then
                    printf '%s\n' "$candidate"
                    return 0
                fi
            done < <(sed -nE 's/^[[:space:]]*"path"[[:space:]]*"([^"]+)".*/\1/p' \
                "$root/steamapps/libraryfolders.vdf")
        fi
    done

    return 1
}

prompt_for_gmod() {
    local detected="" candidate answer

    detected="$(find_gmod || true)"
    if [[ -n "$detected" ]]; then
        printf 'Found Garry\x27s Mod at: %s\n' "$detected" >&2
        read -r -p "Use this folder? [Y/n] " answer || true
        if [[ ! "$answer" =~ ^[Nn]$ ]]; then
            printf '%s\n' "$detected"
            return 0
        fi
    else
        printf 'Could not find Garry\x27s Mod automatically.\n' >&2
    fi

    while true; do
        read -r -p "Enter the full path to the garrysmod folder: " candidate || return 1
        candidate="${candidate/#\~/$HOME}"
        if [[ -d "$candidate" && "${candidate%/}" == */garrysmod ]]; then
            (cd -- "$candidate" && pwd -P)
            return 0
        fi
        printf 'That folder does not exist or is not named garrysmod. Try again.\n' >&2
    done
}

resolve_gmod_silent() {
    local candidate="${GMOD_DIR:-}"

    if [[ -z "$candidate" ]]; then
        candidate="$(find_gmod || true)"
    fi
    candidate="${candidate/#\~/$HOME}"

    if [[ -z "$candidate" ]]; then
        printf 'Could not find Garry\x27s Mod. Set GMOD_DIR to its garrysmod folder and retry.\n' >&2
        return 1
    fi
    if [[ ! -d "$candidate" || "${candidate%/}" != */garrysmod ]]; then
        printf 'GMOD_DIR must point to an existing garrysmod folder: %s\n' "$candidate" >&2
        return 1
    fi

    (cd -- "$candidate" && pwd -P)
}

ensure_game_closed() {
    local silent="${1:-false}"

    if [[ "$silent" == true ]] && pgrep -af '(^|/)(hl2_linux|gmod_linux)( |$)' >/dev/null 2>&1; then
        printf 'Garry\x27s Mod is running. Close it before running this command.\n' >&2
        return 1
    fi

    while pgrep -af '(^|/)(hl2_linux|gmod_linux)( |$)' >/dev/null 2>&1; do
        printf '\nGarry\x27s Mod appears to be running. Close it before continuing.\n'
        pause_for_enter
    done
}

remove_files() {
    local gmod="$1" keep_data="${2:-false}" relative_path path child
    local -a files=(
        "html/main.html"
        "html/menu.html"
        "html/loading.html"
        "html/loading.css"
        "html/awesomium_global.css"
        "html/saves.html"
        "html/dupes.html"
        "html/css/menu/VanillaUI.css"
        "html/css/menu/Custom.css"
        "html/img/gradient.png"
        "html/fonts/Roboto-Regular.ttf"
        "html/fonts/Roboto-Medium.ttf"
        "html/fonts/Roboto-SemiBold.ttf"
        "html/fonts/tgnormal.ttf"
        "html/template/servers.html"
        "resource/SourceScheme.res"
        "resource/LoadingDialogGMod.res"
        "resource/LoadingDialogNoBanner.res"
        "resource/LoadingDialogNoBannerSingle.res"
        "resource/LoadingDialogVAC.res"
        "resource/loadingdialogerror.res"
        "resource/fonts/Roboto-Regular.ttf"
        "resource/fonts/Roboto-Medium.ttf"
        "resource/fonts/Roboto-SemiBold.ttf"
        "resource/fonts/tgnormal.ttf"
        "resource/fonts/vuo_barlow.ttf"
        "resource/fonts/vuo_quicksand.ttf"
        "lua/menu/loading.lua"
        "lua/menu/errors.lua"
        "lua/menu/mount/vgui/workshop.lua"
        "lua/menu/problems/problems_pnl.lua"
        "lua/menu/openurl.lua"
        "lua/autorun/client/spawnmenu_theme.lua"
        "workshop/materials/console/background01.vtf"
        "workshop/materials/console/background01_widescreen.vtf"
        "workshop/materials/console/startup_loading.vtf"
    )

    for relative_path in "${files[@]}"; do
        path="$gmod/$relative_path"
        if [[ -f "$path" || -L "$path" ]]; then
            rm -f -- "$path"
            printf '  Removed %s\n' "$relative_path"
        fi
    done

    for relative_path in "workshop/materials/console" "workshop/materials" "workshop"; do
        rmdir -- "$gmod/$relative_path" 2>/dev/null || true
    done

    path="$gmod/addons/Vanilla_UI_StartupScreen"
    if [[ -e "$path" ]]; then
        rm -rf -- "$path"
        printf '  Removed addons/Vanilla_UI_StartupScreen\n'
    fi

    path="$gmod/addons/garrysmod"
    if [[ -d "$path" ]]; then
        if [[ "$keep_data" == true ]]; then
            while IFS= read -r -d '' child; do
                case "${child##*/}" in
                    materials|sound) ;;
                    *) rm -rf -- "$child" ;;
                esac
            done < <(find "$path" -mindepth 1 -maxdepth 1 -type d -print0)
            find "$path" -mindepth 1 -maxdepth 1 ! -type d -exec rm -f -- {} +
        else
            rm -rf -- "$path"
        fi
        if [[ "$keep_data" == true ]]; then
            printf '  Removed addons/garrysmod mod files (user data kept)\n'
        else
            printf '  Removed addons/garrysmod\n'
        fi
    fi

    if [[ "$keep_data" == true ]]; then
        return
    fi

    for relative_path in \
        "materials/vuo_backgrounds" \
        "materials/vuo_fonts" \
        "sound/vuo_music" \
        "sound/vuo_sounds"; do
        path="$gmod/$relative_path"
        if [[ -e "$path" ]]; then
            rm -rf -- "$path"
            printf '  Removed %s\n' "$relative_path"
        fi
    done
}

install_or_update() {
    local action="$1" mode="$2" gmod="$3" silent="${4:-false}"
    local extracted src candidate item name subdir destination

    ensure_game_closed "$silent"
    if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
        printf 'This script requires curl and unzip. Install them with your package manager.\n' >&2
        return 1
    fi

    TMP_DIR="$(mktemp -d)"
    printf '\nDownloading Vanilla UI+ %s...\n' "$VERSION"
    curl -fL --retry 2 --output "$TMP_DIR/$ARCHIVE" "$BRANCH_ARCHIVE_URL"

    extracted="$TMP_DIR/extracted"
    mkdir -p -- "$extracted"
    unzip -q "$TMP_DIR/$ARCHIVE" -d "$extracted"

    src=""
    if [[ -d "$extracted/garrysmod" ]]; then
        src="$extracted/garrysmod"
    else
        for candidate in "$extracted"/*/garrysmod; do
            if [[ -d "$candidate" ]]; then
                src="$candidate"
                break
            fi
        done
    fi
    if [[ -z "$src" ]]; then
        for candidate in "$extracted"/*; do
            if [[ -d "$candidate" ]]; then
                src="$candidate"
                break
            fi
        done
        [[ -n "$src" ]] || src="$extracted"
    fi

    if [[ "$action" == update ]]; then
        printf '\nRemoving previous mod files (keeping user data)...\n'
        remove_files "$gmod" true
    fi

    printf '\nInstalling...\n'
    if [[ "$mode" == addon ]]; then
        destination="$gmod/addons/garrysmod"
        mkdir -p -- "$destination"
        for item in "$src"/*; do
            [[ -e "$item" ]] || continue
            name="${item##*/}"
            case "$name" in
                html|lua|materials|resource|sound) ;;
                *) continue ;;
            esac
            cp -a -- "$item" "$destination/"
        done
        for subdir in addons workshop; do
            if [[ -d "$src/$subdir" ]]; then
                mkdir -p -- "$gmod/$subdir"
                cp -a -- "$src/$subdir/." "$gmod/$subdir/"
            fi
        done
        printf 'Done. Installed as an addon to:\n%s\n' "$destination"
    else
        for item in "$src"/*; do
            [[ -e "$item" ]] || continue
            name="${item##*/}"
            case "$name" in
                addons|html|lua|materials|resource|sound|workshop) cp -a -- "$item" "$gmod/" ;;
            esac
        done
        printf 'Done. Installed to:\n%s\n' "$gmod"
    fi
    printf '\nLaunch Garry\x27s Mod to see your new menu.\n'
}

uninstall() {
    local gmod="$1" silent="${2:-false}" answer
    ensure_game_closed "$silent"
    printf '\nThis removes the mod files. Verify the game files in Steam afterwards\n'
    printf 'to restore any original Garry\x27s Mod files that were replaced.\n\n'
    if [[ "$silent" != true ]]; then
        read -r -p "Continue? [y/N] " answer || true
        [[ "$answer" =~ ^[Yy]$ ]] || return 0
    fi

    printf '\nRemoving files from %s\n' "$gmod"
    remove_files "$gmod"
    printf '\nMod files removed. Verify Garry\x27s Mod\x27s files in Steam to restore originals.\n'
}

run_silent() {
    local install_mode="" request_update=false request_uninstall=false
    local action mode gmod argument

    while (($#)); do
        argument="$1"
        shift
        case "$argument" in
            -a|--install-standard)
                [[ -z "$install_mode" ]] || { printf 'Choose only one install mode.\n' >&2; usage >&2; return 2; }
                install_mode=standard
                ;;
            -A|--install-addon)
                [[ -z "$install_mode" ]] || { printf 'Choose only one install mode.\n' >&2; usage >&2; return 2; }
                install_mode=addon
                ;;
            -U|--update) request_update=true ;;
            -r|--uninstall) request_uninstall=true ;;
            -h|--help) usage; return 0 ;;
            *) printf 'Unknown option: %s\n' "$argument" >&2; usage >&2; return 2 ;;
        esac
    done

    if [[ "$request_uninstall" == true ]]; then
        if [[ "$request_update" == true || -n "$install_mode" ]]; then
            printf 'Uninstall cannot be combined with install or update options.\n' >&2
            usage >&2
            return 2
        fi
        action=uninstall
    elif [[ "$request_update" == true ]]; then
        if [[ -z "$install_mode" ]]; then
            printf 'Updates require a mode: combine -U with -a or -A.\n' >&2
            usage >&2
            return 2
        fi
        action=update
        mode="$install_mode"
    elif [[ -n "$install_mode" ]]; then
        action=install
        mode="$install_mode"
    else
        printf 'Choose an install, update, or uninstall option.\n' >&2
        usage >&2
        return 2
    fi

    gmod="$(resolve_gmod_silent)" || return 1
    if [[ "$action" == uninstall ]]; then
        uninstall "$gmod" true
    else
        install_or_update "$action" "$mode" "$gmod" true
    fi
}

main() {
    local choice action mode gmod answer

    if (($#)); then
        run_silent "$@"
        return $?
    fi

    while true; do
        printf '\nVanilla UI+ %s\n' "$VERSION"
        printf 'github.com/qudeowl/vanilla-ui-overhaul\n\n'
        printf '  1. Install\n  2. Update\n  3. Uninstall (Reset To Default)\n  4. Exit\n'
        read -r -p "Select an option: " choice || return 0

        case "$choice" in
            1) action=install ;;
            2)
                printf '\nUpdate removes files from previous versions, then installs v1.4.1b.\n'
                printf 'Settings, music, sounds, backgrounds and fonts are kept.\n'
                read -r -p "Continue? [y/N] " answer || true
                [[ "$answer" =~ ^[Yy]$ ]] || continue
                action=update
                ;;
            3)
                gmod="$(prompt_for_gmod)" || continue
                uninstall "$gmod"
                continue
                ;;
            4) return 0 ;;
            *) continue ;;
        esac

        printf '\nChoose your installation method:\n'
        printf '  1. Standard: install directly into the garrysmod folder\n'
        printf '  2. Addons Folder: install under addons/garrysmod\n'
        printf '  3. Back\n'
        read -r -p "Select an option: " choice || return 0
        case "$choice" in
            1) mode=standard ;;
            2) mode=addon ;;
            *) continue ;;
        esac

        gmod="$(prompt_for_gmod)" || continue
        install_or_update "$action" "$mode" "$gmod"
    done
}

main "$@"