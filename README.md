# Pet & Mount Summon Roulette

**Pet & Mount Summon Roulette** is a World of Warcraft addon that summons a random battle pet or mount based on its rarity across the playerbase. It uses data provided by [DataForAzeroth](https://www.dataforazeroth.com) to prioritize summoning items that are rarer, showing off your most unique collections.

## Features

- **Smart Summoning**: Summons mounts appropriate for your current location (Flying, Ground, Aquatic).
- **Rarity Weighted**: Rare mounts and pets have a higher chance of being selected.
- **Dynamic Grouping**: Automatically groups your collection into rarity tiers.
- **ChatMessage**: Announces the summoned companion and its rarity group in the chat.

## Installation

1. Copy the `PetMountSummonRoulette` folder to your World of Warcraft AddOns directory:
   `\World of Warcraft\_retail_\Interface\AddOns\`

## Usage

Use the following slash commands in-game:

- `/pmsrmount` - Summon a random mount based on rarity and current zone restrictions.
- `/pmsrpet` - Summon a random battle pet based on rarity.
- `/pmsrpetdismiss` - Dismiss the currently summoned pet.
- `/pmsrrefresh` - Manually refresh the internal database (useful if you learned a new mount/pet while playing).
- `/pmsrdebug` - Print debug information about the current grouping and environment.

## Updating Rarity Data

This addon relies on external data to determine rarity. To update the rarity percentages with the latest data:

1. **Run the Updater**:
   - You need Python installed on your system.
   - Open a terminal/command prompt in the addon directory.
   - Run the script:
     ```bash
     python3 convert_data.py
     ```
   - The script will automatically:
     - Check [DataForAzeroth](https://www.dataforazeroth.com) for the latest data versions.
     - Download the JSON files (showing the source filename for verification).
     - Update `PetMountSummonRouletteData.lua` with the new values.

2. **Reload WoW**:
   - If WoW is running, type `/reload` to load the new data.

## Release Process

This addon uses an automated release workflow via GitHub. To publish a new version to CurseForge:

1. **Commit Changes**: Ensure all your changes (including the updated `PetMountSummonRouletteData.lua` and `.toc` version number) are committed.
2. **Tag the Release**: Create a new git tag matching the version number (e.g., `1.3`).
   ```bash
   git tag v1.3
   git push origin v1.3
   ```
3. **Automation**: The GitHub Action will detect the new tag, package the addon, and upload it to CurseForge automatically.

4. **Maintain on curseforge.com** The addon can be maintained  on [curseforge.com](https://authors.curseforge.com/#/projects/1189388/general).