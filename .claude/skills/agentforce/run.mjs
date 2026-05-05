#!/usr/bin/env node
// Drives a multi-turn YAML spec against a deployed Agentforce agent over the
// in-org Invocable Action REST endpoint. Captures per-test transcripts as JSON
// for the caller (Claude) to judge against each turn's `expect`. Mechanical only —
// no judging, no LLM calls.
//
// Usage:
//   node run.mjs <spec.yaml> --org <ORG> [--out <dir>] [--concurrency <N>] [--api-version <vXX.X>]
//
// Output (per test): <out>/<test-name>.json with the full turn-by-turn transcript.
// Exits non-zero if any test had a REST-level failure (isSuccess=false or sf crashed).

import { spawn } from 'node:child_process';
import { parseArgs } from 'node:util';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

// ---------- Mini YAML parser ----------
// Handles only the subset used in agent-eval/*.yaml: top-level scalars and
// a `tests:` list, where each item is a mapping with optional nested `turns:` list.
// Keys are simple identifiers; values are quoted ('...' or "...", no escapes) or
// rest-of-line plain scalars. Comments start with `#` (preceded by whitespace or BOL).
function parseYAML(text) {
  const stripComment = (raw) => {
    let inS = false, inD = false;
    for (let j = 0; j < raw.length; j++) {
      const c = raw[j];
      if (c === "'" && !inD) inS = !inS;
      else if (c === '"' && !inS) inD = !inD;
      else if (c === '#' && !inS && !inD && (j === 0 || /\s/.test(raw[j - 1]))) {
        return raw.slice(0, j);
      }
    }
    return raw;
  };

  const lines = text.split('\n').map((raw, i) => {
    const stripped = stripComment(raw).replace(/\s+$/, '');
    if (!stripped.trim()) return null;
    const indent = stripped.match(/^ */)[0].length;
    return { lineNo: i + 1, indent, body: stripped.slice(indent) };
  }).filter(Boolean);

  let pos = 0;

  const parseScalar = (raw) => {
    const s = raw.trim();
    if (s === '') return '';
    if (s.length >= 2 && s[0] === "'" && s[s.length - 1] === "'") return s.slice(1, -1);
    if (s.length >= 2 && s[0] === '"' && s[s.length - 1] === '"') return s.slice(1, -1);
    return s;
  };

  const parseValue = (indent) => {
    if (pos >= lines.length || lines[pos].indent < indent) return null;
    if (lines[pos].body.startsWith('- ')) return parseList(indent);
    return parseMap(indent);
  };

  const parseList = (indent) => {
    const items = [];
    while (pos < lines.length && lines[pos].indent === indent && lines[pos].body.startsWith('- ')) {
      const cur = lines[pos];
      // Rewrite "- key: value" as a virtual map line at indent+2 so parseMap picks it up.
      lines[pos] = { ...cur, indent: indent + 2, body: cur.body.slice(2) };
      items.push(parseMap(indent + 2));
    }
    return items;
  };

  const parseMap = (indent) => {
    const obj = {};
    while (pos < lines.length && lines[pos].indent === indent && !lines[pos].body.startsWith('- ')) {
      const line = lines[pos];
      const m = line.body.match(/^([A-Za-z_][\w-]*):(?:\s+(.*))?\s*$/);
      if (!m) throw new Error(`YAML parse error at line ${line.lineNo}: ${line.body}`);
      const key = m[1];
      const inlineVal = m[2];
      pos++;
      if (inlineVal !== undefined && inlineVal !== '') {
        obj[key] = parseScalar(inlineVal);
      } else if (pos < lines.length && lines[pos].indent > indent) {
        obj[key] = parseValue(lines[pos].indent);
      } else {
        obj[key] = null;
      }
    }
    return obj;
  };

  return parseValue(0) ?? {};
}

// ---------- sf invocation ----------
function callAgent({ org, agent, apiVersion, userMessage, sessionId }) {
  return new Promise((res, rej) => {
    const inputs = sessionId ? { userMessage, sessionId } : { userMessage };
    const body = JSON.stringify({ inputs: [inputs] });
    const url = `/services/data/${apiVersion}/actions/custom/generateAiAgentResponse/${agent}`;
    const p = spawn('sf', [
      'api', 'request', 'rest', '-o', org, url,
      '-X', 'POST', '-H', 'Content-Type:application/json', '-b', '-',
    ]);
    let stdout = '', stderr = '';
    p.stdout.on('data', (d) => { stdout += d; });
    p.stderr.on('data', (d) => { stderr += d; });
    p.on('error', rej);
    p.on('close', (code) => {
      if (code !== 0) {
        rej(new Error(`sf exited ${code}: ${(stderr.trim() || stdout.trim()).slice(0, 800)}`));
        return;
      }
      try { res(JSON.parse(stdout)); }
      catch (e) { rej(new Error(`Non-JSON sf output: ${e.message}\n${stdout.slice(0, 500)}`)); }
    });
    p.stdin.end(body);
  });
}

const unwrapAgentResponse = (raw) => {
  if (typeof raw !== 'string') return raw == null ? null : String(raw);
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === 'object' && 'value' in parsed) return parsed.value;
  } catch { /* fall through */ }
  return raw;
};

// ---------- Per-test driver ----------
async function runTest({ test, org, agent, apiVersion, outDir }) {
  const turns = Array.isArray(test.turns) && test.turns.length
    ? test.turns
    : [{ turn: test.turn ?? null, say: test.say, expect: test.expect }];

  const transcript = {
    name: test.name,
    description: test.description ?? null,
    agent, org, apiVersion,
    sessionId: null,
    turns: [],
  };

  let sessionId = null;
  let allOk = true;

  for (const t of turns) {
    const start = Date.now();
    let resp = null, callError = null;
    try {
      resp = await callAgent({ org, agent, apiVersion, userMessage: t.say, sessionId });
    } catch (e) {
      callError = e.message;
    }
    const elapsedMs = Date.now() - start;

    if (callError) {
      transcript.turns.push({
        turn: t.turn ?? null, say: t.say, expect: t.expect ?? null,
        isSuccess: false, errors: callError, reply: null, rawAgentResponse: null, elapsedMs,
      });
      allOk = false;
      break;
    }

    const item = Array.isArray(resp) ? resp[0] : resp;
    const isSuccess = item?.isSuccess === true;
    const errors = item?.errors ?? null;
    const out = item?.outputValues ?? {};
    if (out.sessionId) sessionId = out.sessionId;
    transcript.sessionId = sessionId;
    const raw = out.agentResponse ?? null;

    transcript.turns.push({
      turn: t.turn ?? null, say: t.say, expect: t.expect ?? null,
      isSuccess, errors,
      reply: unwrapAgentResponse(raw),
      rawAgentResponse: raw,
      elapsedMs,
    });

    if (!isSuccess) { allOk = false; break; }
  }

  const path = resolve(outDir, `${test.name}.json`);
  await writeFile(path, JSON.stringify(transcript, null, 2) + '\n');
  return { name: test.name, path, ok: allOk, turnCount: transcript.turns.length };
}

// ---------- Async pool ----------
async function runPool(items, concurrency, fn) {
  const queue = items.slice();
  const out = [];
  const worker = async () => {
    while (queue.length) {
      const item = queue.shift();
      out.push(await fn(item));
    }
  };
  await Promise.all(Array.from({ length: Math.min(concurrency, items.length) || 1 }, worker));
  return out;
}

// ---------- Main ----------
const { values, positionals } = parseArgs({
  options: {
    org: { type: 'string' },
    out: { type: 'string', default: '/tmp/ae' },
    concurrency: { type: 'string', default: '4' },
    'api-version': { type: 'string', default: 'v66.0' },
  },
  allowPositionals: true,
});

if (positionals.length === 0 || !values.org) {
  console.error('Usage: node run.mjs <spec.yaml> --org <ORG> [--out <dir>] [--concurrency <N>] [--api-version <vXX.X>]');
  process.exit(2);
}

const specPath = positionals[0];
const spec = parseYAML(await readFile(specPath, 'utf8'));
if (!spec.agent || !Array.isArray(spec.tests)) {
  console.error(`Spec must declare top-level 'agent' and 'tests'. Got keys: ${Object.keys(spec).join(', ')}`);
  process.exit(2);
}

await mkdir(values.out, { recursive: true });

const concurrency = Math.max(1, parseInt(values.concurrency, 10));
console.error(`Running ${spec.tests.length} test(s) from ${specPath} against ${spec.agent} on ${values.org} (concurrency=${concurrency})`);
console.error(`Transcripts → ${values.out}/`);

let started = 0;
const results = await runPool(spec.tests, concurrency, async (test) => {
  const idx = ++started;
  const t0 = Date.now();
  console.error(`[${idx}/${spec.tests.length}] ${test.name} START`);
  try {
    const r = await runTest({
      test, org: values.org, agent: spec.agent,
      apiVersion: values['api-version'], outDir: values.out,
    });
    const took = ((Date.now() - t0) / 1000).toFixed(1);
    console.error(`[${idx}/${spec.tests.length}] ${test.name} ${r.ok ? 'OK' : 'REST_ERROR'} ${r.turnCount} turn(s) (${took}s) → ${r.path}`);
    return r;
  } catch (e) {
    console.error(`[${idx}/${spec.tests.length}] ${test.name} CRASH: ${e.message}`);
    return { name: test.name, ok: false, error: e.message };
  }
});

const failed = results.filter((r) => !r.ok);
console.error(`\nDone. ${results.length - failed.length}/${results.length} REST-OK.`);
if (failed.length) console.error(`Failed: ${failed.map((r) => r.name).join(', ')}`);
process.exit(failed.length ? 1 : 0);
