#!/usr/bin/env bash

# check args
if [ -z "${1}" ]; then
    echo "[!] Usage: packer.sh <ghidra_dir> [app_name]"
    exit 1;
fi;

if [ -n "${2}" ]; then
    if [ "${2}" == "Ghidra" ]; then
        echo "[!] app name must not be Ghidra"
        exit 1;
    fi

    if echo "${2}" | grep -q "[^a-zA-Z0-9_]"; then
        echo "[!] app name must be alphanumeric"
        exit 1;
    fi

    GHIDRA_APP_NAME=${2}
else
    GHIDRA_APP_NAME="ghidraRun"
fi;

GHIDRA_DIR="${GHIDRA_APP_NAME}.app/Contents/MacOS"

if [ -a "${GHIDRA_APP_NAME}.app" ]; then
    echo "[!] ${PWD}/${GHIDRA_APP_NAME}.app already exists :("
    exit 1;
fi;


mkdir -p "${GHIDRA_DIR}";
cp -r "${1}"/* "${GHIDRA_DIR}/" 
mv "${GHIDRA_DIR}/ghidraRun" "${GHIDRA_DIR}/${GHIDRA_APP_NAME}"
chmod +x "${GHIDRA_DIR}/${GHIDRA_APP_NAME}"

# create icon

if command -v convert >/dev/null 2>&1; then
    ICONSET_DIR="${GHIDRA_DIR}/${GHIDRA_APP_NAME}.iconset"
    mkdir -p "${ICONSET_DIR}"

    # Extract icons from .ico file
    convert "${GHIDRA_DIR}/support/ghidra.ico" "${ICONSET_DIR}/icon_%03d.png"

    # Rename and resize icons
    mv "${ICONSET_DIR}/icon_000.png" "${ICONSET_DIR}/icon_16x16.png"
    mv "${ICONSET_DIR}/icon_001.png" "${ICONSET_DIR}/icon_24x24.png"
    mv "${ICONSET_DIR}/icon_002.png" "${ICONSET_DIR}/icon_32x32.png"
    mv "${ICONSET_DIR}/icon_003.png" "${ICONSET_DIR}/icon_48x48.png"
    mv "${ICONSET_DIR}/icon_004.png" "${ICONSET_DIR}/icon_64x64.png"
    mv "${ICONSET_DIR}/icon_005.png" "${ICONSET_DIR}/icon_128x128.png"
    mv "${ICONSET_DIR}/icon_006.png" "${ICONSET_DIR}/icon_256x256.png"
    mv "${ICONSET_DIR}/icon_007.png" "${ICONSET_DIR}/icon_512x512.png"

    # Create Retina versions
    convert "${ICONSET_DIR}/icon_16x16.png" -resize 32x32 "${ICONSET_DIR}/icon_16x16@2x.png"
    convert "${ICONSET_DIR}/icon_32x32.png" -resize 64x64 "${ICONSET_DIR}/icon_32x32@2x.png"
    convert "${ICONSET_DIR}/icon_128x128.png" -resize 256x256 "${ICONSET_DIR}/icon_128x128@2x.png"
    convert "${ICONSET_DIR}/icon_256x256.png" -resize 512x512 "${ICONSET_DIR}/icon_256x256@2x.png"
    convert "${ICONSET_DIR}/icon_512x512.png" -resize 1024x1024 "${ICONSET_DIR}/icon_512x512@2x.png"

    # Generate .icns file
    iconutil -c icns "${ICONSET_DIR}" -o "${ICONSET_DIR}/app.icns"

    # Move .icns file to the app's Resources directory
    mkdir -p "${GHIDRA_APP_NAME}.app/Contents/Resources"
    mv "${ICONSET_DIR}/app.icns" "${GHIDRA_APP_NAME}.app/Contents/Resources/app.icns"

    # Clean up
    rm -r "${ICONSET_DIR}"
else
    echo "[!] ImageMagick is not installed. Please install it to proceed with icon conversion."
    echo "brew install imagemagick"
    exit 1
fi

# create info.plist
cat <<EOL > "${GHIDRA_APP_NAME}.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${GHIDRA_APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${GHIDRA_APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.${GHIDRA_APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>${GHIDRA_APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>app</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOL

# move the app to Applications
if [ -d "/Applications/${GHIDRA_APP_NAME}.app" ]; then
    echo "[!] App already exists in /Applications/${GHIDRA_APP_NAME}.app"
    echo "replace it? [y/n] : Be Careful! This will delete the existing app."
    read -r replace
    if [ "${replace}" == "y" ]; then
        rm -rf "/Applications/${GHIDRA_APP_NAME}.app"
        mv "${GHIDRA_APP_NAME}.app" /Applications/
    else
        exit 1
    fi
else
    mv "${GHIDRA_APP_NAME}.app" /Applications/
fi

