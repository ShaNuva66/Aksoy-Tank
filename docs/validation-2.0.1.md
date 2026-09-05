# Aksoy Tank 2.0.1 verification

Date: 2026-09-05. Version code: 23.

## Automated evidence

- Lifecycle regression: solo focus loss pauses; resume is explicit; online menu
  remains interactive without pausing networking; keyboard/fire input is blocked;
  Android Back opens the menu rather than terminating the match.
- Authority transfer regression: pending wave state is applied, network IDs stay
  unique, wall revisions do not go backwards, promoted enemies report their deaths.
- Two real Godot processes plus a local relay: co-op and versus pair, host transport
  closes, guest becomes host, original host reconnects as guest. Both modes passed.
- 60-stage combat soak: actual physics, enemy AI, bullets and damage, up to 30
  simulated seconds per stage. Clean run: 11 victories, 9 losses, 40 time limits.
  This is a simple scripted player, not a human balance or full completion proof.
  Runtime errors fail the wrapper even if Godot exits with code zero.
- Existing 60-stage state-machine tests check objective/result progression.
  They intentionally simulate kills and are separate from combat testing.

Reports: `../aksoy-tank-builds/combat-soak-report.json` and `combat-soak.log`.

## Repeatable commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_combat_soak.ps1
.\play-store-hazirla.cmd
```

The release pipeline includes the lifecycle test, authority-transfer test, combat
soak, existing regressions, two-process network test, package build and API 24 opening.

## Required external verification

No physical Android device was attached during this work. The owner confirmed no
phone can be connected right now. Do not mark these done:

- Play-delivered release install on a physical ARM device.
- Install over the previous Play version without uninstalling. Verify unlocked
  stages, name, style, sound preferences and onboarding state remain intact.
- At least 20 minutes on a low-end phone, especially stages 58-60. Record device,
  Android version, frame pacing, temperature, memory and battery change.
- Two physical phones: Wi-Fi loss, mobile-data handover, background/foreground,
  reconnect exhaustion, host migration and explicit leave-match controls.
- Human playthroughs for difficulty: victory rate, deaths and time per stage.
- Play Console internal-track upload, automated pre-launch results and rollout.
  Signing/manifest validation alone does not prove Play acceptance.
- Signing-key backup in an owner-controlled secure vault or encrypted external
  drive. The signing key is intentionally excluded from the source repository.

Device evidence collector (requires an authorized physical USB device):

```powershell
powershell -ExecutionPolicy Bypass -File tools/collect_device_validation.ps1 -Serial DEVICE_SERIAL -Seconds 1200
```

## Release evidence

- Android 7 / API 24 emulator installation and menu opening passed. Screenshot
  inspected: nonblank, controls visible, no overlapping labels.
- Relay unit suite: 10 tests passed. Production relay updated; HTTPS health and
  live WebSocket pairing, input relay and authority-transfer probes passed.
- Release AAB signature, ARMv7/ARM64 contents and manifest checks passed:
  `com.atalay.aksoytank`, version `2.0.1` / `23`, minimum API 24, target API 36.
- Desktop AAB and build output have identical SHA-256:
  `B70ADD51BCED37FB461972D6ED47307509D6B6D594978F8CA41A1AAD67AAC1A1`.
- Source backup destination: `origin/codex/release-2.0.1-validation`.
  Verify publication with `git ls-remote origin refs/heads/codex/release-2.0.1-validation`.
  Signing credentials are excluded; their external backup remains pending.
