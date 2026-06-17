const chromedriver = require('chromedriver');
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

async function test() {
  console.log("Building chrome driver...");
  const options = new chrome.Options();
  options.addArguments('--headless=new');
  options.addArguments('--no-sandbox');
  options.addArguments('--disable-gpu');
  try {
    const driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .build();
    console.log("Driver built successfully!");
    await driver.quit();
  } catch (err) {
    console.error("Error building driver:", err);
  }
}
test();
