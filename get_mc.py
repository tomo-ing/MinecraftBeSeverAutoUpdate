#----------------------------------------------------
#   Program name : get_mc.py
#   Date of program : 2025/6/18
#   Author : tomo-ing
#----------------------------------------------------

import time
import re
import sys # sysモジュールをインポート
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

def get_minecraft_bedrock_info():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")

    driver = None
    try:
        # Chromeドライバを自動インストール
        service = Service(ChromeDriverManager().install())
        
        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.get("https://minecraft.net/en-us/download/server/bedrock/")

        time.sleep(10) # ページが完全に読み込まれるまで待機

        download_link_element = driver.find_element(By.XPATH, "//a[contains(@href, 'bin-linux/bedrock-server') and contains(@href, '.zip')]")
        
        download_url = download_link_element.get_attribute("href")

        match = re.search(r'bedrock-server-(\d+\.\d+\.\d+\.\d+)\.zip', download_url)
        version = match.group(1) if match else "UNKNOWN_VERSION"

        # バージョンとURLをカンマ区切りで出力
        print(f"{version},{download_url}")
        return True # 成功を示す

    except Exception as e:
        # エラー発生時は標準エラー出力にメッセージを出し、空のバージョンとURLを出力
        print(f"ERROR: {e}", file=sys.stderr)
        print("UNKNOWN_VERSION,UNKNOWN_URL") # シェルが解析しやすいようにデフォルト値を出力
        return False # 失敗を示す
    finally:
        if driver:
            driver.quit()

if __name__ == "__main__":
    get_minecraft_bedrock_info()