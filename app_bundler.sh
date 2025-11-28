#!/usr/bin/env bash

# app_bundler.sh
# Before running the script ensure its executable: chmod +x app_bundler.sh (This will make the script executable)
# Usage: ./app_bundler.sh <APP_NAME> <BUNDLE_ID> <VERSION> <EXECUTABLE_PATH> <ICON_PATH>
# Example: ./app_bundler.sh CoolApp com.example.example_app 1.0 ./build/app ./ASSETS/icon.png

set -euo pipefail

if [ $# -ne 5 ]; then
  echo "Usage: $0 <APP_NAME> <BUNDLE_ID> <VERSION> <EXECUTABLE_PATH> <ICON_PATH>"
  exit 1
fi

APP_NAME="$1"
BUNDLE_ID="$2"
VERSION="$3"
EXECUTABLE_PATH="$4"
ICON_SOURCE="$5"

APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [[ "${ICON_SOURCE}" != *.png ]]; then
  echo "Error: Only .png files are supported."
  exit 1
fi

ICON_BASENAME=$(basename "${ICON_SOURCE}" .png)
TEMP_ICONSET="/tmp/${ICON_BASENAME}.iconset"
mkdir -p "${TEMP_ICONSET}"

echo "Generating iconset from ${ICON_SOURCE}..."

# resize image using sips
generate_icon() {
    local size=$1
    local filename=$2
    sips -z $size $size "${ICON_SOURCE}" --out "${TEMP_ICONSET}/${filename}" > /dev/null
}

# generate standard icon sizes
generate_icon 16 "icon_16x16.png"
generate_icon 32 "icon_16x16@2x.png"
generate_icon 32 "icon_32x32.png"
generate_icon 64 "icon_32x32@2x.png"
generate_icon 128 "icon_128x128.png"
generate_icon 256 "icon_128x128@2x.png"
generate_icon 256 "icon_256x256.png"
generate_icon 512 "icon_256x256@2x.png"
generate_icon 512 "icon_512x512.png"
generate_icon 1024 "icon_512x512@2x.png"
generate_icon 1024 "icon_1024x1024.png"

echo "Converting iconset to .icns..."
if iconutil -c icns "${TEMP_ICONSET}" -o "${RESOURCES_DIR}/${ICON_BASENAME}.icns"; then
    echo "Icon conversion successful."
    FINAL_ICON_NAME="${ICON_BASENAME}.icns"
else
    echo "Error: iconutil failed."
    exit 1
fi
rm -rf "${TEMP_ICONSET}"

# Info.plist
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>${FINAL_ICON_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.10.0</string>
</dict>
</plist>
EOF

echo "Built ${APP_DIR} successfully."
