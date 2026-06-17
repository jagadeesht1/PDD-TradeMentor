from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_hist_001_ledger(driver):
    """Verify ledger records contain entries from executed transactions"""
    # Navigate to Ledger page via tab navigation
    ledger_nav = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Ledger')]"))
    )
    ledger_nav.click()

    # Wait for the Ledger transaction list rows to load
    # Symmetrical check: rows have BUY or SELL or amount/dates
    first_row = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'BUY') or contains(@text, 'SELL') or contains(@text, 'Deposit') or contains(@text, 'Withdraw')]"))
    )
    assert first_row.is_displayed()
