# FinTrack — Personal Finance Tracker

A cross-platform personal finance app built with **Flutter** and **SQLite** as part of the MADL (Mobile Application Development Lab) course project.

---

## Features

- **Dashboard** — Total balance, this month's income & expenses, budget progress bars, and recent transactions at a glance
- **Transactions** — Add, edit, and delete income/expense entries; grouped by date with daily net totals; tabbed view (All / Income / Expenses)
- **Reports** — Month-by-month breakdown, savings rate indicator, and category-wise expense chart
- **Categories** — Full CRUD for custom categories with icon and colour picker
- **Budgets** — Set monthly spending limits per category; visual progress indicators turn orange/red as limits approach
- **SQLite Persistence** — All data stored locally; survives app restarts

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Material 3) |
| Language | Dart |
| Database | SQLite via `sqflite` |
| Web SQLite | `sqflite_common_ffi_web` |
| Formatting | `intl` |

## Flutter Concepts Demonstrated

- `setState()` for real-time balance updates
- `Hero` animation on transaction category icons
- `LinearProgressIndicator` for budget and savings rate
- `TabBar` / `TabBarView` on Transactions and Settings screens
- `IndexedStack` + `GlobalKey` for cross-screen state refresh
- `DatePicker`, `DropdownButtonFormField`, `SegmentedButton`
- `Drawer` navigation with `UserAccountsDrawerHeader`
- `SnackBar` confirmations and `AlertDialog` for destructive actions
- `AnimatedContainer` in the colour picker

## Project Structure

```
lib/
├── main.dart
├── database/
│   └── database_helper.dart   # SQLite singleton, all queries
├── models/
│   ├── transaction_model.dart
│   ├── category_model.dart
│   └── budget_model.dart
└── screens/
    ├── main_screen.dart
    ├── dashboard_screen.dart
    ├── transactions_screen.dart
    ├── reports_screen.dart
    ├── settings_screen.dart
    ├── add_edit_transaction_screen.dart
    └── add_edit_category_screen.dart
```

## Getting Started

**Prerequisites:** Flutter SDK installed ([flutter.dev](https://flutter.dev))

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Build Android APK
flutter build apk
```

## Screenshots

> Dashboard · Transactions · Reports · Settings

| Dashboard | Transactions | Reports |
|---|---|---|
| Balance card with income/expense chips, budget progress | Date-grouped list with Hero animation on icons | Month selector, savings rate, category breakdown |

## Database Schema

```sql
transactions (id, title, amount, type, category_id, date, notes)
categories   (id, name, icon_code, color_value, type)
budgets      (id, category_id, amount, month)
```

13 default categories are seeded on first run (Food, Transport, Salary, etc.).
