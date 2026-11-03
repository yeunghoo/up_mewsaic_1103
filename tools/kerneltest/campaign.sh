#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
clang -fobjc-arc -fmodules -fmodules-cache-path=/tmp/mewsaic-modules \
  -framework Foundation -I loop_miao/Game \
  loop_miao/Game/MCLevel.m loop_miao/Game/MCBoard.m tools/kerneltest/campaign.m \
  -o /tmp/mewsaic-campaign-test
/tmp/mewsaic-campaign-test
