const { By, until, Key } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Navigate to My Rules page first
  await reporter.runStep('TM-ALRT-000', 'Alerts', 'Navigate to My Rules page', async () => {
    const alertsTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(., 'My Rules')]")), config.timeout);
    await alertsTab.click();
    // Wait for deploy alert form to load
    await driver.wait(until.elementLocated(By.xpath("//h2[contains(text(), 'Deploy Alert Rule')]")), config.timeout);
  });

  // Step 1: Deploy a custom alert trigger
  let alertStockSymbol = '';
  await reporter.runStep('TM-ALRT-001', 'Alerts', 'Configure and deploy a custom alert trigger rule', async () => {
    // Select stock from dropdown
    const selectStock = await driver.findElement(By.xpath("//select[preceding-sibling::label[contains(text(), 'Pick Equity')]]"));
    // Get the options and select the second option
    const options = await selectStock.findElements(By.tagName('option'));
    // Make sure we have options, select index 1 (since 0 is the placeholder)
    if (options.length > 1) {
      const val = await options[1].getAttribute('value');
      alertStockSymbol = val;
      await selectStock.sendKeys(val);
    } else {
      throw new Error("No stock options found in Pick Equity dropdown");
    }

    // Select criteria: less than or equal to
    const selectCriteria = await driver.findElement(By.xpath("//select[preceding-sibling::label[contains(text(), 'Conditional Criteria')]]"));
    await selectCriteria.sendKeys('LESS_THAN');

    // Input target price threshold
    const priceInput = await driver.findElement(By.xpath("//input[@placeholder='Enter price trigger threshold']"));
    await priceInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await priceInput.sendKeys("1250");

    // Click Deploy Rule Trigger
    const deployBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Deploy Rule Trigger')]"));
    await deployBtn.click();

    // Verify toast notification
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Alert rule deployed')]")), config.timeout);
    assert.ok(toast, "Alert deployment success toast should be displayed");
  });

  // Step 2: Verify rule is listed in Active Rules
  await reporter.runStep('TM-ALRT-002', 'Alerts', 'Verify the deployed rule is active and visible in the rules ledger', async () => {
    // Switch to Active Rules tab in rules sub-nav (it should be selected by default, but click to be sure)
    const activeRulesBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Active Rules')]")), config.timeout);
    await activeRulesBtn.click();

    // Find the rule card in the list
    const ruleSymbol = await driver.wait(until.elementLocated(By.xpath(`//div[contains(@class, 'flex')]/div/div/span[contains(text(), '${alertStockSymbol}')]`)), config.timeout);
    assert.ok(ruleSymbol, "Newly created alert rule should be displayed in the list");
  });

  // Step 3: Delete the active rule
  await reporter.runStep('TM-ALRT-003', 'Alerts', 'Verify active alert rule deletion', async () => {
    // Find the rule card parent div that contains our symbol, then locate the delete button inside it
    const ruleSymbolSpan = await driver.findElement(By.xpath(`//div[contains(@class, 'flex')]/div/div/span[contains(text(), '${alertStockSymbol}')]`));
    // Traverse up to find the main card container (e.g. flex row)
    const cardContainer = await ruleSymbolSpan.findElement(By.xpath("./ancestor::div[contains(@class, 'p-4')][1]"));
    
    // Find delete button inside the card container
    // The delete button has a trash icon and is on the right of the flex row
    const deleteBtn = await cardContainer.findElement(By.xpath(".//button[contains(@class, 'hover:text-lossRed')]"));
    await deleteBtn.click();

    // Verify toast notification for delete success
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Alert rule deleted')]")), config.timeout);
    assert.ok(toast, "Alert deletion toast should be displayed");

    // Wait for the card to disappear
    await driver.wait(until.stalenessOf(ruleSymbolSpan), config.timeout);
  });
};
