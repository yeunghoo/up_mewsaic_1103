#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
clang -O2 -fobjc-arc -fmodules -fmodules-cache-path=/tmp/mewsaic-modules -framework Foundation -I loop_miao/Game -I loop_miao/Game/Models loop_miao/Game/MCLevel.m loop_miao/Game/MCBoard.m loop_miao/Game/Models/MCVolleyTimeline.m tools/kerneltest/volley_performance.m -o /tmp/mewsaic-volley-performance
/tmp/mewsaic-volley-performance
