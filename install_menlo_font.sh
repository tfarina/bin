#!/bin/bash

font_list=("Menlo-Bold.ttf" \
           "Menlo-BoldItalic.ttf" \
	   "Menlo-Italic.ttf" \
           "Menlo-Regular.ttf")

for file in ${font_list[*]}; do
  echo $file  
done

sudo mkdir -p /usr/share/fonts/truetype/menlo

cd fonts/truetype/menlo

for file in ${font_list[*]}; do
  sudo chown root:root "${file}"
  sudo cp "${file}" /usr/share/fonts/truetype/menlo
done

# Clear and regenerate your font cache and indexes with the following command:
# fc-cache -f -v
#
# You can confirm that the fonts are installed with the following command:
# fc-list | grep Menlo
