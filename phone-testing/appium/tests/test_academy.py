from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_acad_001_tutorials(driver):
    """Verify academy modules cards and trigger study module loading"""
    # Navigate to Academy page
    academy_nav = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Academy')]"))
    )
    academy_nav.click()

    # Wait for Academy tabs (e.g. Academy Modules)
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Market Basics') or contains(@text, 'Study')]"))
    )

    # Click "Start Learning"
    start_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Start Learning')]")
    start_btn.click()

    # Check toast
    toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Initializing') or contains(@text, 'study')]"))
    )
    assert toast.is_displayed()

def test_acad_002_glossary(driver):
    """Verify Financial Dictionary glossary terms list"""
    # Click Financial Dictionary glossary subtab
    glossary_tab = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Financial Dictionary') or contains(@text, 'Dictionary')]"))
    )
    glossary_tab.click()

    # Verify a glossary term card displays (e.g. P/E Ratio)
    pe_term = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'P/E Ratio') or contains(@text, 'Stop Loss')]"))
    )
    assert pe_term.is_displayed()
