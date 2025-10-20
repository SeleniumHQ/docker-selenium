const {test, expect} = require('@playwright/test');
const path = require('path');

// Get test site URL from environment variable or use default
const TEST_SITE = process.env.TEST_SITE || 'the-internet.herokuapp.com';

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

test.describe.parallel('Parallel tests connect to autoscaling Grid', () => {
    test('test_title', async ({page}) => {
        await page.goto(`http://${TEST_SITE}`);
        await expect(page).toHaveTitle('The Internet');
        await sleep(2);
    });

    test('test_with_frames', async ({page}) => {
        await page.goto(`http://${TEST_SITE}/nested_frames`);
        const frame = page.frameLocator('frame[name="frame-top"]').frameLocator('frame[name="frame-middle"]');
        await expect(frame.locator('#content')).toHaveText('MIDDLE');
        await sleep(2);
    });

    test('test_select_from_a_dropdown', async ({page}) => {
        await page.goto(`http://${TEST_SITE}/dropdown`);
        const dropdown = await page.locator('#dropdown');
        await dropdown.selectOption({label: 'Option 1'});
        const selectedOption = await dropdown.inputValue();
        expect(selectedOption).toBe('1');
        await sleep(2);
    });

    test('test_visit_basic_auth_secured_page', async ({page}) => {
        await page.goto(`http://admin:admin@${TEST_SITE}/basic_auth`);
        const pageMessage = await page.locator('.example p').textContent();
        expect(pageMessage.trim()).toBe('Congratulations! You must have the proper credentials.');
        await sleep(2);
    });

    test('test_download_file', async ({page}) => {
        await page.goto(`http://${TEST_SITE}/download`);
        const fileLink = page.locator('a', {hasText: 'some-file.txt'});
        await fileLink.scrollIntoViewIfNeeded();
        const [download] = await Promise.all([
            page.waitForEvent('download'),
            fileLink.click()
        ]);
        const fileName = download.suggestedFilename();
        expect(fileName).toBe('some-file.txt');
        await sleep(2);
    });
});
