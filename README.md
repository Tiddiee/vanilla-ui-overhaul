# Vanilla UI+

A redesigned main menu. Choose your own fonts, backgrounds, music and layout.

Test branch build: `v1.4.1b`. The automatic installers on this branch download the branch snapshot; the published latest release remains v1.4.

> Bug reports welcome via [Issues](https://github.com/qudeowl/vanilla-ui-overhaul/issues).

## Installation

**Linux (Proton) setup**

Complete these steps before installing Vanilla UI+:

1. In Steam, open Garry's Mod **Properties > Betas** and select the `x86-64` branch.
2. Open **Properties > Compatibility**, enable **Force the use of a specific Steam Play compatibility tool**, and select **Proton Experimental**.
3. Run `bash install.sh`. Accept the default **Yes** when asked to run [GModPatchTool](https://github.com/solsticegamestudios/GModPatchTool/releases); the script downloads, verifies, and runs it before installing Vanilla UI+.
4. Choose **Standard** mode for full UI support; the add-ons method may not load all interface files.

**Automatic (Recommended)**

1. On Windows, run `install_update_uninstall_vanilla_ui.bat`. On Linux, run `bash install.sh` from a terminal (requires `curl` and `unzip`)
2. Select your preferred setup when prompted
3. The script finds your GMod folder automatically or asks for its path, then installs the files
4. Launch Garry's Mod

> Make sure the game is closed before running the installer.

**Silent Linux commands**

Run the script with one of these options to skip the interactive menus:

```sh
bash install.sh -a -P    # Standard install, run GModPatchTool first
bash install.sh -A       # Addons-folder install
bash install.sh -U -a -P # Standard update, run GModPatchTool first
bash install.sh -U -A    # Addons-folder update
bash install.sh -r       # Uninstall
```

Interactive installs ask whether to download and run GModPatchTool first (default: yes). Silent install/update commands run it when `-P` or `--patch-gmod` is supplied. The Linux executable is downloaded from its official latest release and checksum-verified before it runs. The script detects the Steam library automatically. If it cannot find Garry's Mod, set `GMOD_DIR` to the full `garrysmod` folder path. Silent commands fail rather than prompt if the game is running or its folder cannot be found.

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

1. Run the Windows `.bat` or Linux `.sh` script
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
