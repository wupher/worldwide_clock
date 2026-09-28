#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# The checked-in Xcode project builds without XcodeGen. Regenerate it only after editing project.yml.
xcodebuild -project WorldwideClock.xcodeproj -scheme WorldwideClock \
  -configuration Release -derivedDataPath .build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
echo "Built: $PWD/.build/Build/Products/Release/WorldwideClock.app"
