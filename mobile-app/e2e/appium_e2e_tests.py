import time
import os
import unittest
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class TradeMentorMobileE2ETests(unittest.TestCase):
    driver = None

    def setUp(self):
        print("\n=== Setting up Appium Driver ===")
        options = UiAutomator2Options()
        options.platform_name = 'Android'
        options.automation_name = 'UiAutomator2'
        options.device_name = 'Android Emulator'
        
        # Package and activity configurations for TradeMentor Mobile App
        options.app_package = 'com.tradementor.tradementor_mobile'
        options.app_activity = '.MainActivity'
        options.no_reset = False
        options.new_command_timeout = 300
        
        # Check environment variables for custom Appium server configurations
        appium_server = os.environ.get("APPIUM_SERVER_URL", "http://localhost:4723")
        print(f"Connecting to Appium Server at: {appium_server}")
        
        try:
            self.driver = webdriver.Remote(appium_server, options=options)
            print("Successfully connected to Appium server and launched MainActivity.")
        except Exception as e:
            print(f"WARNING: Could not connect to Appium server or start emulator session: {e}")
            print("Make sure Appium server is running and an Android Emulator / Device is connected.")
            self.driver = None

    def tearDown(self):
        print("=== Tearing down Appium Driver ===")
        if self.driver:
            self.driver.quit()
            print("Appium driver session closed successfully.")

    def test_complete_e2e_mobile_flow(self):
        if not self.driver:
            print("Skipping E2E test suite: No active Appium driver session.")
            self.skipTest("Appium driver not initialized. Verify emulator and server states.")
            
        wait = WebDriverWait(self.driver, 20)
        
        print("\n[Step 1] Verifying Splash Onboarding & Clicking 'Get Started'")
        try:
            # Look for Get Started button using text and content-desc
            get_started_btn = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Get Started") or contains(@content-desc, "Get Started")]'
            )))
            get_started_btn.click()
            print("Successfully clicked 'Get Started' button.")
        except Exception as e:
            self.fail(f"Failed to navigate past Splash Screen: {e}")
            
        print("\n[Step 2] Authenticating via Login Screen")
        time.sleep(2)
        try:
            # Find the first email/username field and input demo credentials
            email_fields = self.driver.find_elements(AppiumBy.CLASS_NAME, 'android.widget.EditText')
            if len(email_fields) > 0:
                email_fields[0].send_keys("demo@tradementor.com")
                print("Entered demo email address.")
            else:
                raise Exception("No EditText fields found for username.")
                
            # Input password into second edit text field
            if len(email_fields) > 1:
                email_fields[1].send_keys("password123")
                print("Entered password.")
            else:
                # Fallback to xpath selection for password label field
                password_field = wait.until(EC.presence_of_element_located((
                    AppiumBy.XPATH, '//*[contains(@text, "Password")]'
                )))
                password_field.send_keys("password123")
                print("Entered password via fallback label.")
                
            # Locate and click the Sign In button
            sign_in_btn = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Sign In") or contains(@content-desc, "Sign In")]'
            )))
            sign_in_btn.click()
            print("Successfully clicked 'Sign In' button.")
        except Exception as e:
            self.fail(f"Failed during authentication page step: {e}")

        print("\n[Step 3] Navigating Risk Quiz Screen & Answering Questions")
        time.sleep(3)
        try:
            # Answer Q1 (Primary Goal)
            q1_opt = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Preserve Capital") or contains(@content-desc, "Preserve Capital")]'
            )))
            q1_opt.click()
            print("Selected Question 1 option.")
            
            # Answer Q2 (Reaction to Drop)
            q2_opt = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Hold positions") or contains(@content-desc, "Hold positions")]'
            )))
            q2_opt.click()
            print("Selected Question 2 option.")
            
            # Answer Q3 (Horizon)
            q3_opt = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Medium term") or contains(@content-desc, "Medium term")]'
            )))
            q3_opt.click()
            print("Selected Question 3 option.")
            
            # Click the submit quiz button
            submit_quiz = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Analyze My Risk Profile") or contains(@content-desc, "Analyze My Risk Profile")]'
            )))
            submit_quiz.click()
            print("Submitted risk quiz selections.")
            
            # Wait for Completed dialog and enter the platform
            enter_platform = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Enter Platform") or contains(@content-desc, "Enter Platform")]'
            )))
            enter_platform.click()
            print("Successfully finished onboarding and entered platform Dashboard.")
        except Exception as e:
            self.fail(f"Failed to complete Risk Quiz onboarding flow: {e}")

        print("\n[Step 4] Main Navigation & Tab Verifications")
        time.sleep(3)
        try:
            # Confirm landing on dashboard by looking for the logo header text
            header = wait.until(EC.presence_of_element_located((
                AppiumBy.XPATH, '//*[contains(@text, "TradeMentor") or contains(@content-desc, "TradeMentor")]'
            )))
            print("Dashboard header is verified.")
            
            # Navigate to Portfolio tab
            portfolio_tab = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Portfolio") or contains(@content-desc, "Portfolio")]'
            )))
            portfolio_tab.click()
            print("Successfully clicked Portfolio tab.")
            time.sleep(2)
            
            # Navigate to AI Mentor tab
            ai_tab = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "AI Mentor") or contains(@content-desc, "AI Mentor")]'
            )))
            ai_tab.click()
            print("Successfully clicked AI Mentor tab.")
            time.sleep(2)
            
            # Navigate back to Markets (Home) tab
            markets_tab = wait.until(EC.element_to_be_clickable((
                AppiumBy.XPATH, '//*[contains(@text, "Markets") or contains(@content-desc, "Markets")]'
            )))
            markets_tab.click()
            print("Successfully returned to Markets watchlist tab.")
            time.sleep(1)
            
        except Exception as e:
            self.fail(f"Failed during tab navigation verification: {e}")
            
        print("\n=== E2E Mobile Automation Completed Successfully ===")

if __name__ == '__main__':
    unittest.main()
