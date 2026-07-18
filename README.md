# ST Leaf Trading — Flutter App

A **production-ready Flutter app** for **ST Leaf Trading**, a fresh vegetable wholesale supplier based in Jasin, Melaka, Malaysia. The platform supports a full dual-portal system — an **Admin Portal** for operations management and a **Customer Portal** for ordering fresh produce.

> **Architecture:** Firebase-powered (Firestore + Auth + Storage). No traditional REST backend — the Flutter app communicates directly with Firebase services via real-time listeners.

---

## 📱 Platform Support

| Platform | Status | Notes |
|---|---|---|
| 🌐 Web (Admin + Customer) | ✅ Supported | Guest browsing allowed; login required at checkout |
| 🤖 Android (Customer App) | ✅ Supported | Login required to access any screen |
| 🍎 iOS | Planned | — |

### Platform-Specific Auth Behaviour (`kIsWeb`)

| Behaviour | 🌐 Web | 📱 Android |
|---|---|---|
| App opens on | `/shop` (product listing) | `/login` |
| Browse products | ✅ No login needed | ❌ Login required |
| View cart | ✅ No login needed | ❌ Login required |
| My Orders nav | Hidden for guests | Always visible |
| Top-right nav | Login + Register buttons for guests | Profile avatar (always logged in) |
| Checkout | Redirects guest to login | Goes straight to checkout |
| After logout | `/shop` (still browseable) | `/login` |
| "Continue as guest" on login page | ✅ Shown | ❌ Hidden |

---

## 🏢 Business Info

| Detail | Value |
|---|---|
| **Company** | ST Leaf Trading |
| **Location** | J1809 Pasar Jasin, 77000 Jasin, Melaka, Malaysia |
| **WhatsApp** | 011-2889 2991 |
| **Email** | stleaf9193@gmail.com |
| **Hours** | Mon–Tue & Thu–Sun: 7:00 AM – 3:00 PM \| Wed: Closed |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── constants/
│       └── app_constants.dart
├── data/
│   └── models/
│       ├── user_model.dart
│       ├── product_model.dart       # Multi-unit sizes (Kg / Pack / Box) per product
│       ├── customer_model.dart
│       ├── order_model.dart         # Includes cancellationReason field
│       └── inventory_model.dart
├── providers/
│   ├── auth_provider.dart           # Login, register, deleteAccount
│   ├── app_providers.dart           # Product, Cart, Order, Customer, Inventory, Delivery, Dashboard
│   └── settings_provider.dart       # Delivery fee (Firestore-synced)
├── routes/
│   └── app_router.dart              # GoRouter with kIsWeb-aware auth guards
└── presentation/
    ├── widgets/
    │   ├── common/
    │   │   ├── common_widgets.dart
    │   │   └── contact_support_widget.dart
    │   └── layout/
    │       ├── admin_layout.dart
    │       └── customer_layout.dart  # kIsWeb-aware nav: Login/Register vs profile avatar
    └── screens/
        ├── auth/
        │   ├── login_screen.dart     # "Continue as guest" link (web only)
        │   └── register_screen.dart
        ├── admin/
        │   ├── dashboard_screen.dart
        │   ├── products/products_screen.dart
        │   ├── products/product_form_screen.dart  # kg/pack/box responsive layout fixed
        │   ├── inventory/inventory_screen.dart    # Alert banner overflow fix
        │   ├── customers/customers_screen.dart
        │   ├── orders/admin_orders_screen.dart
        │   ├── delivery/delivery_screen.dart
        │   ├── instalments/admin_instalments_screen.dart
        │   └── reports/reports_screen.dart
        └── customer/
            ├── home/home_screen.dart              # Loads products for guests (no auth needed)
            ├── products/product_detail_screen.dart # Total price updates per selected unit
            ├── cart/cart_screen.dart              # "Sign In to Checkout" for web guests
            ├── checkout/
            │   ├── checkout_screen.dart           # TNG/Maybank notices removed
            │   └── payment_proof_screen.dart      # Screenshot upload is mandatory
            ├── orders/
            │   ├── my_orders_screen.dart
            │   └── cancel_order_screen.dart
            └── profile/
                ├── profile_screen.dart
                ├── edit_profile_screen.dart
                └── legal_screen.dart
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Min Version |
|---|---|
| Flutter SDK | 3.0.0+ |
| Dart | 3.0.0+ |
| Android Studio / VS Code | Latest |
| Chrome (for web) | Latest |
| Firebase Project | Active |

### Install & Run

```bash
# 1. Clone the repo
git clone <your-repo-url>
cd STLeaf_Trading

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome (Web) — opens at /shop for guest browsing
flutter run -d chrome

# 4. Run on Android (connect device or start emulator) — opens at /login
flutter run -d android

# 5. Build for web (production)
flutter build web --release
```

---

## 🔥 Firebase Setup

This project uses **Firebase** as its backend. You need to configure your own Firebase project:

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password).
3. Enable **Cloud Firestore**.
4. Enable **Firebase Storage**.
5. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
6. For Web, update `web/index.html` with your Firebase config.
7. Apply the Firestore security rules from the backend repo.

---

## 🖼️ Screens Overview

### Authentication
| Screen | Description |
|---|---|
| Login | Two-panel desktop layout, mobile-responsive. Web shows "Continue as guest →" link |
| Register | Company name, contact person, phone, email, password |

### Admin Portal
| Screen | Description |
|---|---|
| Dashboard | KPI cards (today's orders/revenue, pending, low stock), 7-day revenue chart with real Firestore data, top products pie chart, top customers, recent orders, Export CSV |
| Store Settings | Admin-configurable delivery fee (saves to Firestore, syncs to checkout) |
| Products | Responsive grid, category + search filter, freshness level (0–10 slider), CRUD, image upload |
| Product Form | Create/edit with item code uniqueness check, freshness level slider, **multi-unit pricing (Kg / Pack / Box)**, responsive layout (stacks on narrow screens) |
| Inventory | Stock progress bars, user-defined low stock level, out-of-stock detection, overflow-safe alert banners |
| Customers | CRM list with search |
| Customer Detail | Full profile + outstanding balance |
| Orders | Status filter tabs, order pipeline, Confirm → Packed → Delivered flow |
| Order Detail | Status stepper, items, payment summary, action buttons (Confirm/Packed/Delivered), admin Cancel with reason |
| Delivery | Delivery-only orders (deliveryFee > 0), status tracking |
| Instalments | Track all customer instalment plans, review uploaded receipts, and mark phases as Paid/Late |
| Reports | Analytics charts and tables |

### Customer Portal
| Screen | Description |
|---|---|
| Home / Shop | Hero banner, category filter pills, product grid, floating contact widget. **Accessible to guests on web** |
| Product Detail | Freshness badge (0–10 scale), qty selector, **total price updates based on selected unit (Kg/Pack/Box)**, add to cart |
| Cart | Item list, qty controls, subtotal. Web guests see "Sign In to Checkout" button |
| Checkout | Choose Pickup or Company Delivery (requires address, fee set by admin), Cash/FPX/TNG/Instalment payment. **TNG/Maybank notices removed** (payment proceeds after admin confirmation) |
| Payment Proof | Upload payment screenshot — **mandatory before viewing orders** (no "upload later" option) |
| My Orders | Progress bars, status filter chips, Cancel button (Pending/Confirmed only) |
| Order Detail | Vertical status stepper, cancellation reason display, Cancel Order button |
| Instalments | Track active instalment plans, click to upload receipts, pay phases via FPX/TNG/Cash |
| Cancel Order | Reason selector (preset + custom "Other" option), confirmation dialog |
| Profile | Stats, Edit Profile, My Orders, Contact Support, T&C, Privacy Policy, Delete Account, Logout |
| Edit Profile | Update company name, contact person, phone, delivery address (email read-only) |
| Terms & Conditions | 10-section T&C specific to ST Leaf Trading |
| Privacy Policy | 10-section PDPA-aligned privacy statement |
| Contact Support | WhatsApp (011-2889 2991), Phone, Email, company address + hours |

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `go_router` | Client-side routing with `kIsWeb`-aware auth guards |
| `provider` | State management (ChangeNotifier) |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | User authentication & account management |
| `cloud_firestore` | Real-time NoSQL database |
| `firebase_storage` | Product image & payment proof uploads |
| `fl_chart` | Revenue & product charts |
| `google_fonts` | Inter typography |
| `intl` | Date & currency formatting (RM) |
| `uuid` | Unique order ID generation |
| `url_launcher` | WhatsApp & phone links in contact widget |
| `image_picker` | Product image & payment proof selection |
| `pdf` & `printing` | Generating and downloading PDF order reports |

---

## 🛣️ Routes

### Public Routes (accessible without login on web)
```
/login                        -> Login page
/register                     -> Register page
/shop                         -> Customer: Product catalog (guest-accessible on web)
/shop/cart                    -> Customer: Shopping cart (guest-accessible on web)
```

### Protected Routes (login required on all platforms)
```
/shop/checkout                -> Customer: Checkout (Pickup / Delivery)
/shop/orders                  -> Customer: My orders
/shop/orders/:id              -> Customer: Order detail
/shop/orders/:id/cancel       -> Customer: Cancel order (reason screen)
/shop/orders/:id/instalment   -> Customer: Instalment detail
/shop/instalments             -> Customer: Instalment plans & payments
/shop/profile                 -> Customer: Profile
/shop/edit-profile            -> Customer: Edit profile & address
/shop/payment-proof/:orderId  -> Customer: Upload payment screenshot (mandatory)
```

### Admin Routes (login + admin role required)
```
/admin/dashboard              -> Dashboard (KPIs + Charts + Export CSV)
/admin/products               -> Products list
/admin/products/new           -> Add product form
/admin/products/:id/edit      -> Edit product form
/admin/inventory              -> Inventory management
/admin/customers              -> Customers list
/admin/customers/:id          -> Customer detail
/admin/orders                 -> Orders management
/admin/orders/:id             -> Order detail (with Cancel button)
/admin/delivery               -> Delivery tracking (fee > 0 only)
/admin/instalments            -> Instalment plan tracking & approval
/admin/reports                -> Reports & analytics (Export to PDF/CSV)
```

---

## 🔄 Order Status Flow

```
Pending -> Confirmed -> Packed -> Out For Delivery -> Delivered
                                       |
                         (Only for orders with deliveryFee > 0)

Any stage -> Cancelled (Admin can cancel at any stage)
Pending / Confirmed -> Cancelled (Customer can self-cancel)
```

- **Cancellation reasons** are stored in Firestore and displayed on both customer and admin order detail screens.
- **Order history is preserved** even after a customer deletes their account (for tax/legal compliance).

---

## 🚚 Delivery & Payment

- **Pickup** — Customer collects from J1809 Pasar Jasin. Delivery fee = RM 0.00.
- **Company Delivery** — Requires customer to have a saved address. Fee is set by admin in Store Settings and persisted in Firestore (`settings/general`).
- **Payment Methods** — Cash / COD, FPX (Online Banking), Touch 'n Go (TNG), Instalment.
- **Payment Flow** — Customer places order → Admin confirms → Customer receives payment details and uploads proof screenshot. **Screenshot upload is mandatory** before the customer can navigate away.
- **Delivery Page (Admin)** — Only shows orders where `deliveryFee > 0`.

---

## 🛒 Product Pricing (Multi-Unit)

Each product supports up to **4 pricing tiers** by unit type:

| Unit | Example Use |
|---|---|
| **Kg** | Loose vegetables sold by weight |
| **Pack** | Pre-packed bundles |
| **Box** | Wholesale carton quantities |

- The price shown in the cart and total updates dynamically when the customer changes unit.
- On the product detail screen, the **Total** always reflects the currently selected unit's price × quantity.
- On the admin product form, the unit/price row is responsive — stacks vertically on narrow screens.

---

## 👤 Account Management

- **Register** — Creates a Firebase Auth account + `users/{uid}` + `customers/{uid}` Firestore docs. Sends email verification.
- **Edit Profile** — Updates `contactPerson`, `companyName`, `phoneNumber`, `address` in both collections.
- **Delete Account** — Re-authenticates with password, deletes `users` + `customers` docs and Firebase Auth account. Order history is **preserved**.
- **Email verification** — Enforced for accounts created after June 22, 2026.

---

## 🌐 Web Deployment

```bash
flutter build web --release
# Output: build/web/
# Deploy to Firebase Hosting, Netlify, Vercel, etc.
```

For Firebase Hosting:
```bash
firebase init hosting
firebase deploy
```

> **Note:** Web visitors land on `/shop` and can browse products without signing up. Login/Register buttons appear in the top-right nav. Registration is required at checkout.

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

> **Note:** Android opens directly on `/login`. All screens require authentication.

---

## 🔮 Future Roadmap

| Feature | Status |
|---|---|
| Push Notifications (order updates) | Planned |
| Promotion & Discount Engine | Planned |
| Loyalty Points Program | Planned |
| iOS App | Planned |
| AI-based Demand Prediction | Planned |
| Multi-language (BM / EN) | Planned |

---

## 📞 Contact & Support

**ST Leaf Trading** — Fresh from Farm to Table  
📍 J1809 Pasar Jasin, 77000 Jasin, Melaka, Malaysia  
💬 WhatsApp: [011-2889 2991](https://wa.me/601128892991)  
📧 Email: stleaf9193@gmail.com  
🕒 Mon–Tue & Thu–Sun: 7:00 AM – 3:00 PM \| Wed: Closed
