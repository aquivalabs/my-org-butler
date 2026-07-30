#!/usr/bin/env python3
"""Ask the same questions of two orgs and diff the answers.

The oracle for the autonomous loop. Rather than hand-authoring expected output
for every case, we treat one org as the control (current agent) and the other as
the candidate (my changes), then diff -- the same trick as pixel-diffing a Swift
rewrite against the Electron original.

Two signals come out:
  hard  -- assertions in the case file that either pass or fail (deterministic)
  soft  -- cases where candidate and control disagree (needs a human/model read)

Usage:
    run_eval.py --cases cases.json --control my-org-butler_DEV --candidate butler-lab
    run_eval.py --cases cases.json --candidate butler-lab        # single org
"""

import argparse
import concurrent.futures as futures
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import trace

API_VERSION = "v66.0"
MAX_ATTEMPTS = 3
FLAKE_MARKERS = ("unexpected error", "Something went wrong")


# ORG ACCESS

def org_credentials(alias):
    env = dict(os.environ, SF_TEMP_SHOW_SECRETS="true")
    proc = subprocess.run(
        ["sf", "org", "display", "--target-org", alias, "--json"],
        capture_output=True, text=True, env=env,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"cannot read org {alias}: {proc.stderr[:300]}")

    result = json.loads(proc.stdout)["result"]
    token = result.get("accessToken", "")
    if not token or "REDACTED" in token:
        raise RuntimeError(f"no usable access token for {alias}")

    return token, result["instanceUrl"]


def soql_scalar(creds, query):
    """Run SOQL against an org and reduce it to the one value a case asserts on.

    Lets a case say "whatever this org actually contains" instead of hardcoding a
    row count that is only true in one org (finding F-006). A COUNT() query comes
    back with an empty `records` list and the answer in `totalSize`; anything else
    yields the first field of the first row.
    """
    token, base = creds
    request = urllib.request.Request(
        f"{base}/services/data/{API_VERSION}/query/?q={urllib.parse.quote(query)}",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        body = json.load(response)

    records = body.get("records") or []
    if not records:
        return str(body.get("totalSize", ""))

    fields = [(k, v) for k, v in records[0].items() if k != "attributes"]
    return str(fields[0][1]) if fields else str(body.get("totalSize", ""))


def ask(creds, message, session_id=None, attempts=MAX_ATTEMPTS):
    """One turn. Retries past the runtime's intermittent cold-call failures.

    Note: `attempts=1` is for continuation turns. F-018 (platform-side, reproduces on
    the control org) makes turn 2+ of some sessions fail deterministically, and
    re-sending on that same session NEVER recovers -- so retrying there is three
    guaranteed-wasted calls. Retrying is the conversation's job; see conversation().
    """
    token, base = creds
    payload = {"userMessage": message}
    if session_id:
        payload["sessionId"] = session_id

    request = urllib.request.Request(
        f"{base}/services/data/{API_VERSION}/actions/custom/generateAiAgentResponse/MyOrgButler",
        data=json.dumps({"inputs": [payload]}).encode(),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )

    last_error = ""
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=240) as response:
                body = json.load(response)
            values = body[0].get("outputValues") or {}
            raw = values.get("agentResponse") or ""
            text = json.loads(raw).get("value", raw) if raw.startswith("{") else raw
            if text and not any(m in text for m in FLAKE_MARKERS):
                return {"text": text, "session": values.get("sessionId"), "attempts": attempt}
            last_error = text or "empty response"
        except (urllib.error.URLError, ValueError, KeyError, IndexError) as exc:
            last_error = f"{type(exc).__name__}: {exc}"
        if attempt < attempts:
            time.sleep(4 * attempt)

    return {"text": "", "session": None, "attempts": attempts, "error": last_error}


def play(creds, turns):
    """Play every turn of one conversation in one session."""
    session, transcript = None, []
    for index, turn in enumerate(turns):
        answer = ask(creds, turn, session, attempts=MAX_ATTEMPTS if index == 0 else 1)
        session = answer.get("session") or session
        transcript.append({"user": turn, "agent": answer["text"],
                           "attempts": answer["attempts"], "error": answer.get("error")})

    return session, transcript


def conversation(creds, turns):
    """Replay the WHOLE conversation in a FRESH session when a later turn comes back empty.

    The retry unit has to be the conversation, not the turn. F-018 poisons a session so
    that turn 2 fails every time it is re-sent, but the same conversation replayed from
    turn 1 in a new session can succeed -- measured: 6 pairs failed 6/6 on re-send, while
    other sessions with the identical turn 2 answered fine. Without this, every multi-turn
    case is capped by a platform bug rather than by the agent, which is the whole point of
    the oracle.
    """
    result = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        session, transcript = play(creds, turns)
        complete = all(turn["agent"] for turn in transcript)
        if result is None:
            result = (session, transcript, attempt)
        if complete:
            result = (session, transcript, attempt)
            break
        # Note: a single-turn case already exhausted its retries inside ask(), so
        # replaying it adds nothing but load.
        if len(turns) == 1:
            break

    return result


# SCORING

def found(needle, text, as_regex):
    if as_regex:
        return re.search(needle, text, re.I | re.S) is not None
    return needle.lower() in text.lower()


def check(case, text, derived=()):
    """Deterministic assertions. Absent assertions => no hard verdict.

    `derived` carries expectations resolved from the org itself at run time, so a
    data-dependent case asserts against that org's truth rather than a constant.
    """
    result = {"verdict": "unscored", "failed": []}

    required = list(case.get("expect", [])) + list(derived)
    forbidden = case.get("reject", [])
    if not required and not forbidden:
        return result

    as_regex = case.get("regex", False)
    for needle in required:
        if not found(needle, text, as_regex):
            result["failed"].append(f"missing: {needle}")
    for needle in forbidden:
        if found(needle, text, as_regex):
            result["failed"].append(f"present but forbidden: {needle}")

    result["verdict"] = "fail" if result["failed"] else "pass"
    return result


def run_case(case, orgs):
    """A case is a list of turns; the session carries across them, per org.

    Note: a case flagged `mutates` writes to the org (stores a memory, creates a
    record). Those never run against the control -- contaminating the control is
    the one thing that would destroy the oracle.
    """
    record = {"id": case["id"], "tags": case.get("tags", []),
              "mutates": bool(case.get("mutates")), "orgs": {}}

    targets = dict(orgs)
    if record["mutates"]:
        targets.pop("control", None)
        record["control_skipped"] = "mutating case - control is read-only"

    for label, creds in targets.items():
        derived = []
        for query in case.get("expect_soql", []):
            try:
                derived.append(soql_scalar(creds, query))
            except (urllib.error.URLError, ValueError, KeyError, IndexError) as exc:
                record.setdefault("derive_errors", []).append(f"{label}: {type(exc).__name__}: {exc}")

        session, transcript, replays = conversation(creds, case["turns"])
        final = transcript[-1]["agent"] if transcript else ""
        record["orgs"][label] = {"transcript": transcript, "final": final, "session": session,
                                 "replays": replays, "derived_expect": derived,
                                 **check(case, final, derived)}

    compare(record)
    return record


def compare(record):
    """Cross-org flags. Re-run after tracing, which can move a verdict."""
    if "control" in record["orgs"] and "candidate" in record["orgs"]:
        control = record["orgs"]["control"]
        candidate = record["orgs"]["candidate"]
        # Note: free-text answers differ in wording on almost every case, so a text
        # diff flags everything and means nothing (setup run: 20 of 22 "diverged").
        # The signal worth acting on is a VERDICT flip, and the one that blocks a
        # release is a regression: control passes where the candidate fails.
        record["text_diverged"] = control["final"].strip() != candidate["final"].strip()
        record["diverged"] = control["verdict"] != candidate["verdict"]
        record["regression"] = control["verdict"] == "pass" and candidate["verdict"] == "fail"
        record["improvement"] = control["verdict"] == "fail" and candidate["verdict"] == "pass"


# ACTION TRACES

def attach_traces(records, cases, orgs, timeout):
    """Second phase: recover every session's action trace, then fold in the verdict.

    Deliberately after all cases have been sent. Data Cloud ingests the audit DMOs
    in batches minutes behind live, so paying that lag per case would serialize the
    suite behind it; paid once for the whole suite it is a flat tax.
    """
    expected = {c["id"]: c.get("expect_actions") for c in cases}

    for label, creds in orgs.items():
        sessions = [r["orgs"][label]["session"] for r in records
                    if label in r["orgs"] and r["orgs"][label].get("session")]
        if not sessions:
            continue

        traces = trace.fetch_traces(creds, sessions, timeout=timeout)
        for record in records:
            org = record["orgs"].get(label)
            if not org or not org.get("session"):
                continue
            found = traces.get(org["session"])
            org["trace"] = found
            # Note: the trace's own `actions` is None when inconclusive, where deriving it
            # from the (empty) step list would instead assert "called nothing" -- the exact
            # confusion between missing data and a real result this oracle must avoid.
            org["actions"] = found.get("actions") if found else None

            outcome = trace.check_actions(expected.get(record["id"]), found)
            if outcome["verdict"] == "inconclusive":
                org["trace_inconclusive"] = True
            elif outcome["verdict"] == "fail":
                org["verdict"] = "fail"
                org["failed"].extend(outcome["failed"])
            elif outcome["verdict"] == "pass" and org["verdict"] == "unscored":
                org["verdict"] = "pass"

    for record in records:
        compare(record)


# MAIN

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cases", required=True)
    parser.add_argument("--candidate", required=True, help="org alias under test")
    parser.add_argument("--control", help="org alias to diff against (optional)")
    parser.add_argument("--out", default="-")
    parser.add_argument("--workers", type=int, default=6,
                        help="parallel cases; the REST endpoint handled 5 concurrent cleanly")
    parser.add_argument("--tag", help="only run cases carrying this tag")
    parser.add_argument("--read-only", action="store_true",
                        help="drop mutating cases entirely - required when the target IS the control org")
    parser.add_argument("--trace", action="store_true",
                        help="recover action traces from the audit DMOs and score expect_actions")
    parser.add_argument("--trace-timeout", type=int, default=trace.DEFAULT_TIMEOUT,
                        help="seconds to wait for Data Cloud to ingest the traces")
    args = parser.parse_args()

    cases = json.load(open(args.cases))
    if args.tag:
        cases = [c for c in cases if args.tag in c.get("tags", [])]
    if args.read_only:
        cases = [c for c in cases if not c.get("mutates")]
    if not cases:
        sys.exit("no cases selected")

    orgs = {"candidate": org_credentials(args.candidate)}
    if args.control:
        orgs["control"] = org_credentials(args.control)

    started = time.time()
    with futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        records = list(pool.map(lambda c: run_case(c, orgs), cases))

    if args.trace:
        attach_traces(records, cases, orgs, args.trace_timeout)

    # Note: a case tagged `blocked` is failing on a platform bug outside this
    # project's control (F-007, Data Library chunking). It still runs -- so it
    # flips green by itself when the platform is fixed -- but it must not drag the
    # score down every night for something no change here can affect.
    def is_blocked(record):
        return "blocked" in record.get("tags", [])

    # Note: without --trace, `expect_actions` is not evaluated at all, so a routing case
    # can pass on its text assertions while the action it exists to check never ran. That
    # happened for real to web-search-offtopic on 2026-07-30 and was read as an
    # improvement. Say so out loud rather than letting a silent pass look like proof.
    unverified = [c["id"] for c in cases if c.get("expect_actions")] if not args.trace else []

    scored = [r for r in records
              if r["orgs"]["candidate"]["verdict"] != "unscored" and not is_blocked(r)]
    passed = [r for r in scored if r["orgs"]["candidate"]["verdict"] == "pass"]
    blocked = [r for r in records if is_blocked(r)]
    report = {
        "cases": len(records),
        "scored": len(scored),
        "passed": len(passed),
        "score": round(100 * len(passed) / len(scored), 1) if scored else None,
        "failed_ids": [r["id"] for r in scored
                       if r["orgs"]["candidate"]["verdict"] == "fail"],
        "blocked": len(blocked),
        "blocked_ids": [r["id"] for r in blocked],
        "regressions": sum(1 for r in records if r.get("regression")),
        "regression_ids": [r["id"] for r in records if r.get("regression")],
        "improvements": sum(1 for r in records if r.get("improvement")),
        "improvement_ids": [r["id"] for r in records if r.get("improvement")],
        # Note: an inconclusive trace means Data Cloud had not ingested it yet. It is
        # deliberately counted separately and never folded into failures -- ingestion
        # lag must not read as a defect.
        "trace_inconclusive": sum(1 for r in records
                                  if r["orgs"]["candidate"].get("trace_inconclusive")),
        "trace_inconclusive_ids": [r["id"] for r in records
                                   if r["orgs"]["candidate"].get("trace_inconclusive")],
        "guardrail_blocked_ids": [r["id"] for r in records
                                  if (r["orgs"]["candidate"].get("trace") or {}).get("status")
                                  == trace.STATUS_GUARDRAIL],
        "actions_unverified_ids": unverified,
        # Note: a case that only passed after its conversation was replayed in a fresh
        # session hit F-018. Report it -- a silent replay would hide how much of the
        # multi-turn corpus depends on getting a lucky session.
        "replayed_ids": [r["id"] for r in records
                         for o in r["orgs"].values() if (o.get("replays") or 1) > 1],
        "diverged": sum(1 for r in records if r.get("diverged")),
        "text_diverged": sum(1 for r in records if r.get("text_diverged")),
        "errors": sum(1 for r in records
                      for o in r["orgs"].values()
                      for t in o["transcript"] if t.get("error")),
        "seconds": round(time.time() - started, 1),
        "candidate": args.candidate,
        "control": args.control,
        "records": records,
    }

    text = json.dumps(report, indent=2)
    if args.out == "-":
        print(text)
    else:
        open(args.out, "w").write(text)
        summary = f"{report['passed']}/{report['scored']} passed"
        if report["score"] is not None:
            summary += f" ({report['score']}%)"
        print(f"{summary}, {report['regressions']} regressions, "
              f"{report['improvements']} improvements, {report['blocked']} blocked, "
              f"{report['errors']} errors, {report['seconds']}s -> {args.out}")
        if report["failed_ids"]:
            print(f"  failed:      {', '.join(report['failed_ids'])}")
        if report["regression_ids"]:
            print(f"  REGRESSIONS: {', '.join(report['regression_ids'])}")
        if report["improvement_ids"]:
            print(f"  improved:    {', '.join(report['improvement_ids'])}")
        if report["actions_unverified_ids"]:
            print(f"  NO TRACE, so expect_actions was NOT checked on: "
                  f"{', '.join(report['actions_unverified_ids'])}")
        if report["trace_inconclusive_ids"]:
            print(f"  trace inconclusive (NOT failures): "
                  f"{', '.join(report['trace_inconclusive_ids'])}")
        if report["replayed_ids"]:
            print(f"  replayed in a fresh session (F-018): "
                  f"{', '.join(sorted(set(report['replayed_ids'])))}")
        if report["guardrail_blocked_ids"]:
            print(f"  guardrail short-circuit: {', '.join(report['guardrail_blocked_ids'])}")


if __name__ == "__main__":
    main()
