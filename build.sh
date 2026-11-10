#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="CaffeinateBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
swiftc -O -target arm64-apple-macosx13.0 main.swift -o "$APP/Contents/MacOS/CaffeinateBar"
codesign --force --sign - "$APP"
echo "OK: $(pwd)/$APP"
