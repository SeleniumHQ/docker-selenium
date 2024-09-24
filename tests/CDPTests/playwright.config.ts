import type {PlaywrightTestConfig} from '@playwright/test';
import * as dotenv from 'dotenv';

dotenv.config();

const config: PlaywrightTestConfig = {
    timeout: 1500000,
    testMatch: ["tests/*.ts"],
    use: {
        headless: false,
        screenshot: "on",
        video: "on"
    },
    reporter: [["dot"], ["json", {
        outputFile: "jsonReports/jsonReport.json"
    }], ["html", {
        open: "never"
    }]],
    workers: 5
};

export default config;
