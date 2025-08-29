#!/usr/bin/env python3
"""
Comprehensive Load Balancing Strategies Demo

This script demonstrates all three advanced load balancing strategies:
1. Weighted Round Robin - Distributes sessions based on instance weights
2. HA GEO (Active/Standby) - Geographic high availability with failover
3. Greedy - Assigns sessions up to max limits before moving to next instance

The demo creates multiple sessions and shows how each strategy distributes
the load across Grid instances differently.
"""

import json
import time
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load balancer configuration
LOAD_BALANCER_URL = "http://localhost:4444"
METRICS_URL = f"{LOAD_BALANCER_URL}/metrics"

class LoadBalancingDemo:
    def __init__(self):
        self.sessions = []
        self.session_lock = threading.Lock()
        
    def create_chrome_options(self):
        """Create Chrome options for testing"""
        options = Options()
        options.add_argument("--headless")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        return options
    
    def create_session(self, session_id):
        """Create a single WebDriver session"""
        try:
            options = self.create_chrome_options()
            driver = webdriver.Remote(
                command_executor=f"{LOAD_BALANCER_URL}/wd/hub",
                options=options
            )
            
            with self.session_lock:
                self.sessions.append({
                    'id': session_id,
                    'driver': driver,
                    'selenium_session_id': driver.session_id,
                    'created_at': time.time()
                })
            
            logger.info(f"Session {session_id} created successfully (Selenium ID: {driver.session_id})")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create session {session_id}: {e}")
            return False
    
    def get_load_balancer_metrics(self):
        """Get current metrics from the load balancer"""
        try:
            response = requests.get(METRICS_URL, timeout=5)
            if response.status_code == 200:
                return response.text
            else:
                logger.warning(f"Failed to get metrics: HTTP {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"Error getting metrics: {e}")
            return None
    
    def get_session_distribution(self):
        """Parse metrics to show session distribution across Grid instances"""
        metrics = self.get_load_balancer_metrics()
        if not metrics:
            return {}
        
        distribution = {}
        for line in metrics.split('\n'):
            if 'grid_instance_sessions' in line and not line.startswith('#'):
                # Parse: grid_instance_sessions{instance="grid-1"} 3
                parts = line.split()
                if len(parts) >= 2:
                    instance_part = parts[0]
                    count = int(parts[1])
                    # Extract instance name from {instance="grid-1"}
                    start = instance_part.find('instance="') + 10
                    end = instance_part.find('"', start)
                    if start > 9 and end > start:
                        instance = instance_part[start:end]
                        distribution[instance] = count
        
        return distribution
    
    def demonstrate_weighted_round_robin(self, num_sessions=12):
        """Demonstrate Weighted Round Robin load balancing"""
        logger.info("=" * 60)
        logger.info("DEMONSTRATING WEIGHTED ROUND ROBIN STRATEGY")
        logger.info("=" * 60)
        logger.info("This strategy distributes sessions based on instance weights:")
        logger.info("- grid-1: weight=100 (40% of sessions)")
        logger.info("- grid-2: weight=150 (60% of sessions)")
        logger.info("- grid-3: weight=50 (standby, lower priority)")
        logger.info("")
        
        # Create sessions concurrently
        with ThreadPoolExecutor(max_workers=6) as executor:
            futures = [executor.submit(self.create_session, i) for i in range(1, num_sessions + 1)]
            
            for i, future in enumerate(as_completed(futures), 1):
                success = future.result()
                if success:
                    # Show distribution after every few sessions
                    if i % 3 == 0:
                        time.sleep(1)  # Allow metrics to update
                        distribution = self.get_session_distribution()
                        logger.info(f"After {i} sessions: {distribution}")
        
        # Final distribution
        time.sleep(2)
        final_distribution = self.get_session_distribution()
        logger.info(f"Final distribution: {final_distribution}")
        
        # Calculate percentages
        total_sessions = sum(final_distribution.values())
        if total_sessions > 0:
            logger.info("Distribution percentages:")
            for instance, count in final_distribution.items():
                percentage = (count / total_sessions) * 100
                logger.info(f"  {instance}: {count} sessions ({percentage:.1f}%)")
    
    def demonstrate_ha_geo_strategy(self):
        """Demonstrate HA GEO (Active/Standby) load balancing"""
        logger.info("=" * 60)
        logger.info("DEMONSTRATING HA GEO (ACTIVE/STANDBY) STRATEGY")
        logger.info("=" * 60)
        logger.info("This strategy uses geographic regions with active/standby roles:")
        logger.info("- us-east region: grid-1, grid-2 (active)")
        logger.info("- us-west region: grid-3 (standby)")
        logger.info("Sessions should go to active instances first")
        logger.info("")
        
        # Clean up previous sessions
        self.cleanup_sessions()
        
        # Create sessions to show active preference
        num_sessions = 8
        with ThreadPoolExecutor(max_workers=4) as executor:
            futures = [executor.submit(self.create_session, f"geo-{i}") for i in range(1, num_sessions + 1)]
            
            for i, future in enumerate(as_completed(futures), 1):
                success = future.result()
                if success and i % 2 == 0:
                    time.sleep(1)
                    distribution = self.get_session_distribution()
                    logger.info(f"After {i} sessions: {distribution}")
        
        time.sleep(2)
        final_distribution = self.get_session_distribution()
        logger.info(f"Final distribution: {final_distribution}")
        logger.info("Note: Active instances (grid-1, grid-2) should have most sessions")
    
    def demonstrate_greedy_strategy(self):
        """Demonstrate Greedy load balancing with session limits"""
        logger.info("=" * 60)
        logger.info("DEMONSTRATING GREEDY STRATEGY")
        logger.info("=" * 60)
        logger.info("This strategy fills instances to their max_sessions limit:")
        logger.info("- grid-1: max_sessions=10")
        logger.info("- grid-2: max_sessions=15") 
        logger.info("- grid-3: max_sessions=5")
        logger.info("Sessions fill up instances completely before moving to next")
        logger.info("")
        
        # Clean up previous sessions
        self.cleanup_sessions()
        
        # Create sessions progressively to show greedy behavior
        num_sessions = 20
        for i in range(1, num_sessions + 1):
            success = self.create_session(f"greedy-{i}")
            if success:
                time.sleep(0.5)  # Small delay to see progression
                if i % 5 == 0:
                    distribution = self.get_session_distribution()
                    logger.info(f"After {i} sessions: {distribution}")
        
        time.sleep(2)
        final_distribution = self.get_session_distribution()
        logger.info(f"Final distribution: {final_distribution}")
        logger.info("Note: Instances should fill up to their limits before overflow")
    
    def cleanup_sessions(self):
        """Clean up all WebDriver sessions"""
        logger.info("Cleaning up sessions...")
        
        with self.session_lock:
            for session in self.sessions:
                try:
                    session['driver'].quit()
                except Exception as e:
                    logger.warning(f"Error closing session {session['id']}: {e}")
            
            self.sessions.clear()
        
        # Wait for cleanup to complete
        time.sleep(3)
        logger.info("Session cleanup completed")
    
    def run_comprehensive_demo(self):
        """Run comprehensive demonstration of all load balancing strategies"""
        logger.info("Starting Comprehensive Load Balancing Strategies Demo")
        logger.info("Make sure the load balancer is running with the appropriate strategy configured")
        logger.info("")
        
        try:
            # Test 1: Weighted Round Robin
            self.demonstrate_weighted_round_robin()
            time.sleep(5)
            
            # Test 2: HA GEO (Active/Standby)
            self.demonstrate_ha_geo_strategy()
            time.sleep(5)
            
            # Test 3: Greedy Strategy
            self.demonstrate_greedy_strategy()
            
        except KeyboardInterrupt:
            logger.info("Demo interrupted by user")
        except Exception as e:
            logger.error(f"Demo failed: {e}")
        finally:
            self.cleanup_sessions()
    
    def run_strategy_specific_demo(self, strategy):
        """Run demo for a specific strategy"""
        logger.info(f"Running demo for {strategy} strategy")
        
        try:
            if strategy == "weighted_round_robin":
                self.demonstrate_weighted_round_robin()
            elif strategy == "ha_geo":
                self.demonstrate_ha_geo_strategy()
            elif strategy == "greedy":
                self.demonstrate_greedy_strategy()
            else:
                logger.error(f"Unknown strategy: {strategy}")
                return
                
        except Exception as e:
            logger.error(f"Demo failed: {e}")
        finally:
            self.cleanup_sessions()

def main():
    """Main function to run the load balancing demo"""
    import sys
    
    demo = LoadBalancingDemo()
    
    if len(sys.argv) > 1:
        strategy = sys.argv[1]
        if strategy in ["weighted_round_robin", "ha_geo", "greedy"]:
            demo.run_strategy_specific_demo(strategy)
        else:
            print("Usage: python load-balancing-strategies-demo.py [weighted_round_robin|ha_geo|greedy]")
            print("Or run without arguments for comprehensive demo")
    else:
        demo.run_comprehensive_demo()

if __name__ == "__main__":
    main()
