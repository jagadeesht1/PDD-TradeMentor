from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_advi_001_chat_and_preset(driver):
    """Submit question to AI Chatbot and verify response generation"""
    # Navigate to AI Advisor page
    advisor_nav = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'AI Advisor')]"))
    )
    advisor_nav.click()

    # Wait for chatbot to load
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'TradeMentor AI') or contains(@text, 'AI Advisor')]"))
    )

    # Click a preset command shortcut (e.g. 'Run Market Scanner')
    preset_btn = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Run Market Scanner')]"))
    )
    preset_btn.click()

    # Wait for bot text response to appear (non-empty last message)
    time.sleep(2) # brief pause
    last_msg = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "(//*[contains(@text, 'bullish') or contains(@text, 'PE') or contains(@text, 'rsi') or contains(@text, 'scanner') or contains(@text, 'suggest')])[last()]"))
    )
    assert last_msg.is_displayed()

def test_advi_002_retake_quiz(driver):
    """Verify Retake AI Risk Quiz popup modal dialog"""
    # Click Retake AI Risk Quiz
    retake_btn = WebDriverWait(driver, 15).until(
        EC.element_to_be_clickable((AppiumBy.XPATH, "//*[contains(@text, 'Retake AI Risk Quiz')]"))
    )
    retake_btn.click()

    # Dialog popup opens
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'AI Risk Profile Quiz') or contains(@text, 'Risk Tolerance')]"))
    )

    # Click Moderate/Balanced
    balanced_opt = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Balanced Growth') or contains(@text, 'moderate')]")
    balanced_opt.click()

    # Success toast
    toast = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'MODERATE') or contains(@text, 'success') or contains(@text, 'profile')]"))
    )
    assert toast.is_displayed()
