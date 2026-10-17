'use strict';

const fs = require('node:fs');
const assert = require('node:assert/strict');
const { getApplicationInfo } = require('../src/app');

const tests = [
    {
        name: 'application reports the correct name and running status',
        run() {
            const info = getApplicationInfo();
            assert.equal(info.name, 'kijanikiosk-payments');
            assert.equal(info.status, 'running');
        }
    }
];

function escapeXml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

const results = tests.map((item) => {
    try {
        item.run();
        console.log(`PASS: ${item.name}`);
        return { name: item.name, error: null };
    } catch (error) {
        console.error(`FAIL: ${item.name}: ${error.message}`);
        return { name: item.name, error };
    }
});

const failures = results.filter((result) => result.error);
const cases = results.map((result) => {
    const failure = result.error
        ? `<failure message="${escapeXml(result.error.message)}">${escapeXml(result.error.stack || result.error.message)}</failure>`
        : '';
    return `<testcase classname="kijanikiosk" name="${escapeXml(result.name)}">${failure}</testcase>`;
}).join('\n');

fs.mkdirSync('test-results', { recursive: true });

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="KijaniKiosk Tests" tests="${results.length}" failures="${failures.length}" errors="0" skipped="0">
${cases}
</testsuite>
`;

fs.writeFileSync('test-results/results.xml', xml);

console.log(`Tests: ${results.length}, Passed: ${results.length - failures.length}, Failed: ${failures.length}`);

if (failures.length > 0) {
    process.exitCode = 1;
}
