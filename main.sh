#!/bin/bash

# Check for required dependencies
command -v magick >/dev/null 2>&1 || {
  echo "ImageMagick (magick command) is required but not installed. Please install it and try again."
  exit 1
}

# Set file paths
screenshot="screenshot.png"
mask="mask/3px_dither.png"
wheel="wheel.png"

# Ask user for the output file name
read -p "Enter the output file name: " output

# Automatically add .png extension if not provided
if [[ ! "$output" =~ \.png$ ]]; then
  output="${output}.png"
fi

# Check if necessary files exist
if [[ ! -f "$screenshot" || ! -f "$mask" || ! -f "$wheel" ]]; then
  echo "Missing necessary files. Please ensure the following files are in the same folder as this script:"
  echo "1. screenshot.png"
  echo "2. mask/3px_dither.png"
  echo "3. wheel.png"
  exit 1
fi

# Step 1: Crop the screenshot to 4:3 aspect ratio (center crop)
magick "$screenshot" -resize 640x480^ -gravity center -crop 640x480+0+0 +repage temp_screenshot.png

# Step 2: Apply opacity to the cropped screenshot
magick temp_screenshot.png -gravity center -background none -extent 640x480 -channel A -evaluate multiply 0.5 temp_screenshot_opacity.png

# Step 3: Apply the mask to the screenshot
magick temp_screenshot_opacity.png "$mask" -alpha on -compose DstIn -composite masked_screenshot.png

# Step 4: Ask if user wants to add shadow to the wheel icon
read -p "Do you want to add a shadow to the wheel icon? (Y/n): " add_shadow

if [[ "$add_shadow" =~ ^[Yy]$ ]]; then
  # Add shadow to the wheel image
  magick "$wheel" -resize 150x150 \
    -alpha set -background none \
    \( +clone -background black -shadow 50x5+8+8 \) \
    +swap -background none -layers merge \
    wheel_with_shadow.png
else
  # No shadow, just resize the wheel image
  magick "$wheel" -resize 150x150 \
    -alpha set -background none \
    wheel_with_shadow.png
fi

# Step 5: Composite the wheel onto the masked screenshot
# Position the wheel at the bottom-right corner with a small offset
magick masked_screenshot.png wheel_with_shadow.png \
  -gravity southeast -geometry +20+20 -composite "$output"

# Cleanup temporary files
rm temp_screenshot.png temp_screenshot_opacity.png masked_screenshot.png wheel_with_shadow.png

# Output success message
echo "Artwork generated successfully: $output"