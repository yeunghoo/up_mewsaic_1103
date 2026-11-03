#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
clang -fobjc-arc -fmodules -fmodules-cache-path=/tmp/mewsaic-modules \
  -framework Foundation -I loop_miao/Game -I loop_miao/Game/Models \
  loop_miao/Game/MCLevel.m loop_miao/Game/MCBoard.m loop_miao/Game/Models/MCVolleyTimeline.m tools/kerneltest/volley.m \
  -o /tmp/mewsaic-volley-test
/tmp/mewsaic-volley-test
