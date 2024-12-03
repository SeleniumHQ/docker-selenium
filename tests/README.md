Run test in [AutoscalingTest](./AutoscalingTests)

Install dependencies to virtual environment or system wide.
```bash
python3 -m pip install -r requirements.txt
```

Run tests with the following commands.

```bash
REMOTE_SERVER_ADDR="http://$(hostname -I | cut -d' ' -f1)/selenium/wd/hub" \
python3 -m unittest AutoscalingTests.test_scale_chaos
```

```bash
REMOTE_SERVER_ADDR="http://$(hostname -I | cut -d' ' -f1)/selenium/wd/hub" \
python3 -m unittest AutoscalingTests.test_scale_up
```
