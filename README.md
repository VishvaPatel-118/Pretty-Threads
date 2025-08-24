# Pretty Threads (Flutter App)

Flutter client for the Pretty Threads platform. Connects to the Laravel API in `my-api/` for authentication, catalog browsing, cart, and an admin panel for managing users, products, categories, and payments.

## Requirements
- Flutter 3.22+
- Dart 3+
- Android Studio/Xcode (for device/emulator)

## Project Structure
- `lib/main.dart` — app entry and theme
- `lib/services/api.dart` — HTTP client; base URL via `API_BASE_URL` dart-define
- `lib/screens/` — splash, auth, home, catalog, etc.
- `lib/admin/` — admin dashboard and tabs
  - `admin/dashboard.dart`
  - `admin/users/`, `admin/products/`, `admin/categories/`, `admin/payments/`

## Configure API Base URL
The app reads the API base URL from a compile-time define.

Default (in code):
```
ApiService.baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://dff277d6b695.ngrok-free.app')
```

Recommended: pass your local/server URL when running/building.

Examples:
- Windows PowerShell (local Laravel `php artisan serve`):
```
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

- Android device with LAN IP:
```
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

- Release build:
```
flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.com
```

## Run the App
1) Ensure the API is running (see `my-api/README.md`).
2) Start emulator or connect a device.
3) Run with your API base URL as above.

## Admin Panel
- Location: `lib/admin/dashboard.dart`
- Access: login using the seeded admin account from the API seeders.
  - Default credentials: `admin@example.com` / `password` (see `my-api/database/seeders/AdminUserSeeder.php`)
- The Admin menu/entry is shown only for users with `is_admin == true`.
- Tabs:
  - Users: list, search, block/unblock
  - Products: list, search/filter; image upload; CRUD
  - Categories: hierarchical list; CRUD
  - Payments: list, details; status update/refund

## Theming
- Defined in `lib/main.dart`.
- Uses Material theme with purple brand color. To adjust, change the seed color or component themes in `ThemeData`.

## Troubleshooting
- Android emulator cannot reach `localhost` of your PC:
  - Use your machine LAN IP (e.g., `http://192.168.x.x:8000`).
  - For Android emulator, `http://10.0.2.2:8000` maps to host machine localhost.
- 401/403 errors:
  - Ensure token is passed; verify login succeeded.
  - If account is blocked, admin must unblock in Users tab.
- Images not loading:
  - The app normalizes `/storage/...` to `API_BASE_URL + path`. Ensure `APP_URL` and storage symlink are configured in Laravel (`php artisan storage:link`).

## Build Commands
- Debug run with base URL:
```
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
- Build APK:
```
flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.com
```
- Build AppBundle:
```
flutter build appbundle --dart-define=API_BASE_URL=https://api.your-domain.com
```

---
Backend setup and endpoints: see `../my-api/README.md`.
