// Copyright 2022 ODK Central Developers
// See the NOTICE file at the top-level directory of this distribution and at
// https://github.com/getodk/central-backend/blob/master/NOTICE.
// This file is part of ODK Central. It is subject to the license terms in
// the LICENSE file found in the top-level directory of this distribution and at
// https://www.apache.org/licenses/LICENSE-2.0. No part of ODK Central,
// including this file, may be copied, modified, propagated, or distributed
// except according to the terms contained in the LICENSE file.

import fs from 'node:fs';
import fetch, { fileFromSync } from 'node-fetch';
import _ from 'lodash';
import { v4 as uuid } from 'uuid';
import { spawn } from 'node:child_process';
import { basename } from 'node:path';
import { program } from 'commander';

const _log = (...args) => console.log(`[${new Date().toISOString()}]`, '[benchmarker]', ...args);
const log  = (...args) => true  && _log('INFO',   ...args);
log.debug  = (...args) => false && _log('DEBUG',  ...args);
log.info   = log;
log.error  = (...args) => true  && _log('ERROR',  ...args);
log.report = (...args) => true  && _log('REPORT', ...args);

const REAL_LOGIN = false; // SET TO TRUE ONCE THE TESTS ARE "working" TO SOME EXTENT AND WE CAN START RUNNING THE FULL docker-compose CONTAINER SUITE

program
    .option('-s, --server-url <serverUrl>', 'URL of ODK Central server', 'http://localhost:19080')
    .option('-u, --user-email <serverUrl>', 'Email of central user', 'x@example.com')
    .option('-P, --user-password <userPassword>', 'Password of central user', 'secret')
    ;
program.parse();
const { serverUrl, userEmail, userPassword } = program.opts();

let bearerToken;

log('Starting nginx docker container...');
const cp = spawn('docker-compose', ['up', '--build', 'nginx'], { env:{ HTTP_PORT:19080, HTTPS_PORT:19443, DOMAIN:'odk-nginx-test.localhost', SYSADMIN_EMAIL:'sysadmin@example.com', SSL_TYPE:'upstream' } });
cp.stdout.on('data', processDockerComposeOutput);
cp.stderr.on('data', processDockerComposeOutput);

log('waiting for start confirmation...');

function processDockerComposeOutput(data) {
	const out = data.toString().replace(/\n$/, '');
	log('[docker-compose]', out);
	if(out.includes('starting nginx without local SSL to allow for upstream SSL..')) {
    setTimeout(runTests, 1000); // TODO can prob remove timeout when things are working
	}
}

async function runTests() {
  log.info('Setting up...');

  try {
  //  log.info('Creating session...');
  //  const { token } = await apiPostJson('sessions', { email:userEmail, password:userPassword }, { Authorization:null });
  //  bearerToken = token;

    log.info('Setup complete.  Starting tests...');

    let pass = true;
    pass &= await test('version.txt', { Authorization:false }, 100, 100);

    log.info('Complete.');

    setTimeout(process.exit, 1000); // TODO can prob remove timeout when things are working
  } catch(err) {
    console.log('Fatal error:', err);
    // TODO process.exit(1);
  }
}

async function test(path, headers, expectedSuccess_min, expectedSuccess_max) {
  const promises = [];
  for(let i=0; i<100; ++i) promises.push(apiFetch('get', path, undefined, headers));
  const statuses = await Promise.all(promises);

  const successCount     = statuses.filter(s => s === 200);
  const rateLimitedCount = statuses.filter(s => s === 527); // TODO double-check status code
  const successPercent = successCount; // currently doing 100 requests, so no calculation required

  const failed = false ||
      (successPercent < expectedSuccess_min) ||
      (successPercent > expectedSuccess_max) ||
      (successCount + rateLimitedCount !== 100) ||
      false;
  const passed = !failed;

  console.log(`
    ----------------------------
    TEST REPORT: GET ${path}
    ----------------------------
    REQUESTS:     100
    SUCCESSES:    ${successCount.toString().padStart(3, ' ')}
    RATE LIMITED: ${rateLimitedCount.toString().padStart(3, ' ')}
    ---
    TEST ${passed ? 'PASSED ✅' : 'FAILED ❌'}
    ----------------------------
  `);

  return passed;
}

function reportFatalError(message) {
  reportWarning(message);
  process.exit(1);
}

function reportWarning(message) {
  log.report('!!!');
  log.report('!!!');
  log.report(`!!! ${message}!`);
  log.report('!!!');
  log.report('!!!');
  log.report('--------------------------');
}

function apiPostFile(path, filePath) {
  const mimeType = mimetypeFor(filePath);
  const blob = fileFromSync(filePath, mimeType);
  return apiPost(path, blob, { 'Content-Type':mimeType });
}

function apiPostJson(path, body, headers) {
  return apiPost(path, JSON.stringify(body), { 'Content-Type':'application/json', ...headers });
}

function apiGetAndDump(prefix, n, path, headers) {
  return fetchToFile(prefix, n, 'GET', path, undefined, headers);
}

function apiPostAndDump(prefix, n, path, body, headers) {
  return fetchToFile(prefix, n, 'POST', path, body, headers);
}

async function fetchToFile(filenamePrefix, n, method, path, body, headers) {
  const res = await apiFetch(method, path, body, headers);

  return new Promise((resolve, reject) => {
    try {
      let bytes = 0;
      res.body.on('data', data => bytes += data.length);
      res.body.on('error', reject);

      const file = fs.createWriteStream(`${logPath}/${filenamePrefix}.${n.toString().padStart(9, '0')}.dump`);
      res.body.on('end', () => file.close(() => resolve(bytes)));

      file.on('error', reject);

      res.body.pipe(file);
    } catch(err) {
      console.log(err);
      process.exit(99);
    }
  });
}

async function apiPost(path, body, headers) {
  const res = await apiFetch('POST', path, body, headers);
  return res.json();
}

async function apiFetch(method, path, body, extraHeaders) {
  const url = `${serverUrl}/v1/${path}`;

  const headers = { ...extraHeaders };
  if(headers.Authorization === false) {
    delete headers.Authorization;
  } else if(headers.Authorization) {
    // set elsewhere
  } else if(bearerToken) {
    headers.Authorization = `Bearer ${bearerToken}`;
  } else {
    headers.Authorization = `Basic ${base64(`${userEmail}:${userPassword}`)}`;
  }

  const res = await fetch(url, { method, body, headers });
  log.debug(method, res.url, '->', res.status);
  return res.status;
}

function base64(s) {
  return Buffer.from(s).toString('base64');
}

function mimetypeFor(f) {
  const extension = fileExtensionFrom(f);
  log.debug('fileExtensionFrom()', f, '->', extension);
  switch(extension) {
    case 'xls' : return 'application/vnd.ms-excel';
    case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'xml' : return 'application/xml';
    default: throw new Error(`Unsure what mime type to use for: ${f}`);
  }
}

function fileExtensionFrom(f) {
  try {
    return basename(f).match(/\.([^.]*)$/)[1];
  } catch(err) {
    throw new Error(`Could not get file extension from filename '${f}'!`);
  }
}

function randomSubmission(n, projectId, formId) {
  const headers = {
    'Content-Type': 'multipart/form-data; boundary=foo',
    'X-OpenRosa-Version': '1.0',
  };

  const body = `--foo\r
Content-Disposition: form-data; name="xml_submission_file"; filename="submission.xml"\r
Content-Type: application/xml\r
\r
${submissionTemplate
  .replace(/{{uuid}}/g, () => uuid())
  .replace(/{{randInt}}/g, randInt)
}
\r
--foo--`;

  return apiPostAndDump('randomSubmission', n, `projects/${projectId}/forms/${formId}/submissions`, body, headers);
}

function randInt() {
  return Math.floor(Math.random() * 9999);
}

function exportZipWithDataAndMedia(n, projectId, formId) {
  return apiGetAndDump('exportZipWithDataAndMedia', n, `projects/${projectId}/forms/${formId}/submissions.csv.zip?splitSelectMultiples=true&groupPaths=true&deletedFields=true`);
}

function durationForHumans(ms) {
  if(ms > 1000) return oneDp((ms / 1000)) + 's';
  else          return oneDp(         ms) + 'ms';
}

function oneDp(n) {
  return Number(n.toFixed(1));
}
