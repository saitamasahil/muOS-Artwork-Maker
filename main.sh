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
  FALSE "800x480" "WVGA (16:10)" \
  --width=400 --height=450)

if [[ -z "$resolution" ]]; then
  zenity --error --title="Error" --text="No resolution selected. Exiting."
  exit 1
fi

# Set width, height, and wheel size based on resolution
case $resolution in
"320x240")
  width=320
  height=240
  wheel_size=80
  x_offset=$((width / 33))
  ;;
"480x320")
  width=480
  height=320
  wheel_size=100
  x_offset=$((width / 28))
  ;;
"640x480")
  width=640
  height=480
  wheel_size=130
  x_offset=$((width / 28))
  ;;
"720x480")
  width=720
  height=480
  wheel_size=130
  x_offset=$((width / 7))
  ;;
"800x480")
  width=800
  height=480
  wheel_size=130
  x_offset=$((width / 43 * 10))
  ;;
*)
  zenity --error --title="Error" --text="Invalid resolution selected. Exiting."
  exit 1
  ;;
esac

# Adjust offsets for wheel positioning to ensure it's inside the boundaries
y_offset=$((height / 15)) # Adjusted for 15% of height

# Step 5: Ask the user to select a crop gravity
crop_gravity=$(zenity --list --title="Select Crop Gravity" \
  --text="Choose the gravity for cropping the image:" \
  --radiolist \
  --column="Select" --column="Gravity" --column="Description" \
  TRUE "center" "Crop from the center (default)" \
  FALSE "north" "Crop from the top-center" \
  FALSE "south" "Crop from the bottom-center" \
  FALSE "west" "Crop from the left-center" \
  FALSE "east" "Crop from the right-center" \
  FALSE "northwest" "Crop from the top-left corner" \
  FALSE "northeast" "Crop from the top-right corner" \
  FALSE "southwest" "Crop from the bottom-left corner" \
  FALSE "southeast" "Crop from the bottom-right corner" \
  --width=450 --height=500)

if [[ -z "$crop_gravity" ]]; then
  zenity --error --title="Error" --text="No crop gravity selected. Exiting."
  exit 1
fi

# Step 6: Crop the base image to the selected resolution (based on gravity)
magick base.png -resize ${width}x${height}^ -gravity $crop_gravity -crop ${width}x${height}+0+0 +repage temp_base.png

# Step 7: Apply opacity to the cropped base image
magick temp_base.png -gravity center -background none -extent ${width}x${height} -channel A -evaluate multiply 0.5 temp_base_opacity.png

# Step 8: Apply the mask to the base image
mask="mask/3px_dither.png"
if [[ ! -f "$mask" ]]; then
  zenity --error --title="Error" --text="Mask file not found at '$mask'. Please ensure the mask file exists at mask/3px_dither.png."
  exit 1
fi

magick temp_base_opacity.png "$mask" -alpha on -compose DstIn -composite masked_base.png

# Step 9: Ask if user wants to add shadow to the logo/icon/boxart
add_shadow=$(zenity --question --title="Add Shadow" --text="Do you want to add a shadow to the Logo/Icon/Boxart?")
if [[ $? -eq 0 ]]; then
  magick wheel.png -resize ${wheel_size}x${wheel_size} \
    -alpha set -background none \
    \( +clone -background black -shadow 50x5+8+8 \) \
    +swap -background none -layers merge \
    wheel_with_shadow.png
else
  magick wheel.png -resize ${wheel_size}x${wheel_size} \
    -alpha set -background none \
    wheel_with_shadow.png
fi

# Step 10: Composite the wheel onto the masked base image
magick masked_base.png wheel_with_shadow.png \
  -gravity southeast -geometry +${x_offset}+${y_offset} -composite "$output_path"

# Step 11: Cleanup temporary files
rm temp_base.png temp_base_opacity.png masked_base.png wheel_with_shadow.png
rm base.png wheel.png

# Output success message
zenity --info --title="Success" --text="Artwork generated successfully: $output_path"