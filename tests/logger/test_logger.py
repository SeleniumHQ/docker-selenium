import os
import re
import subprocess
import unittest

LOGGER = os.path.join(os.path.dirname(__file__), '..', '..', 'Base', 'logger.sh')


def run_bash(script, env=None):
    """Runs a bash snippet with Base/logger.sh sourced and returns the completed process."""
    full_env = {'PATH': os.environ.get('PATH', '/usr/bin:/bin')}
    full_env.update(env or {})
    return subprocess.run(
        ['bash', '-c', f'source "{LOGGER}"; {script}'],
        capture_output=True,
        text=True,
        env=full_env,
        check=False,
    )


class ToJavaTimestampFormatTest(unittest.TestCase):
    def convert(self, fmt):
        return run_bash('to_java_timestamp_format "$FMT"', {'FMT': fmt})

    def test_supported_formats(self):
        cases = {
            '%Y-%m-%d %H:%M:%S,%3N': 'yyyy-MM-dd HH:mm:ss,SSS',
            '%H:%M:%S.%3N': 'HH:mm:ss.SSS',
            '%Y-%m-%dT%H:%M:%S%z': "yyyy-MM-dd'T'HH:mm:ssZ",
            '%d/%b/%Y at %I:%M %p': "dd/MMM/yyyy 'at' hh:mm a",
            "%H:%M 'x' %%": "HH:mm '''x''' %",
        }
        for date_format, java_format in cases.items():
            with self.subTest(date_format=date_format):
                result = self.convert(date_format)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), java_format)

    def test_unsupported_token(self):
        for date_format in ('%s', '%H:%M:%S.%N', '%Y-%q'):
            with self.subTest(date_format=date_format):
                self.assertEqual(self.convert(date_format).returncode, 1)


class SetLogTimestampOptsTest(unittest.TestCase):
    def opts(self, env):
        return run_bash('set_log_timestamp_opts >/dev/null; printf "%s\\n" "${LOG_TIMESTAMP_OPTS[@]}"', env)

    def test_default_format(self):
        result = self.opts({})
        self.assertEqual(result.stdout.splitlines(), ['--log-timestamp-format', 'yyyy-MM-dd HH:mm:ss,SSS'])

    def test_custom_format(self):
        result = self.opts({'SE_LOG_TIMESTAMP_FORMAT': '%H:%M:%S.%3N'})
        self.assertEqual(result.stdout.splitlines(), ['--log-timestamp-format', 'HH:mm:ss.SSS'])

    def test_se_opts_takes_precedence(self):
        result = self.opts({'SE_OPTS': '--log-timestamp-format HH:mm'})
        self.assertEqual(result.stdout.strip(), '')

    def test_unsupported_format_keeps_server_default(self):
        result = run_bash(
            'set_log_timestamp_opts; echo "count=${#LOG_TIMESTAMP_OPTS[@]}"', {'SE_LOG_TIMESTAMP_FORMAT': '%s'}
        )
        self.assertIn('count=0', result.stdout)
        self.assertRegex(result.stdout, r' WARN \[.*\] - SE_LOG_TIMESTAMP_FORMAT')


class LogFunctionsTest(unittest.TestCase):
    LINE = re.compile(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3} (INFO|WARN|ERROR) \[test.process\] - hello world$')

    def test_levels_and_layout(self):
        result = run_bash(
            'process_name=test.process; log_info hello world; log_warn hello world; log_error hello world'
        )
        stdout = result.stdout.splitlines()
        stderr = result.stderr.splitlines()
        self.assertEqual([self.LINE.match(line).group(1) for line in stdout], ['INFO', 'WARN'])
        self.assertEqual([self.LINE.match(line).group(1) for line in stderr], ['ERROR'])

    def test_process_name_defaults_to_script_name(self):
        result = subprocess.run(
            ['bash', '-c', f'source "{LOGGER}"; log_info started', 'start-test.sh'],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertIn(' INFO [start-test] - started', result.stdout)


if __name__ == '__main__':
    unittest.main()
