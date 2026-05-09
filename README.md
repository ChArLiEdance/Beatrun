# Beatrun

Beatrun is an iOS running music app that helps runners find music matching their target cadence, then overlays a synced metronome so each beat lands cleanly with the music.

The long-term goal is to make running cadence easier to maintain: the user chooses a steps-per-minute target, Beatrun finds suitable music, aligns the song rhythm with a metronome, and plays a steady, "on-beat" running track.

## Core Idea

Many running playlists use 180 BPM music because a stable tempo can help runners keep a consistent stride. Beatrun extends that idea by combining three parts:

1. Music discovery for the runner's selected cadence.
2. A generated metronome click at the target frequency.
3. Beat alignment so the metronome matches the song's drum rhythm instead of feeling random or off-beat.

## User Flow

1. The user opens Beatrun and selects a target running cadence, such as 160, 170, or 180 steps per minute.
2. The user chooses whether they want instrumental music or music with vocals.
3. Beatrun searches for music with a suitable tempo and rhythm profile.
4. Beatrun analyzes the selected track's beat grid.
5. Beatrun generates a metronome at the selected cadence.
6. Beatrun aligns the metronome clicks with the song's drum beats.
7. If the user changes cadence, Beatrun finds a new suitable track or adjusts the current matching process.

## Main Features

### 1. Cadence-Based Music Discovery

Beatrun should recommend tracks that fit the user's current running cadence.

Initial version:

- Let users select a target cadence.
- Let users choose between instrumental and vocal music.
- Search for tracks whose BPM is close to the target cadence.
- Prefer songs with clear rhythmic structure and stable tempo.

Future versions:

- Add custom genre filters.
- Add mood and energy filters.
- Save favorite cadence playlists.
- Support user-provided music files where legally allowed.

### 2. Metronome Generation

Beatrun should generate a clear metronome sound at the selected cadence.

Initial version:

- Use one default click sound.
- Generate clicks at the target steps-per-minute frequency.
- Keep timing stable during playback.

Future versions:

- Add multiple metronome sound choices.
- Add volume control for the click track.
- Add downbeat accents.
- Add left/right step cues.

### 3. Beat and Metronome Alignment

This is the most important part of the app. The metronome should not simply play over the music; it should lock onto the song's rhythm.

Initial version:

- Detect or receive the song BPM.
- Estimate the song beat grid.
- Align the metronome phase with the strongest beat positions.
- Keep the metronome synchronized during playback.

Future versions:

- Improve beat detection for songs with tempo drift.
- Support half-time and double-time matching.
- Handle intro sections before the main drum pattern starts.
- Add automatic beat correction when sync drifts.
- Support offline preprocessing for downloaded or user-owned tracks.

## Music Source and Copyright Strategy

Beatrun must use legal music sources. The app should not scrape, download, or redistribute copyrighted music without permission.

Possible implementation paths:

- Use licensed music APIs or streaming integrations.
- Use preview clips where the provider allows analysis and playback.
- Use royalty-free, public-domain, or creator-licensed tracks.
- Let users import music they own, if the platform and license allow it.

The music discovery system should store metadata such as BPM, vocal/instrumental type, genre, energy, and beat confidence. Actual full-track playback must follow the rules of the selected music provider.

## Technical Plan

### iOS App

- SwiftUI for the user interface.
- AVFoundation for audio playback and timing.
- A cadence picker for steps per minute.
- Music preference controls for instrumental or vocal tracks.
- Playback screen with music, metronome, and sync state.

### Audio Analysis

- Track BPM detection or metadata lookup.
- Beat onset detection.
- Beat grid estimation.
- Phase alignment between detected beat positions and generated metronome clicks.
- Sync monitoring during playback.

### Data Model

Potential track metadata:

- Track title
- Artist
- Source provider
- BPM
- Instrumental or vocal
- Genre
- Energy level
- Beat confidence score
- Playback or preview URL, depending on provider permissions

## MVP Roadmap

### Phase 1: App Skeleton

- Build the basic SwiftUI app structure.
- Add cadence selection.
- Add instrumental/vocal preference toggle.
- Add a placeholder music recommendation list.
- Add a basic metronome engine.

### Phase 2: Local Beat Matching Prototype

- Use a small set of test tracks with known BPM.
- Generate metronome clicks.
- Align clicks with known beat positions.
- Build a playback UI for testing sync quality.

### Phase 3: Music Discovery

- Choose a legal music source.
- Fetch music metadata.
- Filter tracks by cadence and vocal preference.
- Rank tracks by BPM closeness and beat confidence.

### Phase 4: Automatic Sync

- Add beat detection or beat-grid import.
- Align click phase automatically.
- Handle cadence changes by selecting a new track or recalculating sync.

### Phase 5: Apple Watch Support

- Create a watchOS companion app.
- Show cadence and playback status on Apple Watch.
- Explore integration with Apple Watch workout sessions.
- Keep iPhone and Watch state synchronized.

## Current Status

Beatrun is currently at the project setup stage. The repository contains a minimal SwiftUI iOS app and the first version of the product plan.

## Requirements

- Xcode 26.4.1 or later recommended
- iOS 18 or later
- SwiftUI
- AVFoundation

## Getting Started

Open `Beatrun.xcodeproj` in Xcode, select an iPhone simulator, then run the `Beatrun` scheme.

## License

This project is released under the MIT License. Anyone using, copying, modifying, or distributing this software must keep the copyright notice and license text.
