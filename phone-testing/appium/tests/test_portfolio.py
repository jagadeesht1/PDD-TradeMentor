from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_port_001_holdings_and_sell(driver):
    """Verify holdings table details and simulate selling shares"""
    # Navigate to Portfolio page via tab navigation
    # Bottom navigation tabs: Markets, Portfolio, My Rules, AI Advisor, Ledger, Academy
    portfolio_nav = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Portfolio')]"))
    )
    portfolio_nav.click()

    # Wait for Holdings list to display
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Total Invested') or contains(@text, 'Open Positions')]"))
    )

    # Click Sell button on holding if any exists (since we bought in previous test)
    sell_btn = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "(//*[contains(@text, 'Sell')])[1]"))
    )
    sell_btn.click()

    # Order ticket modal opens, type qty and click Confirm
    qty_input = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//android.widget.EditText"))
    )
    qty_input.clear()
    qty_input.send_keys("5")

    confirm_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'CONFIRM SELL ORDER')]")
    confirm_btn.click()

    # Success toast should show
    toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'executed successfully') or contains(@text, 'trade')]"))
    )
    assert toast.is_displayed()

def test_port_002_wallet_flow(driver):
    """Verify Wallet Manager Deposit and Withdrawal flow"""
    # Tap on 'Wallet Manager' subtab
    wallet_tab = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Wallet Manager')]"))
    )
    wallet_tab.click()

    # Verify Deposit header displays
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Deposit Simulated Capital') or contains(@text, 'Confirm UPI')]"))
    )

    # Perform Deposit
    # Quantity inputs are text edits, let's find the first one or by placeholder/label
    deposit_input = driver.find_element(AppiumBy.XPATH, "(//android.widget.EditText)[1]")
    deposit_input.clear()
    deposit_input.send_keys("15000")

    deposit_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Confirm UPI Deposit')]")
    deposit_btn.click()

    # Check success toast
    toast1 = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'credited') or contains(@text, 'wallet')]"))
    )
    assert toast1.is_displayed()

    # Perform Withdrawal
    withdraw_input = driver.find_element(AppiumBy.XPATH, "(//android.widget.EditText)[2]")
    withdraw_input.clear()
    withdraw_input.send_keys("5000")

    withdraw_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Confirm Bank Withdrawal')]")
    withdraw_btn.click()

    # Check success toast
    toast2 = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'withdrew') or contains(@text, 'wallet')]"))
    )
    assert toast2.is_displayed()

def test_port_003_capital_gains_tax(driver):
    """Verify Capital Gains Tax summary card outputs"""
    tax_tab = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Capital Gains Tax')]"))
    )
    tax_tab.click()

    tax_header = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Gains Tax Breakdown')]"))
    )
    assert tax_header.is_displayed()
