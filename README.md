# Table Tally Local

A real-time accounting system built with Flutter, featuring local storage and voice memo capabilities.

## Features

- 💰 **Transaction Management**: Add, update, and delete financial transactions
- 💾 **Local Storage**: SQLite database for offline data persistence
- 🎤 **Voice Memos**: Record and attach voice notes to transactions (coming soon)
- 📊 **Balance Tracking**: Real-time balance calculation
- 📱 **Cross-platform**: Supports Android and iOS

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Local Database**: SQLite (sqflite)
- **Utilities**: intl (currency/date formatting), uuid (ID generation)
- **Audio**: flutter_sound, permission_handler
- **File System**: path_provider

## Getting Started

### Prerequisites

1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Ensure you have Android Studio or Xcode installed
3. Run `flutter doctor` to verify your setup

### Installation

1. Navigate to the project directory:
   ```bash
   cd table_tally_local
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── transaction_model.dart
├── providers/
│   └── transaction_provider.dart
├── screens/
│   └── home_screen.dart
├── services/
│   └── database_service.dart
└── utils/
```

## Usage

1. **Add Transaction**: Tap the + button to add a new transaction
2. **View Balance**: Current balance is displayed in the app bar
3. **Transaction History**: View all transactions sorted by date

## License

MIT License
