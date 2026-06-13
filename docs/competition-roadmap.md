# Beatrun Competition Roadmap

This roadmap turns Beatrun from an interactive prototype into a competition-ready entry for the Qidi track.

## Competition Positioning

Beatrun is a running music assistant that matches music rhythm to a runner's target cadence, then overlays a synchronized metronome so the runner can keep a stable step rhythm.

The competition story should be:

- Runners often struggle to keep a steady cadence during training.
- Existing playlists only roughly match BPM and do not adapt to the runner's cadence.
- Beatrun combines cadence selection, authorized music-library matching, 1:1 tempo adjustment, beat-boundary queue transitions, synchronized metronome playback, and Watch standalone workout state in one mobile workflow.
- The current product uses MediaPlayer library metadata, CC/manual-BPM fallback metadata, WatchConnectivity enhancement, and a HealthKit Workout Session path while clearly documenting simulator and DRM limits.

## Scoring Targets

### Innovation and Distinctiveness - 40 Points

Target score: 31-35

Required evidence:

- Clear problem definition for cadence training.
- A visible workflow from target cadence to music recommendation to synchronized playback.
- Tempo-fit details shown in the app: target cadence, original BPM, adjusted BPM, speed change, confidence, rights status, and sync state.
- A technical explanation of why the metronome aligns with the track rhythm instead of playing independently.

Current gap:

- Tempo matching now supports MediaPlayer BPM metadata and CC/manual-BPM fallback metadata.
- The app still needs user-imported local audio analysis and true local-file retiming verification on device.

### Market and Social Value - 25 Points

Target score: 18-21

Required evidence:

- Target users: recreational runners, beginner runners, cadence-training runners, and school running groups.
- Use cases: warm-up cadence, long-run pacing, interval training, and form correction.
- Lightweight user validation: interviews, survey results, or before/after cadence stability examples.
- Legal music strategy: user-authorized local library tracks, imported files, CC/royalty-free files, and metadata-only handling for DRM/cloud tracks.

Current gap:

- No user validation evidence yet.
- No formal comparison against running apps, metronome apps, or BPM playlist tools.

### Basic Product Parameters - 25 Points

Target score: 21-24

Required evidence:

- The app builds and runs on iOS.
- The demo path works without network access.
- The user can set cadence, choose music preference, scan the music library or use fallback metadata, get recommendations, and hear synchronized clicks.
- The user can see the upcoming track and an MVP-level beat-synced transition countdown.
- The Watch app can show standalone workout state, target/current cadence, HealthKit metrics, current/next track, transition state, and workout controls.
- The app handles cadence changes by refreshing matches and keeping sync state visible.
- The demo is stable enough for screen recording and live judging.

Current gap:

- No test target or repeatable demo checklist.
- No real-device verification record in the repository.
- Simulator HealthKit and music-library behavior still need real-device verification.

### Submission Material Quality - 10 Points

Target score: 8-10

Required evidence:

- Official work description document.
- Two-to-three-minute demo video.
- App screenshots.
- One-page poster or product overview image.
- Technical architecture diagram.
- Legal and copyright statement for audio materials.
- Clear changelog and build instructions.

Current gap:

- The repository has README and CHANGELOG, but not the official submission package.

## Deadline Plan

Qidi initial submission deadline: 2026-06-30 23:59.

### Stage 1 - Make the Prototype Look Competition-Ready

Target finish: 2026-06-15

- Update README to reflect the current interactive prototype instead of "setup stage".
- Add a competition-oriented product summary.
- Add a demo script for a 90-second walkthrough.
- Add a repeatable local build and demo checklist.
- Polish in-app wording so it sounds like a product, not an engineering placeholder.

### Stage 2 - Add Stronger Demo Evidence

Target finish: 2026-06-20

- Keep the starter catalog documented with BPM, beat-grid metadata, and rights/source status.
- Mark each track as user library, metadata-only Apple Music, imported file, CC licensed, or development fallback.
- Show why each recommended track matches the selected cadence through 1:1 tempo adjustment.
- Add a simple "analysis confidence" explanation in the product material.
- Record a real simulator or device demo path.

### Stage 3 - Build Submission Materials

Target finish: 2026-06-25

- Draft the official work description document.
- Create product screenshots.
- Create a short technical architecture diagram.
- Create a two-to-three-minute demo video script.
- Prepare a one-page poster or overview graphic.

### Stage 4 - Final Polish and Risk Removal

Target finish: 2026-06-29

- Run a clean iOS build.
- Verify demo flow from a fresh launch.
- Remove wording that suggests illegal scraping or unauthorized copyrighted music use.
- Confirm every material uses the same product name, team name, and feature wording.
- Keep a final submitted ZIP/package backup.

## Recommended Demo Flow

1. Open Beatrun and show the target cadence control.
2. Select 180 SPM and instrumental music.
3. Show ranked recommendations and explain original BPM, adjusted BPM, and speed change.
4. Select the best match and start playback.
5. Show the synchronized metronome status, offset, confidence, and beat counter.
6. Show the next-track countdown and crossfade state.
7. Change cadence to 170 SPM and show automatic rediscovery.
8. Explain that user-authorized library tracks, local imports, or CC/royalty-free files are required for legal playback.
9. Close with the Apple Watch standalone workout flow and note that real sensor metrics require physical Watch validation.

## Highest-Impact Implementation Tasks

1. Replace placeholder wording with competition-facing product language.
2. Keep the documented demo catalog with explicit BPM, beat-grid offset, confidence, copyright status, and tempo-adjustment permission.
3. Add a demo checklist and screenshots directory.
4. Add an architecture diagram or text outline for the submission document.
5. Add a lightweight verification record after each successful build and demo run.
6. Verify WatchConnectivity and HealthKit/Workout Session on a paired real device setup after simulator validation.

## Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Music copyright ambiguity | High | Use user-authorized local tracks, imported files, or CC/royalty-free files; treat Apple Music DRM/cloud tracks as metadata-only. |
| Beat alignment looks simulated | High | Document BPM metadata, manual BPM fallback, and measurable offset values. |
| App crashes during demo | High | Keep the demo path offline and deterministic. |
| Materials feel incomplete | High | Prepare document, video, screenshots, poster, and architecture diagram before feature expansion. |
| Product value is unclear | Medium | Add runner user scenarios and cadence-training explanation. |
| Too many future promises | Medium | Separate current MVP from future Apple Watch and provider integrations. |

## Definition of Competition-Ready

Beatrun is competition-ready when:

- The app can complete the recommended demo flow from a fresh launch.
- The submitted materials clearly explain the problem, innovation, technical method, market value, and copyright strategy.
- A judge can understand the core value within the first 30 seconds of the video.
- The project avoids unsupported claims such as universal Apple Music retiming or simulator-proven health metrics unless those features are actually verified.
