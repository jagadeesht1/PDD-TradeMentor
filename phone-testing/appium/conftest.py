import os
import json
import time
from datetime import datetime
import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options
import config
import generate_mobile_report

# Global list to hold results during test execution
_test_results = []
_start_time = None

@pytest.fixture(scope="session")
def driver():
    global _start_time
    _start_time = datetime.now()
    
    print("\nInitializing Appium Android Driver...")
    options = UiAutomator2Options()
    for key, value in config.CAPABILITIES.items():
        options.set_capability(key, value)
        
    try:
        # Build driver connection
        driver_instance = webdriver.Remote(config.APPIUM_URL, options=options)
        print("Driver connected successfully!")
        yield driver_instance
    except Exception as e:
        print(f"Failed to connect to Appium Server or start emulator: {e}")
        raise e
    finally:
        print("Quitting Appium driver session...")
        try:
            driver_instance.quit()
        except:
            pass

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    # Execute all other hooks to obtain the report object
    outcome = yield
    rep = outcome.get_result()
    
    # We only record results on the 'call' phase (the actual test execution)
    if rep.when == "call":
        # Get category from file name
        file_name = os.path.basename(item.fspath)
        category = "General"
        if "auth" in file_name:
            category = "Authentication"
        elif "market" in file_name:
            category = "Markets"
        elif "port" in file_name:
            category = "Portfolio"
        elif "alert" in file_name:
            category = "Alerts"
        elif "advisor" in file_name:
            category = "AI Advisor"
        elif "history" in file_name:
            category = "Ledger"
        elif "academy" in file_name:
            category = "Academy"
            
        # Parse ID from function name (e.g., test_auth_001_splash -> TM-AUTH-001)
        func_name = item.name
        test_id = "TM-MOB-000"
        parts = func_name.split('_')
        if len(parts) >= 3:
            mod_prefix = parts[1][:4].upper()
            num = parts[2]
            if num.isdigit():
                test_id = f"TM-{mod_prefix}-{num}"
                
        # Description is the docstring of the test function
        description = item.obj.__doc__ or f"Execute {item.name}"
        description = description.strip().split('\n')[0]
        
        status = "PASS" if rep.passed else "FAIL"
        duration_ms = int(rep.duration * 1000)
        error_msg = None
        screenshot_name = None
        
        if rep.failed:
            error_msg = str(rep.longrepr.reprcrash.message if rep.longrepr and hasattr(rep.longrepr, 'reprcrash') else rep.longrepr)
            
            # Take screenshot if driver is active in the session
            # Get driver from item's fixtures
            if "driver" in item.funcargs:
                driver_instance = item.funcargs["driver"]
                try:
                    screenshots_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "screenshots"))
                    if not os.path.exists(screenshots_dir):
                        os.makedirs(screenshots_dir, exist_ok=True)
                        
                    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
                    screenshot_name = f"{test_id}-{timestamp}.png"
                    screenshot_path = os.path.join(screenshots_dir, screenshot_name)
                    driver_instance.save_screenshot(screenshot_path)
                    print(f"  [SCREENSHOT] Saved failure state to {screenshot_path}")
                except Exception as ex:
                    print(f"  [ERROR] Failed to save failure screenshot: {ex}")
                    
        _test_results.append({
            "id": test_id,
            "category": category,
            "description": description,
            "status": status,
            "duration_ms": duration_ms,
            "error": error_msg,
            "screenshot": screenshot_name
        })

def pytest_sessionfinish(session, exitstatus):
    # Executed at the end of all test runs
    end_time = datetime.now()
    total_duration_ms = int((end_time - _start_time).total_seconds() * 1000) if _start_time else 0
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    reports_dir = os.path.join(base_dir, "reports")
    if not os.path.exists(reports_dir):
        os.makedirs(reports_dir, exist_ok=True)
        
    results_json_path = os.path.join(reports_dir, "test_results.json")
    report_xlsx_path = os.path.join(reports_dir, f"appium_test_report_{datetime.now().strftime('%Y%m%d-%H%M%S')}.xlsx")
    
    report_data = {
        "start_time": _start_time.isoformat() if _start_time else datetime.now().isoformat(),
        "end_time": end_time.isoformat(),
        "total_duration_ms": total_duration_ms,
        "appium_url": config.APPIUM_URL,
        "platform": "Android",
        "results": _test_results
    }
    
    # Save raw json results
    with open(results_json_path, 'w') as f:
        json.dump(report_data, f, indent=2)
    print(f"\nSaved raw test results to {results_json_path}")
    
    # Generate styled Excel workbook
    generate_mobile_report.generate_report(results_json_path, report_xlsx_path)
