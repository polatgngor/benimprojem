/**
 * Cross-platform Node runner for Taksibu backend tests.
 * Usage:
 *   node test/run_all_tests_node.js         # assumes server already started
 *   node test/run_all_tests_node.js start   # will attempt to start server (npm run dev) in background
 *
 * Features:
 * - optional starts server in background (uses 'npm run dev')
 * - checks /health and /metrics
 * - runs test/check_ride_jobs.js, test/e2e_full_test.js
 * - prints a JSON summary at the end
 */

const { exec, spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

function runCmd(cmd, opts = {}) {
  return new Promise((resolve) => {
    exec(cmd, { maxBuffer: 1024 * 1024, ...opts }, (err, stdout, stderr) => {
      resolve({ err, stdout: stdout || '', stderr: stderr || '' });
    });
  });
}

function httpGet(url, timeout = 5000) {
  return new Promise((resolve) => {
    const req = http.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ ok: true, statusCode: res.statusCode, body: data }));
    });
    req.on('error', (e) => resolve({ ok: false, error: e.message }));
    req.setTimeout(timeout, () => {
      req.abort();
      resolve({ ok: false, error: 'timeout' });
    });
  });
}

(async () => {
  const root = path.resolve(__dirname, '..');
  process.chdir(root);
  const startArg = process.argv[2] === 'start';
  const summary = { startAt: new Date().toISOString(), steps: [] };

  // optionally start server
  let serverProc = null;
  if (startArg) {
    console.log('Starting server via `npm run dev` in background...');
    serverProc = spawn('npm', ['run', 'dev'], { detached: true, stdio: 'ignore' });
    serverProc.unref();
    summary.serverStarted = true;
    console.log('Server started (detached). Waiting 3s...');
    await new Promise((r) => setTimeout(r, 3000));
  }

  // step: health
  console.log('Checking /health...');
  const health = await httpGet('http://localhost:3000/health', 5000);
  summary.steps.push({ name: 'health', result: health.ok ? 'ok' : 'fail', info: health });

  if (!health.ok) {
    console.error('Health check failed:', health.error || health.statusCode);
    console.log(JSON.stringify(summary, null, 2));
    process.exit(3);
  }
  console.log('OK /health');

  // step: metrics
  console.log('Fetching /metrics...');
  const metrics = await httpGet('http://localhost:3000/metrics', 5000);
  summary.steps.push({ name: 'metrics', result: metrics.ok ? 'ok' : 'fail', snippet: metrics.body ? metrics.body.slice(0, 1000) : null });
  if (metrics.ok) {
    // quick parse for core gauges
    const hasDb = /taksibu_db_up/.test(metrics.body || '');
    const hasRedis = /taksibu_redis_up/.test(metrics.body || '');
    summary.metricsHasDb = hasDb;
    summary.metricsHasRedis = hasRedis;
    console.log('Metrics fetched; db gauge:', hasDb, 'redis gauge:', hasRedis);
  } else {
    console.warn('Metrics fetch failed:', metrics.error);
  }

  // step: run check_ride_jobs
  const checkJobsPath = path.join('test', 'check_ride_jobs.js');
  if (fs.existsSync(checkJobsPath)) {
    console.log('Running test/check_ride_jobs.js...');
    const r = await runCmd(`node ${checkJobsPath}`);
    summary.steps.push({ name: 'check_ride_jobs', result: r.err ? 'fail' : 'ok', stdout: r.stdout, stderr: r.stderr });
    console.log(r.stdout);
  } else {
    console.warn('Missing test/check_ride_jobs.js');
    summary.steps.push({ name: 'check_ride_jobs', result: 'missing' });
  }

  // step: e2e
  const e2ePath = path.join('test', 'e2e_full_test.js');
  if (fs.existsSync(e2ePath)) {
    console.log('Running E2E test (this may take ~1-2 minutes)...');
    // spawn e2e to stream output
    await new Promise((resolve) => {
      const p = spawn('node', [e2ePath], { stdio: 'inherit' });
      p.on('close', (code) => {
        summary.steps.push({ name: 'e2e_full_test', result: code === 0 ? 'ok' : 'fail', exitCode: code });
        resolve();
      });
    });
  } else {
    console.warn('Missing e2e_full_test.js');
    summary.steps.push({ name: 'e2e_full_test', result: 'missing' });
  }

  // optional: manual_auto_reject
  const manualPath = path.join('test', 'manual_auto_reject.js');
  if (fs.existsSync(manualPath)) {
    console.log('Running manual_auto_reject (sample) ...');
    const r = await runCmd(`node ${manualPath} 1`);
    summary.steps.push({ name: 'manual_auto_reject', result: r.err ? 'fail' : 'ok', stdout: r.stdout, stderr: r.stderr });
    console.log(r.stdout);
  } else {
    summary.steps.push({ name: 'manual_auto_reject', result: 'missing' });
  }

  summary.endAt = new Date().toISOString();
  console.log('\n===== SUMMARY =====');
  console.log(JSON.stringify(summary, null, 2));

  // decide exit code
  const anyFail = summary.steps.some(s => s.result === 'fail');
  process.exit(anyFail ? 2 : 0);
})();