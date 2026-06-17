const { By, until } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Navigate to Ledger page
  await reporter.runStep('TM-HIST-000', 'Ledger', 'Navigate to Ledger history page', async () => {
    const ledgerTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(., 'Ledger')]")), config.timeout);
    await ledgerTab.click();
    // Wait for the ledger header to load
    await driver.wait(until.elementLocated(By.xpath("//h2[contains(text(), 'Trade Ledger records')]")), config.timeout);
  });

  // Step 1: Verify Ledger history entries are loaded
  await reporter.runStep('TM-HIST-001', 'Ledger', 'Verify ledger records contain entries from executed transactions', async () => {
    // Check if the ledger table rows exist
    const ledgerRow = await driver.wait(until.elementLocated(By.xpath("//table/tbody/tr")), config.timeout);
    assert.ok(await ledgerRow.isDisplayed(), "Ledger table should list transactions");

    // Verify presence of transaction types (BUY or SELL)
    const typeCell = await ledgerRow.findElement(By.xpath("./td[1]//span"));
    const typeText = await typeCell.getText();
    assert.ok(typeText === 'BUY' || typeText === 'SELL', "Transaction type should be BUY or SELL");
  });

  // Step 2: Refresh ledger record
  await reporter.runStep('TM-HIST-002', 'Ledger', 'Test transaction list refresh button trigger', async () => {
    // Locate refresh button in the header and click it
    const refreshBtn = await driver.findElement(By.xpath("//h2[contains(text(), 'Trade Ledger records')]/following-sibling::button"));
    await refreshBtn.click();
    await driver.sleep(500); // Wait for refresh state

    const ledgerRow = await driver.findElement(By.xpath("//table/tbody/tr[1]"));
    assert.ok(await ledgerRow.isDisplayed(), "Ledger table should remain populated after refresh");
  });
};
