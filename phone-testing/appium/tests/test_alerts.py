from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_alrt_001_deploy_rule(driver):
    """Configure and deploy a custom alert trigger rule"""
    # Navigate to My Rules nav
    alerts_nav = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'My Rules')]"))
    )
    alerts_nav.click()

    # Wait for Deploy form
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Deploy Alert Rule') or contains(@text, 'Pick Equity')]"))
    )

    # Pick Equity select (in mobile list, we can open dropdown or choose)
    dropdown = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Pick Equity') or contains(@text, 'Select Stock')]")
    dropdown.click()
    
    # Select first stock in dropdown options
    option = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "(//android.widget.CheckedTextView)[1] or //*[contains(@text, 'RELIANCE') or contains(@text, 'INFY') or contains(@text, 'TCS')]"))
    )
    option.click()

    # Target Price input
    price_input = driver.find_element(AppiumBy.XPATH, "//android.widget.EditText")
    price_input.clear()
    price_input.send_keys("1250")

    # Click Deploy
    deploy_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'DEPLOY ALERT RULE') or contains(@text, 'Deploy Rule')]")
    deploy_btn.click()

    # Check toast
    toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Alert rule active') or contains(@text, 'deployed')]"))
    )
    assert toast.is_displayed()

def test_alrt_002_delete_rule(driver):
    """Verify active alert rule deletion"""
    # Go to Active Rules subtab
    active_tab = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Active Rules')]"))
    )
    active_tab.click()

    # Find the trash bin icon button next to active rules and click it
    # We can use xpath for the icon button or class name
    delete_icon = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "(//android.widget.Button[descendant::android.widget.ImageView or contains(@content-desc, 'delete') or contains(@text, 'Delete')])[1]"))
    )
    delete_icon.click()

    # Success toast
    toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'deleted') or contains(@text, 'removed')]"))
    )
    assert toast.is_displayed()
