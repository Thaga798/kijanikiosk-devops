'use strict';

const http = require('http');

const PORT = Number(process.env.PORT || 3000);
const VERSION = process.env.APP_VERSION || 'v1.3.0';

const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'ok',
            version: VERSION,
            port: PORT
        }));
        return;
    }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
        application: 'kijanikiosk-payments',
        version: VERSION
    }));
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('KijaniKiosk API ' + VERSION + ' listening on port ' + PORT);
});
