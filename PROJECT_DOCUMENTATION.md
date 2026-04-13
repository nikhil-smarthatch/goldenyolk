# Golden Yolk - Poultry Farm Management App

## Overview

Golden Yolk is a comprehensive mobile application for managing home poultry farms. Built with Flutter and SQLite, it provides complete offline functionality for tracking flocks, egg production, sales, feed inventory, and expenses.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Database**: SQLite (via sqflite package)
- **Charts**: fl_chart
- **UI Design**: Material 3

## Architecture

The app follows a feature-based architecture with clear separation of concerns:

```
lib/
├── core/           # Shared core functionality
│   ├── database/   # Database helper and seeding
│   ├── models/     # Data models
│   ├── providers/  # Riverpod state management
│   └── utils/      # Utilities (formatters, helpers, colors)
├── features/       # Feature modules
│   ├── dashboard/  # Home dashboard
│   ├── eggs/       # Egg collection management
│   ├── sales/      # Egg sales & orders
│   ├── flock/      # Flock management
│   ├── feed/       # Feed purchases & usage
│   ├── expenses/   # Expense tracking
│   ├── reports/    # Analytics & reports
│   └── settings/   # App settings
└── widgets/        # Shared UI components
```

## Database Schema

### Tables

| Table | Purpose |
|-------|---------|
| `flocks` | Flock batches with breed, acquisition date, initial count |
| `mortality_log` | Death records linked to flocks |
| `egg_collection` | Daily egg counts per flock (collected, broken) |
| `egg_sales` | Orders with status (ordered/delivered/cancelled) |
| `feed_purchases` | Feed inventory purchases |
| `feed_usage` | Daily feed consumption per flock |
| `expenses` | Other farm expenses by category |
| `customer_pricing` | Buyer-specific pricing history |

### Key Relationships

- `egg_collection.flock_id` → `flocks.id`
- `mortality_log.flock_id` → `flocks.id`
- `feed_usage.flock_id` → `flocks.id`

## State Management (Riverpod)

### Provider Types

1. **StateNotifierProvider**: For CRUD operations with loading states
   - `eggCollectionProvider` - Egg collection CRUD
   - `eggSalesProvider` - Order management
   - `FlockNotifier` - Flock management

2. **FutureProvider**: For computed/read-only data
   - `todayEggCollectionProvider` - Today's egg summary
   - `remainingStockProvider` - Current egg inventory
   - `totalLiveChickensProvider` - Live chicken count

3. **FutureProvider.family**: For parameterized queries
   - `monthlyEggReportProvider` - Monthly reports by year/month

### Provider Invalidation

Providers are invalidated after mutations to ensure UI freshness:
```dart
_ref.invalidate(todayEggCollectionProvider);
_ref.invalidate(remainingStockProvider);
```

## Core Features

### 1. Dashboard
- Live chicken count (calculated from flocks - mortality)
- Today's egg collection (good eggs + broken count)
- Today's revenue from delivered orders
- Remaining egg stock (total collected - total delivered)
- Weekly production chart (7-day bar chart)
- Quick action buttons

### 2. Flock Management
- Add flocks with breed, acquisition date, initial count
- Track mortality per flock
- Automatic live chicken calculation
- Flock detail view with history

### 3. Egg Collection
- Daily logging per flock
- Track collected and broken eggs
- Historical data by date range
- Summary statistics

### 4. Order Management (Sales)
- Create orders with buyer, quantity, price, delivery date
- Three statuses: `ordered`, `delivered`, `cancelled`
- Stock automatically deducted when marking delivered
- Customer pricing auto-fill from history

### 5. Inventory Tracking
- Real-time egg stock calculation:
  ```
  remaining = Σ(collected - broken) - Σ(delivered)
  ```
- Pending order count
- Available for sale calculation

### 6. Feed Management
- Purchase tracking (supplier, quantity, cost)
- Usage logging per flock
- Current stock calculation
- Low stock alerts

### 7. Expense Tracking
- Categorized expenses
- Date-based logging
- Monthly summaries

### 8. Reports
- Monthly egg report with:
  - Eggs laid/broken/sold
  - Revenue calculation
  - Remaining stock (cumulative)
  - Daily breakdown
- Profit/loss summary
- Production analytics

## Key Workflows

### Adding Egg Collection
1. User logs eggs per flock
2. `EggCollectionNotifier.addCollection()` called
3. Data saved to `egg_collection` table
4. Providers invalidated:
   - `todayEggCollectionProvider`
   - `remainingStockProvider`
   - `weeklyEggProductionProvider`
5. Dashboard auto-updates

### Creating Order
1. User creates order (status = 'ordered')
2. `EggSalesNotifier.addOrder()` called
3. Data saved to `egg_sales` table
4. `pendingOrderEggCountProvider` updates

### Delivering Order
1. User marks order as delivered
2. `EggSalesNotifier.markAsDelivered()` called
3. Status updated to 'delivered'
4. Delivery date set to now
5. Providers invalidated:
   - `remainingStockProvider` (stock decreased)
   - `todayEggSalesProvider` (revenue updated)
   - `monthlyEggReportProvider`

### Inventory Calculation
All inventory calculations use SQL aggregation (not Dart-side):

```sql
-- Remaining stock
SELECT 
  COALESCE((SELECT SUM(collected - broken) FROM egg_collection), 0) -
  COALESCE((SELECT SUM(quantity) FROM egg_sales WHERE status = 'delivered'), 0)
  as remaining_stock
```

## Utility Classes

| Class | Purpose |
|-------|---------|
| `DatabaseHelper` | All database operations, singleton pattern |
| `DateHelpers` | Date formatting, range calculations |
| `CurrencyFormatter` | Money formatting with symbol |
| `NumberFormatter` | Number formatting with Indian locale |
| `AppColors` | Centralized color palette |

## Database Migration Strategy

- Database version tracked in `_databaseVersion`
- `onUpgrade` handles schema migrations
- `onCreate` initializes all tables and indexes
- Example migration pattern:
  ```dart
  if (oldVersion < 2) {
    // Add new column
    await db.execute('ALTER TABLE ...');
  }
  ```

## Backup/Restore

- Export: All tables → JSON file
- Import: JSON file → Database (transaction-based)
- Tables cleared before import for clean restore
- Validation checks for required keys

## UI Components

### Shared Widgets
- `LoadingShimmer` - Skeleton loader
- `SummaryCard` - Metric display card
- `DatePickerField` - Date input with picker
- `StatusChip` - Colored status indicators
- `SwipeableListItem` - Delete gesture wrapper
- `EmptyState` - No data placeholder

### Design System
- Material 3 components
- Custom color palette (greens for farm theme)
- Consistent card-based layout
- Emoji icons for visual appeal

## Data Flow

```
UI → Provider → DatabaseHelper → SQLite
UI ← AsyncValue ← Provider ← Database
```

## Offline Capability

- 100% offline functionality
- SQLite persistence
- No cloud dependencies
- Manual backup/restore for data portability

## Testing Considerations

Key areas for testing:
1. Inventory calculations after order delivery
2. Provider invalidation chains
3. Date range queries
4. Database migration paths
5. Backup/restore data integrity
