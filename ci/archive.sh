#!/bin/bash
set -euo pipefail
mkdir -p artifacts
xcodebuild -project loop_miao.xcodeproj -scheme MewsaicNook \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$PWD/artifacts/MewsaicNook.xcarchive" \
  -derivedDataPath "$RUNNER_TEMP/mewsaic-derived" \
  MARKETING_VERSION="$MARKETING_VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" IPHONEOS_DEPLOYMENT_TARGET=15.0 \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" PROVISIONING_PROFILE_SPECIFIER="$PROFILE_UUID" \
  OTHER_CODE_SIGN_FLAGS="--keychain $SIGNING_KEYCHAIN" \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES archive
python3 - <<'PY'
import os,plistlib
from pathlib import Path
options={'method':'app-store-connect','destination':'export','teamID':os.environ['APPLE_TEAM_ID'],
 'signingStyle':'manual','signingCertificate':os.environ['SIGNING_IDENTITY'],
 'provisioningProfiles':{os.environ['BUNDLE_ID']:os.environ['PROFILE_UUID']},
 'manageAppVersionAndBuildNumber':False,'stripSwiftSymbols':True,'uploadSymbols':True}
Path(os.environ['SIGNING_DIR'],'ExportOptions.plist').write_bytes(plistlib.dumps(options))
PY
xcodebuild -exportArchive -archivePath "$PWD/artifacts/MewsaicNook.xcarchive" \
  -exportPath "$PWD/artifacts/export" -exportOptionsPlist "$SIGNING_DIR/ExportOptions.plist"
python3 - <<'PY'
import os,plistlib,json,hashlib,zipfile
from pathlib import Path
ipas=list(Path('artifacts/export').glob('*.ipa'));assert len(ipas)==1,'Expected exactly one exported IPA'
p=ipas[0]
with zipfile.ZipFile(p) as z:
 info_paths=[n for n in z.namelist() if n.startswith('Payload/') and n.count('/')==2 and n.endswith('.app/Info.plist')]
 assert len(info_paths)==1
 info=plistlib.loads(z.read(info_paths[0]));prefix=info_paths[0].removesuffix('Info.plist')
 for key,expected in [('CFBundleIdentifier',os.environ['BUNDLE_ID']),('CFBundleShortVersionString',os.environ['MARKETING_VERSION']),('CFBundleVersion',os.environ['BUILD_NUMBER']),('MinimumOSVersion','15.0')]:
  assert info[key]==expected,(key,info.get(key),expected)
 assert info.get('ITSAppUsesNonExemptEncryption') is False
 for name in ['campaign.json','daily.json','PrivacyInfo.xcprivacy','PrivacyPolicy.txt','embedded.mobileprovision']:
  assert prefix+name in z.namelist(),name
 assert not any(n.endswith(('.p12','.p8')) for n in z.namelist())
 result={'bundle_id':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'build':info['CFBundleVersion'],
 'minimum_ios':info['MinimumOSVersion'],'commit':os.environ['GITHUB_SHA'],'ipa_sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
Path('artifacts/build-info.json').write_text(json.dumps(result,indent=2)+'\n')
with open(os.environ['GITHUB_ENV'],'a') as f:f.write('IPA_PATH='+str(p.resolve())+'\n')
print(json.dumps(result,indent=2))
PY
codesign --verify --deep --strict "artifacts/MewsaicNook.xcarchive/Products/Applications/loop_miao.app"
printf '### Signed IPA ready\n\nVersion: %s · Build: %s · Minimum iOS: 15.0\n' "$MARKETING_VERSION" "$BUILD_NUMBER" >> "$GITHUB_STEP_SUMMARY"
