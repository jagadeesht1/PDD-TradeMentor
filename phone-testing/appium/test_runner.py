import os
import sys
import pytest

def main():
    print("Starting E2E Appium Mobile Test Suite for TradeMentor...\n")
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    tests_dir = os.path.join(current_dir, "tests")
    
    # Ensure screenshots and reports folder exists
    base_dir = os.path.dirname(current_dir)
    os.makedirs(os.path.join(base_dir, "screenshots"), exist_ok=True)
    os.makedirs(os.path.join(base_dir, "reports"), exist_ok=True)
    
    # Execute pytest programmatically on the test modules
    exit_code = pytest.main(["-v", "-s", tests_dir])
    
    print(f"\nMobile test suite execution completed with exit code: {exit_code}")
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
