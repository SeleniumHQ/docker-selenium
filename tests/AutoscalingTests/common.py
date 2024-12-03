import unittest
import random
import time
import subprocess
import signal
import concurrent.futures
import csv
import os
from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.remote.client_config import ClientConfig
from csv2md.table import Table

BROWSER = {
    "chrome": ChromeOptions(),
    "firefox": FirefoxOptions(),
    "edge": EdgeOptions(),
}

REMOTE_SERVER_ADDR = os.getenv("REMOTE_SERVER_ADDR", "http://localhost/selenium/wd/hub")

CLIENT_CONFIG = ClientConfig(
    remote_server_addr=REMOTE_SERVER_ADDR,
    keep_alive=True,
    timeout=3600,
)

FIELD_NAMES = ["Iteration", "New request sessions", "Sessions created time", "Sessions failed to create", "New pods scaled up", "Total running sessions", "Total running pods", "Max sessions per pod", "Gaps", "Sessions closed"]

def get_pod_count():
    result = subprocess.run(["kubectl", "get", "pods", "-A", "--no-headers"], capture_output=True, text=True)
    return len([line for line in result.stdout.splitlines() if "selenium-node-" in line and "Running" in line])

def create_session(browser_name):
    return webdriver.Remote(command_executor=CLIENT_CONFIG.remote_server_addr, options=BROWSER[browser_name], client_config=CLIENT_CONFIG)

def wait_for_count_matches(sessions, timeout=10, interval=5):
    elapsed = 0
    while elapsed < timeout:
        pod_count = get_pod_count()
        if pod_count == len(sessions):
            break
        print(f"VALIDATING: Waiting for pods to match sessions... ({elapsed}/{timeout} seconds elapsed)")
        time.sleep(interval)
        elapsed += interval
    if pod_count != len(sessions):
        print(f"WARN: Mismatch between pod count and session count after {timeout} seconds. Gaps: {pod_count - len(sessions)}")
    else:
        print(f"PASS: Pod count matches session count after {elapsed} seconds.")

def close_all_sessions(sessions):
    for session in sessions:
        session.quit()
    sessions.clear()
    return sessions

def create_sessions_in_parallel(new_request_sessions):
    failed_jobs = 0
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(create_session, random.choice(list(BROWSER.keys()))) for _ in range(new_request_sessions)]
        sessions = []
        for future in concurrent.futures.as_completed(futures):
            try:
                sessions.append(future.result())
            except Exception as e:
                print(f"ERROR: Failed to create session: {e}")
                failed_jobs += 1
    print(f"Total failed jobs: {failed_jobs}")
    return sessions

def randomly_quit_sessions(sessions, sublist_size):
    if sessions:
        sessions_to_quit = random.sample(sessions, min(sublist_size, len(sessions)))
        for session in sessions_to_quit:
            session.quit()
            sessions.remove(session)
        print(f"QUIT: {len(sessions_to_quit)} sessions have been randomly quit.")
    return len(sessions_to_quit)

def get_result_file_name():
    return f"tests/autoscaling_results"

def export_results_to_csv(output_file, field_names, results):
    with open(output_file, mode="w") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names)
        writer.writeheader()
        writer.writerows(results)

def export_results_csv_to_md(csv_file, md_file):
    with open(csv_file) as f:
        table = Table.parse_csv(f)
    with open(md_file, mode="w") as f:
        f.write(table.markdown())
