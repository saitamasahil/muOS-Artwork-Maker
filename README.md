
# muOS Artwork Scraper (Manual Version)

## Description
This script allows users to manually scrape artwork for muOS systems like NES, SNES, and more. It is particularly useful when the automated tool Scrappy (https://github.com/gabrielfvale/scrappy) fails to generate the required 3px dither art. The script requires the user to provide `screenshot.png` (the base image) and `wheel.png` (the logo or box image of a ROM/game).

While Scrappy can generate artwork automatically for many systems, this script offers manual intervention when Scrappy does not work as expected. Additionally, you can use this script to generate artwork for a system itself.

## Requirements
- **ImageMagick**: Ensure that the `magick` command is available on your system. You can install it with the following:
  - For Linux (Ubuntu/Debian): `sudo apt-get install imagemagick`
  - For macOS: `brew install imagemagick`
  
## How to Use
1. **Prepare Your Files**:
   - `screenshot.png`: This will be your base image for the artwork.
   - `wheel.png`: This is the logo or box image of a ROM/game. You can find icons on sites like [Flaticon](https://www.flaticon.com/).

2. **Run the Script**:
   - Download the script to your local machine.
   - Place `screenshot.png`, `mask/3px_dither.png`, and `wheel.png` in the same directory as the script.
   - Run the script and follow the prompts.
   - The output file will be generated as a PNG image.

3. **Saving Output**:
   After generating the artwork, you must place the output file in the correct directory:
   - For a game, ROM, or system, the output file should be placed in the following path:
     ```
     /mnt/mmc/MUOS/info/catalogue/<system-name>/box
     ```
   - If you generated artwork for a specific system, place the file in:
     ```
     /mnt/mmc/MUOS/info/catalogue/<system-folder>/box
     ```
   - The output PNG file name should match the name of the game, ROM, or system folder.

4. **Note on Wheel PNG**:
   - `wheel.png` can be a logo or a box art image of a ROM/game. If you want to use the wheel as an icon, you can use [Flaticon](https://www.flaticon.com/) to find icons. Alternatively, you can use a box art image of the ROM/game.

## Why Use This Script?
- **Manual Artwork Generation**: If Scrappy fails to generate the 3px dither art, this script lets you manually create artwork for your muOS systems.
- **Customization**: You can adjust the `wheel.png` and `screenshot.png` to generate artwork tailored to your needs.

## License
This script is licensed under the GPLv3 License. See the [LICENSE](LICENSE) file for details.