# Hasan & Morcos Mobile App MVP

Flutter starter app for customer mobile ordering.

## Current Scope

- Login by phone OTP.
- Select branch.
- Browse in-stock products from Django API.
- View product images and product detail.
- Add products to cart.
- Create reservation order.
- View order summary.
- View customer order history.
- Track shipment courier and tracking number.
- Submit payment reference and proof image.
- View customer notifications.

## Backend API Used

- `POST /orders/api/auth/request-otp/`
- `POST /orders/api/auth/verify-otp/`
- `GET /orders/api/my/orders/`
- `GET /orders/api/my/notifications/`
- `POST /orders/api/my/notifications/<notification_id>/read/`
- `GET /orders/api/branches/`
- `GET /orders/api/products/?branch=<branch_id>`
- `POST /orders/api/orders/`
- `GET /orders/api/orders/<order_id>/`
- `POST /orders/api/orders/<order_id>/payment/`

## Run Later

Flutter is not installed on this machine right now. On a machine with Flutter:

```bash
cd mobile_app
flutter pub get
flutter run
```

For Android emulator, set `baseUrl` in `lib/config/api_config.dart` to:

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

For Windows/Desktop browser testing, keep:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```
