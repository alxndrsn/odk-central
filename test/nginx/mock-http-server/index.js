const { randomBytes } = require('node:crypto');
const { Readable } = require('node:stream');

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
app.get('/v1/endless/response', async (req, res) => {
  const log = (...args) => console.log(new Date(), '/response', ...args);
  ++openEndlessConnections;

  log('start: openEndlessConnections:', openEndlessConnections);

  res.setHeader('Content-Type', 'application/octet-stream');
  res.setHeader('Cache-Control', 'private, no-store');

  req.on('close', () => {
    log('req closed');
    --openEndlessConnections; // TODO need to handle premature client disconnection?
    log('end: openEndlessConnections:', openEndlessConnections);
  });

  const byteStream = new RandomByteStream(10_000_000, 50_000);
  byteStream.pipe(res);
  byteStream.on('error', (err) => {
    console.error('stream error:', err);
    res.end();
  });
  byteStream.on('end', () => {
    console.log(`Successfully streamed ${BYTES_TO_STREAM} bytes.`);
    res.end();
  });
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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

class RandomByteStream extends Readable {
  constructor(totalBytes, chunkSize, options) {
    super(options);

    this.totalBytes = totalBytes;
    this.bytesGenerated = 0;
    this.chunkSize = chunkSize;
  }

  _read(size) {
    if(this.bytesGenerated >= this.totalBytes) return this.push(null); // done

    try {
      const bytesToGenerate = Math.min(this.chunkSize, this.totalBytes - this.bytesGenerated);
      const chunk = randomBytes(bytesToGenerate);
      const wasPushed = this.push(chunk);
      if(wasPushed) this.bytesGenerated += chunk.length;
    } catch (err) {
      this.destroy(err);
    }
  }
}
