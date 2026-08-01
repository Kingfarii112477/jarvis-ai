# JARVIS AI

A premium, open-source AI assistant for Android, built with Flutter. Dark Obsidian
glassmorphism UI, a procedurally-animated orb, on-device voice, and a Clean
Architecture core that routes every AI interaction through a n8n webhook you
control.

This is a from-scratch rebuild of the app previously in this repo — same core
idea (JARVIS + n8n + voice), new design language, and a much wider feature set
(chat, tasks, memory, automation, knowledge base, analytics), all wired to
real local persistence instead of placeholder screens.

## Screenshots

The dashboard, chat, voice and settings screens follow the Dark Obsidian
palette defined in `lib/core/constants/app_colors.dart` — background `#05070B`,
cards `#0D1118`, glow accents in cyan/violet/magenta, 24px rounded corners.

## Architecture

Clean Architecture, feature-first, with Riverpod for state/DI:

```
lib/
  core/
    config/       compile-time constants (box names, timeouts, contract version)
    constants/    color palette, spacing/radius scale
    network/      ApiClient (n8n), DTOs, retry interceptor, connectivity
    router/       go_router StatefulShellRoute (one branch per sidebar item)
    services/     notifications, system stats (battery/memory/uptime)
    storage/      Hive (encrypted) + flutter_secure_storage wrappers
    theme/        ThemeData, typography, accent colors
    utils/        Result<T>, typed AppException hierarchy, logger
  features/
    assistant/    the Dashboard/home screen (orb hero, quick actions, stats)
    chat/         markdown chat, sessions, streaming reveal
    voice/        full-screen voice UI, STT/TTS, wake word, push-to-talk
    tasks/        task manager (Hive-backed CRUD)
    automation/   n8n workflow registry, manual runs, execution history
    memory/       persistent memory store with categories + search
    knowledge/    document import/index (file_picker) + keyword search
    analytics/    local usage log + fl_chart dashboards
    settings/     theme, voice, privacy, backend, developer mode
  shared/
    widgets/      GlassCard, GlowButton, JarvisOrb, nav rail, stat tiles
```

Each feature follows `domain/` (freezed models) → `data/` (repository over a
Hive box) → `presentation/` (Riverpod `StateNotifier` + screen). There is no
`Provider`/`GetX`/`Bloc` anywhere — state management is Riverpod only.

## The orb

`lib/shared/widgets/orb/` — a `CustomPainter` driven by four looping
`AnimationController`s (breathe, rotate, counter-rotate, wave) plus a small
particle simulation. It has seven moods (`AssistantMood`): idle, listening,
processing, speaking, offline, error, success, each with a distinct visual
treatment (ping rings, rotating energy field, reactive waveform, error burst,
success ripple). When a real microphone/playback amplitude is available it's
passed in and genuinely deforms the waveform; otherwise the orb still
animates procedurally rather than sitting static.

This is real per-frame Canvas painting, not a Lottie loop — "shaders" in the
GLSL/`FragmentProgram` sense were considered but skipped in favor of
`CustomPainter`, which is portable, doesn't need an asset pipeline, and is
what most production Flutter apps use for this effect.

## n8n integration

Every AI turn — text or voice — goes through `ApiClient.postToWebhook`, using
a fixed JSON contract:

**Request**
```json
{
  "user_id": "usr_jarvis_mobile",
  "chat_id": "chat_abc123",
  "message_type": "text | voice",
  "text": "...",
  "audio_base64": null,
  "language": "en",
  "conversation_history": [{"role": "user", "text": "..."}],
  "device": {"platform": "android", "app": "jarvis"},
  "timestamp": "2026-08-01T12:00:00.000Z"
}
```

**Response**
```json
{
  "request_id": "req_123",
  "text": "...",
  "audio_base64": null,
  "tool_used": "search",
  "latency": 480,
  "metadata": {}
}
```

`ApiClient` also supports: exponential-backoff retry on timeouts/5xx
(`RetryInterceptor`), gzip compression above 32KB, an offline outbox
(Hive-backed, auto-flushed when connectivity returns), a chunked
`streamMessage()` path for backends that stream tokens, and multipart
`uploadFile()` for document workflows.

Configure the webhook URL (and an optional bearer API key) in **Settings →
Backend** — both are stored via `flutter_secure_storage`, never hardcoded.

## Security & storage

- All structured data (chat, tasks, memory, automation, knowledge, analytics,
  settings) lives in **Hive boxes encrypted with AES-256**; the cipher key is
  generated on first launch and stored in the platform keystore via
  `flutter_secure_storage`.
- Webhook URL, API key and user id are stored exclusively in secure storage —
  never in Hive, never in plaintext prefs.
- Optional **biometric app lock** (Settings → Privacy) via `local_auth`.
- Certificate pinning is not implemented in this repo — it needs your
  backend's actual certificate/public-key hash, which this repo can't know in
  advance. `ApiClient` is structured so pinning can be added to the shared
  `Dio` instance in one place.

## Known limitations (by design, not oversight)

- **Wake word** (`features/voice/data/wake_word_engine.dart`) ships a real,
  working `EnergyThresholdWakeWordEngine` — it detects "someone spoke loudly,"
  not the specific word "Jarvis." True keyword spotting needs an on-device ML
  engine (Picovoice Porcupine, openWakeWord) that requires a native plugin and
  a model/access key this repo can't ship. The interface is pluggable —
  swap the provider override in `main.dart`.
- **Heavy blur** (`GlassCard.blurred`, real `BackdropFilter`) is off by
  default. A previous investigation in this codebase found `BackdropFilter`
  reliably grays out the whole screen on some Android GPU/driver
  combinations (see the git history around the `DIAGNOSTIC` commit this
  rebuild replaces). It's available as an opt-in under **Settings →
  Appearance → Experimental heavy blur**, with that risk disclosed in the UI.
- **Weather** was intentionally left out of the dashboard rather than shipped
  with fabricated numbers — wiring a real provider needs an API key and a
  location permission flow, both product decisions for you to make.
- **CPU/RAM tiles**: Flutter has no cross-platform "device CPU load" API
  without a native plugin, so the dashboard shows what's actually measurable
  (battery via `battery_plus`, network via `connectivity_plus`, app memory
  via `dart:io ProcessInfo.currentRss`, session uptime) instead of a
  plausible-looking fake percentage.
- **Knowledge base** extracts real text for `.txt/.md/.csv/.json`; PDF/DOCX/
  images are indexed by filename only. Full-document extraction needs either
  a Dart PDF/OOXML parser or routing the file through your n8n backend via
  `ApiClient.uploadFile`.
- **Push notifications** (remote/FCM) aren't wired up — that needs a Firebase
  project you'd have to create. Local notifications (task reminders, via
  `flutter_local_notifications`) work today.
- **Semantic/vector memory search** isn't implemented — the memory store uses
  on-device keyword search. Real semantic search needs a vector index that
  should live on your n8n/backend side.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

On first launch, open **Settings → Backend** and set your n8n webhook URL.

## Testing

```bash
flutter analyze
flutter test
```

- `test/widget_test.dart` — the orb renders and responds to input in every
  mood.
- `test/repositories/` — Hive-backed repository CRUD (tasks, chat sessions).
- `test/core/` — the `Result<T>` type and the n8n JSON contract's snake_case
  round-trip.

## CI/CD

`.github/workflows/build_apk.yml` runs two jobs:

1. **test** — `flutter analyze` + `flutter test`, on every push and PR.
2. **build** — signed `apk` + `appbundle`, on pushes to `main`/`master` only,
   gated on `test` passing.

Add these repository secrets to enable signed release builds:

| Secret | Description |
| --- | --- |
| `KEYSTORE_BASE64` | base64-encoded `.jks` keystore |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_PASSWORD` | key password |
| `KEY_ALIAS` | key alias |

Without those secrets, the build job still runs and produces a
debug-signed APK/AAB.

## License

MIT
