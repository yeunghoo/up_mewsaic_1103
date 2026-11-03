#!/bin/bash
set -euo pipefail
umask 077
: "${IOS_CERTIFICATE_P12:?Missing certificate secret}"
: "${IOS_CERTIFICATE_PASSWORD?Missing certificate password secret}"
: "${IOS_PROVISIONING_PROFILE:?Missing provisioning profile secret}"
: "${APPLE_TEAM_ID:?Missing developer team secret}"
SIGNING_DIR=$(mktemp -d "$RUNNER_TEMP/mewsaic-signing-XXXXXX")
export SIGNING_DIR
printf 'SIGNING_DIR=%s\n' "$SIGNING_DIR" >> "$GITHUB_ENV"
python3 - <<'PY'
import os, base64
from pathlib import Path
root=Path(os.environ['SIGNING_DIR'])
for key,name in [('IOS_CERTIFICATE_P12','certificate.p12'),('IOS_PROVISIONING_PROFILE','profile.mobileprovision')]:
    (root/name).write_bytes(base64.b64decode(os.environ[key],validate=True))
PY
security cms -D -i "$SIGNING_DIR/profile.mobileprovision" > "$SIGNING_DIR/profile.plist"
python3 - <<'PY'
import os,plistlib,datetime,hashlib
from pathlib import Path
root=Path(os.environ['SIGNING_DIR']); p=plistlib.loads((root/'profile.plist').read_bytes()); e=p['Entitlements']
assert p['TeamIdentifier']==[os.environ['APPLE_TEAM_ID']], 'Provisioning team mismatch'
assert e['application-identifier']==os.environ['APPLE_TEAM_ID']+'.'+os.environ['BUNDLE_ID'], 'Profile Bundle ID mismatch'
assert not e.get('get-task-allow') and not p.get('ProvisionedDevices') and not p.get('ProvisionsAllDevices'), 'Profile must be App Store distribution'
assert p['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Provisioning profile expired'
profile_dir=Path.home()/'Library/Developer/Xcode/UserData/Provisioning Profiles';profile_dir.mkdir(parents=True,exist_ok=True)
target=profile_dir/(p['UUID']+'.mobileprovision');target.write_bytes((root/'profile.mobileprovision').read_bytes())
with open(os.environ['GITHUB_ENV'],'a') as f:
    f.write('PROFILE_UUID='+p['UUID']+'\nINSTALLED_PROFILE='+str(target)+'\n')
(root/'allowed-certificate-hashes.txt').write_text('\n'.join(hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates']))
PY
SIGNING_KEYCHAIN="$SIGNING_DIR/signing.keychain-db"
printf 'SIGNING_KEYCHAIN=%s\n' "$SIGNING_KEYCHAIN" >> "$GITHUB_ENV"
keychain_password=$(openssl rand -hex 32)
printf '::add-mask::%s\n' "$keychain_password"
security create-keychain -p "$keychain_password" "$SIGNING_KEYCHAIN"
security set-keychain-settings -lut 21600 "$SIGNING_KEYCHAIN"
security unlock-keychain -p "$keychain_password" "$SIGNING_KEYCHAIN"
security import "$SIGNING_DIR/certificate.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$SIGNING_KEYCHAIN" >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$SIGNING_KEYCHAIN" >/dev/null
security list-keychains -d user -s "$SIGNING_KEYCHAIN" "$HOME/Library/Keychains/login.keychain-db"
security find-identity -v -p codesigning "$SIGNING_KEYCHAIN" > "$SIGNING_DIR/identities.txt"
python3 - <<'PY'
import os,re
from pathlib import Path
p=Path(os.environ['SIGNING_DIR']); allowed=set((p/'allowed-certificate-hashes.txt').read_text().splitlines())
found=re.findall(r'\b[0-9A-F]{40}\b',(p/'identities.txt').read_text());matches=[h for h in found if h in allowed]
assert len(matches)==1,'No unique valid signing identity matches the App Store profile'
with open(os.environ['GITHUB_ENV'],'a') as f:f.write('SIGNING_IDENTITY='+matches[0]+'\n')
print('App Store profile and signing identity verified.')
PY
