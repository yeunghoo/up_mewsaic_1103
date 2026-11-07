#!/usr/bin/env python3
"""Validate checked-in ad configuration against the official SKAN snapshot."""
import json
import plistlib
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
snapshot = json.loads((ROOT / 'docs/inmobi/skadnetworkids-2026-11-07.json').read_text())
expected = {row['skadnetwork_id'] for row in snapshot['skadnetwork_ids']}
info = plistlib.loads((ROOT / 'loop_miao/Info.plist').read_bytes())
actual = [item['SKAdNetworkIdentifier'] for item in info['SKAdNetworkItems']]
assert len(actual) == len(set(actual)), 'Duplicate SKAdNetwork identifiers'
assert expected <= set(actual), 'Missing official InMobi SKAdNetwork identifiers'
assert all(re.fullmatch(r'[a-z0-9]{10}\.skadnetwork', value) for value in actual)
# Xcode's Info editor may move this key into generated Info.plist build settings.
# Both sources are valid. Validate every app configuration, not just the XML file.
project = json.loads(subprocess.check_output([
    'plutil', '-convert', 'json', '-o', '-',
    str(ROOT / 'loop_miao.xcodeproj/project.pbxproj'),
]))
app_configs = [obj for obj in project['objects'].values()
              if obj.get('isa') == 'XCBuildConfiguration'
              and obj.get('buildSettings', {}).get('INFOPLIST_FILE') == 'loop_miao/Info.plist']
assert len(app_configs) == 2, 'Expected Debug and Release app configurations'
for configuration in app_configs:
    settings = configuration['buildSettings']
    usage = settings.get('INFOPLIST_KEY_NSUserTrackingUsageDescription') or info.get('NSUserTrackingUsageDescription')
    assert usage and usage.isascii() and len(usage) > 30, f'Missing English ATT text: {configuration["name"]}'
config = (ROOT / 'loop_miao/Game/Ads/MCAdConfiguration.m').read_text()
for value in ['ed31e775c4884238b53b017cb015bb7f', '10000871089', '10000871090', '10000871091']:
    assert value in config, f'Missing configuration: {value}'
print(f'InMobi configuration OK: {len(expected)} official SKAdNetwork IDs, English ATT, 3 placements.')
