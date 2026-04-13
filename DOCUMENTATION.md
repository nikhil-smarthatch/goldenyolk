# Golden Yolk - Poultry Farm Management App

## Overview

Golden Yolk (also known as PoultryPro) is a comprehensive, offline-first mobile application for managing poultry farms. Built with Flutter and SQLite, it provides complete offline functionality for tracking flocks, egg production, sales, feed inventory, and expenses. The app supports pre-orders (future delivery dates), real-time inventory tracking, and detailed analytics.

## Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter (Dart) | >=3.0.0 |
| State Management | Riverpod | ^2.4.9 |
| Database | SQLite (sqflite) | ^2.3.0 |
| Charts | fl_chart | ^0.66.0 |
| UI Design | Material 3 | - |
| Localization | intl | ^0.18.1 |
| PDF Generation | pdf | ^3.10.7 |
| Data Export | share_plus | ^7.2.1 |
| Shimmer Effect | shimmer | ^3.0.0 |
| File Picker | file_picker | ^8.0.0 |

---

## Architecture

The app follows **Clean Architecture** principles with a feature-based folder structure:

```
lib/
├── app.dart                    # App widget & MaterialApp configuration
├── main.dart                   # Entry point with error logging setup
│
├── core/                       # Shared core functionality
│   ├── database/
│   │   ├── db_helper.dart      # Singleton DatabaseHelper class
│   │   └── database_seeder.dart # Initial data seeding
│   │
│   ├── models/
│   │   ├── models.dart         # Barrel file exporting all models
│   │   ├── egg_sale.dart       # Order model with pre-order support
│   │   ├── egg_collection.dart # Daily egg collection model
│   │   ├── flock.dart          # Flock/batch model
│   │   ├── mortality_log.dart  # Death record model
│   │   ├── feed_purchase.dart  # Feed inventory model
│   │   ├── feed_usage.dart     # Feed consumption model
│   │   └── expense.dart        # Expense tracking model
│   │
│   ├── providers/
│   │   ├── providers.dart      # Barrel file
│   │   ├── egg_provider.dart   # Egg collection state management
│   │   ├── sales_provider.dart # Order management (CRUD + status)
│   │   ├── flock_provider.dart # Flock management
│   │   ├── feed_provider.dart  # Feed inventory & usage
│   │   ├── expense_provider.dart # Expense tracking
│   │   ├── report_provider.dart # Monthly reports
│   │   ├── settings_provider.dart # App settings persistence
│   │   ├── theme_provider.dart # Dark/light mode
│   │   └── customer_pricing_provider.dart # Buyer price history
│   │
│   ├── services/
│   │   ├── data_export_service.dart # JSON/CSV export & sharing
│   │   └── error_logger.dart   # Error logging to file
│   │
│   └── utils/
│       ├── utils.dart          # Barrel file
│       ├── app_colors.dart     # Centralized color palette
│       ├── date_helpers.dart   # Date formatting & ranges
│       ├── formatters.dart     # Currency & number formatting
│       ├── validators.dart     # Input validation
│       └── exceptions.dart     # Custom exceptions
│
├── features/                   # Feature modules (screens)
│   ├── dashboard/
│   │   └── dashboard_screen.dart # Home with stats & pending orders
│   │
│   ├── eggs/
│   │   ├── eggs_screen.dart    # Egg collection list
│   │   └── add_egg_collection_screen.dart # Add/edit collection
│   │
│   ├── sales/
│   │   ├── sales_screen.dart   # Order list with status
│   │   ├── add_egg_sale_screen.dart # Create pre-order/order
│   │   └── egg_sale_detail_screen.dart # Order details
│   │
│   ├── flock/
│   │   ├── flock_screen.dart   # Flock list
│   │   ├── flock_detail_screen.dart # Flock history
│   │   └── add_flock_screen.dart # Add new flock
│   │
│   ├── feed/
│   │   ├── feed_screen.dart    # Feed inventory
│   │   ├── add_feed_purchase_screen.dart # Purchase feed
│   │   └── add_feed_usage_screen.dart # Log usage
│   │
│   ├── expenses/
│   │   ├── expenses_screen.dart # Expense list
│   │   └── add_expense_screen.dart # Add expense
│   │
│   ├── reports/
│   │   ├── reports_screen.dart # Analytics dashboard
│   │   └── monthly_report_screen.dart # Detailed monthly view
│   │
│   ├── settings/
│   │   └── settings_screen.dart # App configuration
│   │
│   ├── splash/
│   │   └── splash_screen.dart  # App launch screen
│   │
│   └── features.dart           # Barrel file
│
└── widgets/
    └── widgets.dart            # Shared UI components
```

---

## Database Schema

### Entity Relationship Diagram

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   flocks    │────▶│  mortality_log   │     │ egg_collection  │
├─────────────┤     ├──────────────────┤     ├─────────────────┤
│ id (PK)     │     │ id (PK)          │     │ id (PK)         │
│ name        │     │ flock_id (FK)    │     │ flock_id (FK)   │
│ breed       │     │ date             │     │ date            │
│ initial_cnt │     │ count            │     │ collected       │
│ date_acq    │     │ reason           │     │ broken          │
│ purpose     │     │ notes            │     │ notes           │
│ notes       │     └──────────────────┘     └─────────────────┘
└─────────────┘
         │
         │          ┌─────────────────┐
         └─────────▶│   feed_usage    │
                    ├─────────────────┤
                    │ id (PK)         │
                    │ flock_id (FK)   │
                    │ date            │
                    │ quantity_kg     │
                    └─────────────────┘

┌─────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│  egg_sales      │   │ feed_purchases  │   │     expenses     │
├─────────────────┤   ├─────────────────┤   ├──────────────────┤
│ id (PK)         │   │ id (PK)         │   │ id (PK)          │
│ order_date      │   │ date            │   │ date             │
│ delivery_date   │   │ feed_type       │   │ category         │
│ quantity        │   │ quantity_kg     │   │ description      │
│ price_per_unit  │   │ price_per_unit  │   │ amount           │
│ buyer           │   │ supplier        │   │ notes            │
│ status          │   │ notes           │   └──────────────────┘
│ notes           │   └─────────────────┘
└─────────────────┘

┌─────────────────────┐
│  customer_pricing   │
├─────────────────────┤
│ id (PK)             │
│ buyer_name (UNIQUE) │
│ price_per_unit      │
│ last_used_date      │
└─────────────────────┘
```

### Table Details

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `flocks` | Track chicken batches | breed, initial_count, date_acquired |
| `mortality_log` | Death records per flock | flock_id, date, count, reason |
| `egg_collection` | Daily egg counts | flock_id, collected, broken, date |
| `egg_sales` | Orders with pre-order support | order_date, delivery_date, status |
| `feed_purchases` | Feed inventory | feed_type, quantity_kg, price |
| `feed_usage` | Daily feed consumption | flock_id, quantity_kg, date |
| `expenses` | Farm expenses | category, amount, date |
| `customer_pricing` | Buyer price history | buyer_name, price_per_unit |

### Key Indexes
- `idx_mortality_flock_id` - Mortality lookup by flock
- `idx_egg_collection_date` - Date range queries
- `idx_egg_sales_order_date` - Order date filtering
- `idx_feed_purchases_date` - Purchase history

---

## State Management (Riverpod)

### Provider Types

```dart
// 1. StateNotifierProvider - For CRUD with loading states
final eggSalesProvider = StateNotifierProvider<EggSalesNotifier, AsyncValue<List<EggSale>>>((ref) {
  return EggSalesNotifier(ref);
});

// 2. FutureProvider - For read-only computed data
final remainingStockProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getRemainingEggStock();
});

// 3. Provider - For derived/filtered state
final pendingOrdersProvider = Provider<AsyncValue<List<EggSale>>>((ref) {
  final salesAsync = ref.watch(eggSalesProvider);
  return salesAsync.when(
    data: (sales) => AsyncValue.data(
      sales.where((s) => s.status == 'ordered').toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
```

### Provider Invalidation Pattern

After any mutation, invalidate related providers:
```dart
Future<void> markAsDelivered(int id) async {
  await _db.updateEggSale(...);
  await loadSales();
  _ref.invalidate(todayEggSalesProvider);
  _ref.invalidate(remainingStockProvider);
  _ref.invalidate(pendingOrdersProvider);
}
```

---

## Core Features

### 1. Dashboard (dashboard_screen.dart)

**Components:**
- **Header**: Greeting, farm name, date chip, settings button
- **Stats Row**: Live chickens, eggs today, revenue, egg stock, feed stock
- **Manage Farm**: 4-card grid (Flock, Eggs, Sales, Feed)
- **Weekly Production**: 7-day bar chart using fl_chart
- **Quick Actions**: Expenses and Reports buttons
- **Pending Orders**: List of undelivered orders with deliver action

**Features:**
- Pull-to-refresh invalidates all providers
- Animated header with fade/slide
- Real-time stock calculation

### 2. Pre-Order System (egg_sales table)

**Status Lifecycle:**
```
ordered → delivered (stock deducted)
ordered → cancelled (no stock change)
```

**Key Features:**
- `order_date`: When order was placed (can be future date)
- `delivery_date`: When actually delivered
- Stock validation before delivery
- Pending orders shown on dashboard

**Database Methods:**
```dart
Future<List<EggSale>> getPendingOrders()  // Status = 'ordered'
Future<int> getPendingOrdersCount()       // Quick count
Future<int> getPendingOrderEggCount()     // Total egg quantity pending
```

### 3. Inventory Management

**Stock Formula:**
```
Remaining Stock = Σ(collected - broken) - Σ(delivered quantity)
Available for Sale = Remaining - Pending Orders
```

**Key Methods:**
```dart
getRemainingEggStock()        // Current available stock
getPendingOrderEggCount()     // Eggs committed to orders
getInventorySummary()         // Complete breakdown
```

### 4. Order Management

**EggSale Model:**
```dart
class EggSale {
  DateTime orderDate;      // Order creation date
  DateTime? deliveryDate;  // Set when delivered
  int quantity;
  double pricePerUnit;
  String status;           // 'ordered', 'delivered', 'cancelled'
  // ...
}
```

**Notifier Methods:**
- `addOrder()` - Create pre-order
- `markAsDelivered()` - Fulfill order (checks stock first)
- `cancelOrder()` - Cancel pending order
- `updateOrder()` - Edit existing order

### 5. Flock Management

**Live Chicken Calculation:**
```sql
SELECT SUM(initial_count) - SUM(mortality) as live_count
FROM flocks f
LEFT JOIN mortality_log m ON f.id = m.flock_id
```

**Features:**
- Add flocks with breed, count, acquisition date
- Log mortality with reason
- Flock detail with mortality history
- Automatic live count on dashboard

### 6. Reports & Analytics

**Monthly Reports:**
- Eggs laid/broken/sold
- Revenue (delivered orders only)
- Remaining stock (cumulative)
- Daily breakdown charts
- Profit/Loss with expense breakdown

**Export Options:**
- JSON backup (complete database)
- CSV export (sales, collections, expenses)
- Share via native share sheet

### 7. Production Features

**Error Logging:**
```dart
// Global error handling in main.dart
FlutterError.onError = (FlutterErrorDetails details) {
  ErrorLogger.instance.log(...);
};
```

**Android Auto-Backup:**
- Configured in `AndroidManifest.xml`
- `data_extraction_rules.xml` includes database & shared preferences
- Cloud and device transfer support

---

## Key Workflows

### Creating a Pre-Order
1. User fills buyer, quantity, price, future order date
2. `EggSalesNotifier.addOrder()` called
3. Saved with `status = 'ordered'`, `delivery_date = null`
4. `pendingOrdersProvider` auto-updates
5. Order appears on dashboard pending list

### Delivering an Order
1. User taps deliver button on dashboard or sales screen
2. `EggSalesNotifier.markAsDelivered()` called
3. Stock validation: checks if eggs available
4. If insufficient stock → shows error message
5. If sufficient stock → updates status to 'delivered'
6. `delivery_date` set to current time
7. Providers invalidated → dashboard updates

### Daily Egg Collection
1. User selects flock and enters collected/broken counts
2. `EggCollectionNotifier.addCollection()` saves to database
3. Invalidates:
   - `todayEggCollectionProvider`
   - `remainingStockProvider`
   - `weeklyEggProductionProvider`
4. Dashboard stats update automatically

---

## Utility Classes

| Class | Location | Purpose |
|-------|----------|---------|
| `DatabaseHelper` | `core/database/db_helper.dart` | Singleton for all DB operations |
| `DateHelpers` | `core/utils/date_helpers.dart` | Formatting, range calculations |
| `CurrencyFormatter` | `core/utils/formatters.dart` | Money formatting with ₹ or $ |
| `NumberFormatter` | `core/utils/formatters.dart` | Indian number format (1,00,000) |
| `AppColors` | `core/utils/app_colors.dart` | Color constants |

---

## Services

### DataExportService
```dart
static Future<String> exportAllData()      // JSON backup
static Future<String> exportToCSV()        // CSV report
static Future<void> shareExportFile(path) // Native share
```

### ErrorLogger
```dart
static final ErrorLogger instance;
Future<void> log(String message, {String level, Object? error, StackTrace? stackTrace})
Future<String> getLogs()
Future<void> clearLogs()
```

---

## UI Components

### Shared Widgets (widgets.dart)
- `LoadingShimmer` - Skeleton loader for async states
- `SummaryCard` - Metric display with icon
- `DatePickerField` - Date input with Material picker
- `StatusChip` - Colored status indicators (ordered/delivered/cancelled)
- `SwipeableListItem` - Delete/edit gestures
- `EmptyState` - No data illustration

### Design System
- **Color Palette**: Farm-themed greens (#2E7D32, #4CAF50, #66BB6A)
- **Typography**: Inter font family
- **Cards**: White with subtle shadows, 16-22px border radius
- **Icons**: Emoji-based icons for friendly feel
- **Layout**: Sliver-based scrolling for smooth performance

---

## Data Flow Architecture

```
┌─────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────┐
│   UI    │────▶│ Provider │────▶│ DatabaseHelper│────▶│  SQLite  │
│ (Widget)│     │(Riverpod)│     │  (Singleton) │     │ (poultry │
└─────────┘     └──────────┘     └──────────────┘     │  pro.db) │
     ▲                  │                                  └──────────┘
     │                  │
     └──────────────────┘
        AsyncValue<T>
           (data/loading/error)
```

---

## Offline Capability

- **100% Offline**: SQLite database, no cloud dependencies
- **Auto-Backup**: Android cloud backup configured
- **Manual Export**: JSON/CSV export for data portability
- **Restore**: Import JSON to restore all data

---

## Development Commands

```bash
# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Analyze code
flutter analyze

# Clean build cache
flutter clean && flutter pub get
```

---

## License

MIT License

---

*Generated: March 31, 2026*
