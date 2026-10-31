#!/bin/zsh
# Derler ve ~/Applications/GeriSayim.app olarak kurar.
set -e
cd "$(dirname "$0")"
APP="$HOME/Applications/GeriSayim.app"

pkill -x GeriSayim 2>/dev/null || true
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -swift-version 5 -o "$APP/Contents/MacOS/GeriSayim" main.swift

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>GeriSayim</string>
  <key>CFBundleDisplayName</key><string>Geri Sayım</string>
  <key>CFBundleIdentifier</key><string>com.berfu.gerisayim</string>
  <key>CFBundleExecutable</key><string>GeriSayim</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"
open "$APP"
echo "Kuruldu: $APP"
