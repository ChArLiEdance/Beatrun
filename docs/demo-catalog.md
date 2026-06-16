# Beatrun Demo Catalog

This catalog documents the starter catalog used by the current Beatrun competition MVP when no user-authorized library tracks are available.

Important limits:

- Primary matching should use user-authorized system music-library tracks, user-imported files, or explicitly licensed files.
- The instrumental starter catalog bundles CC0 audio files from Wikimedia Commons for competition fallback.
- Vocal-style entries remain metadata fallback only until matching CC/royalty-free vocal assets are selected.
- No unauthorized commercial music is downloaded, scraped, streamed, bundled, or redistributed.
- Matching is 1:1 only.
- Tempo adjustment must stay within +/-10%.
- Double-time and half-time matching are disabled.
- Tracks without BPM metadata are not recommended unless BPM is supplied by a supported manual-tagging flow.

## Audio Rights

Instrumental entries use per-track CC0 source metadata documented in [docs/audio-sources.md](audio-sources.md).

| Field | Value |
| --- | --- |
| Rights status | CC licensed |
| License/source type | CC0 1.0 Public Domain Dedication for bundled instrumental tracks |
| Attribution | Recorded per track even when attribution is not required |
| Source link | `docs/audio-sources.md` and original Wikimedia Commons file pages |
| Source explanation | Source Ogg files are retained; iOS playback uses AAC `.m4a` transcodes |
| Tempo adjustment | Allowed |
| Redistribution risk | Re-check Commons/FMA source pages before public distribution |

Vocal-style metadata fallback entries keep the older conservative profile: no vocal recording is bundled, and entries should be replaced with user-authorized local files or clearly licensed CC assets before real playback.

## Tracks

| Title | Artist | Type | Original BPM | Genre | Beat grid | Confidence | Tempo change allowed | Source / license |
| --- | --- | --- | ---: | --- | --- | ---: | --- | --- |
| Go to the Picnic | Loyalty Freak Music | Instrumental | 147 | Folk / Soundtrack | Estimated from local onset analysis | 72% | Yes | CC0 bundled audio |
| High Technologic Beat Explosion | Loyalty Freak Music | Instrumental | 147 | Electronic / Techno | Estimated from local onset analysis | 72% | Yes | CC0 bundled audio |
| Waiting TTTT | Loyalty Freak Music | Instrumental | 166 | Electronic | Estimated from local onset analysis | 66% | Yes | CC0 bundled audio |
| Level 1 | Monplaisir | Instrumental | 178 | Rock / Game soundtrack | Estimated from local onset analysis | 86% | Yes | CC0 bundled audio |
| Level 3 | Monplaisir | Instrumental | 206 | Electronic / Game soundtrack | Estimated from local onset analysis | 82% | Yes | CC0 bundled audio |
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
