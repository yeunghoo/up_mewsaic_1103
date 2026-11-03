#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p /tmp/mewsaic-daily-kernel
cp loop_miao/Content/campaign.json loop_miao/Content/daily.json /tmp/mewsaic-daily-kernel/
clang -DDEBUG=1 -fobjc-arc -fmodules -fmodules-cache-path=/tmp/mewsaic-modules -framework Foundation -I loop_miao/Game -I loop_miao/Game/Models loop_miao/Game/MCLevel.m loop_miao/Game/MCBoard.m loop_miao/Game/Models/MCVolleyTimeline.m loop_miao/Game/Models/MCGameSession.m loop_miao/Game/Models/MCDailyChallengeStore.m tools/kerneltest/daily.m -o /tmp/mewsaic-daily-kernel/check
/tmp/mewsaic-daily-kernel/check
