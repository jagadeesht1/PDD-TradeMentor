const { By, until, Key } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Navigate to AI Advisor page first
  await reporter.runStep('TM-ADVI-000', 'AI Advisor', 'Navigate to AI Advisor page', async () => {
    const advisorTab = await driver.wait(until.elementLocated(By.xpath("//button[contains(., 'AI Advisor')]")), config.timeout);
    await advisorTab.click();
    // Wait for AI Advisor main header to load
    await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'TradeMentor AI Advisor')]")), config.timeout);
  });

  // Step 1: Verify Risk Profile classification change
  await reporter.runStep('TM-ADVI-001', 'AI Advisor', 'Modify AI Risk Profile classification and verify sensitivity adjustment', async () => {
    // Click 'high' risk button
    const highRiskBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'high')]")), config.timeout);
    await highRiskBtn.click();

    // Verify success toast
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'model set to HIGH')]")), config.timeout);
    assert.ok(toast, "Risk model change toast should show HIGH risk confirmation");
  });

  // Step 2: Send message to chatbot and receive reply
  await reporter.runStep('TM-ADVI-002', 'AI Advisor', 'Submit question to AI Chatbot and verify response generation', async () => {
    // Locate the chat input
    const chatInput = await driver.findElement(By.xpath("//input[@placeholder=\"Ask AI (e.g. 'Is INFY a buy?', 'PE ratio definition')\"]"));
    await chatInput.sendKeys("what is RSI indicator?");
    
    // Locate send button and click
    const sendBtn = await driver.findElement(By.xpath("//form[contains(@class, 'p-4')]/button[@type='submit']"));
    await sendBtn.click();

    // Wait for the AI processing spinner to disappear or response message to load
    // The spinner text is: "AI is scanning database ticks…"
    await driver.sleep(1000); // give it a moment to show spinner
    
    // Now wait until the chatbot response bubble containing technical details is displayed.
    // The bot message bubble has background bg-[#0B121E] and text-white. Let's find the last message bubble.
    const lastMessage = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'bg-[#0B121E]') and contains(@class, 'text-white') and contains(@class, 'rounded-tl-none')][last()]")), config.timeout);
    const msgText = await lastMessage.getText();
    assert.ok(msgText.length > 0, "AI Advisor should return a text reply");
    assert.ok(!msgText.includes("scanning database ticks"), "AI response should finish loading");
  });

  // Step 3: Trigger a Quick Preset Command
  await reporter.runStep('TM-ADVI-003', 'AI Advisor', 'Execute quick AI preset scanner command shortcut', async () => {
    // Click "Run Market Scanner" preset button
    const presetBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Run Market Scanner')]"));
    await presetBtn.click();

    // Verify a new chat bubble is added
    await driver.sleep(1500); // Wait for response
    const lastMessage = await driver.findElement(By.xpath("//div[contains(@class, 'bg-[#0B121E]') and contains(@class, 'text-white') and contains(@class, 'rounded-tl-none')][last()]"));
    const msgText = await lastMessage.getText();
    assert.ok(msgText.length > 0, "AI Advisor should output preset scan results");
  });

  // Step 4: Retake Risk Quiz flow
  await reporter.runStep('TM-ADVI-004', 'AI Advisor', 'Verify Retake AI Risk Quiz popup modal dialog', async () => {
    const retakeBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Retake AI Risk Quiz')]"));
    await retakeBtn.click();

    // Wait for the modal dialog to load
    await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'AI Risk Profile Quiz')]")), config.timeout);

    // Select "Balanced Growth"
    const balancedBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Balanced Growth')]"));
    await balancedBtn.click();

    // Verify modal closes and success toast displays
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Risk profile set to MODERATE')]")), config.timeout);
    assert.ok(toast, "Risk quiz retake success toast should be displayed");
  });
};
