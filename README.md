# Audiobook Mixer / Booktune

An immersive audiobook player that blends your stories with ambient sounds. This Flutter application is designed to create a unique and customizable listening experience by allowing you to mix audiobook playback with background ambiances like rain, a fireplace, or a café.

## Features

- **Audiobook Library**: Import and manage your audiobook files (MP3, M4A, OGG, etc.) in a local library.
- **Text-to-Speech (TTS)**: Import text files (.txt) and have them read aloud by a TTS engine, effectively turning any e-book into an audiobook.
- **Ambient Sound Mixer**: Play a background ambient sound from a predefined list (fireplace, rain, forest...) while listening to your audiobook.
- **Independent Volume Controls**: Adjust the volume of the audiobook and the ambient sound separately for the perfect mix.
- **Playback Progress**: The app saves your progress for each book, allowing you to pick up where you left off.
- **Modern UI**: A sleek, dark-themed, and easy-to-navigate user interface.

## Architecture

This project is built using a clean and scalable architecture, leveraging well-known Flutter packages and patterns:

- **State Management**: `provider` is used for state management, separating UI from business logic.
- **Service Layer**: A dedicated service layer handles business logic and interactions with data sources (e.g., `DatabaseService`, `FileImportService`, `AudioPlayerService`).
- **Database**: `sqflite` is used for local data persistence, storing information about the audiobook library, progress, and preferences.
- **Audio Playback**: `just_audio` provides the powerful and flexible audio playback engine.

## Recent Improvements (Branch: booktune)

### Logging System
- Added centralized logging with `logger` package
- Created `LoggingService` for consistent and structured logging
- Replaced all `print()` statements with proper logging calls

### Caching
- Added `CacheService` for managing network file cache
- Improved LibriVox streaming performance
- Added cache size tracking and management

### Testing
- Added unit tests for `CacheService`
- Added unit tests for `PlayerProvider`
- Improved test coverage

### Error Handling
- Improved error handling across all providers
- Better error logging and notifications

## Getting Started

This project is a standard Flutter application. To get started, ensure you have the Flutter SDK installed.

1.  **Clone the repository (or download the source code).**
    ```sh
    git checkout booktune  # Switch to improvements branch
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Run the application:**
    ```sh
    flutter run
    ```

## Running Tests

```sh
flutter test
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
