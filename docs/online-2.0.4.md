# Online 2.0.4 validation

Date: 2026-09-06. Android version code: 26.

## Changes

- Both arenas must load before the host starts a three-second countdown.
- A per-arena readiness token prevents an old scene acknowledgement from starting a new round. Reconnect invalidates readiness; completed results are retained.
- Tanks, projectiles and pickups remain frozen during preparation. Networking and the leave menu remain active. Spawn shields are not consumed by the countdown.
- Readiness also works when the local tank has been eliminated and the client is spectating.
- A centered, fixed-size countdown uses a short fade and respects reduced-motion settings.
- World packets use per-packet column tables to avoid repeating entity field names. Each table is independently decoded; there is no cross-packet dictionary/cache dependency. Existing wall revision handling is unchanged.
- Mixed entity schemas fall back to ordinary dictionaries. Unknown formats, duplicate columns and malformed rows are rejected.

## Focused checks

- `snapshot_codec_test.gd`: exact JSON roundtrip, caller immutability, mixed schemas, legacy packets and malformed tables PASS.
- The synthetic 40-projectile fixture decreased from 8,002 to 3,125 JSON bytes (60.9%). This is a fixture result, not a universal traffic reduction, FPS measurement or ping improvement.
- `network_start_test.gd`: initial freeze, wrong/expired tokens, full countdown, release, disconnect invalidation, menu/result overlap prevention and result preservation PASS.
- `test_relay.py`: 12 tests PASS, including readiness input bounds/type checks.
- Two real local Godot clients: co-op and versus PASS, including delayed guest scene loading, guest firing/steering, next stage, retry, host departure/promotion and rejoining a result screen.
- The same two-client flow through the local impairment proxy PASS in both modes, also repeated in the release pipeline. Per direction: 100 ms latency, +/-30 ms seeded jitter, 512 kbps application payload bandwidth. Observed end samples across these runs: roughly 208-219 ms relay RTT, 17-48 ms jitter.
- The impairment fixture preserves ordered WebSocket messages. It models queuing/delay, not independent UDP loss or real radio conditions. Forced transport disconnects are exercised by the game test.
- UI captures at 960x540 and 1560x720 PASS and were visually inspected, including centered countdown, wait state and in-match menu.
- Gameplay, lifecycle, authority transfer, hitbox, wall collision, tank separation, smoothing, resilience, mobile touch, stage 60 and onboarding regressions PASS.
- All 60 stage completion state machines PASS. The final scripted combat soak completed without runtime errors: 9 victories, 7 losses, 44 time limits. Neither test proves human beatability or the difficulty curve.

## Production

- Relay source backed up as `/opt/atify/aksoy-tank-relay/server.py.before-2.0.4` before deployment. No established relay connection was observed before restart.
- Only the Aksoy Tank relay service was rebuilt. Other site services were not changed.
- Local and deployed server.py SHA256 match: `2D892EAE4C27674A03ABF78046F6783646915514A917D8612452E791974EA9B7`.
- Public health endpoint returned `status: ok`; Docker health is healthy.
- Two actual Godot clients through `wss://atify.com.tr/aksoy-tank/ws`: co-op and versus PASS, including countdown, rematches, host migration and completed-result reconnection.
- Production end-sample relay RTT was 21.4-23.0 ms and jitter 1.2-4.2 ms on this connection. This is not a promised latency or a before/after benchmark.

## Reproduction

Run the full release pipeline with `play-store-hazirla.cmd`. It now includes the codec, readiness and impaired two-client tests.

For focused two-client tests:

```powershell
python online-relay/test_game_clients.py --godot "PATH_TO_GODOT_CONSOLE.exe"
python online-relay/test_game_clients.py --godot "PATH_TO_GODOT_CONSOLE.exe" --impaired
python online-relay/test_game_clients.py --godot "PATH_TO_GODOT_CONSOLE.exe" --server wss://atify.com.tr/aksoy-tank/ws
```

Use the same 2.0.4 build on both players. The server rejects mixed builds. The desktop online CMD opens the native Godot game, not a browser export.

## Final package

- Full release pipeline rerun after the menu/result countdown fix: PASS (exit 0).
- Android 7 / API 24 emulator install and menu opening PASS; final screenshot visually inspected.
- Signed AAB, ARMv7/ARM64, minSdk 24, targetSdk 36, version 2.0.4/code 26 checks PASS.
- AAB size: 51,454,857 bytes.
- AAB SHA256: `AC859D6181A02E4AE550968059C3238DCA5F3DB624C822D6304FEB007116CCD3`.
- Desktop `Aksoy-Tank-2.0.4-Play-Store.aab` hash matches the verified build.
- Desktop `Aksoy-Tank-2.0.4-Test.apk` is debug signed and cannot update an existing Play-signed install. Both ARM ABIs are included. Its hash matches the final debug build.
- Turkish and English short release notes plus cumulative notes are on the desktop alongside the AAB.
- Source backup branch: `codex/release-2.0.4-online`. Signing credentials and generated Android build directories remain excluded from Git.

## Remaining external validation

No physical Android phone was available. Two-phone Wi-Fi/mobile handover, long-session low-end frame pacing/heat/battery, and Play-installed update/progress retention still need device testing. No Play Console upload or rollout was performed. There is no concurrent-room capacity certification or human 60-stage difficulty certification.
