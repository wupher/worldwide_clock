#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/tests .build/test-module-cache
xcrun swiftc -swift-version 6 -module-cache-path .build/test-module-cache \
  Shared/City.swift App/TimeZoneService.swift Tests/ClockTests.swift \
  -o .build/tests/ClockTests
.build/tests/ClockTests
