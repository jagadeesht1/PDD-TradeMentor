# TradeMentor E2E Selenium Test Suite

This directory contains the End-to-End (E2E) testing suite for the TradeMentor web application, built using Selenium WebDriver and Node.js. It tests all core features of the platform, handles visual failures by capturing screenshots, and aggregates results into a styled Excel spreadsheet.

## Prerequisites

1. **Node.js**: Make sure you have Node.js installed (v16+ recommended).
2. **Google Chrome**: The tests run on Chrome (via Selenium Manager). Google Chrome must be installed on your machine.
3. **Application Running**:
   - The React frontend should be running locally (default: `http://localhost:5173`).
   - The Express backend and MongoDB should be running (via docker-compose or locally on port `5000`).

## Setup

Navigate to this directory and install dependencies:

```bash
cd selenium-tests
npm install
```

## Running the Tests

To run the complete E2E test suite in headless mode (default):

```bash
npm test
```

To run the tests with the Chrome browser window visible:
1. Open `config.js`.
2. Change `headless: true` to `headless: false`.
3. Save and run `npm test`.

## Test Reports and Screenshots

- **Excel Report**: Every test run generates a styled spreadsheet inside the `reports/` folder: `reports/e2e-test-report-<timestamp>.xlsx`. The sheet includes a summary dashboard and a detailed results ledger.
- **Failure Screenshots**: If any test step fails, a screenshot will automatically be captured and saved to the `screenshots/` directory: `screenshots/<test-id>-<timestamp>.png`. The Excel report will include a clickable hyperlink to the screenshot for quick debugging.

## Test Suite Structure

The tests are organized into modular files corresponding to key user flows:
- `tests/auth.test.js`: Validates onboarding splash screens, login input errors, and successful credentials submission.
- `tests/markets.test.js`: Validates stock watchlist, sector filter tabs, technical scanners, company visual details modal tabs, and paper trading BUY order execution.
- `tests/portfolio.test.js`: Validates paper trading holdings, SELL order execution, Wallet deposits/withdrawals, and capital gains tax analysis.
- `tests/alerts.test.js`: Validates alert trigger criteria creation, active rules checks, and rule deletion.
- `tests/advisor.test.js`: Validates conversational AI chat, quick sentiment queries, and risk profiling quiz retake flows.
- `tests/academy.test.js`: Validates beginner, intermediate, and advanced tutorial starters, as well as the financial glossary interface.
