package dev.selenium;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.remote.http.ClientConfig;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.openqa.selenium.edge.EdgeOptions;
import org.openqa.selenium.Capabilities;

import java.net.URI;
import java.time.Duration;

class SeleniumTests {
    private WebDriver driver;
    private String TEST_SITE = System.getenv().getOrDefault("TEST_SITE", "the-internet.herokuapp.com");

    @BeforeEach
    void setUp() {
        String browser = System.getenv().getOrDefault("BROWSER", "chrome").toLowerCase();
        Capabilities options;

        switch (browser) {
            case "firefox":
                FirefoxOptions firefoxOptions = new FirefoxOptions();
                firefoxOptions.enableBiDi();
                options = firefoxOptions;
                break;
            case "edge":
                EdgeOptions edgeOptions = new EdgeOptions();
                edgeOptions.addArguments("--no-sandbox", "--disable-dev-shm-usage");
                edgeOptions.enableBiDi();
                options = edgeOptions;
                break;
            case "chrome":
            default:
                ChromeOptions chromeOptions = new ChromeOptions();
                chromeOptions.addArguments("--no-sandbox", "--disable-dev-shm-usage");
                chromeOptions.enableBiDi();
                options = chromeOptions;
        }

        ClientConfig config = ClientConfig.defaultConfig()
                .readTimeout(Duration.ofSeconds(300))
                .connectionTimeout(Duration.ofSeconds(120));

        String gridUrl = System.getenv().getOrDefault("GRID_URL", "http://localhost:4444/wd/hub");
        driver = RemoteWebDriver.builder()
                .oneOf(options)
                .address(gridUrl)
                .config(config)
                .build();
    }

    @Test
    void abTestingLinkOpensCorrectPage() {
        driver.get(String.format("http://%s", TEST_SITE));
        driver.findElement(By.linkText("A/B Testing")).click();
        String header = driver.findElement(By.tagName("h3")).getText();
        assert header.contains("A/B Test");
    }

    @Test
    void checkboxesCanBeToggled() {
        driver.get(String.format("http://%s/checkboxes", TEST_SITE));
        WebElement checkbox1 = driver.findElements(By.cssSelector("input[type='checkbox']")).get(0);
        boolean initialState = checkbox1.isSelected();
        checkbox1.click();
        assert checkbox1.isSelected() != initialState;
    }

    @Test
    void dropdownSelectionWorks() {
        driver.get(String.format("http://%s/dropdown", TEST_SITE));
        WebElement dropdown = driver.findElement(By.id("dropdown"));
        Select select = new Select(dropdown);
        select.selectByVisibleText("Option 2");
        assert select.getFirstSelectedOption().getText().equals("Option 2");
    }

    @AfterEach
    void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
} 