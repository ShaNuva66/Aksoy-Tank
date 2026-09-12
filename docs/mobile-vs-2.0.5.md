# Mobile controls and VS 2.0.5

Date: 2026-09-12. Android version code: 27.

## Changes

- Floating analog: the first touch in the lower-left movement zone becomes the origin. Direction can change without lifting; a separate finger can fire. Additional touches cannot steal movement ownership.
- Touch ownership is cleared on pause, focus loss, viewport resize and local player-slot changes.
- Larger main-menu controls and direct Story, Co-op and VS tabs.
- Visible online lobby player list, room code and shared three-second start after both arenas are ready.
- Larger pause button and a separate return-to-Story action that disconnects the online room.
- Solo pause stops simulation. The online match menu disables local controls without pausing the opponent.
- VS is first to three victories, with three rotating symmetric maps and alternating spawn sides. Both players confirm each next round or rematch.
- Series scores survive reconnect and authority transfer. A completed series resets for the next mutually confirmed rematch.
- Tank nameplates are upright even while the initial countdown freezes tank processing.

## Focused verification

- `floating_analog_test.gd`: initial zero movement, multiple origins, continuous direction reversal, simultaneous fire, pointer ownership, pause cleanup, guest slot routing and focus loss.
- `online_ui_smoke_test.gd`: Story/online mode buttons, viewport containment, lobby visibility, countdown/menu exclusivity and actual return-to-Story scene transition with disconnect. Captures at 960x540 and 1560x720 were visually inspected.
- `gameplay_regression_test.gd`: round-result presentation, score update and duplicate-result protection, along with existing gameplay checks.
- `vs_rules_test.gd`: score progression, draws, duplicate resolution, rematch reset, distinct maps, symmetry and spawn/pickup path reachability.
- Two real Godot clients passed co-op and VS through a local proxy with 100 ms added latency, +/-30 ms jitter and 512 kbps payload bandwidth per direction. Tests include reconnect, host migration, a complete VS series and rematch reset.

## Production route repair

The relay container was healthy, but the active Caddy configuration no longer contained the game route. Public game requests reached the main backend and returned HTTP 403.

- Backed up the current configuration to `/opt/atify/deploy/Caddyfile.before-aksoy-2.0.5-20260912`.
- Preserved the main site and `/Yenicag/*` handlers. Added only the game handler, validated Caddy configuration and gracefully reloaded it without restarting the relay.
- Public game health returned `status: ok`; the main site and `/Yenicag/` both returned HTTP 200 after reload.
- Two real Godot 2.0.5 clients passed both co-op and VS through `wss://atify.com.tr/aksoy-tank/ws`, including shared starts, reconnect, host transfer, score retention and a complete series/rematch cycle. Final relay RTT samples were 23.0-29.3 ms on this connection, not a latency guarantee.
- Future Atify deployments must retain this block inside the existing site, before the fallback `handle`:

```caddyfile
handle /aksoy-tank/* {
    reverse_proxy aksoy-tank-relay:8765
}
```

## Final release verification

- Full `prepare_play_store_release.ps1` pipeline PASS, exit 0.
- Catalog, gameplay, mobile lifecycle, authority transfer, hitbox, wall collision, tank separation, smoothing, resilience, codec, shared start, floating analog, mobile touch, stage 60 and onboarding checks PASS.
- All 60 completion state-machine checks PASS. Scripted combat soak PASS with 8 wins, 3 losses and 49 time limits; this is not a human difficulty certification.
- Relay integration: 12 tests PASS. Real two-client local and impaired co-op/VS flows PASS again using version 2.0.5.
- Android 7 / API 24 emulator install and opening PASS; screenshot visually inspected.
- Signed AAB metadata and both ARM ABIs verified: minSdk 24, targetSdk 36, version 2.0.5/code 27.
- AAB size: 51,461,906 bytes. SHA256: `4421FA5717BA80E20363903B5F33C71AF209FF309A402FA0899796EBC0C5349B`.
- Desktop `Aksoy-Tank-2.0.5-Play-Store.aab` matches the verified build. Short Turkish/English notes and cumulative release notes are alongside it.
- Desktop `Aksoy-Tank-2.0.5-Test.apk` matches the ARM debug build, SHA256 `3ADAB6588DC8C352DD9390521FACA55DFF0E82F74E7CD18A6DE948B4D6DC50FD`. It is debug signed and cannot replace an existing Play-signed installation.
- Source backup branch: `codex/release-2.0.5-mobile-vs`. Keys and generated build directories remain excluded from Git.

## Limits

Both online players must run the same build. No physical Android phone was available. Automated input and emulator checks do not certify touch comfort, thermal performance, real cellular handover or the human difficulty of all 60 stages. No Play Console rollout is performed by the packaging script.
