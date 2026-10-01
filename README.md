# Vanilla UI+

A redesigned main menu. Choose your own fonts, backgrounds, music and layout.

> Bug reports welcome via [Issues](https://github.com/qudeowl/vanilla-ui-overhaul/issues).

## Installation

**Automatic (Recommended)**

1. Download `install_update_uninstall_vanilla_ui.bat` from the [latest release](https://github.com/qudeowl/vanilla-ui-overhaul/releases/latest) and run it
2. Select your preferred setup when prompted
3. The script finds your GMod folder automatically and installs the files
4. Launch Garry's Mod

> Make sure the game is closed before running the installer.

**Manual**

1. Download the zip from the [latest release](https://github.com/qudeowl/vanilla-ui-overhaul/releases/latest)
2. Extract and drop the `garrysmod` folder into `...\Steam\steamapps\common\GarrysMod`
> You're ready.

**Manual (Alternative)**
1. Download the zip from the [latest release](https://github.com/qudeowl/vanilla-ui-overhaul/releases/latest)
2. Extract and drop the `garrysmod` folder into `...\Steam\steamapps\common\GarrysMod\garrysmod\addons`
3. For the startup screen, move `addons\garrysmod\addons\Vanilla_UI_StartupScreen` to `...\garrysmod\addons` and `addons\garrysmod\workshop` to `...\garrysmod`
> The alternative installation method avoids modifying game files and reduces issues caused by official updates. However, some interface elements may be unavailable or may not work as expected, as they may be ignored by the game.

---

## Uninstall

**Automatic (Recommended)**

1. Run the .bat
2. Select > 3. Uninstall (Reset To Default)
3. Verify game files on Steam

**Manual**

1. Verify game files on Steam
2. Delete `...\garrysmod\addons\Vanilla_UI_StartupScreen` and `...\garrysmod\workshop\materials\console`
3. If you installed v1.0, also delete `spawnmenu_theme.lua` from `...\garrysmod\lua\autorun\client` if it exists

**Manual (Alternative)**

1. Go to `...\Steam\steamapps\common\GarrysMod\garrysmod\addons`
2. Delete the `garrysmod` and `Vanilla_UI_StartupScreen` folders
3. Delete `...\garrysmod\workshop\materials\console`
> Follow alternative steps only if you installed the mod using the alternative installation method.

---

## Credits

Inspired by [TuPiDAn](https://steamcommunity.com/sharedfiles/filedetails/?id=3599195211)'s Dark Main Menu, [Remedy](https://steamcommunity.com/id/voidcubes/myworkshopfiles/)'s Theme Engine and [Portal](https://store.steampowered.com/bundle/234/Portal_Bundle/)
