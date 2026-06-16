# Codex for Open Source Application Draft

This draft is written for the Codex for Open Source application form.
Replace bracketed fields before submitting.

Official program reference:
https://developers.openai.com/community/codex-for-oss

## Project Basics

Project name: Beatrun

Repository: https://github.com/ChArLiEdance/Beatrun

License: MIT

Primary maintainer: Charlie

Maintainer role: Core maintainer and repository owner with write access.

Project type: Open-source iOS and watchOS app prototype.

Technology stack: Swift, SwiftUI, AVFoundation, WatchConnectivity, Xcode.

## Short Description

Beatrun is an open-source iOS running cadence app that helps runners match music rhythm to a target step cadence. A runner chooses a target cadence, Beatrun recommends copyright-safe demo tracks, and the app plays a tempo-adjusted generated backing loop with a synchronized metronome click.

The current MVP focuses on safe, transparent 1:1 BPM matching. It includes an iOS demo interface, a watchOS companion target, WatchConnectivity state sharing, beat-boundary queue transitions, and documented audio rights metadata so the project can demonstrate cadence-music synchronization without redistributing unauthorized commercial music.

## Why This Project Matters

Running cadence training is useful for beginner runners, recreational runners, school running groups, and athletes trying to keep a stable rhythm during warm-ups, long runs, and intervals. Existing playlist and metronome workflows often separate music discovery from cadence control, and many prototypes in this area are unclear about music licensing.

Beatrun contributes an open, inspectable implementation path for:

- cadence-to-BPM matching in a mobile training interface;
- copyright-safe demo audio generation and rights metadata;
- synchronized metronome and generated backing-loop playback with AVFoundation;
- iOS to watchOS state sharing for companion workout controls;
- clear separation between current prototype behavior and future licensed music or HealthKit integrations.

Even before broad adoption, Beatrun can be useful as a practical open-source reference for developers building rhythm-aware fitness tools, legal-audio demos, SwiftUI app prototypes, and Apple Watch companion flows.

## Current State

Beatrun currently supports:

- target cadence selection from 140 to 200 steps per minute;
- instrumental and vocal-style generated demo track preferences;
- an offline demo catalog with original BPM, adjusted BPM, beat-grid confidence, rights metadata, attribution, and tempo-adjustment permission;
- 1:1 BPM matching only, with tempo adjustment capped at +/-10%;
- automatic best-match rediscovery after cadence or preference changes;
- generated backing-loop and metronome playback through AVFoundation;
- beat-boundary playback queue transitions with an MVP-level 4-beat crossfade;
- iOS UI for current track, upcoming track, transition countdown, target cadence, adjusted BPM, tempo shift, rights status, and beat count;
- watchOS companion UI with Play/Pause, Stop, cadence +/-5 controls, sync state, current/next track, crossfade state, BPM, shift, and beat count;
- documentation for the demo catalog, development log, competition roadmap, submission checklist, and build commands.

Recent maintenance work includes polishing the iOS demo interface, adding WatchConnectivity payloads, adding a watchOS companion target, documenting copyright-safe demo audio, and repeatedly verifying iOS/watchOS simulator builds.

## Maintenance Burden

As the sole maintainer, I need to handle product iteration, SwiftUI implementation, audio-engine changes, watchOS companion behavior, documentation, issue triage, build verification, and future contributor review. The project touches several areas where regressions are easy to miss: audio timing, cadence matching rules, WatchConnectivity reachability, Xcode project configuration, legal-audio wording, and user-facing documentation.

The highest-value maintenance tasks are:

- reviewing pull requests for SwiftUI, AVFoundation, and WatchConnectivity changes;
- keeping matching rules honest and documented;
- adding focused tests or simulator verification for queue transitions and Watch commands;
- checking that demo audio remains copyright-safe;
- improving release and submission checklists;
- preparing future HealthKit, Workout Session, and licensed-audio integrations without overclaiming features that are not implemented yet.

## How Codex Support Would Help

Six months of ChatGPT Pro with Codex would help with daily development and maintenance work:

- implement focused Swift and SwiftUI improvements while preserving existing app behavior;
- review PRs for timing regressions, unsafe audio assumptions, and watchOS state bugs;
- triage issues into product, audio, WatchConnectivity, documentation, and build-system work;
- generate and maintain repeatable simulator verification checklists;
- improve documentation so contributors understand the 1:1 BPM rule, +/-10% tempo limit, generated-audio strategy, and future integration boundaries;
- keep release notes, changelogs, and submission materials synchronized with the actual code.

API credits would be used for maintainer automation and core OSS workflows, not for unrelated commercial usage. Planned workflows include:

- PR review summaries focused on SwiftUI, AVFoundation, WatchConnectivity, and Xcode project risks;
- issue triage that labels cadence matching, audio playback, watchOS, documentation, and legal-audio topics;
- automated release-note and changelog draft generation from merged commits;
- documentation consistency checks across README, demo catalog, roadmap, and submission materials;
- future lightweight contributor-assistance tools for explaining matching decisions and demo-audio metadata.

Conditional Codex Security access would be useful as the project grows because future versions may handle HealthKit data, workout sessions, licensed music-provider integrations, and device connectivity paths. Security review would help identify privacy, entitlement, data-handling, dependency, and authorization risks before those features become user-facing.

## Six-Month Plan

Month 1:

- add focused test coverage or repeatable simulator scripts for 1:1 matching, tempo filtering, and queue transition behavior;
- improve contributor documentation and project setup instructions;
- add issue templates for bugs, feature requests, audio-rights questions, and watchOS reports.

Months 2-3:

- verify WatchConnectivity on paired simulators or real devices;
- add structured regression checks for playback state, cadence changes, and transition countdowns;
- prepare a contributor-friendly roadmap for HealthKit and Workout Session work.

Months 4-5:

- evaluate safe integration paths for royalty-free or licensed audio providers;
- document privacy and copyright requirements before accepting integrations;
- add release automation for changelogs and verification records.

Month 6:

- use Codex-assisted review and security checks to harden the next public release;
- publish clearer examples for developers who want to build cadence-aware fitness experiences in SwiftUI.

## Honest Scope Statement

Beatrun is not claiming large-scale adoption yet. It is an actively maintained public MIT-licensed project with a clear open-source purpose: to make cadence-aware running music, legal demo audio, AVFoundation timing, and iOS/watchOS companion workflows easier to inspect, reuse, and improve.

The project does not scrape, download, stream, redistribute, or package unauthorized commercial music. The current MVP uses generated demo audio and documents the source, rights status, tempo adjustment permission, and beat-grid confidence for every demo track.

## Suggested Form Answers

### What does your project do?

Beatrun is an open-source iOS and watchOS running cadence app. It lets a runner choose a target step cadence, recommends copyright-safe generated demo tracks, and plays a tempo-adjusted backing loop with a synchronized metronome click. The current MVP focuses on transparent 1:1 BPM matching, AVFoundation playback, beat-boundary queue transitions, and WatchConnectivity companion controls.

### Why is your project important to the open-source ecosystem?

Beatrun provides an inspectable SwiftUI reference for cadence-aware fitness apps, legal-audio demo workflows, AVFoundation timing, and Apple Watch companion state. Many rhythm or running-music ideas depend on unclear licensing or closed implementations; Beatrun documents its matching rules, generated-audio strategy, and limitations so other developers can learn from or extend the work safely.

### How would you use Codex, Codex Security, or API credits?

I would use Codex for daily maintenance, PR review, issue triage, SwiftUI/watchOS implementation, documentation, and release workflows. API credits would support OSS automation such as PR summaries, issue labeling, changelog drafts, and documentation consistency checks. Codex Security would help review future HealthKit, Workout Session, licensed-audio, and connectivity features for privacy, entitlement, and data-handling risks.

### What maintenance work is currently most difficult?

The hardest work is keeping audio timing, cadence matching, watchOS state, Xcode configuration, and legal-audio documentation aligned as the app evolves. Small changes can affect playback synchronization, queue transitions, or WatchConnectivity behavior. Codex would help review these changes, generate targeted tests and verification checklists, and keep documentation honest about what is implemented.

### Who uses or benefits from the project?

The direct users are runners and developers interested in cadence training, rhythm-aware workout tools, and iOS/watchOS fitness prototypes. The current project is also useful to open-source Swift developers because it demonstrates generated demo audio, rights metadata, 1:1 BPM matching, AVFoundation playback, and WatchConnectivity in a compact, documented app.

### Anything else the review team should know?

Beatrun is intentionally conservative about copyright and health-data claims. The MVP uses local generated demo audio only, disables double-time and half-time matching, limits tempo changes to +/-10%, and clearly documents that HealthKit and Workout Session features are not implemented yet. I want Codex support to keep the project maintainable, legally careful, and technically reliable as it grows.

## Fields To Fill Before Submission

- Maintainer email: [fill in]
- GitHub profile: [fill in]
- Current stars/forks/downloads/users: [fill in if available]
- Public project URL or demo video: [fill in if available]
- Other maintainers with write access: [fill in if any]
- Specific API credit amount requested, if the form asks: [fill in based on expected automation usage]
