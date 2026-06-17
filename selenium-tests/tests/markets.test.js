const { By, until, Key } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Step 1: Verify Indices Cards loaded
  await reporter.runStep('TM-MKT-001', 'Markets', 'Verify real-time index cards are loaded and visible on Markets tab', async () => {
    // Wait for the indices section
    const niftyCard = await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'NIFTY 50')]")), config.timeout);
    assert.ok(niftyCard, "NIFTY 50 card should be displayed");
    
    const sensexCard = await driver.findElement(By.xpath("//span[contains(text(), 'SENSEX')]"));
    assert.ok(sensexCard, "SENSEX card should be displayed");
  });

  // Step 2: Test Sector Filter Pills in Watchlist
  await reporter.runStep('TM-MKT-002', 'Markets', 'Test sector filter pills in the stock watchlist', async () => {
    // Click 'Energy' sector filter pill
    const energyPill = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Energy')]")), config.timeout);
    await driver.executeScript("arguments[0].click();", energyPill);
    await driver.sleep(500); // Wait for filter to apply
    
    // Check that all displayed stocks in table are Energy sector
    const sectorLabels = await driver.findElements(By.xpath("//table/tbody/tr/td[contains(@class, 'hidden lg:table-cell')]/span"));
    for (let label of sectorLabels) {
      const text = await label.getText();
      assert.strictEqual(text, 'Energy', "Stock sector filter should restrict list to Energy stocks");
    }

    // Reset to 'All'
    const allPill = await driver.findElement(By.xpath("//button[contains(text(), 'All')]"));
    await driver.executeScript("arguments[0].click();", allPill);
    await driver.sleep(500);
  });

  // Step 3: Open Stock Details Modal and switch tabs
  await reporter.runStep('TM-MKT-003', 'Markets', 'Open Stock Details modal and verify sub-tabs data load', async () => {
    // Find first stock in watchlist (usually Reliance or INFY) and click View
    const firstStockRow = await driver.wait(until.elementLocated(By.xpath("//table/tbody/tr[1]")), config.timeout);
    const symbolText = await firstStockRow.findElement(By.xpath("./td[1]//span[contains(@class, 'font-extrabold')]")).getText();
    config.lastBoughtSymbol = symbolText;
    
    const viewButton = await firstStockRow.findElement(By.xpath(".//button[contains(text(), 'View')]"));
    await driver.executeScript("arguments[0].click();", viewButton);

    // Verify Modal Header shows the symbol name
    await driver.wait(until.elementLocated(By.xpath(`//h3[contains(text(), '${symbolText}')]`)), config.timeout);
    
    // Click through modal subtabs and verify visual presence of section
    const analysisTab = await driver.findElement(By.xpath("//button[contains(text(), 'Analysis')]"));
    await driver.executeScript("arguments[0].click();", analysisTab);
    await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'Market Cap')]")), config.timeout);

    const financialsTab = await driver.findElement(By.xpath("//button[contains(text(), 'P&L statements')]"));
    await driver.executeScript("arguments[0].click();", financialsTab);
    await driver.wait(until.elementLocated(By.xpath("//h4[contains(text(), 'Quarterly Audits')]")), config.timeout);

    const peersTab = await driver.findElement(By.xpath("//button[contains(text(), 'Peers')]"));
    await driver.executeScript("arguments[0].click();", peersTab);
    await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'Company Symbol')]")), config.timeout);

    const sentimentTab = await driver.findElement(By.xpath("//button[contains(text(), 'Sentiment')]"));
    await driver.executeScript("arguments[0].click();", sentimentTab);
    // Sentiment takes a moment or shows loader, let's wait for the card or summary text
    await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'AI Sentiment') or contains(text(), 'Scraping')]")), config.timeout);
  });

  // Step 4: Execute BUY transaction in Order Ticket
  await reporter.runStep('TM-MKT-004', 'Markets', 'Simulate a paper trade BUY order in the Order Ticket tab', async () => {
    // Click Order Ticket tab
    const orderTicketTab = await driver.findElement(By.xpath("//button[contains(text(), 'ORDER TICKET')]"));
    await driver.executeScript("arguments[0].click();", orderTicketTab);

    // Verify BUY is selected
    const buyBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'BUY')]")), config.timeout);
    // Get class to check if selected (has bg-gainGreen)
    const btnClass = await buyBtn.getAttribute('className');
    assert.ok(btnClass.includes('bg-gainGreen'), "BUY option should be active by default");

    // Input quantity 10
    const qtyInput = await driver.findElement(By.xpath("//input[@placeholder='Quantity of shares']"));
    await qtyInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await qtyInput.sendKeys("10");

    // Click Confirm Order
    const confirmBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Confirm BUY order')]"));
    await confirmBtn.click();

    // Verify Toast success shows up
    await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'executed successfully')]")), config.timeout);

    // Modal should close. Wait for modal to be removed or view button of table to be clickable again
    await driver.wait(until.stalenessOf(confirmBtn), config.timeout);
  });

  // Step 5: Test Scanners Tab
  await reporter.runStep('TM-MKT-005', 'Markets', 'Verify technical scanners tab functionality', async () => {
    // Click Scanners tab in markets sub-nav
    const scannersSubTab = await driver.findElement(By.xpath("//button[contains(text(), 'scanners')]"));
    await scannersSubTab.click();

    // Verify gainer/loser buttons exist
    const losersBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'losers')]")), config.timeout);
    await losersBtn.click();
    await driver.sleep(500);

    const gainersBtn = await driver.findElement(By.xpath("//button[contains(text(), 'gainers')]"));
    await gainersBtn.click();
    await driver.sleep(500);
  });

  // Step 6: Test Sectors Tab
  await reporter.runStep('TM-MKT-006', 'Markets', 'Verify sectors constituent breakdown loads correctly', async () => {
    const sectorsSubTab = await driver.findElement(By.xpath("//button[contains(text(), 'sectors')]"));
    await sectorsSubTab.click();

    // Wait for sector card (e.g. Energy Sector, IT Sector)
    const sectorHeader = await driver.wait(until.elementLocated(By.xpath("//span[contains(., 'Energy Sector')]")), config.timeout);
    assert.ok(sectorHeader, "Energy sector constituents card should be displayed");
  });
};
