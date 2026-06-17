from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_mkt_001_indices_cards(driver):
    """Verify real-time index cards are loaded and visible on Markets tab"""
    # Verify NIFTY 50 is displayed
    nifty = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'NIFTY 50')]"))
    )
    assert nifty.is_displayed()
    
    sensex = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'SENSEX')]")
    assert sensex.is_displayed()

def test_mkt_002_watchlist_details(driver):
    """Open Stock Details modal and verify sub-tabs data load"""
    # Locate first stock view button in the watchlist (usually ACC or ADANIGREEN)
    # The view button text is 'View' or search by tag
    view_btn = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "(//*[contains(@text, 'View')])[1]"))
    )
    view_btn.click()

    # Wait for the Stock Details screen to load (AppBar shows stock title)
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'CHART & MACD')]"))
    )

    # Click through tabs
    metrics_tab = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'METRICS')]")
    metrics_tab.click()
    WebDriverWait(driver, 5).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Fundamentals') or contains(@text, 'P/E')]"))
    )

    sentiment_tab = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'SENTIMENT')]")
    sentiment_tab.click()
    WebDriverWait(driver, 5).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Sentiment Meter') or contains(@text, 'Headlines')]"))
    )

def test_mkt_003_buy_transaction(driver):
    """Simulate a paper trade BUY order in the Order Ticket tab"""
    # Navigate to ORDER tab
    order_tab = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'ORDER')]"))
    )
    order_tab.click()

    # Tap on inputs
    qty_input = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//android.widget.EditText"))
    )
    qty_input.clear()
    qty_input.send_keys("10")

    # Click Confirm Buy
    confirm_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'CONFIRM BUY ORDER')]")
    confirm_btn.click()

    # Success snackbar should show
    success_toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'executed successfully') or contains(@text, 'trade')]"))
    )
    assert success_toast.is_displayed()
