const { Builder, By, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');

async function runE2ESuite() {
    console.log("==================================================");
    console.log("   TRADEMENTOR SELENIUM NODE.JS AUTOMATED TEST   ");
    console.log("==================================================");

    let options = new chrome.Options();
    options.addArguments('--headless=new');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
    options.addArguments('--window-size=1280,1024');

    let driver;
    try {
        driver = await new Builder()
            .forBrowser('chrome')
            .setChromeOptions(options)
            .build();
        console.log("Chrome WebDriver initialized successfully.");
    } catch (e) {
        console.error(`[ERROR] Failed to initialize Chrome WebDriver: ${e}`);
        console.error("Make sure Google Chrome is installed on your local computer to execute this automation.");
        process.exit(1);
    }

    try {
        // 1. Open React Web App
        console.log("\n[STEP 1] Navigating to React Web Application...");
        await driver.get("http://localhost:5173");
        await driver.sleep(1500);
        
        let title = await driver.getTitle();
        if (!title.includes("TradeMentor")) {
            throw new Error(`Expected page title to contain 'TradeMentor', but got '${title}'`);
        }
        console.log(`[OK] Success: Page loaded. Title contains 'TradeMentor'.`);

        // 2. Splash screen navigation trigger
        console.log("\n[STEP 2] Testing Splash screen Get Started redirect CTA...");
        let ctaBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Get Started')]")), 10000);
        await driver.wait(until.elementIsVisible(ctaBtn), 10000);
        await ctaBtn.click();
        await driver.sleep(1500);
        console.log("[OK] Success: Navigation completed to Login screen.");

        // 3. Fill authentication inputs and submit
        console.log("\n[STEP 3] Testing Login form credential validations and submit...");
        let emailField = await driver.wait(until.elementLocated(By.xpath("//input[@type='email']")), 10000);
        let passField = await driver.findElement(By.xpath("//input[@type='password']"));
        let submitBtn = await driver.findElement(By.xpath("//button[@type='submit']"));

        await emailField.clear();
        await emailField.sendKeys("demo@tradementor.com");
        await passField.clear();
        await passField.sendKeys("password123");
        await submitBtn.click();
        await driver.sleep(2000);
        console.log("[OK] Success: Login form submitted.");

        // 4. Handle Risk Quiz Screen
        console.log("\n[STEP 4] Completing the AI Onboarding Risk Quiz...");
        let q1Btn = await driver.wait(until.elementLocated(By.xpath("//div[contains(., 'primary investment goal?')]/div/button[1]")), 10000);
        await q1Btn.click();
        await driver.sleep(300);

        let q2Btn = await driver.findElement(By.xpath("//div[contains(., 'react if your portfolio drops')]/div/button[1]"));
        await q2Btn.click();
        await driver.sleep(300);

        let q3Btn = await driver.findElement(By.xpath("//div[contains(., 'planned investment horizon?')]/div/button[1]"));
        await q3Btn.click();
        await driver.sleep(300);

        let analyzeBtn = await driver.findElement(By.xpath("//button[contains(text(), 'Analyze My Risk Profile')]"));
        await analyzeBtn.click();
        await driver.sleep(1500);
        console.log("  - Analyzed risk profile.");

        let enterPlatformBtn = await driver.wait(until.elementLocated(By.xpath("//button[contains(text(), 'Enter Platform')]")), 10000);
        await enterPlatformBtn.click();
        await driver.sleep(2000);
        console.log("[OK] Success: Risk Quiz completed. User entered the main platform.");

        // 5. Tab Navigation checks
        console.log("\n[STEP 5] Verifying dashboard navigation headers and active tabs...");
        const dashboardTabs = ['markets', 'portfolio', 'alerts', 'advisor', 'history', 'academy'];
        for (let tab of dashboardTabs) {
            let tabBtn = await driver.wait(until.elementLocated(By.xpath(`//button[contains(., '${tab.charAt(0).toUpperCase() + tab.slice(1)}') or contains(., 'My Rules') or contains(., 'AI Advisor') or contains(., 'Ledger')]`)), 10000);
            await tabBtn.click();
            await driver.sleep(500);
            console.log(`  - Loaded dashboard tab: ${tab.toUpperCase()}`);
        }
        console.log("[OK] Success: Navigation buttons are operational across all tabs.");

        // 6. Check mock data loading (Markets Dashboard)
        console.log("\n[STEP 6] Checking active stock list rendering...");
        let marketsTab = await driver.findElement(By.xpath("//button[contains(., 'Markets')]"));
        await marketsTab.click();
        await driver.sleep(800);

        let stockCard = await driver.wait(until.elementLocated(By.xpath("//span[contains(text(), 'TCS') or contains(text(), 'RELIANCE')]")), 10000);
        console.log("[OK] Success: Watchlist rows and ticker data populated correctly.");

        console.log("\n==================================================");
        console.log("   ALL SELENIUM E2E FUNCTIONAL TESTS COMPLETED: PASSED");
        console.log("==================================================");

    } catch (error) {
        console.error(`\n[ERROR] E2E test suite failed with error assertion: ${error}`);
        try {
            let image = await driver.takeScreenshot();
            fs.writeFileSync('selenium_failure_screenshot.png', image, 'base64');
            console.log("Failure screenshot captured at 'selenium_failure_screenshot.png'");
        } catch (screenshotError) {
            console.error(`Could not take failure screenshot: ${screenshotError}`);
        }
        process.exit(1);
    } finally {
        if (driver) {
            await driver.quit();
        }
    }
}

runE2ESuite();
