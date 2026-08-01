# JARVIS AI Assistant

A production-grade Flutter application featuring a Dark Obsidian aesthetic, glassmorphic UI, and an animated glowing orb assistant.

## Features

- **Dark Obsidian Theme**: A premium, minimal, and elegant dark interface.
- **Glassmorphism**: Modern UI elements with blur and transparency effects.
- **Animated Glowing Orb**: Visualizes assistant states (Idle, Listening, Processing, Speaking).
- **n8n Integration**: Fully integrated with n8n webhooks for voice processing and audio responses.
- **Clean Architecture**: Built using a modular, feature-first structure.
- **Riverpod State Management**: Robust and scalable state management.

## CI/CD Pipeline

The project includes a GitHub Actions workflow that automatically builds and signs a production APK on every push to the `main` branch.

### Required Secrets

To enable the APK build, add the following secrets to your GitHub repository:

- `KEYSTORE_BASE64`: The base64-encoded string of your `.jks` keystore file.
- `KEYSTORE_PASSWORD`: The password for your keystore.
- `KEY_PASSWORD`: The password for your key.
- `KEY_ALIAS`: The alias for your key.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Run `dart run build_runner build --delete-conflicting-outputs` to generate the `ChatMessage` model files.
4. Run `flutter run` to launch the app.
5. On first launch, open **Settings** and enter your n8n webhook URL — it's stored on-device via `shared_preferences`, not hardcoded.

## Known limitations

- **Wake-word detection** (`wake_word_service.dart`) uses simple audio-energy thresholding as a placeholder. It is not real speech/keyword recognition. For genuine hands-free "Hey Jarvis" activation, integrate a proper on-device wake-word engine (e.g. Picovoice Porcupine) before relying on this in production.
- The n8n webhook is expected to accept `{ user_id, chat_id, message_type, text, audio_base64 }` and return `{ request_id, text, tool_used, audio_base64 }`. Update `ApiClient.postToWebhook` if your workflow's contract differs.

## License

MIT
