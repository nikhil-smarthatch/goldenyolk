# PoultryPro - Flutter Poultry Farm Management App

A comprehensive, offline-first mobile application for managing poultry farms. Built with Flutter and SQLite.

## Features

### Core Modules
- **Dashboard**: Overview with summary cards, weekly production charts, and alerts
- **Flock Management**: Track batches, breeds, counts, and mortality
- **Egg Collection**: Daily logging with production trends
- **Sales Management**: Record egg and chicken sales with payment tracking
- **Feed & Inventory**: Purchase tracking, usage logging, and stock alerts
- **Expense Tracker**: Categorized expense logging with breakdown analytics
- **Reports & Analytics**: Profit/loss reports, production statistics, charts
- **Settings**: Farm info, currency, backup/restore, dark mode

## Tech Stack

- **Flutter** (latest stable)
- **Riverpod** for state management
- **SQLite** (sqflite) for local persistence
- **fl_chart** for data visualization
- **Material 3** design system

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd poultrypro
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
├── app.dart                  # App widget & navigation
├── core/
│   ├── database/            # DB helper & seeder
│   ├── models/              # Data models
│   ├── providers/           # State management
│   └── utils/               # Utilities & helpers
├── features/                # Feature modules
│   ├── dashboard/
│   ├── flock/
│   ├── eggs/
│   ├── sales/
│   ├── feed/
│   ├── expenses/
│   ├── reports/
│   └── settings/
└── widgets/                 # Shared widgets
```

## Database Schema

The app uses SQLite with the following tables:
- `flocks` - Flock batch information
- `mortality_log` - Death records
- `egg_collection` - Daily egg collection
- `egg_sales` - Egg sales records
- `chicken_sales` - Chicken sales records
- `feed_purchases` - Feed inventory
- `feed_usage` - Daily feed consumption
- `expenses` - Other expenses

## Offline Support

All data is stored locally using SQLite. The app works completely offline with:
- Local database persistence
- Automatic data seeding on first launch
- Backup/restore functionality (JSON export/import)

## Screenshots

*(Screenshots to be added)*

## License

MIT License
# goldenyolk
