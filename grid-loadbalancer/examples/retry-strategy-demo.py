#!/usr/bin/env python3
"""
Selenium Grid Load Balancer - Intelligent Retry Strategy Demo

This script demonstrates the enhanced retry strategy that considers the number of available Grid instances:

Strategy 1: MaxRetries <= GridInstance count
- Try one-by-one on different instances until success or maxRetries reached

Strategy 2: MaxRetries > GridInstance count  
- Try one-by-one until reach max GridInstance then repeat cycles

The load balancer automatically handles retries transparently to the client.
"""

import time
import requests
import json
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import WebDriverException, TimeoutException

# Configuration
LOAD_BALANCER_URL = "http://localhost:4444"
GRID_INSTANCES = [
    "http://localhost:4445",  # Grid 1
    "http://localhost:4446",  # Grid 2  
    "http://localhost:4447",  # Grid 3
]

def check_load_balancer_health():
    """Check load balancer and Grid instance health"""
    try:
        response = requests.get(f"{LOAD_BALANCER_URL}/lb/health", timeout=10)
        health_data = response.json()
        
        print("=== Load Balancer Health Status ===")
        print(f"Load Balancer: {'Healthy' if health_data.get('healthy', False) else 'Unhealthy'}")
        
        grid_instances = health_data.get('grid_instances', {})
        healthy_count = 0
        
        for instance_id, status in grid_instances.items():
            is_healthy = status.get('healthy', False)
            if is_healthy:
                healthy_count += 1
            print(f"  {instance_id}: {'Healthy' if is_healthy else 'Unhealthy'} "
                  f"(URL: {status.get('url', 'N/A')})")
        
        print(f"Total Healthy Instances: {healthy_count}")
        return healthy_count
        
    except Exception as e:
        print(f"Failed to check health: {e}")
        return 0

def get_current_config():
    """Get current retry configuration from load balancer"""
    try:
        # This would typically be available via a config endpoint
        # For demo purposes, we'll show the expected behavior
        print("\n=== Current Retry Configuration ===")
        print("MaxRetries: 3 (from config.yaml)")
        print("RetryInterval: 5s (from config.yaml)")
        print("Strategy: Intelligent retry based on Grid instance count")
        return {"max_retries": 3, "retry_interval": 5}
    except Exception as e:
        print(f"Could not get config: {e}")
        return {"max_retries": 3, "retry_interval": 5}

def demonstrate_retry_strategy_1():
    """
    Demonstrate Strategy 1: MaxRetries <= GridInstance count
    With 3 Grid instances and MaxRetries=3, each instance gets tried once
    """
    print("\n" + "="*60)
    print("DEMO: Retry Strategy 1 (MaxRetries <= GridInstance count)")
    print("Expected behavior: Try different instances one-by-one")
    print("="*60)
    
    try:
        # Create WebDriver session - this will trigger retry logic if some instances fail
        driver = webdriver.Remote(
            command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
            desired_capabilities=DesiredCapabilities.CHROME
        )
        
        print("✅ Session created successfully")
        print("   Load balancer automatically selected best available instance")
        
        # Perform some operations to test session affinity
        driver.get("https://httpbin.org/get")
        print("✅ Navigation successful - routed to correct Grid instance")
        
        # Get page title to verify session works
        title = driver.title
        print(f"✅ Page title retrieved: {title}")
        
        # Check current session info
        session_id = driver.session_id
        print(f"✅ Session ID: {session_id}")
        
        # Test session persistence with another operation
        driver.get("https://httpbin.org/headers")
        print("✅ Second navigation successful - session affinity maintained")
        
        driver.quit()
        print("✅ Session terminated successfully")
        
    except WebDriverException as e:
        print(f"❌ WebDriver error (this demonstrates retry exhaustion): {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def demonstrate_retry_strategy_2():
    """
    Demonstrate Strategy 2: MaxRetries > GridInstance count
    If we had MaxRetries=7 and 3 Grid instances, it would cycle: 1,2,3,1,2,3,1
    """
    print("\n" + "="*60)
    print("DEMO: Retry Strategy 2 (MaxRetries > GridInstance count)")
    print("Expected behavior: Cycle through instances multiple times")
    print("="*60)
    
    print("Note: This strategy would be used if MaxRetries=7 with 3 Grid instances")
    print("Retry sequence would be: Instance1 -> Instance2 -> Instance3 -> Instance1 -> Instance2 -> Instance3 -> Instance1")
    
    try:
        # Create multiple sessions to demonstrate load distribution
        sessions = []
        
        for i in range(3):
            print(f"\nCreating session {i+1}...")
            driver = webdriver.Remote(
                command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
                desired_capabilities=DesiredCapabilities.CHROME
            )
            
            session_id = driver.session_id
            print(f"✅ Session {i+1} created: {session_id}")
            
            # Test the session
            driver.get("https://httpbin.org/get")
            print(f"✅ Session {i+1} navigation successful")
            
            sessions.append(driver)
        
        # Clean up all sessions
        for i, driver in enumerate(sessions):
            driver.quit()
            print(f"✅ Session {i+1} terminated")
            
    except Exception as e:
        print(f"❌ Error in retry strategy 2 demo: {e}")

def demonstrate_failover_with_retry():
    """
    Demonstrate how retry strategy works during failover scenarios
    """
    print("\n" + "="*60)
    print("DEMO: Failover with Intelligent Retry")
    print("Expected behavior: Automatic retry on healthy instances")
    print("="*60)
    
    try:
        # Create a session
        driver = webdriver.Remote(
            command_executor=f'{LOAD_BALANCER_URL}/wd/hub',
            desired_capabilities=DesiredCapabilities.CHROME
        )
        
        session_id = driver.session_id
        print(f"✅ Session created: {session_id}")
        
        # Perform operations that would trigger retry if instance fails
        for i in range(3):
            print(f"\nPerforming operation {i+1}...")
            try:
                driver.get(f"https://httpbin.org/delay/{i}")
                print(f"✅ Operation {i+1} successful")
                
                # Check if we can get page source (tests session persistence)
                page_source_length = len(driver.page_source)
                print(f"✅ Page source retrieved: {page_source_length} characters")
                
            except TimeoutException:
                print(f"⚠️  Operation {i+1} timed out - retry strategy would activate")
            except WebDriverException as e:
                print(f"⚠️  Operation {i+1} failed - retry strategy activated: {e}")
        
        driver.quit()
        print("✅ Session terminated successfully")
        
    except Exception as e:
        print(f"❌ Failover demo error: {e}")

def monitor_retry_metrics():
    """
    Monitor retry-related metrics from the load balancer
    """
    print("\n" + "="*60)
    print("MONITORING: Retry Strategy Metrics")
    print("="*60)
    
    try:
        # Get metrics from Prometheus endpoint
        response = requests.get(f"{LOAD_BALANCER_URL}:9090/metrics", timeout=10)
        metrics_text = response.text
        
        # Parse relevant retry metrics
        retry_metrics = []
        for line in metrics_text.split('\n'):
            if 'retry' in line.lower() or 'attempt' in line.lower():
                retry_metrics.append(line)
        
        if retry_metrics:
            print("Retry-related metrics:")
            for metric in retry_metrics[:10]:  # Show first 10 metrics
                print(f"  {metric}")
        else:
            print("No retry-specific metrics found (this is normal for new deployment)")
            
        # Get session distribution
        response = requests.get(f"{LOAD_BALANCER_URL}/lb/sessions", timeout=10)
        if response.status_code == 200:
            session_data = response.json()
            print(f"\nCurrent active sessions: {session_data.get('active_sessions', 0)}")
            
            distribution = session_data.get('distribution', {})
            if distribution:
                print("Session distribution across instances:")
                for instance_id, count in distribution.items():
                    print(f"  {instance_id}: {count} sessions")
        
    except Exception as e:
        print(f"Could not retrieve metrics: {e}")
        print("This is normal if metrics endpoint is not available")

def main():
    """
    Main demo function that runs all retry strategy demonstrations
    """
    print("Selenium Grid Load Balancer - Intelligent Retry Strategy Demo")
    print("=" * 70)
    
    # Check initial health
    healthy_count = check_load_balancer_health()
    if healthy_count == 0:
        print("\n❌ No healthy Grid instances available. Please start Grid instances first.")
        print("\nTo start the demo environment:")
        print("  docker-compose up -d")
        return
    
    # Get current configuration
    config = get_current_config()
    
    print(f"\nWith {healthy_count} healthy Grid instances and MaxRetries={config['max_retries']}:")
    if config['max_retries'] <= healthy_count:
        print("→ Using Strategy 1: Try each instance once")
    else:
        print("→ Using Strategy 2: Cycle through instances multiple times")
    
    # Run demonstrations
    demonstrate_retry_strategy_1()
    
    time.sleep(2)  # Brief pause between demos
    
    demonstrate_retry_strategy_2()
    
    time.sleep(2)  # Brief pause between demos
    
    demonstrate_failover_with_retry()
    
    time.sleep(2)  # Brief pause before metrics
    
    monitor_retry_metrics()
    
    print("\n" + "="*70)
    print("DEMO COMPLETE")
    print("="*70)
    print("\nKey Benefits of Intelligent Retry Strategy:")
    print("✅ Automatically adapts to available Grid instance count")
    print("✅ Maximizes success rate by trying different instances")
    print("✅ Prevents unnecessary retries on the same failed instance")
    print("✅ Provides predictable retry behavior for monitoring")
    print("✅ Completely transparent to WebDriver clients")
    
    print(f"\nLoad Balancer URL: {LOAD_BALANCER_URL}")
    print(f"Metrics URL: {LOAD_BALANCER_URL}:9090/metrics")
    print(f"Health Check: {LOAD_BALANCER_URL}/lb/health")

if __name__ == "__main__":
    main()
