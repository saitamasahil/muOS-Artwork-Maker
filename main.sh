#!/bin/bash

# Check for required dependencies
command -v magick >/dev/null 2>&1 || {
  zenity --error --title="Dependency Missing" --text="ImageMagick (magick command) is required but not installed. Please install it and try again."
  exit 1
}

command -v zenity >/dev/null 2>&1 || {
  echo "Zenity is required but not installed. Please install it and try again."
  exit 1
}

# Step 1: Select the base image
base_image=$(zenity --file-selection --title="Select the Base Image" --file-filter="Images | *.png *.jpg *.jpeg")
if [[ -z "$base_image" || ! -f "$base_image" ]]; then
  zenity --error --title="Error" --text="No valid base image selected. Exiting."
  exit 1
fi

# Rename the base image to base.png
cp "$base_image" base.png

# Step 2: Select the logo/icon/boxart
logo_image=$(zenity --file-selection --title="Select the Logo/Icon/Boxart" --file-filter="Images | *.png *.jpg *.jpeg")
if [[ -z "$logo_image" || ! -f "$logo_image" ]]; then
  zenity --error --title="Error" --text="No valid logo/icon/boxart selected. Exiting."
  exit 1
fi

# Rename the logo/icon/boxart to wheel.png
cp "$logo_image" wheel.png

# Step 3: Ask for the output file name
output=$(zenity --entry --title="Output File Name" --text="Enter the name for the output file:")
if [[ -z "$output" ]]; then
  zenity --error --title="Error" --text="No output file name provided. Exiting."
  exit 1
fi

# Automatically add .png extension if not provided
if [[ ! "$output" =~ \.png$ ]]; then
  output="${output}.png"
fi

# Ensure the output folder exists
output_dir="output"
mkdir -p "$output_dir"

# Full output path
output_path="${output_dir}/${output}"

# Step 4: Ask the user to select a resolution
resolution=$(zenity --list --title="Select Resolution" \
  --text="Choose the resolution for your output:" \
  --radiolist \
  --column="Select" --column="Resolution" --column="Description" \
  TRUE "320x240" "QVGA (4:3)" \
  FALSE "480x320" "3:2" \
  FALSE "640x480" "VGA (4:3)" \
  FALSE "720x480" "3:2" \
  FALSE "800x480" "16:9" \
  FALSE "1280x800" "16:10" \
  --width=400 --height=500)  # Adjust width and height values here

if [[ -z "$resolution" ]]; then
  zenity --error --title="Error" --text="No resolution selected. Exiting."
  exit 1
fi

# Set width, height, and wheel size based on resolution
case $resolution in
  "320x240") width=320; height=240; wheel_size=75 ;;
  "480x320") width=480; height=320; wheel_size=100 ;;
  "640x480") width=640; height=480; wheel_size=150 ;;
  "720x480") width=720; height=480; wheel_size=160 ;;
  "800x480") width=800; height=480; wheel_size=170 ;;
  "1280x800") width=1280; height=800; wheel_size=250 ;;
  *) 
    zenity --error --title="Error" --text="Invalid resolution selected. Exiting."
    exit 1
    ;;
esac

# Step 5: Crop the base image to the selected resolution (center crop)
magick base.png -resize ${width}x${height}^ -gravity center -crop ${width}x${height}+0+0 +repage temp_base.png

# Step 6: Apply opacity to the cropped base image
magick temp_base.png -gravity center -background none -extent ${width}x${height} -channel A -evaluate multiply 0.5 temp_base_opacity.png

# Step 7: Apply the mask to the base image
mask="mask/3px_dither.png"
if [[ ! -f "$mask" ]]; then
  zenity --error --title="Error" --text="Mask file not found at '$mask'. Please ensure the mask file exists at mask/3px_dither.png."
  exit 1
fi

magick temp_base_opacity.png "$mask" -alpha on -compose DstIn -composite masked_base.png

# Step 8: Ask if user wants to add shadow to the logo/icon/boxart
add_shadow=$(zenity --question --title="Add Shadow" --text="Do you want to add a shadow to the Logo/Icon/Boxart?")
if [[ $? -eq 0 ]]; then
  # Add shadow to the wheel image
  magick wheel.png -resize ${wheel_size}x${wheel_size} \
    -alpha set -background none \
    \( +clone -background black -shadow 50x5+8+8 \) \
    +swap -background none -layers merge \
    wheel_with_shadow.png
else
  # No shadow, just resize the wheel image
  magick wheel.png -resize ${wheel_size}x${wheel_size} \
    -alpha set -background none \
    wheel_with_shadow.png
fi

# Step 9: Composite the wheel onto the masked base image
magick masked_base.png wheel_with_shadow.png \
  -gravity southeast -geometry +20+20 -composite "$output_path"

# Step 10: Cleanup temporary files
rm temp_base.png temp_base_opacity.png masked_base.png wheel_with_shadow.png

# Cleanup the renamed PNG files (base.png and wheel.png)
rm base.png wheel.png

# Output success message
zenity --info --title="Success" --text="Artwork generated successfully: $output_path"