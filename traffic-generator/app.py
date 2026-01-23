from flask import Flask, render_template, jsonify, request
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import threading
import time
import random
import os
from datetime import datetime
import requests

app = Flask(__name__, static_folder='static', template_folder='static')

# Configuration
STORE_URL = os.getenv('STORE_SERVICE_URL', 'http://music-store-1-service:5000')
CART_URL = os.getenv('CART_SERVICE_URL', 'http://cart-service:5002')
ORDER_URL = os.getenv('ORDER_SERVICE_URL', 'http://order-service:5001')
USERS_URL = os.getenv('USERS_SERVICE_URL', 'http://users-service:5003')

# Global state
traffic_state = {
    'running': False,
    'active_sessions': 0,
    'total_journeys': 0,
    'total_page_loads': 0,
    'total_api_calls': 0,
    'success_count': 0,
    'failure_count': 0,
    'service_stats': {
        'store': {'calls': 0, 'errors': 0},
        'cart': {'calls': 0, 'errors': 0},
        'order': {'calls': 0, 'errors': 0},
        'users': {'calls': 0, 'errors': 0}
    },
    'recent_actions': [],
    'start_time': None,
    'config': {},
    'active_drivers': []  # Track active browser sessions for cleanup
}

def log_action(action, status='success'):
    """Log an action to recent activity"""
    traffic_state['recent_actions'].insert(0, {
        'action': action,
        'status': status,
        'timestamp': datetime.now().strftime('%H:%M:%S')
    })
    # Keep only last 20 actions
    traffic_state['recent_actions'] = traffic_state['recent_actions'][:20]

def create_driver(headless=True):
    """Create a Selenium WebDriver instance"""
    chrome_options = Options()
    if headless:
        chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    
    driver = webdriver.Chrome(options=chrome_options)
    driver.set_page_load_timeout(30)
    return driver

def browse_journey(driver, user_id, base_url):
    """Simulate a user browsing the store"""
    try:
        log_action(f'User {user_id}: Starting browse journey')
        
        # Visit store homepage
        driver.get(base_url)
        traffic_state['total_page_loads'] += 1
        traffic_state['service_stats']['store']['calls'] += 1
        time.sleep(random.uniform(1, 3))
        log_action(f'User {user_id}: Loaded store homepage')
        
        # Click on Shop tab if available
        try:
            shop_tab = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Shop')]"))
            )
            shop_tab.click()
            time.sleep(random.uniform(1, 2))
            log_action(f'User {user_id}: Viewing shop')
        except TimeoutException:
            pass
        
        # Browse albums (scroll and view)
        for _ in range(random.randint(2, 5)):
            driver.execute_script("window.scrollBy(0, 300)")
            time.sleep(random.uniform(0.5, 1.5))
        
        traffic_state['success_count'] += 1
        log_action(f'User {user_id}: Completed browse journey', 'success')
        return True
        
    except Exception as e:
        traffic_state['failure_count'] += 1
        traffic_state['service_stats']['store']['errors'] += 1
        log_action(f'User {user_id}: Browse journey failed - {str(e)}', 'error')
        return False

def shopping_journey(driver, user_id, base_url):
    """Simulate a complete shopping journey"""
    try:
        log_action(f'User {user_id}: Starting shopping journey')
        
        # Visit store
        driver.get(base_url)
        traffic_state['total_page_loads'] += 1
        traffic_state['service_stats']['store']['calls'] += 1
        time.sleep(random.uniform(1, 2))
        
        # Go to shop tab
        try:
            shop_tab = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Shop')]"))
            )
            shop_tab.click()
            time.sleep(random.uniform(1, 2))
        except TimeoutException:
            pass
        
        # Add items to cart (look for "Add to Cart" buttons)
        try:
            add_buttons = driver.find_elements(By.XPATH, "//button[contains(text(), 'Add to Cart')]")
            if add_buttons:
                num_items = min(random.randint(1, 3), len(add_buttons))
                for i in range(num_items):
                    add_buttons[i].click()
                    traffic_state['service_stats']['cart']['calls'] += 1
                    time.sleep(random.uniform(0.5, 1))
                    log_action(f'User {user_id}: Added item {i+1} to cart')
        except Exception as e:
            log_action(f'User {user_id}: Could not add items - {str(e)}', 'warning')
        
        # View cart
        try:
            cart_link = driver.find_element(By.XPATH, "//a[contains(@href, 'cart') or contains(text(), 'Cart')]")
            cart_link.click()
            traffic_state['total_page_loads'] += 1
            traffic_state['service_stats']['cart']['calls'] += 1
            time.sleep(random.uniform(1, 2))
            log_action(f'User {user_id}: Viewing cart')
        except NoSuchElementException:
            pass
        
        # Proceed to checkout
        try:
            checkout_btn = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Checkout')] | //a[contains(text(), 'Checkout')]"))
            )
            checkout_btn.click()
            traffic_state['total_page_loads'] += 1
            traffic_state['service_stats']['cart']['calls'] += 1
            time.sleep(random.uniform(1, 2))
            log_action(f'User {user_id}: At checkout')
            
            # Fill payment form
            try:
                card_number = driver.find_element(By.ID, "cardNumber")
                card_number.send_keys("4532123456789012")
                
                expiry = driver.find_element(By.ID, "expiryDate")
                expiry.send_keys("12/25")
                
                cvv = driver.find_element(By.ID, "cvv")
                cvv.send_keys("123")
                
                time.sleep(random.uniform(0.5, 1))
                
                # Submit payment
                submit_btn = driver.find_element(By.XPATH, "//button[contains(text(), 'Pay')]")
                submit_btn.click()
                traffic_state['service_stats']['order']['calls'] += 1
                time.sleep(random.uniform(2, 3))
                log_action(f'User {user_id}: Completed purchase')
                
            except NoSuchElementException:
                log_action(f'User {user_id}: Payment form not found', 'warning')
                
        except TimeoutException:
            log_action(f'User {user_id}: Checkout button not found', 'warning')
        
        traffic_state['success_count'] += 1
        log_action(f'User {user_id}: Completed shopping journey', 'success')
        return True
        
    except Exception as e:
        traffic_state['failure_count'] += 1
        log_action(f'User {user_id}: Shopping journey failed - {str(e)}', 'error')
        return False

def order_journey(driver, user_id, base_url):
    """View order dashboard"""
    try:
        log_action(f'User {user_id}: Checking orders')
        
        # Try to navigate to orders from the base URL
        driver.get(base_url)
        traffic_state['total_page_loads'] += 1
        traffic_state['service_stats']['order']['calls'] += 1
        time.sleep(random.uniform(2, 3))
        
        # Scroll through orders
        driver.execute_script("window.scrollBy(0, 500)")
        time.sleep(random.uniform(1, 2))
        
        traffic_state['success_count'] += 1
        log_action(f'User {user_id}: Viewed orders', 'success')
        return True
        
    except Exception as e:
        traffic_state['failure_count'] += 1
        traffic_state['service_stats']['order']['errors'] += 1
        log_action(f'User {user_id}: Order journey failed - {str(e)}', 'error')
        return False

def admin_journey(driver, user_id, base_url):
    """Simulate admin actions"""
    try:
        log_action(f'User {user_id}: Admin actions')
        
        driver.get(base_url)
        traffic_state['total_page_loads'] += 1
        traffic_state['service_stats']['store']['calls'] += 1
        time.sleep(random.uniform(1, 2))
        
        # Click Admin tab
        try:
            admin_tab = WebDriverWait(driver, 5).until(
                EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Admin')]"))
            )
            admin_tab.click()
            time.sleep(random.uniform(1, 2))
            log_action(f'User {user_id}: Viewing admin panel')
        except TimeoutException:
            pass
        
        # View statistics tab
        try:
            stats_tab = driver.find_element(By.XPATH, "//button[contains(text(), 'Statistics')]")
            stats_tab.click()
            time.sleep(random.uniform(1, 2))
            log_action(f'User {user_id}: Viewing statistics')
        except NoSuchElementException:
            pass
        
        traffic_state['success_count'] += 1
        log_action(f'User {user_id}: Completed admin journey', 'success')
        return True
        
    except Exception as e:
        traffic_state['failure_count'] += 1
        log_action(f'User {user_id}: Admin journey failed - {str(e)}', 'error')
        return False

def user_session(user_id, config):
    """Run a single user session"""
    driver = None
    try:
        traffic_state['active_sessions'] += 1
        driver = create_driver(headless=config.get('headless', True))
        
        # Track this driver for cleanup
        traffic_state['active_drivers'].append(driver)
        
        # Get base URL from config
        base_url = config.get('base_url', STORE_URL)
        
        # Determine journey mix
        journey_weights = config.get('journey_mix', {
            'browse': 30,
            'shopping': 40,
            'order': 20,
            'admin': 10
        })
        
        journeys = []
        for journey, weight in journey_weights.items():
            journeys.extend([journey] * weight)
        
        # Run journeys based on duration
        end_time = time.time() + (config.get('duration', 5) * 60)
        
        while time.time() < end_time and traffic_state['running']:
            journey_type = random.choice(journeys)
            
            if journey_type == 'browse':
                browse_journey(driver, user_id, base_url)
            elif journey_type == 'shopping':
                shopping_journey(driver, user_id, base_url)
            elif journey_type == 'order':
                order_journey(driver, user_id, base_url)
            elif journey_type == 'admin':
                admin_journey(driver, user_id, base_url)
            
            traffic_state['total_journeys'] += 1
            
            # Check if we should stop
            if not traffic_state['running']:
                log_action(f'User {user_id}: Stopping due to stop signal')
                break
            
            # Wait between journeys based on intensity
            intensity = config.get('intensity', 'medium')
            wait_times = {
                'low': (10, 20),
                'medium': (5, 10),
                'high': (2, 5),
                'extreme': (0.5, 2)
            }
            wait_range = wait_times.get(intensity, (5, 10))
            time.sleep(random.uniform(*wait_range))
        
        log_action(f'User {user_id}: Session completed')
        
    except Exception as e:
        log_action(f'User {user_id}: Session error - {str(e)}', 'error')
    finally:
        if driver:
            try:
                driver.quit()
                if driver in traffic_state['active_drivers']:
                    traffic_state['active_drivers'].remove(driver)
            except:
                pass
        traffic_state['active_sessions'] -= 1

def run_traffic(config):
    """Main traffic generation function"""
    traffic_state['running'] = True
    traffic_state['start_time'] = time.time()
    traffic_state['config'] = config
    
    num_users = config.get('concurrent_users', 5)
    
    threads = []
    for i in range(num_users):
        thread = threading.Thread(target=user_session, args=(i+1, config))
        thread.daemon = True
        thread.start()
        threads.append(thread)
        time.sleep(random.uniform(0.5, 2))  # Stagger user starts
    
    # Wait for all threads to complete
    for thread in threads:
        thread.join()
    
    traffic_state['running'] = False

@app.route('/')
def index():
    """Serve the main UI"""
    return render_template('index.html')

@app.route('/api/start', methods=['POST'])
def start_traffic():
    """Start traffic generation"""
    if traffic_state['running']:
        return jsonify({'error': 'Traffic already running'}), 400
    
    config = request.json
    
    # Reset stats
    traffic_state['total_journeys'] = 0
    traffic_state['total_page_loads'] = 0
    traffic_state['total_api_calls'] = 0
    traffic_state['success_count'] = 0
    traffic_state['failure_count'] = 0
    traffic_state['recent_actions'] = []
    for service in traffic_state['service_stats']:
        traffic_state['service_stats'][service] = {'calls': 0, 'errors': 0}
    
    # Start traffic in background thread
    thread = threading.Thread(target=run_traffic, args=(config,))
    thread.daemon = True
    thread.start()
    
    return jsonify({'status': 'started'})

@app.route('/api/stop', methods=['POST'])
def stop_traffic():
    """Stop traffic generation"""
    traffic_state['running'] = False
    log_action('Stop signal sent to all sessions')
    
    # Force quit all active drivers
    drivers_to_quit = list(traffic_state['active_drivers'])
    for driver in drivers_to_quit:
        try:
            driver.quit()
        except:
            pass
    
    traffic_state['active_drivers'] = []
    log_action(f'Stopped {len(drivers_to_quit)} browser sessions')
    
    return jsonify({'status': 'stopped'})

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get current statistics"""
    runtime = 0
    if traffic_state['start_time']:
        runtime = int(time.time() - traffic_state['start_time'])
    
    return jsonify({
        'running': traffic_state['running'],
        'active_sessions': traffic_state['active_sessions'],
        'total_journeys': traffic_state['total_journeys'],
        'total_page_loads': traffic_state['total_page_loads'],
        'success_count': traffic_state['success_count'],
        'failure_count': traffic_state['failure_count'],
        'service_stats': traffic_state['service_stats'],
        'recent_actions': traffic_state['recent_actions'],
        'runtime': runtime
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=False)
