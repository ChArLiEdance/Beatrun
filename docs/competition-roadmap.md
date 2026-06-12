# Beatrun Competition Roadmap

This roadmap turns Beatrun from an interactive prototype into a competition-ready entry for the Qidi track.

## Competition Positioning

Beatrun is a running music assistant that matches music rhythm to a runner's target cadence, then overlays a synchronized metronome so the runner can keep a stable step rhythm.

The competition story should be:

- Runners often struggle to keep a steady cadence during training.
- Existing playlists only roughly match BPM and do not adapt to the runner's cadence.
- Beatrun combines cadence selection, legal demo music matching, 1:1 tempo adjustment, and synchronized metronome playback in one mobile workflow.
- The current product starts with safe generated or licensed audio samples, then can expand to legal music providers and Apple Watch cadence sensing.

## Scoring Targets

### Innovation and Distinctiveness - 40 Points

Target score: 31-35

Required evidence:

- Clear problem definition for cadence training.
- A visible workflow from target cadence to music recommendation to synchronized playback.
- Tempo-fit details shown in the app: target cadence, original BPM, adjusted BPM, speed change, confidence, rights status, and sync state.
- A technical explanation of why the metronome aligns with the track rhythm instead of playing independently.

Current gap:

- Tempo matching is still based on curated demo metadata and generated audio.
- The app needs either real royalty-free sample-track beat data or a simple local beat-analysis pipeline after the MVP.

### Market and Social Value - 25 Points

Target score: 18-21

Required evidence:

- Target users: recreational runners, beginner runners, cadence-training runners, and school running groups.
- Use cases: warm-up cadence, long-run pacing, interval training, and form correction.
- Lightweight user validation: interviews, survey results, or before/after cadence stability examples.
- Legal music strategy: generated samples for prototype, royalty-free samples for demo, licensed provider path for future product.

Current gap:

- No user validation evidence yet.
- No formal comparison against running apps, metronome apps, or BPM playlist tools.

### Basic Product Parameters - 25 Points

Target score: 21-24

Required evidence:

- The app builds and runs on iOS.
- The demo path works without network access.
- The user can set cadence, choose music preference, get recommendations, play a backing loop, and hear synchronized clicks.
- The app handles cadence changes by refreshing matches and keeping sync state visible.
- The demo is stable enough for screen recording and live judging.

Current gap:

- No test target or repeatable demo checklist.
- No real-device verification record in the repository.
- The generated music loop is useful for demo safety and is now documented as a legal prototype asset.

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

- Keep the curated demo catalog documented with BPM, beat-grid metadata, and rights status.
- Mark each demo track as generated, royalty-free, or licensed before any non-generated sample is added.
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
6. Change cadence to 170 SPM and show automatic rediscovery.
7. Explain that generated or licensed samples are used to avoid copyright risk.
8. Close with Apple Watch and real-time cadence sensing as the next product stage.

## Highest-Impact Implementation Tasks

1. Replace placeholder wording with competition-facing product language.
2. Keep the documented demo catalog with explicit BPM, beat-grid offset, confidence, copyright status, and tempo-adjustment permission.
3. Add a demo checklist and screenshots directory.
4. Add an architecture diagram or text outline for the submission document.
5. Add a lightweight verification record after each successful build and demo run.

## Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Music copyright ambiguity | High | Use generated or royalty-free samples for the submitted demo. |
| Beat alignment looks simulated | High | Document demo-track beat metadata and show measurable BPM/offset values. |
| App crashes during demo | High | Keep the demo path offline and deterministic. |
| Materials feel incomplete | High | Prepare document, video, screenshots, poster, and architecture diagram before feature expansion. |
| Product value is unclear | Medium | Add runner user scenarios and cadence-training explanation. |
| Too many future promises | Medium | Separate current MVP from future Apple Watch and provider integrations. |

## Definition of Competition-Ready

Beatrun is competition-ready when:

- The app can complete the recommended demo flow from a fresh launch.
- The submitted materials clearly explain the problem, innovation, technical method, market value, and copyright strategy.
- A judge can understand the core value within the first 30 seconds of the video.
- The project avoids unsupported claims such as full commercial music integration or real-time Apple Watch sensing unless those features are actually implemented.
