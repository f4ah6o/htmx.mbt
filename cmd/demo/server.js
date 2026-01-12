const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const pathname = url.pathname;

    console.log(`${req.method} ${pathname}`);

    // CORS headers (for safety, though we serve static from same origin)
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'HX-Request, HX-Target, HX-Trigger, HX-Swap');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    // Static files
    if (pathname === '/') {
        fs.readFile(path.join(__dirname, 'index.html'), (err, data) => {
            if (err) { res.writeHead(500); res.end('Error loading index.html'); }
            else { res.writeHead(200, { 'Content-Type': 'text/html' }); res.end(data); }
        });
        return;
    }
    if (pathname === '/main.js') {
        // MoonBitビルド出力から配信
        const mainJsPath = path.join(__dirname, '../../target/js/release/build/cmd/main/main.js');
        fs.readFile(mainJsPath, (err, data) => {
            if (err) { res.writeHead(500); res.end('Error loading main.js: ' + err.message); }
            else { res.writeHead(200, { 'Content-Type': 'text/javascript' }); res.end(data); }
        });
        return;
    }

    // API Endpoints
    if (pathname === '/api/hello') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end('<strong>Hello from htmx.mbt!</strong>');
        return;
    }

    if (pathname === '/api/time') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`Time: ${new Date().toLocaleTimeString()}`);
        return;
    }

    if (pathname === '/api/clear') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(``);
        return;
    }

    if (pathname === '/api/submit' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            // Just acknowledge submission
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(`<div class="success" style="color: green; border: 1px solid green; padding: 10px;">
                ✅ Form received!<br>
                Payload Size: ${body.length} bytes
             </div>`);
        });
        return;
    }

    if (pathname === '/api/morph') { // POST
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            const ts = new Date().toLocaleTimeString();
            // Return updated form html
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(`
            <form hx-post="/api/morph" hx-target="#morph-demo" hx-swap="morph">
                <label>Type here (should keep focus): <input type="text" name="q" value="Focus me"></label>
                <button type="submit">Morph Update</button>
            </form>
            <p>Last update: <span id="morph-ts">${ts}</span></p>
             `);
        });
        return;
    }

    if (pathname === '/api/full-page') {
        // hx-select demo
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
         <html><body>
           <header>Header (Ignored)</header>
           <div id="content-only">
               <p style="color: purple; font-weight: bold;">This content was extracted from a full HTML page via hx-select!</p>
               <p>Timestamp: ${new Date().toISOString()}</p>
           </div>
           <footer>Footer (Ignored)</footer>
         </body></html>
         `);
        return;
    }

    if (pathname === '/api/oob-demo') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
         <div>Main response content: <strong>Request Successful</strong></div>
         <div id="oob-target" hx-swap-oob="true" style="background: #e6f3ff; border: 1px solid blue; padding: 10px;">
             ⚡️ OOB Update occurred at ${new Date().toLocaleTimeString()}!
         </div>
         `);
        return;
    }

    if (pathname.startsWith('/api/page')) {
        const page = pathname.replace('/api/', '');
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
        <h3>You are on ${page}</h3>
        <p>The URL bar should now reflect the new state.</p>
        <button hx-get="/api/time" hx-target="this" hx-swap="outerHTML">Check Time</button>
        <p><a href="/" hx-get="/" hx-target="body">Back to Home</a></p>
        `);
        return;
    }

    res.writeHead(404);
    res.end('Not Found');
});

server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}/`);
    console.log('Press Ctrl+C to stop');
});
