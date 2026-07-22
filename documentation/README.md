# TradeMentor: Real-Time Stock Monitoring and Rule-Based Trading Assistance System

TradeMentor is a final-year engineering project built as a cross-platform fintech portal. It enables retail investors to track stock markets in real-time, configure complex rule-based strategies, and interact with a conversational AI assistant for analysis, risk assessment, and financial learning.

---

## 🚀 Key Features

1. **Dual-Platform Single Codebase**: Built using Flutter for seamless distribution as a responsive Web App and native Android APK.
2. **Premium Dark Mode & Light Mode**: Curated design system styled after modern industry platforms like Zerodha Kite, Upstox, and TradingView, using glassmorphic cards and smooth animations.
3. **Advanced Interactive Charting**: Real-time candlestick charts, line charts, moving averages, and technical indicators (RSI, MACD).
4. **No-Code Rule Builder Engine**: Users visually build mathematical conditions (e.g., "RSI below 30 and volume spikes by 200%") to generate instant recommendations and notification alerts, without auto-executing trades (assistance-only).
5. **TradeMentor AI Chatbot**: Built-in conversational AI assistant capable of analyzing portfolio performance, outlining risk distributions, clarifying trading terms, and summarizing news.
6. **Detailed Admin Panel**: System-wide monitor for users, rules performance, custom alerts, API configurations, and custom market simulation controls.

---

## 📁 Repository Directory Structure

- 📂 `mobile_app/`: Single-codebase Flutter app (handles both Web & Android layout).
- 📂 `web_app/`: Hosting deployment wrappers (Vercel, Netlify, Github Pages, Firebase Hosting).
- 📂 `backend/`: Node.js Express server running the rules engine, AI API integrations, and mock stock WebSockets.
- 📂 `assets/`: UI branding materials, mock logos, and icons.
- 📂 `documentation/`: System design guides, architecture docs, database layouts, and manuals.
- 📂 `deployment/`: Build automation and quick deployment batch scripts.

---

## 📚 Technical Documentation Guides

For detailed blueprints, please refer to:
* [Architecture.md](file:///c:/Users/ishwa/OneDrive/Desktop/Tradementor/documentation/Architecture.md) - Design patterns, Riverpod state lifecycle, and rules engine workflow.
* [DatabaseSchema.md](file:///c:/Users/ishwa/OneDrive/Desktop/Tradementor/documentation/DatabaseSchema.md) - Cloud Firestore and local Hive collection layout.
* [ApiDocumentation.md](file:///c:/Users/ishwa/OneDrive/Desktop/Tradementor/documentation/ApiDocumentation.md) - API endpoints, WebSockets, and AI prompt formatting.
* [UserManual.md](file:///c:/Users/ishwa/OneDrive/Desktop/Tradementor/documentation/UserManual.md) - Actionable steps for both traders and administrators.
* [TestingPlan.md](file:///c:/Users/ishwa/OneDrive/Desktop/Tradementor/documentation/TestingPlan.md) - Automated checks, manual simulations, and testing routines.

---

## 🛠️ Quick Start & Installation

### Backend Services Setup
1. Open a terminal, go to the `backend/` directory:
   ```bash
   cd backend
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in your Gemini API keys and Firebase Admin SDK configurations.
3. Launch the server:
   ```bash
   npm start
   ```

### Frontend Setup
1. Go to the `mobile_app/` directory:
   ```bash
   cd mobile_app
   flutter pub get
   ```
2. Run locally on Chrome/Web:
   ```bash
   flutter run -d chrome
   ```
3. Compile the production APK for Android devices:
   ```bash
   flutter build apk --release
   ```
