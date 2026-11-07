# Mewsaic Nook App Store workflow

The `Build and upload Mewsaic Nook` workflow is manually dispatched on GitHub Actions. It builds the shared `MewsaicNook` scheme using Xcode 26.2 on `macos-15`.

- Bundle identifier: `com.mewsaic.erden.nook.app`
- Marketing version: `1.1.0`
- Deployment target: iOS `15.0`
- Build number: workflow run number by default; optionally supply an unused integer (1–9999).

Required repository Actions secrets:

| Secret | Value |
| --- | --- |
| IOS_CERTIFICATE_P12 | Base64-encoded distribution certificate plus private key |
| IOS_CERTIFICATE_PASSWORD | Certificate export password |
| IOS_PROVISIONING_PROFILE | Base64-encoded App Store profile for this Bundle ID |
| APPLE_TEAM_ID | Apple Developer team identifier |
| APPLE_ID | Apple upload account email |
| APPLE_APP_SPECIFIC_PASSWORD | App-specific upload password |
| ASC_APP_ID | Numeric App Store Connect app identifier |
| ASC_PROVIDER_ID | App Store Connect provider public identifier |

The workflow validates all bundled puzzles, installs signing credentials in a temporary keychain, checks profile/team/Bundle ID/certificate compatibility, archives, exports and inspects the IPA, and retains the IPA, dSYMs and build metadata for 14 days. Upload uses Apple's `altool` with an environment-sourced password and waits for Apple's processing response. Signing material is removed in an `always()` cleanup step. It is never committed or included in the downloadable artifact.

To run: Actions → Build and upload Mewsaic Nook → Run workflow. Leave `upload` enabled to upload to App Store Connect. Uploading a build does not submit it for App Review or release it. Do not rerun an already successfully uploaded build number; dispatch a new run or provide a new build number instead.

The source repository contains only the app, tests, level validation tools, shared scheme and CI configuration. Website delivery files, store screenshot exports, local credentials, simulator data and user-specific Xcode state are not part of this release checkout.
