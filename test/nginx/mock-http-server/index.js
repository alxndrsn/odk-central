const { randomBytes } = require('node:crypto');

const express = require('express');

const port = process.env.PORT || 80;
const log = (...args) => console.log('[mock-http-server]', ...args);

const requests = [];

const app = express();

app.use((req, res, next) => {
  console.log(new Date(), req.method, req.originalUrl);
  next();
});

// Enketo express returns response with Vary and Cache-Control headers
app.use('/-/', (req, res, next) => {
  res.set('Vary', 'Accept-Encoding');
  res.set('Cache-Control', 'public, max-age=0');
  next();
});

app.get('/health',      (req, res) => res.send('OK'));
app.get('/request-log', (req, res) => res.json(requests));
app.get('/reset',       (req, res) => {
  requests.length = 0;
  res.json('OK');
});

// TODO these need renaming to e.g. 500kb connections or something
let openEndlessConnections = 0;
app.get('/v1/endless/in-progress', (req, res) => {
  res.send(String(openEndlessConnections));
});
app.get('/v1/endless/response', (req, res) => {
  const log = (...args) => console.log(new Date(), '/response', ...args);
  ++openEndlessConnections;

  res.setHeader('Content-Type', 'application/octet-stream');
  res.setHeader('Transfer-Encoding', 'chunked');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  req.on('close', () => {
    log('req closed');
    --openEndlessConnections; // TODO need to handle premature client disconnection?
  });

  const byteCount = 50_000_000;
  log('beginning to write', byteCount, 'bytes...');
  res.write(randomBytes(byteCount));
  log('write completed.');
});

app.get('/v1/reflect-headers', (req, res) => res.json(req.headers));

// Central-Backend can set Cache headers and those should have highest precedence
app.get('/v1/projects', (_, res) => {
  res.set('Vary', 'Cookie');
  res.set('Cache-Control', 'private, max-age=3600');
  res.send('OK');
});

[
  'delete',
  'get',
  'patch',
  'post',
  'put',
  // TODO add more methods as required
].forEach(method => app[method]('/{*splat}', (req, res) => {
  requests.push({ method:req.method, path:req.originalUrl });
  res.send('OK');
}));

app.listen(port, () => {
  log(`Listening on port: ${port}`);
});
