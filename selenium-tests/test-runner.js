const chromedriver = require('chromedriver');
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');
const config = require('./config');

// Ensure reporting and screenshot directories exist
const reportsDir = path.join(__dirname, 'reports');
const screenshotsDir = path.join(__dirname, 'screenshots');
if (!fs.existsSync(reportsDir)) fs.mkdirSync(reportsDir, { recursive: true });
if (!fs.existsSync(screenshotsDir)) fs.mkdirSync(screenshotsDir, { recursive: true });

// Setup a global state for storing test results
const results = [];
const startTime = new Date();

const reporter = {
  runStep: async (id, category, description, fn) => {
    console.log(`[RUNNING] ${id} - ${category}: ${description}...`);
    const stepStart = Date.now();
    try {
      await fn();
      const duration = Date.now() - stepStart;
      results.push({
        id,
        category,
        description,
        status: 'PASS',
        duration,
        error: null,
        screenshot: null
      });
      console.log(`  [PASS] Completed in ${duration}ms\n`);
    } catch (err) {
      const duration = Date.now() - stepStart;
      console.error(`  [FAIL] Error: ${err.message}`);
      
      // Attempt to take screenshot
      let screenshotFilename = null;
      if (global.driver) {
        try {
          const screenshotData = await global.driver.takeScreenshot();
          const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
          screenshotFilename = `${id}-${timestamp}.png`;
          const screenshotPath = path.join(screenshotsDir, screenshotFilename);
          fs.writeFileSync(screenshotPath, screenshotData, 'base64');
          console.log(`  [SCREENSHOT] Saved failure state to ${screenshotPath}\n`);
        } catch (screenshotErr) {
          console.error(`  [ERROR] Failed to capture screenshot: ${screenshotErr.message}`);
        }
        try {
          const logs = await global.driver.manage().logs().get('browser');
          if (logs && logs.length > 0) {
            console.log('  [BROWSER LOGS] on failure:');
            logs.forEach(log => console.log(`    [${log.level.name}] ${log.message}`));
          }
        } catch (logErr) {}
      }
      
      results.push({
        id,
        category,
        description,
        status: 'FAIL',
        duration,
        error: err.message,
        screenshot: screenshotFilename
      });
    }
  }
};

async function generateExcelReport() {
  const endTime = new Date();
  const totalDuration = endTime - startTime;
  const timestamp = endTime.toISOString().replace(/[:.]/g, '-');
  const reportFilename = `e2e-test-report-${timestamp}.xlsx`;
  const reportPath = path.join(reportsDir, reportFilename);

  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'TradeMentor E2E Selenium Reporter';
  workbook.created = endTime;

  // ─── Sheet 1: Dashboard Summary ───
  const dashboardSheet = workbook.addWorksheet('Summary Dashboard');
  dashboardSheet.views = [{ showGridLines: true }];

  // Setup Title Banner
  dashboardSheet.mergeCells('A1:D1');
  const titleCell = dashboardSheet.getCell('A1');
  titleCell.value = 'TradeMentor E2E Automation test report';
  titleCell.font = { name: 'Arial', size: 16, bold: true, color: { argb: 'FFFFFFFF' } };
  titleCell.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF0B121E' } // Dark Navy matching TradeMentor
  };
  titleCell.alignment = { vertical: 'middle', horizontal: 'center' };
  dashboardSheet.getRow(1).height = 40;

  // Add Summary Metrics Table
  dashboardSheet.getCell('A3').value = 'Execution Summary Metric';
  dashboardSheet.getCell('A3').font = { bold: true };
  dashboardSheet.getCell('B3').value = 'Details / Value';
  dashboardSheet.getCell('B3').font = { bold: true };
  dashboardSheet.getRow(3).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF141F32' } // Slate background
  };
  dashboardSheet.getRow(3).font = { color: { argb: 'FFFFFFFF' }, bold: true };

  const totalSteps = results.length;
  const passedSteps = results.filter(r => r.status === 'PASS').length;
  const failedSteps = results.filter(r => r.status === 'FAIL').length;
  const passRate = totalSteps > 0 ? (passedSteps / totalSteps) * 100 : 0;

  const metrics = [
    { name: 'Run Timestamp', val: endTime.toLocaleString('en-IN') },
    { name: 'Target App URL', val: config.baseUrl },
    { name: 'Browser Platform', val: `${config.browserName} (headless: ${config.headless})` },
    { name: 'Total Test Steps', val: totalSteps },
    { name: 'Passed Steps', val: passedSteps },
    { name: 'Failed Steps', val: failedSteps },
    { name: 'Pass Rate (%)', val: `${passRate.toFixed(2)}%` },
    { name: 'Total Suite Duration', val: `${(totalDuration / 1000).toFixed(2)} seconds` }
  ];

  metrics.forEach((m, index) => {
    const rNum = 4 + index;
    dashboardSheet.getCell(`A${rNum}`).value = m.name;
    dashboardSheet.getCell(`B${rNum}`).value = m.val;
    dashboardSheet.getCell(`A${rNum}`).font = { name: 'Arial', size: 11, bold: true };
    dashboardSheet.getCell(`B${rNum}`).font = { name: 'Arial', size: 11 };

    // Format metrics rows slightly
    if (m.name === 'Pass Rate (%)') {
      dashboardSheet.getCell(`B${rNum}`).font = {
        name: 'Arial',
        size: 11,
        bold: true,
        color: { argb: passRate === 100 ? 'FF00D09C' : 'FFFF5353' } // Emerald green or Crimson red
      };
    }
  });

  // Adjust columns for Dashboard
  dashboardSheet.getColumn('A').width = 32;
  dashboardSheet.getColumn('B').width = 45;

  // ─── Sheet 2: Test Results Ledger ───
  const ledgerSheet = workbook.addWorksheet('Test Results Ledger');
  ledgerSheet.views = [{ showGridLines: true }];

  // Headers
  const headers = ['Test ID', 'Category', 'Test Step Description', 'Status', 'Duration (ms)', 'Details / Error message', 'Screenshot Reference'];
  ledgerSheet.addRow(headers);
  const headerRow = ledgerSheet.getRow(1);
  headerRow.height = 25;
  headerRow.font = { name: 'Arial', size: 11, bold: true, color: { argb: 'FFFFFFFF' } };
  headerRow.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF141F32' } // Slate background
  };
  headerRow.alignment = { vertical: 'middle', horizontal: 'left' };

  // Add Data
  results.forEach(r => {
    const row = ledgerSheet.addRow([
      r.id,
      r.category,
      r.description,
      r.status,
      r.duration,
      r.error || 'N/A',
      r.screenshot ? 'View Screenshot' : 'N/A'
    ]);

    // Align vertical
    row.alignment = { vertical: 'middle' };

    // Format Status cells
    const statusCell = row.getCell(4);
    if (r.status === 'PASS') {
      statusCell.font = { name: 'Arial', size: 11, bold: true, color: { argb: 'FF00D09C' } }; // Emerald
    } else {
      statusCell.font = { name: 'Arial', size: 11, bold: true, color: { argb: 'FFFF5353' } }; // Crimson
    }

    // Format Screenshot column
    const screenshotCell = row.getCell(7);
    if (r.screenshot) {
      // Create clickable hyperlink pointing to screenshots folder
      screenshotCell.value = {
        text: 'View Failure Screenshot',
        hyperlink: path.join(__dirname, 'screenshots', r.screenshot),
        tooltip: 'Click to open failure screenshot on local machine'
      };
      screenshotCell.font = { name: 'Arial', size: 11, color: { argb: 'FF4285F4' }, underline: true };
    }
  });

  // Adjust column widths automatically
  ledgerSheet.columns.forEach((column, index) => {
    let maxLen = 0;
    column.eachCell({ includeEmpty: true }, (cell) => {
      const valStr = cell.value ? String(cell.value.text || cell.value) : '';
      if (valStr.length > maxLen) {
        maxLen = valStr.length;
      }
    });
    // Add margin and cap
    column.width = Math.min(Math.max(maxLen + 4, 12), 65);
  });

  // Write Excel file to disk
  await workbook.xlsx.writeFile(reportPath);
  console.log(`\n======================================================`);
  console.log(`[COMPLETED] Suite finished!`);
  console.log(`  Total Steps: ${totalSteps}`);
  console.log(`  Passed:      ${passedSteps}`);
  console.log(`  Failed:      ${failedSteps}`);
  console.log(`  Pass Rate:   ${passRate.toFixed(2)}%`);
  console.log(`  Excel Report Path: ${reportPath}`);
  console.log(`======================================================\n`);
}

async function runSuite() {
  console.log(`Starting E2E Selenium Test Suite for TradeMentor...\n`);
  
  // Reset database before suite starts
  try {
    const { execSync } = require('child_process');
    console.log('Resetting database before starting test run...');
    execSync('node reset-db.js', { cwd: __dirname, stdio: 'inherit' });
  } catch (resetErr) {
    console.error('Failed to reset database before starting suite:', resetErr.message);
  }
  
  const chromeOptions = new chrome.Options();
  if (config.headless) {
    chromeOptions.addArguments('--headless=new');
    chromeOptions.addArguments('--disable-gpu');
    chromeOptions.addArguments('--no-sandbox');
    chromeOptions.addArguments('--disable-dev-shm-usage');
  }
  // Setup large screen resolution to prevent layout collapse
  chromeOptions.addArguments('--window-size=1920,1080');

  // Build the Chrome Driver
  const driver = await new Builder()
    .forBrowser(config.browserName)
    .setChromeOptions(chromeOptions)
    .build();

  global.driver = driver;

  try {
    // 1. Auth & Onboarding Flow
    await require('./tests/auth.test.js')(driver, config, reporter);
    
    // 2. Markets and Sector/Scanners & Trading
    await require('./tests/markets.test.js')(driver, config, reporter);

    // 3. Portfolio, Holdings, Wallet cash flow & Capital Gains
    await require('./tests/portfolio.test.js')(driver, config, reporter);

    // 4. Alerts and Rule Triggers Deployment/Deletion
    await require('./tests/alerts.test.js')(driver, config, reporter);

    // 5. Chatbot Interface and Risk Profile retakes
    await require('./tests/advisor.test.js')(driver, config, reporter);

    // 6. Ledger History logs auditing
    await require('./tests/history.test.js')(driver, config, reporter);

    // 7. Academic Tutorials & Financial Glossary dictionary
    await require('./tests/academy.test.js')(driver, config, reporter);

  } catch (topErr) {
    console.error(`\n[CRITICAL ERROR] Test suite aborted prematurely: ${topErr.message}`);
    // Register the critical crash
    results.push({
      id: 'TM-CRASH-000',
      category: 'System',
      description: 'Test runner execution stability check',
      status: 'FAIL',
      duration: 0,
      error: topErr.message,
      screenshot: null
    });
  } finally {
    // Quit Driver
    if (driver) {
      console.log('Quitting browser session...');
      await driver.quit();
    }
    
    // Generate Report
    await generateExcelReport();
  }
}

// Run the script
runSuite();
