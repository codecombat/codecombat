#!/bin/sh

# Creates base64 strings from SVG files, which can easily be used inline in sass files.
# Useful to completely remove loading for small SVG's that need to be on the page ASAP.
# This has been used to fix image loading order for buttons in TutorialPlayComponent.vue.
#
# Step by step guide:
#
# 0) Install the svgo package: npm install -g svgo
# 1) Generate base64 images, for example for a folder: svgo -f path/to/svg/folder -o path/to/output --datauri base64
# 2) Put all the file names (without .svg) in the SVG_FILENAMES array
# 3) Run this script
# 4) Look for a new file in this folder named like the string in OUTPUT_SASS_FILE, like: images.sass
# 5) Add the base64 strings to the repo, like: ozaria/site/styles/play/images.sass
# 6) Import the new sass file where you want the inline, like: @import "ozaria/site/styles/play/images"
# 7) Use the name of the original SVG file as the name for the base64 string, like: background-image: url($ActiveL)
#
# Step by step example:
#
# 1) Convert a Ozaria level SVG image: svgo ../app/assets/images/ozaria/level/ActiveL.svg -o . --datauri base64 or all in the folder: svgo -f ../app/assets/images/ozaria/level -o . --datauri base64
# 2) declare -a SVG_FILENAMES=("ActiveL")
# 3) ./convert_svg_to_base64.sh
# 4) images.sass now has $ActiveL: 'base64 string here'
# 5) Move images.sass to some style folder
# 6) Import it in some Vue component or pug template
# 7) Use the new base64 string as a background image for a button with: background-image: url($ActiveL)


OUTPUT_SASS_FILE="images.sass"

declare -a SVG_FILENAMES=(
  "ActiveL"
  "ActiveR"
  "Button"
  "ButtonHover"
  "ButtonInactive"
  "CloseButton"
  "CloseButton_Hover"
  "CloseButton_Inactive"
  "HoverL"
  "HoverR"
  "InactiveL"
  "InactiveR"
  "PointerCenter"
  "StartButton"
  "StartButton_Hover"
  "ThangTypeHUD_Container"
  "refresh"
)

for i in "${SVG_FILENAMES[@]}"
do
  printf "\$$i: \"" >> $OUTPUT_SASS_FILE
  cat `echo $i`.svg >> $OUTPUT_SASS_FILE
  echo "\"\n" >> $OUTPUT_SASS_FILE
done
