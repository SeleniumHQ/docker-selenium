# Selenium Java Tests

This project contains Selenium tests that connect to a Selenium Grid using RemoteWebDriver with modern builder pattern and ClientConfig.

## Prerequisites
- JDK 17 installed
- Selenium Grid running on `http://localhost:4444`
- Chrome browser available in the grid

## How to run the test

1. Start Selenium Grid (e.g., using Docker):
   ```bash
   docker run --rm --name standalone -d -p 4444:4444 selenium/standalone-chromium:latest
   ```

2. From this directory, run:
   ```bash
   export BROWSER=chrome
   export GRID_URL=http://localhost:4444/wd/hub
   ./gradlew clean test
   ```

This will launch a simple Selenium test that opens AUT using RemoteWebDriver connected to the Selenium Grid.
