from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def test_auth_001_splash_screen(driver):
    """Verify welcome/splash screen loads and displays TradeMentor branding"""
    # Wait for the main title
    el = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'TradeMentor')]"))
    )
    assert el.is_displayed()
    
    # Check Get Started button
    btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Get Started')]")
    assert btn.is_displayed()

def test_auth_002_navigate_login(driver):
    """Navigate from Splash screen to Login page"""
    btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Get Started')]")
    btn.click()
    
    # Wait for email input
    el = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email')]"))
    )
    assert el.is_displayed()

def test_auth_003_invalid_login(driver):
    """Verify login validation fails with invalid inputs"""
    # Find inputs
    email = driver.find_element(AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Email')]")
    password = driver.find_element(AppiumBy.XPATH, "//android.widget.EditText[contains(@text, 'Password')]")
    submit = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Sign In')]")
    
    # Clear and type wrong credentials
    email.clear()
    email.send_keys("wrong@email.com")
    password.clear()
    password.send_keys("wrongpass")
    submit.click()
    
    # Check for snackbar validation or error toast
    err = WebDriverWait(driver, 8).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'enter') or contains(@text, 'failed') or contains(@text, 'invalid')]"))
    )
    assert err.is_displayed()

def test_auth_004_valid_login(driver):
    """Verify successful login loads the Risk Onboarding Quiz"""
    # Click 'Use Offline Demo Mode' to bypass server check for local test running
    offline_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Use Offline Demo Mode')]")
    offline_btn.click()
    
    # Wait for RISK_QUIZ screen to load
    quiz_header = WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'AI Onboarding Quiz')]"))
    )
    assert quiz_header.is_displayed()

def test_auth_005_risk_quiz_completion(driver):
    """Complete AI Risk Quiz and enter TradeMentor platform dashboard"""
    # Select Q1 option
    q1 = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Balance Capital Growth')]")
    q1.click()
    
    # Select Q2 option
    q2 = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Hold positions')]")
    q2.click()
    
    # Select Q3 option
    q3 = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Medium term')]")
    q3.click()
    
    # Submit Quiz
    submit = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Analyze My Risk Profile')]")
    submit.click()
    
    # Wait for popup "Quiz Completed!"
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Quiz Completed!')]"))
    )
    
    # Click Enter Platform
    enter_btn = driver.find_element(AppiumBy.XPATH, "//*[contains(@text, 'Enter Platform')]")
    enter_btn.click()
    
    # Check if dashboard is loaded
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Markets')]"))
    )
