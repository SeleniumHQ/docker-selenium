import logging
import sys
import unittest

import yaml

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


def load_template(yaml_file):
    try:
        with open(yaml_file) as file:
            documents = yaml.safe_load_all(file)
            list_of_documents = [doc for doc in documents]
            return list_of_documents
    except yaml.YAMLError as error:
        print("Error in configuration file: ", error)


class ScaledJobTemplateTests(unittest.TestCase):
    def test_scaled_job_has_zero_limits(self):
        scaled_jobs = [doc for doc in LIST_OF_DOCUMENTS if doc and doc.get("kind") == "ScaledJob"]
        self.assertTrue(scaled_jobs, "No ScaledJob resources found")
        for doc in scaled_jobs:
            logger.info(f"Assert ScaledJob limits are set to 0 in {doc['metadata']['name']}")
            self.assertEqual(doc.get("apiVersion"), "keda.sh/v1alpha1")
            spec = doc.get("spec", {})
            job_target_ref = spec.get("jobTargetRef", {})
            self.assertEqual(job_target_ref.get("backoffLimit"), 0)
            self.assertEqual(spec.get("minReplicaCount"), 0)
            self.assertEqual(spec.get("successfulJobsHistoryLimit"), 0)


if __name__ == "__main__":
    failed = False
    try:
        FILE_NAME = sys.argv[1]
        LIST_OF_DOCUMENTS = load_template(FILE_NAME)
        suite = unittest.TestLoader().loadTestsFromTestCase(ScaledJobTemplateTests)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    if failed:
        exit(1)
