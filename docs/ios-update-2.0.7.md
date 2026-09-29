# iOS 2.0.7 update

This update uses the existing GitHub Actions macOS signing/upload workflow.
The App Store app is 6804423770, bundle ID com.atalay.aksoytanks.
Runtime game version remains 2.0.7 for compatibility with the Android room list.
Build number is 29 plus the workflow run number, separate from game version.

The client sources match the current shared 2.0.7 source. No signing keys or
certificates are stored in source. Existing GitHub secrets are reused.
Upload is followed by Apple processing verification and assignment to the
existing internal TestFlight group. It does not submit a public store release.

Test on an actual iPhone before submitting to App Review, including updates
over 1.0 without uninstalling, saved progress, controls, pause/resume, audio,
and private/public VS and co-op rooms with another device.

Privacy: use docs/privacy-policy.md. Older release instructions describing
offline-only behavior or "Data Not Collected" must not be reused blindly.
Online mode processes nicknames, room data, input, and match state.
Review the current App Privacy declarations before the public update.
