# ST Leaf Trading — Backend Handoff Document

This document provides all the necessary context for the AI agent to build the backend for the **ST Leaf Trading** platform. The frontend (Flutter) is already complete and is currently running on mock data. Your task is to build the REST API backend to replace the mock data.

## 🏢 Project Overview
- **Name:** ST Leaf Trading
- **Industry:** Vegetable Wholesale Supplier (Melaka)
- **Architecture:** Separate Frontend (Flutter) and Backend (Spring Boot) repositories.
- **Goal:** Build the backend REST API, database schema, and authentication system.

## 🛠️ Required Tech Stack
- **Framework:** Spring Boot 3
- **Language:** Java 21 (or latest)
- **Database:** PostgreSQL
- **Authentication:** Spring Security with JWT (JSON Web Tokens)
- **API Documentation:** Swagger / OpenAPI 3
- **Build Tool:** Maven or Gradle (your choice)

---

## 📦 Data Models (Entities) Needed

Based on the frontend UI, the backend needs the following core entities:

### 1. User / Auth
- `id` (UUID), `email`, `password` (hashed), `name`, `role` (ADMIN or CUSTOMER), `createdAt`

### 2. Product
- `id` (UUID), `itemCode` (String, e.g., VEG-001)
- `name`, `category`, `description`, `precaution` (Storage info)
- `freshnessLevel` (A, B, C)
- `packType` (Bundle, KG, Pack), `weightKg` (Double)
- `price` (Double), `promotionPrice` (Double, nullable)
- `stockQuantity` (Int), `status` (Active, Inactive)

### 3. Customer (Company Profile)
- `id` (UUID), `userId` (Foreign Key to User)
- `customerCode` (String, e.g., CUST-1001)
- `companyName`, `contactPerson`, `phoneNumber`, `email`
- `businessRegistrationNo`, `address`
- `creditTerm` (e.g., 30 Days), `creditLimit` (Double)
- `outstandingBalance` (Double), `status` (Active, Pending)

### 4. Order
- `id` (UUID), `orderId` (String, e.g., ORD-20231015-001)
- `customerId` (UUID), `customerName`
- `orderDate` (Timestamp), `deliveryDate` (Timestamp)
- `subtotal` (Double), `deliveryFee` (Double), `totalAmount` (Double)
- `paymentMethod` (Cash, Bank Transfer, Credit Term)
- `paymentStatus` (Pending, Paid)
- `orderStatus` (Pending, Confirmed, Packed, Out For Delivery, Delivered, Cancelled)

### 5. Order Item
- `id` (UUID), `orderId` (Foreign Key)
- `productId` (Foreign Key), `productName`
- `quantity` (Int), `price` (Double), `subtotal` (Double)

### 6. Delivery
- `id` (UUID), `orderId` (Foreign Key), `orderCode`
- `customerId` (Foreign Key), `customerName`
- `driverName`, `vehicleNumber`
- `deliveryDate` (Timestamp)
- `status` (Scheduled, Loading, In Transit, Delivered, Failed)

---

## 🔌 Required REST API Endpoints

The frontend expects standard JSON REST APIs. Prefix all endpoints with `/api/v1`.

### Authentication (`/api/v1/auth`)
- `POST /login` -> Returns JWT token & user info.
- `POST /register` -> Register a new customer (Default role: CUSTOMER).

### Products (`/api/v1/products`)
- `GET /` -> List all products (public or customer/admin).
- `GET /{id}` -> Get product details.
- `POST /` -> Create a product (Admin only).
- `PUT /{id}` -> Update a product (Admin only).
- `DELETE /{id}` -> Delete a product (Admin only).

### Customers (`/api/v1/customers`)
- `GET /` -> List all customers (Admin only).
- `GET /{id}` -> Get customer details.
- `PUT /{id}` -> Update customer profile/credit limit.

### Orders (`/api/v1/orders`)
- `GET /` -> List all orders (Admin sees all; Customer sees their own).
- `GET /{id}` -> Get order details & items.
- `POST /` -> Place a new order.
- `PUT /{id}/status` -> Update order status (Admin only).

### Inventory (`/api/v1/inventory`)
- `GET /` -> Get inventory overview (Current stock, reserved stock, available stock).
- `PUT /{productId}/stock` -> Manually adjust stock levels.

### Delivery (`/api/v1/delivery`)
- `GET /` -> List all deliveries.
- `PUT /{id}/status` -> Update delivery tracking status.

### Dashboard / Analytics (`/api/v1/dashboard`)
- `GET /stats` -> Get KPI metrics (Today's revenue, pending orders, top products, weekly revenue chart data).

---

## 🚨 Instructions for the AI Agent
1. **Initialize** a new Spring Boot 3 project.
2. **Setup** PostgreSQL configuration in `application.yml`.
3. **Implement** the Entity classes (JPA/Hibernate).
4. **Create** the Repositories, Services, and Controllers.
5. **Implement** Spring Security with JWT filters.
6. **Provide** SQL or Flyway scripts for some initial mock data so the frontend has data to fetch.
7. Test the API logic.
