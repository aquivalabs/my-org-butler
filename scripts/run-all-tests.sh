#!/bin/bash
# Run all test suites and report results

echo "=== Apex Tests ==="
sf apex run test --test-level RunLocalTests --wait 30 --result-format human 2>&1 | grep -E "(Outcome|Pass Rate|Fail Rate|Tests Ran)"

echo ""
echo "=== Testing Center ==="
sf agent test run --api-name Regression_Test --wait 15 --json 2>&1 > /tmp/tc-results.json
python3 -c "
import json
with open('/tmp/tc-results.json') as f:
    content = f.read()
    d = json.loads(content[content.index('{'):])
r = d.get('result', {})
cases = r.get('testCases', [])
tp = ap = op = 0
for c in cases:
    num = c.get('testNumber', '?')
    utt = c.get('inputs', {}).get('utterance', '')[:70]
    results = {tr.get('name'): tr for tr in c.get('testResults', [])}
    t = results.get('topic_assertion', {})
    a = results.get('actions_assertion', {})
    o = results.get('output_validation', {}) or results.get('bot_response_rating', {})
    tr_ = t.get('result', '?')
    ar_ = a.get('result', '?')
    or_ = o.get('result', '?')
    if tr_ == 'PASS': tp += 1
    if ar_ == 'PASS': ap += 1
    if or_ == 'PASS': op += 1
    ok = tr_ == 'PASS' and ar_ == 'PASS' and or_ == 'PASS'
    print(f'{\"PASS\" if ok else \"FAIL\"} #{num} T:{tr_} A:{ar_} O:{or_} | {utt}')
    if ar_ != 'PASS' and a.get('actualValue'):
        print(f'   Expected: {a.get(\"expectedValue\",\"\")}')
        print(f'   Actual:   {a.get(\"actualValue\",\"\")}')
    if or_ != 'PASS' and o.get('actualValue'):
        print(f'   Outcome: {str(o.get(\"actualValue\",\"\"))[:200]}')
n = len(cases) or 1
print(f'\nTopic: {tp}/{n} ({100*tp//n}%) | Action: {ap}/{n} ({100*ap//n}%) | Outcome: {op}/{n} ({100*op//n}%)')
"

echo ""
echo "=== Promptfoo Demo Story ==="
(cd regressions/promptfoo && npx promptfoo@latest eval -c demo-story.yaml --env-file .env --output /tmp/demo-results.json 2>&1) | tail -5
python3 -c "
import json
data = json.load(open('/tmp/demo-results.json'))
for r in data.get('results',{}).get('results',[]):
    desc = r.get('description', r.get('vars',{}).get('utterance','?'))[:60]
    passed = r.get('success', False)
    if not passed:
        failures = [a.get('reason','?') for a in r.get('gradingResult',{}).get('componentResults',[]) if not a.get('pass')]
        print(f'FAIL: {desc}')
        for f in failures: print(f'      {f[:150]}')
    else:
        print(f'PASS: {desc}')
"

echo ""
echo "=== Promptfoo Regression ==="
(cd regressions/promptfoo && npx promptfoo@latest eval -c regression.yaml --env-file .env --output /tmp/regression-results.json 2>&1) | tail -5
python3 -c "
import json
data = json.load(open('/tmp/regression-results.json'))
for r in data.get('results',{}).get('results',[]):
    desc = r.get('description', r.get('vars',{}).get('utterance','?'))[:60]
    passed = r.get('success', False)
    if not passed:
        failures = [a.get('reason','?') for a in r.get('gradingResult',{}).get('componentResults',[]) if not a.get('pass')]
        print(f'FAIL: {desc}')
        for f in failures: print(f'      {f[:150]}')
    else:
        print(f'PASS: {desc}')
"
