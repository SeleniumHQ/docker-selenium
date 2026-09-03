import concurrent.futures
import csv
import math
import os
import random
import signal
import subprocess
import time
import unittest
from collections import Counter

from csv2md.table import Table
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.remote.client_config import ClientConfig

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

FIELD_NAMES = [
    "Iteration",
    "New request sessions",
    "Sessions created time",
    "Sessions failed to create",
    "New pods scaled up",
    "Total running sessions",
    "Total running pods",
    "Max sessions per pod",
    "Gaps",
    "Sessions closed",
]


def get_pod_count():
    result = subprocess.run(["kubectl", "get", "pods", "-A", "--no-headers"], capture_output=True, text=True)
    return len([line for line in result.stdout.splitlines() if "selenium-node-" in line and "Running" in line])


def create_session(browser_name):
    options = BROWSER[browser_name]
    options.set_capability("platformName", "Linux")
    driver = webdriver.Remote(
        command_executor=CLIENT_CONFIG.remote_server_addr, options=options, client_config=CLIENT_CONFIG
    )
    print(f"Session created: {driver.session_id} ({browser_name})")
    return driver


def expected_pod_count(sessions, node_max_sessions):
    # Each browser type scales independently (its own ScaledJob/trigger), so the
    # expected pod count is the sum of per-browser ceilings, not a single ceiling
    # over the total - packing sessions across types would understate it.
    counts = Counter(browser_name for _, browser_name in sessions)
    return sum(math.ceil(count / node_max_sessions) for count in counts.values())


def wait_for_count_matches(sessions, node_max_sessions=1, timeout=60, interval=5):
    # Regression guard for https://github.com/SeleniumHQ/docker-selenium/issues/3167:
    # a ScaledJob strategy that double-counts on-going sessions never converges
    # pod count to the expected value, so a bounded poll that hard-fails on timeout
    # catches that runaway growth instead of only warning about it.
    expected = expected_pod_count(sessions, node_max_sessions)
    elapsed = 0
    pod_count = get_pod_count()
    while elapsed < timeout:
        pod_count = get_pod_count()
        if pod_count == expected:
            print(f"PASS: Pod count ({pod_count}) matches expected ({expected}) after {elapsed} seconds.")
            return
        print(f"VALIDATING: pod_count={pod_count}, expected={expected}... ({elapsed}/{timeout} seconds elapsed)")
        time.sleep(interval)
        elapsed += interval
    raise AssertionError(
        f"Pod count mismatch: expected {expected} pods for {len(sessions)} sessions "
        f"(node_max_sessions={node_max_sessions}), got {pod_count} after {timeout} seconds"
    )


def close_all_sessions(sessions):
    for session, _ in sessions:
        session.quit()
    sessions.clear()
    return sessions


def create_sessions_in_parallel(new_request_sessions):
    failed_jobs = 0
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = {
            executor.submit(create_session, browser_name): browser_name
            for browser_name in (random.choice(list(BROWSER.keys())) for _ in range(new_request_sessions))
        }
        sessions = []
        for future in concurrent.futures.as_completed(futures):
            browser_name = futures[future]
            try:
                sessions.append((future.result(), browser_name))
            except Exception as e:
                print(f"ERROR: Failed to create session: {e}")
                failed_jobs += 1
    print(f"Total failed jobs: {failed_jobs}")
    return sessions


def randomly_quit_sessions(sessions, sublist_size):
    if sessions:
        sessions_to_quit = random.sample(sessions, min(sublist_size, len(sessions)))
        for session in sessions_to_quit:
            session[0].quit()
            sessions.remove(session)
        print(f"QUIT: {len(sessions_to_quit)} sessions have been randomly quit.")
        return len(sessions_to_quit)
    return 0


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
