const { By, until, Key } = require('selenium-webdriver');
const assert = require('assert');

module.exports = async function(driver, config, reporter) {
  // Step 1: Open Application
  await reporter.runStep('TM-AUTH-001', 'Authentication', 'Verify welcome/splash screen loads and displays TradeMentor branding', async () => {
    await driver.get(config.baseUrl);
    // Wait for the h1 contains TradeMentor
    const title = await driver.wait(until.elementLocated(By.xpath("//h1[contains(text(), 'TradeMentor')]")), config.timeout);
    assert.ok(await title.isDisplayed(), "TradeMentor header title should be displayed");
    
    const getStartedBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Get Started')]"));
    assert.ok(await getStartedBtn.isDisplayed(), "Get Started button should be displayed");
  });

  // Step 2: Navigate to Login
  await reporter.runStep('TM-AUTH-002', 'Authentication', 'Navigate from Splash screen to Login page', async () => {
    const getStartedBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Get Started')]"));
    await getStartedBtn.click();
    
    // Wait for email input to be visible
    await driver.wait(until.elementLocated(By.xpath("//input[@type='email']")), config.timeout);
    const loginHeader = await driver.findElement(By.xpath("//h2[contains(text(), 'Welcome Back')]"));
    assert.ok(await loginHeader.isDisplayed(), "Login page header should be displayed");
  });

  // Step 3: Verify Invalid Login
  await reporter.runStep('TM-AUTH-003', 'Authentication', 'Verify login validation fails with empty fields', async () => {
    const emailInput = await driver.findElement(By.xpath("//input[@type='email']"));
    const passwordInput = await driver.findElement(By.xpath("//input[@type='password']"));
    const submitBtn = await driver.findElement(By.xpath("//button[@type='submit' and contains(text(), 'Sign In')]"));
    
    // Clear fields
    await emailInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await passwordInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await submitBtn.click();
    
    // Check if error toast displays
    const toast = await driver.wait(until.elementLocated(By.xpath("//div[contains(@class, 'animate-fadeIn') and contains(., 'Please enter both email and password')]")), 5000);
    const toastText = await toast.getAttribute("textContent");
    assert.ok(toastText.includes('Please enter both email and password'), "Empty inputs error toast should be visible");
  });

  // Step 4: Verify Successful Login & Quiz Onboarding
  await reporter.runStep('TM-AUTH-004', 'Authentication', 'Verify successful login loads the Risk Onboarding Quiz', async () => {
    const emailInput = await driver.findElement(By.xpath("//input[@type='email']"));
    const passwordInput = await driver.findElement(By.xpath("//input[@type='password']"));
    const submitBtn = await driver.findElement(By.xpath("//button[@type='submit' and contains(text(), 'Sign In')]"));
    
    await emailInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await emailInput.sendKeys(config.credentials.email);
    await passwordInput.sendKeys(Key.chord(Key.CONTROL, "a"), Key.BACK_SPACE);
    await passwordInput.sendKeys(config.credentials.password);
    await submitBtn.click();
    
    // Should navigate to RISK_QUIZ screen
    const quizHeader = await driver.wait(until.elementLocated(By.xpath("//h2[contains(text(), 'AI Onboarding Quiz')]")), config.timeout);
    assert.ok(await quizHeader.isDisplayed(), "Risk Onboarding Quiz should be displayed");
  });

  // Step 5: Answer Risk Quiz & Enter Platform
  await reporter.runStep('TM-AUTH-005', 'Authentication', 'Complete AI Risk Quiz and enter TradeMentor platform dashboard', async () => {
    // Select answers for Q1, Q2, Q3
    // Q1 Option 2: Balance Capital Growth
    const q1Option = await driver.findElement(By.xpath("//button[contains(text(), 'Balance Capital Growth')]"));
    await q1Option.click();
    
    // Q2 Option 2: Hold positions
    const q2Option = await driver.findElement(By.xpath("//button[contains(text(), 'Hold positions')]"));
    await q2Option.click();
    
    // Q3 Option 2: Medium term
    const q3Option = await driver.findElement(By.xpath("//button[contains(text(), 'Medium term')]"));
    await q3Option.click();
    
    // Submit Quiz
    const analyzeBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Analyze My Risk Profile')]"));
    await driver.executeScript("arguments[0].click();", analyzeBtn);
    
    // Wait for popup dialog "Quiz Completed!"
    await driver.wait(until.elementLocated(By.xpath("//h3[contains(text(), 'Quiz Completed!')]")), config.timeout);
    
    // Click "Enter Platform"
    const enterBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Enter Platform')]"));
    await enterBtn.click();
    
    // Verify Dashboard is loaded (Header has TradeMentor title and balance)
    await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'REAL-TIME SIMULATION')]")), config.timeout);
    const brand = await driver.findElement(By.xpath("//span[contains(text(), 'TradeMentor')]"));
    assert.ok(brand, "TradeMentor Dashboard should be loaded");
  });
};
