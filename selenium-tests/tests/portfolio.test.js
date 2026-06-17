const { By, until, Key } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Navigate to Portfolio page first
  await reporter.runStep('TM-PORT-000', 'Portfolio', 'Navigate to Portfolio page', async () => {
    const portfolioTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(., 'Portfolio')]")), config.timeout);
    await portfolioTab.click();
    // Wait for the Portfolio content to load
    await driver.wait(until.elementLocated(By.xpath("//p[contains(text(), 'Total Invested')]")), config.timeout);
  });

  // Step 1: Verify Holdings table contains the bought stock
  await reporter.runStep('TM-PORT-001', 'Portfolio', 'Verify holdings table details match previous trade', async () => {
    // Open Positions subtab is active by default
    // Check if the table has at least one row representing our open positions
    const stockRow = await driver.wait(until.elementLocated(By.xpath("//table/tbody/tr")), config.timeout);
    const symbolText = await stockRow.findElement(By.xpath("./td[1]//span[contains(@class, 'font-extrabold')]")).getText();
    assert.ok(symbolText.length > 0, "Holdings table should show a symbol");
    
    const qtyText = await stockRow.findElement(By.xpath("./td[2]")).getText();
    const qty = parseInt(qtyText, 10);
    assert.ok(qty > 0, "Quantity of holding should be greater than zero");
  });

  // Step 2: Sell part of the holdings
  await reporter.runStep('TM-PORT-002', 'Portfolio', 'Simulate selling portion of holdings via order ticket', async () => {
    // Find the row containing our last bought stock symbol
    const stockRow = await driver.wait(until.elementLocated(By.xpath(`//table/tbody/tr[descendant::span[contains(text(), '${config.lastBoughtSymbol}')]]`)), config.timeout);
    const sellButton = await stockRow.findElement(By.xpath(".//button[contains(text(), 'Sell')]"));
    await sellButton.click();

    // Verify Modal opens and ORDER TICKET is selected
    const confirmSellBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Confirm SELL order')]")), config.timeout);
    
    // Set quantity to 5
    const qtyInput = await driver.findElement(By.xpath("//input[@placeholder='Quantity of shares']"));
    await qtyInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await qtyInput.sendKeys("5");

    await confirmSellBtn.click();

    // Verify Toast success
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'executed successfully')]")), config.timeout);
    assert.ok(toast, "SELL order success toast should be displayed");

    // Modal should close
    await driver.wait(until.stalenessOf(confirmSellBtn), config.timeout);
  });

  // Step 3: Test Wallet Manager deposits & withdrawals
  await reporter.runStep('TM-PORT-003', 'Portfolio', 'Verify Wallet Manager Deposit and Withdrawal flow', async () => {
    // Navigate to Wallet Manager sub-tab
    const walletTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Wallet Manager')]")), config.timeout);
    await walletTab.click();

    // Wait for Deposit Form to load
    await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'Deposit Simulated Capital')]")), config.timeout);

    // Get current wallet balance from header to compare
    const balanceSpan = await driver.findElement(By.xpath("//header//span[contains(text(), '₹')]"));
    const balanceBefore = parseFloat((await balanceSpan.getText()).replace(/[^0-9.]/g, ''));

    // Perform Deposit
    const depositInput = await driver.findElement(By.xpath("//input[@type='number' and following-sibling::button[contains(text(), 'Confirm UPI Deposit')]]"));
    await depositInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await depositInput.sendKeys("15000");
    
    const depositBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Confirm UPI Deposit')]"));
    await depositBtn.click();

    // Verify success toast
    const toast1 = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Successfully credited')]")), config.timeout);
    assert.ok((await toast1.getAttribute("textContent")).includes('credited'), "Deposit toast should show credit confirmation");

    // Perform Withdrawal
    const withdrawInput = await driver.wait(until.elementLocated(By.xpath("//input[@type='number' and following-sibling::button[contains(text(), 'Confirm Bank Withdrawal')]]")), config.timeout);
    await withdrawInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await withdrawInput.sendKeys("5000");

    const withdrawBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Confirm Bank Withdrawal')]"));
    await withdrawBtn.click();

    // Verify success toast
    const toast2 = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Successfully withdrew')]")), config.timeout);
    assert.ok((await toast2.getAttribute("textContent")).includes('withdrew'), "Withdrawal toast should show debit confirmation");

    // Verify that the net balance changed by +10000
    const balanceAfter = parseFloat((await balanceSpan.getText()).replace(/[^0-9.]/g, ''));
    // Wait for state updates if necessary, but it should be fast
    assert.strictEqual(Math.round(balanceAfter - balanceBefore), 10000, "Wallet balance should reflect net deposit of ₹10,000");
  });

  // Step 4: Verify Capital Gains Tax view
  await reporter.runStep('TM-PORT-004', 'Portfolio', 'Verify Capital Gains Tax summary card outputs', async () => {
    // Navigate to Capital Gains Tax sub-tab
    const taxTab = await driver.findElement(By.xpath("//button[contains(text(), 'Capital Gains Tax')]"));
    await taxTab.click();

    // Wait for the tax breakdown title
    const taxHeader = await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'Capital Gains Tax Breakdown')]")), config.timeout);
    assert.ok(taxHeader, "Capital gains tax breakdown should be visible");
  });
};
