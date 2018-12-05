# Mod Installer for BnSBuddy
Installs Mods into BnsBuddy's Mod folder.

Automatically creates a very basic description, if one is missing.
Automatically creates a mod folder for .upk or .umap files.

## Requirements
- Make sure it is ***NOT*** in a network shared folder! **IT WON'T WORK!**
- Make sure you can have Administrator access (Windows Vista and up) before you try to run this code.
- Make sure the game is closed completely.
- To make it easier in the future, make sure the game is installed in a path existing in the registry keys:
    - `HKEY_LOCAL_MACHINE\SOFTWARE\NCWest\BnS` (value `BaseDir`) for 32-bit Windows
    - `HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\NCWest\BnS` (value `BaseDir`) for 64-bit Windows
- To make even easier, you can place this file inside BnSBuddy's folder (will read `Settings.ini` when available)
- You ***MUST*** have [7-Zip](https://www.7-zip.org/), [Winrar](https://www.win-rar.com/) or [WinZip](https://www.winzip.com/) with the [Command line](https://www.winzip.com/win/en/downcl.html) addon for it to work with .zip, .7z or .rar files. If you get errors, try updating it first.


## How to use?
1. Download the mods you need
    You can download mods in https://www.bnsbuddy.com/, https://www.reddit.com/r/BladeAndSoulMods/ or https://www.nexusmods.com/bladeandsoul/
2. Download the `mod_installer.bat` file
3. Right-click and click on "Run as Administrator" (or similar for your language)
    Update: automatically forces to start as Administrator.
4. Press M to pick a folder to install the mod into, or press I to install the mod
5. If BnSBuddy is open, refresh the "Mod Manager" list and install the mod
    Update: you may install with the tool as well

## How to revert?
Uninstall the mod in BnSBuddy and remove the folder from BnSBuddy's mod folder.

## When I try to run, I get `<xyz>`
If you have any issues, don't hesitate to contact me (@cupid.rips.hearts#3337) on the BnS Buddy Discord server, in the `#support` channel.

<hr>

# Disclaimer
I guarantee that the file works for me and me only. Different environment may behave differently.

I am **NOT** responsible for **ANY** damage or data loss from using this. **You are the only responsible for making your own backups**, if you want to do so.

Before installing, **YOU are responsible** for checking if the mod path is correct.
