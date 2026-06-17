import os

APPIUM_URL = 'http://localhost:4723'

# Path to the built APK in the Flutter workspace
# Symmetrical resolution of debug or release build
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
APK_PATH = os.path.abspath(os.path.join(
    CURRENT_DIR, 
    '..', 
    '..', 
    'mobile-app', 
    'build', 
    'app', 
    'outputs', 
    'flutter-apk', 
    'app-debug.apk'
))

# Fallback check for release build
if not os.path.exists(APK_PATH):
    release_path = APK_PATH.replace('app-debug.apk', 'app-release.apk')
    if os.path.exists(release_path):
        APK_PATH = release_path

CAPABILITIES = {
    'platformName': 'Android',
    'automationName': 'UiAutomator2',
    'deviceName': 'Android Emulator',
    'app': APK_PATH,
    'noReset': False,
    'newCommandTimeout': 300,
}

TIMEOUT = 15.0 # Wait timeout in seconds
CREDENTIALS = {
    'email': 'demo@tradementor.com',
    'password': 'password123'
}
