# Beatrun Demo Catalog

This catalog documents the starter metadata used by the current Beatrun competition MVP when no user-authorized library tracks are available.

Important limits:

- Primary matching should use user-authorized system music-library tracks, user-imported files, or explicitly licensed files.
- This starter catalog is metadata fallback only; it does not bundle commercial recordings.
- No unauthorized commercial music is downloaded, scraped, streamed, bundled, or redistributed.
- Matching is 1:1 only.
- Tempo adjustment must stay within +/-10%.
- Double-time and half-time matching are disabled.
- Tracks without BPM metadata are not recommended unless BPM is supplied by a supported manual-tagging flow.

## Shared Audio Rights

The starter entries use the same conservative rights profile.

| Field | Value |
| --- | --- |
| Rights status | CC/manual-BPM fallback metadata |
| License/source type | Starter metadata for CC or user-imported files |
| Attribution | Beatrun starter metadata |
| Source link | `docs/demo-catalog.md` |
| Source explanation | No external recording is bundled; replace with a user-authorized local file or clearly licensed CC file for real playback |
| Tempo adjustment | Allowed |
| Redistribution risk | No third-party recording is redistributed |

## Tracks

| Title | Artist | Type | Original BPM | Genre | Beat grid | Confidence | Tempo change allowed | Source / license |
| --- | --- | --- | ---: | --- | --- | ---: | --- | --- |
| Easy Warmup | CC Starter Pack | Instrumental | 144 | Electronic | Curated 1:1 starter grid | 92% | Yes | CC/manual-BPM metadata |
| Night Circuit | CC Starter Pack | Instrumental | 160 | Electronic | Curated 1:1 starter grid | 94% | Yes | CC/manual-BPM metadata |
| Forward Motion | CC Starter Pack | Instrumental | 166 | Synth | Curated 1:1 starter grid | 91% | Yes | CC/manual-BPM metadata |
| Steel Horizon | CC Starter Pack | Instrumental | 172 | Breakbeat | Curated 1:1 starter grid | 89% | Yes | CC/manual-BPM metadata |
| Clean Stride | CC Starter Pack | Instrumental | 180 | House | Curated 1:1 starter grid | 97% | Yes | CC/manual-BPM metadata |
| Blue Relay | CC Starter Pack | Instrumental | 188 | Dance | Curated 1:1 starter grid | 90% | Yes | CC/manual-BPM metadata |
| Final Kick | CC Starter Pack | Instrumental | 198 | Dance | Curated 1:1 starter grid | 88% | Yes | CC/manual-BPM metadata |
| Step Into Light | CC Starter Pack | Vocal-style | 146 | Pop | Vocal-style 1:1 starter grid | 86% | Yes | CC/manual-BPM metadata |
| Hold the Pace | CC Starter Pack | Vocal-style | 158 | Indie Pop | Vocal-style 1:1 starter grid | 88% | Yes | CC/manual-BPM metadata |
| Keep Breathing | CC Starter Pack | Vocal-style | 168 | Pop Rock | Vocal-style 1:1 starter grid | 87% | Yes | CC/manual-BPM metadata |
| Run the Line | CC Starter Pack | Vocal-style | 180 | Dance Pop | Vocal-style 1:1 starter grid | 92% | Yes | CC/manual-BPM metadata |
| After the Turn | CC Starter Pack | Vocal-style | 190 | Alternative | Vocal-style 1:1 starter grid | 85% | Yes | CC/manual-BPM metadata |
| Finish Lights | CC Starter Pack | Vocal-style | 198 | Dance Pop | Vocal-style 1:1 starter grid | 86% | Yes | CC/manual-BPM metadata |

## Matching Evidence

The app calculates:

- `speedRatio = targetCadence / originalBPM`
- `speedChangePercent = (speedRatio - 1) * 100`
- reject when `abs(speedChangePercent) > 10`
- reject when rights metadata does not allow tempo adjustment
- reject when BPM metadata is missing and no manual BPM exists

For accepted tracks, adjusted BPM equals the target cadence. The UI shows original BPM, adjusted BPM, speed change, match score, confidence, source type, analysis availability, and rights status. Apple Music or cloud/DRM items can be metadata-only; Beatrun does not claim waveform analysis or tempo-adjusted playback for those items.
