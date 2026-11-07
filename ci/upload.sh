#!/bin/bash
set -euo pipefail
: "${APPLE_ID:?Missing Apple upload account}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Missing app-specific password}"
: "${ASC_APP_ID:?Missing App Store Connect app ID}"
: "${ASC_PROVIDER_ID:?Missing App Store Connect provider ID}"
# Read the password through the environment; never write it to disk or argv.
# --wait waits for Apple's processing instead of treating transfer alone as success.
xcrun altool --upload-package "$IPA_PATH" --platform ios \
  --apple-id "$ASC_APP_ID" --provider-public-id "$ASC_PROVIDER_ID" \
  --bundle-id "$BUNDLE_ID" --bundle-version "$BUILD_NUMBER" \
  --bundle-short-version-string "$MARKETING_VERSION" \
  --username "$APPLE_ID" --password '@env:APPLE_APP_SPECIFIC_PASSWORD' \
  --wait --output-format json 2>&1 | tee "$RUNNER_TEMP/mewsaic-apple-upload.log"
python3 tools/check_apple_upload.py "$RUNNER_TEMP/mewsaic-apple-upload.log"
printf '\n### App Store Connect\n\nIPA upload completed; Apple processing response is in the upload step log. This workflow does not submit the app for review or publish it.\n' >> "$GITHUB_STEP_SUMMARY"
