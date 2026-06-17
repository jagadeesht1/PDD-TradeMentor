const { By, until } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Navigate to Academy page first
  await reporter.runStep('TM-ACAD-000', 'Academy', 'Navigate to Academy page', async () => {
    const academyTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(., 'Academy')]")), config.timeout);
    await academyTab.click();
    // Wait for Academy content subtabs to load
    await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Trading Academy Modules')]")), config.timeout);
  });

  // Step 1: Verify and start an academy module tutorial
  await reporter.runStep('TM-ACAD-001', 'Academy', 'Verify academy modules cards and trigger study module loading', async () => {
    // Check level cards
    const beginnerCard = await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'Level 1: Market Basics')]")), config.timeout);
    assert.ok(beginnerCard, "Level 1 Market Basics card should be displayed");

    // Click "Start Learning"
    // Find the first "Start Learning" button (Level 1)
    const startLearningBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Start Learning')]"));
    await startLearningBtn.click();

    // Verify toast notification
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Initializing')]")), config.timeout);
    assert.ok(toast, "Tutorial loading toast should be displayed");
  });

  // Step 2: Test Financial Dictionary Glossary Tab
  await reporter.runStep('TM-ACAD-002', 'Academy', 'Verify Financial Dictionary glossary terms list', async () => {
    // Navigate to Glossary tab
    const glossaryTab = await driver.findElement(By.xpath("//button[contains(text(), 'Financial Dictionary')]"));
    await glossaryTab.click();

    // Verify some glossary term exists (e.g. P/E Ratio)
    const peTerm = await driver.wait(until.elementLocated(By.xpath("//p[contains(text(), 'P/E Ratio')]")), config.timeout);
    assert.ok(peTerm, "P/E Ratio term card should be visible in glossary list");
  });
};
