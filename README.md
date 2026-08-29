# Sa'n Tayo

Flutter frontend + Laravel backend + MySQL database.

## Project structure

```
san_tayo/
├── backend/          # Laravel API (grades-style layer pattern)
│   ├── app/
│   │   ├── Http/Controllers/   # Thin HTTP entry points
│   │   ├── Http/Services/        # Business logic / calculations
│   │   ├── Libraries/            # api.php + SharedFunction.php
│   │   ├── Models/               # Eloquent models
│   │   └── Repositories/         # Interface + Repository pairs
│   └── routes/api.php            # All API endpoints
├── frontend/         # Flutter app
│   └── lib/core/
│       ├── config/               # api_config.dart, api_endpoints.dart
│       ├── models/               # api_response.dart
│       └── network/              # api_client.dart (api_request)
└── README.md
```

## Prerequisites

- PHP 8.2+ and Composer
- XAMPP MySQL (or any MySQL server)
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)

## Database setup (XAMPP)

1. Start Apache and MySQL in XAMPP.
2. Open phpMyAdmin or run:

```sql
CREATE DATABASE san_tayo;
```

3. Backend `.env` is already configured for XAMPP defaults:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=san_tayo
DB_USERNAME=root
DB_PASSWORD=
```

## Backend setup

```bash
cd backend
composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

API base URL: `http://127.0.0.1:8000/api`

### Test health endpoint

```bash
curl http://127.0.0.1:8000/api/health
```

Expected response:

```json
{
  "code": 1,
  "title": "Success!",
  "msg": "Health check successful.",
  "data": {
    "app": "Sa'n Tayo",
    "status": "ok",
    "timestamp": "..."
  }
}
```

## Frontend setup

After installing Flutter and adding it to PATH:

```bash
cd frontend
flutter create . --project-name san_tayo --org com.santayo
flutter pub get
flutter run
```

> `flutter create .` generates Android/iOS/Web/Windows platform folders while keeping the existing `lib/` code.

### API base URL by platform

Configured in `frontend/lib/core/config/api_config.dart`:

| Platform         | Base URL                        |
|------------------|---------------------------------|
| Web / Windows    | `http://127.0.0.1:8000/api`     |
| Android emulator | `http://10.0.2.2:8000/api`      |
| Physical device  | Use your PC's LAN IP + `:8000`  |

## Centralized API connection

### Backend — add a new endpoint

1. Add route in `backend/routes/api.php`
2. Create Controller method
3. Create `*RepoInterface` + `*Repository` in `app/Repositories/`
4. Register binding in `app/Providers/RepositoryServiceProvider.php`
5. Put queries in `app/Libraries/api.php`
6. Put calculations in `app/Http/Services/`
7. Return via `SharedFunction::api_success()` or `SharedFunction::api_error()`

### Frontend — call the endpoint

1. Add path constant in `frontend/lib/core/config/api_endpoints.dart`
2. Call `api_request()` from your screen or service:

```dart
final res = await api_request('GET', ApiEndpoints.health);
if (res.code == 1) {
  // use res.data
}
```

## Request flow

```
Flutter api_request()
  → routes/api.php
  → Controller
  → Repository
  → Libraries/api.php or SharedFunction
  → JSON { code, title, msg, data }
  → ApiResponse model in Flutter
```
