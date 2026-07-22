# Database Schema & Storage Configuration

This document specifies the collection structure, property keys, data types, and index configurations for Firebase Firestore (Cloud Database) and Hive (Local Cache).

---

## 🔥 Firebase Cloud Firestore Collections

Firestore stores user profiles, portfolios, rules configuration, and historic stock alerts.

### 1. `users` Collection
* **Path**: `/users/{userId}`
* **Description**: User profile data, security settings, subscription levels, and risk parameters.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | Unique user ID from Firebase Authentication |
| `name` | String | Full name of the user |
| `email` | String | Registered email address |
| `phoneNumber` | String | Registered mobile number |
| `avatarUrl` | String | Profile picture URL |
| `riskTolerance` | String | `Conservative`, `Moderate`, or `Aggressive` |
| `subscriptionLevel` | String | `Free`, `Pro`, or `Elite` |
| `createdAt` | Timestamp | Account creation timestamp |
| `mfaEnabled` | Boolean | True if Multi-factor authentication is active |

---

### 2. `watchlists` Subcollection
* **Path**: `/users/{userId}/watchlists/{watchlistId}`
* **Description**: User-created lists containing watchable tickers.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Watchlist ID |
| `name` | String | User-defined name (e.g. "Crypto", "Tech Stocks") |
| `tickers` | Array (String) | List of tickers (e.g. `["AAPL", "TSLA", "RELIANCE"]`) |
| `isDefault` | Boolean | Highlighted watchlist on app startup |

---

### 3. `portfolio` Subcollection
* **Path**: `/users/{userId}/portfolio/{holdingId}`
* **Description**: Shares currently held or simulated buy orders.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Transaction holding ID |
| `ticker` | String | Stock symbol |
| `companyName` | String | Legal name of corporate entity |
| `sharesCount` | Double | Quantity of shares bought |
| `averageBuyPrice` | Double | Purchase price average |
| `purchaseDate` | Timestamp | Timestamp of acquisition |
| `marketValue` | Double | Cached value based on latest tick data |

---

### 4. `rules` Subcollection
* **Path**: `/users/{userId}/rules/{ruleId}`
* **Description**: Custom no-code trading assistant rules defined by the user.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Rule ID |
| `name` | String | Human readable strategy name |
| `ticker` | String | Target symbol to monitor |
| `isActive` | Boolean | Toggle rule evaluation |
| `operator` | String | Logical connection: `AND`, `OR` |
| `conditions` | Array (Map) | Conditions list (see detail below) |
| `createdAt` | Timestamp | Rule composition timestamp |

#### Conditions Map Structure:
```json
{
  "indicator": "RSI | MACD | MovingAverage | Volume | Price",
  "period": 14,
  "comparison": "LESS_THAN | GREATER_THAN | CROSSES_ABOVE | CROSSES_BELOW",
  "thresholdValue": 30.0
}
```

---

### 5. `alerts` Subcollection
* **Path**: `/users/{userId}/alerts/{alertId}`
* **Description**: Historical list of alerts dispatched when rule conditions are satisfied.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Alert ID |
| `ruleId` | String | Referencing Rule that triggered |
| `ruleName` | String | Snapshot of the rule's name |
| `ticker` | String | Stock ticker |
| `triggerPrice` | Double | Price of the asset when rule evaluated true |
| `message` | String | Detailed signal message generated |
| `readStatus` | Boolean | True if user viewed notification |
| `createdAt` | Timestamp | Trigger timestamp |

---

## 🍯 Hive Local Storage Boxes (Offline Cache)

Hive is used for lightning-fast caching, biometric configurations, and chatbot conversation logging.

### 1. `settingsBox`
* **Box Name**: `user_settings`
* **Description**: Application preference toggles.
  - `themeMode`: String (`dark` or `light`)
  - `biometricsEnabled`: Boolean (Biometric login toggle)
  - `offlineDataCache`: Boolean (Toggle database caching on/off)
  - `deviceToken`: String (FCM token)

### 2. `chatBox`
* **Box Name**: `chat_history`
* **Description**: Locally stored threads for the TradeMentor AI chatbot.
  - `messages`: List of objects containing:
    - `id`: String
    - `sender`: String (`user` or `ai`)
    - `content`: String (Text context)
    - `timestamp`: DateTime

### 3. `marketCacheBox`
* **Box Name**: `cached_stocks`
* **Description**: List of latest stock ticks to load screen indices immediately before WebSockets launch.
  - Key: Ticker Symbol (e.g. `"TSLA"`)
  - Value: Map containing price, percentage change, high, low, and 50-day average array.
