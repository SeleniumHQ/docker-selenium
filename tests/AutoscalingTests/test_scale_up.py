import unittest
import random
import time
import signal
import csv
from csv2md.table import Table
from .common import *

SESSIONS = []
RESULTS = []
TEST_NODE_MAX_SESSIONS = int(os.getenv("TEST_NODE_MAX_SESSIONS", 1))
TEST_AUTOSCALING_ITERATIONS = int(os.getenv("TEST_AUTOSCALING_ITERATIONS", 20))

def signal_handler(signum, frame):
    print("Signal received, quitting all sessions...")
    close_all_sessions(SESSIONS)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

class SeleniumAutoscalingTests(unittest.TestCase):
    def test_run_tests(self):
        try:
            for iteration in range(TEST_AUTOSCALING_ITERATIONS):
                new_request_sessions = random.randint(1, 3)
                start_time = time.time()
                start_pods = get_pod_count()
                new_sessions = create_sessions_in_parallel(new_request_sessions)
                failed_sessions = new_request_sessions - len(new_sessions)
                end_time = time.time()
                stop_pods = get_pod_count()
                SESSIONS.extend(new_sessions)
                elapsed_time = end_time - start_time
                new_scaled_pods = stop_pods - start_pods
                total_sessions = len(SESSIONS)
                total_pods = get_pod_count()
                print(f"ADDING: Created {new_request_sessions} new sessions in {elapsed_time:.2f} seconds.")
                print(f"INFO: Total sessions: {total_sessions}")
                print(f"INFO: Total pods: {total_pods}")
                if iteration % 5 == 0:
                    closed_session = randomly_quit_sessions(SESSIONS, 20)
                else:
                    closed_session = 0
                RESULTS.append({
                    FIELD_NAMES[0]: iteration + 1,
                    FIELD_NAMES[1]: new_request_sessions,
                    FIELD_NAMES[2]: f"{elapsed_time:.2f} s",
                    FIELD_NAMES[3]: failed_sessions,
                    FIELD_NAMES[4]: new_scaled_pods,
                    FIELD_NAMES[5]: total_sessions,
                    FIELD_NAMES[6]: total_pods,
                    FIELD_NAMES[7]: TEST_NODE_MAX_SESSIONS,
                    FIELD_NAMES[8]: (total_pods * TEST_NODE_MAX_SESSIONS) - total_sessions,
                    FIELD_NAMES[9]: closed_session,
                })
                time.sleep(15)
        finally:
            print(f"FINISH: Closing {len(SESSIONS)} sessions.")
            close_all_sessions(SESSIONS)
            output_file = get_result_file_name()
            export_results_to_csv(f"{output_file}.csv", FIELD_NAMES, RESULTS)
            export_results_csv_to_md(f"{output_file}.csv", f"{output_file}.md")

if __name__ == "__main__":
    unittest.main()
