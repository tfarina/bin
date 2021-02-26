#!/bin/sh

sudo mkdir -p /usr/share/fonts/truetype/hack

cd /tmp
wget -O hack-font.zip https://github.com/chrissimpkins/Hack/releases/download/v2.020/Hack-v2_020-ttf.zip
unzip -o hack-font.zip

for file in Hack-Bold.ttf Hack-BoldItalic.ttf Hack-Italic.ttf Hack-Regular.ttf; do
  sudo chown root:root "${file}"
  sudo mv "${file}" /usr/share/fonts/truetype/hack
done

# Clear and regenerate your font cache and indexes with the following command:
# fc-cache -f -v
#
# You can confirm that the fonts are installed with the following command:
# fc-list | grep Hack
