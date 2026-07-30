#!/usr/bin/env python3
"""Turn `claude --output-format stream-json` into a readable GitHub Actions log.

Without this the whole run is one opaque step: `--output-format json` buffers
everything and emits a single blob at the end, so there is no way to see what
the loop is doing, or whether it is stuck in a rabbit hole.

Reads JSONL on stdin, writes human-readable lines to stdout (flushed per line,
or the Actions log shows nothing until the step ends), and keeps the raw stream
so lab/usage.py can do the accounting afterwards.
"""

import argparse
import json
import sys
import time

TOOL_ICON = {
    "Read": "📖", "Write": "📝", "Edit": "✏️", "Bash": "⚙️",
    "Glob": "🔍", "Grep": "🔍", "Task": "🤖", "TodoWrite": "📋",
    "WebFetch": "🌐", "WebSearch": "🌐",
}

# Tool inputs worth showing, in the order we try them.
SUMMARY_KEYS = ("file_path", "command", "pattern", "path", "query", "url",
                "prompt", "description", "old_string")


def shorten(text, limit):
    text = " ".join(str(text).split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


def tool_summary(name, payload):
    for key in SUMMARY_KEYS:
        if key in payload and payload[key]:
            return shorten(payload[key], 160)
    return shorten(json.dumps(payload, default=str), 120) if payload else ""


class Reporter:
    def __init__(self, raw_path):
        self.started = time.time()
        self.raw = open(raw_path, "w") if raw_path else None
        self.tools = 0
        self.turns = 0
        self.agents = 0

    def stamp(self):
        elapsed = int(time.time() - self.started)
        return f"[{elapsed // 60:3d}:{elapsed % 60:02d}]"

    def say(self, icon, text):
        print(f"{self.stamp()} {icon} {text}", flush=True)

    def handle(self, event):
        kind = event.get("type")

        if kind == "system" and event.get("subtype") == "init":
            model = event.get("model", "?")
            tools = len(event.get("tools") or [])
            self.say("🚀", f"session started · model={model} · {tools} tools")
            return

        if kind == "assistant":
            self.turns += 1
            for block in (event.get("message") or {}).get("content") or []:
                btype = block.get("type")
                if btype == "thinking":
                    thought = block.get("thinking") or block.get("text") or ""
                    if thought.strip():
                        self.say("💭", shorten(thought, 400))
                elif btype == "text":
                    text = block.get("text") or ""
                    if text.strip():
                        self.say("💬", shorten(text, 400))
                elif btype == "tool_use":
                    self.tools += 1
                    name = block.get("name", "?")
                    payload = block.get("input") or {}
                    if name in ("Task", "Workflow"):
                        self.agents += 1
                        kind = payload.get("subagent_type") or payload.get("name") or "agent"
                        self.say("🤖", f"SPAWN #{self.agents} {name}({kind}): "
                                       f"{tool_summary(name, payload)}")
                    else:
                        self.say(TOOL_ICON.get(name, "🔧"),
                                 f"{name}: {tool_summary(name, payload)}")
            return

        if kind == "user":
            for block in (event.get("message") or {}).get("content") or []:
                if block.get("type") != "tool_result":
                    continue
                content = block.get("content")
                if isinstance(content, list):
                    content = " ".join(
                        part.get("text", "") for part in content if isinstance(part, dict)
                    )
                marker = "❌" if block.get("is_error") else "↳"
                self.say(marker, shorten(content or "(empty)", 220))
            return

        if kind == "result":
            elapsed = int(time.time() - self.started)
            usage = event.get("usage") or {}
            self.say("🏁", (
                f"done · {event.get('subtype', '?')} · {elapsed // 60}m{elapsed % 60}s · "
                f"{event.get('num_turns', self.turns)} turns · {self.tools} tool calls · "
                f"agents={self.agents} · out={usage.get('output_tokens', 0):,} · "
                f"${event.get('total_cost_usd', 0) or 0:.2f}"
            ))
            if self.agents == 0:
                self.say("⚠️", "agents=0 - this wakeup did not orchestrate at all")
            if event.get("is_error") or event.get("subtype") not in (None, "success"):
                self.say("⚠️", "run did not end cleanly - see the ledger and the issue comment")

    def close(self):
        if self.raw:
            self.raw.close()
        elapsed = int(time.time() - self.started)
        print(f"\n=== stream ended after {elapsed // 60}m{elapsed % 60}s, "
              f"{self.turns} assistant turns, {self.tools} tool calls ===", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw", help="also write the untouched JSONL here")
    args = parser.parse_args()

    reporter = Reporter(args.raw)
    try:
        for line in sys.stdin:
            if reporter.raw:
                reporter.raw.write(line)
                reporter.raw.flush()
            line = line.strip()
            if not line:
                continue
            try:
                reporter.handle(json.loads(line))
            except json.JSONDecodeError:
                # Not every line is guaranteed to be an event; show it rather
                # than swallow it, since it may be the error that matters.
                print(f"{reporter.stamp()} ·  {shorten(line, 200)}", flush=True)
    finally:
        reporter.close()


if __name__ == "__main__":
    main()
