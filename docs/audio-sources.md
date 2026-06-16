# Beatrun Audio Sources

This file records every third-party audio file bundled with Beatrun.

Important policy:

- Only files with clear redistribution and modification permission may be bundled.
- Beatrun does not download, scrape, decrypt, copy, or redistribute commercial music.
- Tempo changes are only applied when the license allows derivative/modified playback.
- BPM values below are seed estimates from local onset analysis and should be manually verified before public release.

## Bundled Instrumental Tracks

| App file | Source file | Artist | License | BPM seed | Source |
| --- | --- | --- | --- | ---: | --- |
| `go_to_the_picnic.m4a` | `go_to_the_picnic.ogg` | Loyalty Freak Music | CC0 1.0 Public Domain Dedication | 147 | https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_01_-_Go_to_the_Picnic.ogg |
| `high_technologic_beat_explosion.m4a` | `high_technologic_beat_explosion.ogg` | Loyalty Freak Music | CC0 1.0 Public Domain Dedication | 147 | https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_02_-_High_Technologic_Beat_Explosion.ogg |
| `waiting_tttt.m4a` | `waiting_tttt.ogg` | Loyalty Freak Music | CC0 1.0 Public Domain Dedication | 166 | https://commons.wikimedia.org/wiki/File:Loyalty_Freak_Music_-_05_-_Waiting_TTTT.ogg |
| `level_1.m4a` | `level_1.ogg` | Monplaisir | CC0 1.0 Public Domain Dedication | 178 | https://commons.wikimedia.org/wiki/File:Monplaisir_-_04_-_Level_1.ogg |
| `level_3.m4a` | `level_3.ogg` | Monplaisir | CC0 1.0 Public Domain Dedication | 206 | https://commons.wikimedia.org/wiki/File:Monplaisir_-_06_-_Level_3.ogg |

## User-Imported Test Library

These files were provided locally by the user and are treated as imported music-library files for app testing. Beatrun first checks for an embedded BPM tag. If no BPM tag exists, it analyzes the decoded waveform locally and uses that BPM estimate for 1:1 cadence matching.

| App file | Artist label | Source type | BPM source |
| --- | --- | --- | --- |
| `nastelbom-instrumental-495889.mp3` | Nastelbom | User-provided local import | BPM tag or automatic waveform analysis |
| `nastelbom-instrumental-instrumental-music-501717.mp3` | Nastelbom | User-provided local import | BPM tag or automatic waveform analysis |
| `the_mountain-instrumental-513154.mp3` | The Mountain | User-provided local import | BPM tag or automatic waveform analysis |
| `the_mountain-instrumental-508025.mp3` | The Mountain | User-provided local import | BPM tag or automatic waveform analysis |
| `leberch-instrumental-instrumental-piano-music-522790.mp3` | Leberch | User-provided local import | BPM tag or automatic waveform analysis |
| `leberch-instrumental-516791.mp3` | Leberch | User-provided local import | BPM tag or automatic waveform analysis |
| `atlasaudio-instrumental-519455.mp3` | AtlasAudio | User-provided local import | BPM tag or automatic waveform analysis |

## Processing Notes

- Source Ogg files are stored in `Beatrun/Audio/SourceOgg/`.
- iOS playback files are AAC `.m4a` transcodes stored in `Beatrun/Audio/Processed/`.
- User-imported MP3 files are stored in `Beatrun/Audio/UserLibrary/`.
- Runtime BPM analysis is implemented in `Beatrun/AudioBPMAnalyzer.swift`.
- Transcoding command shape:

```zsh
ffmpeg -y -i source.ogg -c:a aac -b:a 128k -movflags +faststart output.m4a
```

## License Review Notes

Wikimedia Commons machine-readable metadata reported `LicenseShortName=CC0` and `AttributionRequired=false` for these files when they were selected on 2026-06-13.

Some Commons imports from Free Music Archive may still carry maintenance categories such as `License review needed (audio)`. Keep the source URLs and original Ogg files in the repository, and re-check the Commons/FMA pages before App Store distribution or public competition packaging.
