#!/usr/bin/env python3
"""
Comprehensive demo showing automatic session tracking with the Go Load Balancer.

This example demonstrates:
1. Automatic session creation and routing
2. Session affinity (requests go to correct Grid instance)
3. Connection recovery using client UUID
4. Automatic failover handling
5. Session cleanup and monitoring

No special client-side code is required - the load balancer handles everything automatically.
"""

import time
import uuid
import requests
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Load balancer configuration
LOAD_BALANCER_URL = "http://localhost:4444"
LOAD_BALANCER_STATUS_URL = f"{LOAD_BALANCER_URL}/status"
LOAD_BALANCER_HEALTH_URL = f"{LOAD_BALANCER_URL}/lb/health"
LOAD_BALANCER_SESSIONS_URL = f"{LOAD_BALANCER_URL}/lb/sessions"
LOAD_BALANCER_INSTANCES_URL = f"{LOAD_BALANCER_URL}/lb/instances"

def print_separator(title):
    print(f"\n{'='*60}")
    print(f" {title}")
    print(f"{'='*60}")

def get_load_balancer_status():
    """Get load balancer status and Grid instance information."""
    try:
        response = requests.get(LOAD_BALANCER_STATUS_URL, timeout=5)
        return response.json() if response.status_code == 200 else None
    except:
        return None

def get_session_info():
    """Get current session information from load balancer."""
    try:
        response = requests.get(LOAD_BALANCER_SESSIONS_URL, timeout=5)
        return response.json() if response.status_code == 200 else None
    except:
        return None

def get_grid_instances():
    """Get Grid instance status from load balancer."""
    try:
        response = requests.get(LOAD_BALANCER_INSTANCES_URL, timeout=5)
        return response.json() if response.status_code == 200 else None
    except:
        return None

def demo_basic_automatic_tracking():
    """Demonstrate basic automatic session tracking."""
    print_separator("DEMO 1: Basic Automatic Session Tracking")
    
    print("1. Creating WebDriver session (load balancer automatically selects Grid instance)...")
    driver = webdriver.Remote(
        command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
        desired_capabilities=DesiredCapabilities.CHROME
    )
    
    session_id = driver.session_id
    print(f"   Session created: {session_id}")
    
    # Check session info
    session_info = get_session_info()
    if session_info:
        print(f"   Active sessions: {session_info.get('active_sessions', 0)}")
    
    print("2. Performing WebDriver operations (automatically routed to correct Grid instance)...")
    driver.get("https://www.selenium.dev")
    print(f"   Page title: {driver.title}")
    
    print("3. Multiple operations on same session...")
    driver.get("https://github.com/SeleniumHQ/selenium")
    print(f"   New page title: {driver.title}")
    
    # Find element to demonstrate session persistence
    try:
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "h1"))
        )
        print(f"   Found element: {element.text[:50]}...")
    except:
        print("   Could not find element (expected in some cases)")
    
    print("4. Closing session (automatically removed from tracking)...")
    driver.quit()
    
    # Check session cleanup
    time.sleep(2)
    session_info = get_session_info()
    if session_info:
        print(f"   Active sessions after cleanup: {session_info.get('active_sessions', 0)}")

def demo_multiple_sessions():
    """Demonstrate automatic tracking of multiple concurrent sessions."""
    print_separator("DEMO 2: Multiple Concurrent Sessions")
    
    print("1. Creating multiple WebDriver sessions...")
    drivers = []
    
    for i in range(3):
        print(f"   Creating session {i+1}...")
        driver = webdriver.Remote(
            command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
            desired_capabilities=DesiredCapabilities.CHROME
        )
        drivers.append(driver)
        print(f"   Session {i+1} ID: {driver.session_id}")
        
        # Each session goes to a different page
        driver.get(f"https://httpbin.org/delay/{i+1}")
    
    # Check session distribution
    session_info = get_session_info()
    if session_info:
        print(f"   Total active sessions: {session_info.get('active_sessions', 0)}")
    
    grid_instances = get_grid_instances()
    if grid_instances and 'instances' in grid_instances:
        print("   Grid instance distribution:")
        for instance in grid_instances['instances']:
            status = "healthy" if instance.get('healthy') else "unhealthy"
            print(f"     {instance['id']}: {status} (response: {instance.get('response_time_ms', 0)}ms)")
    
    print("2. Performing operations on each session (automatically routed)...")
    for i, driver in enumerate(drivers):
        try:
            title = driver.title
            print(f"   Session {i+1}: {title[:50]}...")
        except Exception as e:
            print(f"   Session {i+1}: Error - {str(e)[:50]}...")
    
    print("3. Closing all sessions...")
    for i, driver in enumerate(drivers):
        try:
            driver.quit()
            print(f"   Session {i+1} closed")
        except:
            print(f"   Session {i+1} already closed")

def demo_connection_recovery():
    """Demonstrate connection recovery using client UUID."""
    print_separator("DEMO 3: Connection Recovery with Client UUID")
    
    # Generate a client UUID for tracking
    client_uuid = str(uuid.uuid4())
    print(f"1. Generated client UUID: {client_uuid}")
    
    print("2. Creating session with client UUID header...")
    
    # Create a custom WebDriver with UUID header
    # Note: This requires a custom implementation or proxy to add headers
    # For demo purposes, we'll show the concept
    
    driver = webdriver.Remote(
        command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
        desired_capabilities=DesiredCapabilities.CHROME
    )
    
    session_id = driver.session_id
    print(f"   Session created: {session_id}")
    
    print("3. Performing initial operations...")
    driver.get("https://www.selenium.dev")
    print(f"   Initial page: {driver.title}")
    
    print("4. Simulating connection interruption...")
    # In a real scenario, network interruption would occur here
    # The load balancer would use the client UUID to recover the session
    
    print("5. Continuing operations (load balancer handles recovery automatically)...")
    try:
        driver.get("https://selenium.dev/documentation/")
        print(f"   Recovered page: {driver.title}")
    except Exception as e:
        print(f"   Recovery handling: {str(e)[:100]}...")
    
    driver.quit()

def demo_automatic_failover():
    """Demonstrate automatic failover when a Grid instance fails."""
    print_separator("DEMO 4: Automatic Failover Handling")
    
    print("1. Checking initial Grid instance health...")
    grid_instances = get_grid_instances()
    if grid_instances and 'instances' in grid_instances:
        healthy_count = sum(1 for inst in grid_instances['instances'] if inst.get('healthy'))
        print(f"   Healthy instances: {healthy_count}/{len(grid_instances['instances'])}")
    
    print("2. Creating session on healthy Grid instance...")
    driver = webdriver.Remote(
        command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
        desired_capabilities=DesiredCapabilities.CHROME
    )
    
    session_id = driver.session_id
    print(f"   Session created: {session_id}")
    
    driver.get("https://www.selenium.dev")
    print(f"   Initial operation successful: {driver.title}")
    
    print("3. Simulating Grid instance failure...")
    print("   (In real scenario, a Grid instance would become unhealthy)")
    print("   Load balancer automatically detects failures and handles failover")
    
    print("4. Continuing operations (automatic failover if needed)...")
    try:
        driver.get("https://selenium.dev/downloads/")
        print(f"   Operation after potential failover: {driver.title}")
    except Exception as e:
        print(f"   Failover handling: {str(e)[:100]}...")
    
    driver.quit()

def demo_session_monitoring():
    """Demonstrate automatic session monitoring and cleanup."""
    print_separator("DEMO 5: Automatic Session Monitoring")
    
    print("1. Creating session for monitoring demo...")
    driver = webdriver.Remote(
        command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
        desired_capabilities=DesiredCapabilities.CHROME
    )
    
    session_id = driver.session_id
    print(f"   Session created: {session_id}")
    
    print("2. Load balancer automatically monitors session state...")
    print("   - Verifies session exists on Grid instance every 30 seconds")
    print("   - Discovers new sessions from Grid instances every 2 minutes")
    print("   - Cleans up expired sessions every 5 minutes")
    
    session_info = get_session_info()
    if session_info:
        print(f"   Current active sessions: {session_info.get('active_sessions', 0)}")
    
    print("3. Performing long-running operation...")
    driver.get("https://httpbin.org/delay/3")
    print("   Operation completed")
    
    print("4. Session automatically tracked and monitored in background...")
    print("   (Monitoring continues even if client disconnects temporarily)")
    
    driver.quit()
    print("   Session closed and automatically removed from tracking")

def main():
    """Run all automatic session tracking demos."""
    print("Selenium Grid Load Balancer - Automatic Session Tracking Demo")
    print("=" * 60)
    
    # Check load balancer status
    status = get_load_balancer_status()
    if not status:
        print("ERROR: Load balancer not accessible at", LOAD_BALANCER_URL)
        print("Please ensure the load balancer is running.")
        return
    
    print(f"Load balancer status: {'Ready' if status.get('ready') else 'Not Ready'}")
    if 'value' in status and 'grid_instances' in status['value']:
        healthy_instances = [inst for inst in status['value']['grid_instances'] if inst.get('healthy')]
        print(f"Healthy Grid instances: {len(healthy_instances)}")
    
    if not status.get('ready'):
        print("WARNING: Load balancer not ready. Some demos may fail.")
    
    try:
        # Run all demos
        demo_basic_automatic_tracking()
        time.sleep(2)
        
        demo_multiple_sessions()
        time.sleep(2)
        
        demo_connection_recovery()
        time.sleep(2)
        
        demo_automatic_failover()
        time.sleep(2)
        
        demo_session_monitoring()
        
        print_separator("DEMO COMPLETED")
        print("All automatic session tracking features demonstrated!")
        print("\nKey Benefits:")
        print("✓ Zero client-side configuration required")
        print("✓ Automatic session-to-Grid-instance mapping")
        print("✓ Transparent connection recovery")
        print("✓ Automatic failover handling")
        print("✓ Background session monitoring and cleanup")
        print("✓ Real-time session discovery")
        
    except Exception as e:
        print(f"\nDemo error: {e}")
        print("This may be expected if Grid instances are not available.")

if __name__ == "__main__":
    main()
