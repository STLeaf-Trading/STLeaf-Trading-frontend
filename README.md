# 🌿 ST Leaf Trading — Frontend (Flutter)

A **production-ready Flutter frontend** for ST Leaf Trading, a vegetable wholesale supplier based in Melaka, Malaysia.

> **Repository:** `stleaf-frontend` (this repo)  
> **Backend repo:** `stleaf-backend` *(Spring Boot 3, to be built in Phase 2)*

---

## 📱 Platform Support

| Platform | Status |
|---|---|
| 🌐 Web (Admin + Customer) | ✅ Supported |
| 📱 Android (Customer App) | ✅ Supported |
| 🍎 iOS | Future |

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary Green | `#1B6B35` |
| Accent Green | `#4CAF50` |
| Mint Background | `#E8F5E9` |
| White | `#FFFFFF` |
| Font | Inter (Google Fonts) |

---

## 🗂 Project Structure

```
lib/
├── main.dart                        # App entry point
├── core/
│   ├── theme/
│   │   ├── app_colors.dart          # All color constants
│   │   └── app_theme.dart           # Material 3 theme config
│   └── constants/
│       └── app_constants.dart       # App-wide constants
├── data/
│   ├── models/                      # Dart model classes
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   ├── customer_model.dart
│   │   ├── order_model.dart
│   │   └── inventory_model.dart     # Inventory, Delivery, Payment, Dashboard
│   └── mock/
│       └── mock_data.dart           # All mock data (12 products, 5 customers, 5 orders)
├── providers/                       # State management (Provider)
│   ├── auth_provider.dart
│   └── app_providers.dart           # Product, Cart, Order, Customer, Inventory, Delivery, Dashboard
├── routes/
│   └── app_router.dart              # GoRouter with auth guards
└── presentation/
    ├── widgets/
    │   ├── common/
    │   │   └── common_widgets.dart  # Button, Badge, Card, TextField, EmptyState, StatCard
    │   └── layout/
    │       ├── admin_layout.dart    # Sidebar (desktop) + Drawer (mobile)
    │       └── customer_layout.dart # AppBar + BottomNav
    └── screens/
        ├── auth/
        │   ├── login_screen.dart
        │   └── register_screen.dart
        ├── admin/
        │   ├── dashboard_screen.dart
        │   ├── products/products_screen.dart
        │   ├── products/product_form_screen.dart
        │   ├── inventory/inventory_screen.dart
        │   ├── customers/customers_screen.dart
        │   ├── orders/admin_orders_screen.dart
        │   ├── delivery/delivery_screen.dart
        │   └── reports/reports_screen.dart
        └── customer/
            ├── home/home_screen.dart
            ├── products/product_detail_screen.dart
            ├── cart/cart_screen.dart
            ├── checkout/checkout_screen.dart
            ├── orders/my_orders_screen.dart
            └── profile/profile_screen.dart
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Min Version |
|---|---|
| Flutter SDK | 3.0.0+ |
| Dart | 3.0.0+ |
| Android Studio | Latest |
| Chrome (for web) | Latest |

### Install & Run

```bash
# 1. Clone the repo
git clone https://github.com/your-org/stleaf-frontend.git
cd stleaf-frontend

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome (Web)
flutter run -d chrome

# 4. Run on Android (connect device or start emulator)
flutter run -d android

# 5. Build for web (production)
flutter build web --release
```

---

## 🔐 Demo Login Credentials

| Role | Email | Password |
|---|---|---|
| **Admin** | `admin@stleaf.com` | `Admin123!` |
| **Customer** | `john@abcrestaurant.com` | `Customer123!` |
| **Customer 2** | `mary@goldenpalace.com` | `Customer123!` |

---

## 📱 Screens Overview

### Authentication
| Screen | Description |
|---|---|
| Login | Two-panel (desktop), hero banner, demo credentials shown |
| Register | Business info + credentials form |

### Admin Portal
| Screen | Description |
|---|---|
| Dashboard | KPI cards, weekly revenue chart, top products pie, recent orders |
| Products | Responsive grid, category/search filter, promo badges, CRUD |
| Product Form | Create/edit with live card preview |
| Inventory | Stock progress bars, reorder alerts, inline editing |
| Customers | CRM list with credit bars, search |
| Customer Detail | Full profile + credit overview |
| Orders | Status filter tabs, order pipeline |
| Order Detail | Status stepper, items, payment summary |
| Delivery | Status-grouped kanban board |
| Reports | Bar chart, top products/customers tables |

### Customer Portal
| Screen | Description |
|---|---|
| Home | Hero banner, category filter pills, product grid |
| Product Detail | Freshness badge, precaution note, qty selector |
| Cart | Item list, qty controls, subtotal |
| Checkout | Delivery info, payment method selector, success dialog |
| My Orders | Progress bars, status filter chips |
| Order Detail | Vertical status stepper |
| Profile | Stats, account options, logout |

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `go_router` | Client-side routing with auth guards |
| `provider` | State management (ChangeNotifier) |
| `fl_chart` | Revenue & product charts |
| `google_fonts` | Inter typography |
| `shared_preferences` | Auth token persistence |
| `intl` | Date & currency formatting |
| `uuid` | Generate unique IDs |
| `http` | HTTP client (for real API) |

---

## 🔄 Switching from Mock to Real API

All data is currently served from `lib/data/mock/mock_data.dart`.

To connect to the Spring Boot backend:

1. Update `.env` (create if not exists):
```env
VITE_API_BASE_URL=http://localhost:8080
```

2. In `lib/core/constants/app_constants.dart`, set:
```dart
static const bool useMock = false;
```

3. Update each provider in `lib/providers/app_providers.dart` to call the real API:
```dart
// Before (mock)
_products = List.from(MockData.products);

// After (real API)
final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/products'));
_products = (jsonDecode(response.body) as List).map((e) => ProductModel.fromJson(e)).toList();
```

---

## 🛣 Routes

```
/login                     → Login page
/register                  → Register page

/admin/dashboard           → Admin: Dashboard (KPI + Charts)
/admin/products            → Admin: Products list
/admin/products/new        → Admin: Add product form
/admin/products/:id/edit   → Admin: Edit product form
/admin/inventory           → Admin: Inventory management
/admin/customers           → Admin: Customers list
/admin/customers/:id       → Admin: Customer detail
/admin/orders              → Admin: Orders management
/admin/orders/:id          → Admin: Order detail
/admin/delivery            → Admin: Delivery tracking
/admin/reports             → Admin: Reports & analytics

/shop                      → Customer: Product catalog
/shop/products/:id         → Customer: Product detail
/shop/cart                 → Customer: Shopping cart
/shop/checkout             → Customer: Checkout
/shop/orders               → Customer: My orders
/shop/orders/:id           → Customer: Order detail
/shop/profile              → Customer: Profile
```

---

## 🌐 Web Deployment

```bash
# Build for web
flutter build web --release

# Output: build/web/
# Deploy to: Firebase Hosting, Netlify, Vercel, etc.
```

For Firebase Hosting:
```bash
firebase init hosting
firebase deploy
```

---

## 📱 Android Build

```bash
# Debug APK
flutter build apk --debug

# Release APK (requires signing)
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release
```

---

## 🔮 Phase 2 — Backend (stleaf-backend)

The backend will be a separate repository:

```
stleaf-backend/              ← Spring Boot 3 + Java 21
  src/main/java/com/stleaf/
    auth/                    ← JWT auth
    product/                 ← Product management
    inventory/               ← Inventory management
    customer/                ← Customer CRM
    order/                   ← Order management
    payment/                 ← Payment tracking
    delivery/                ← Delivery management
    dashboard/               ← KPI aggregation
  src/main/resources/
    application.yml          ← PostgreSQL + JWT config
  docker-compose.yml         ← PostgreSQL container
  pom.xml
```

Tech stack: Spring Boot 3 · Java 21 · PostgreSQL · JWT · Swagger

---

## 🔮 Future Roadmap

| Feature | Status |
|---|---|
| Retail Customers Portal | Planned |
| FPX / TNG Payment | Planned |
| Promotion Engine | Planned |
| Loyalty Program | Planned |
| AI Demand Prediction | Planned |
| iOS App | Planned |

---

## 📞 Support

**ST Leaf Trading** — Fresh from Farm to Table  
📍 Melaka, Malaysia  
📧 admin@stleaf.com
