#!/usr/bin/env python3
"""
E2E tests for set_agent_status / clear_agent_status socket commands.

Tests that:
  1. set_agent_status sets the "agent" key in statusEntries
  2. Each valid status (running/waiting/done/error) is accepted
  3. Unknown status values return an error
  4. clear_agent_status removes the "agent" key
  5. Repeated same-status calls are deduped (no-op)
  6. Case-insensitive parsing works

Usage:
    python3 tests/test_agent_status.py

Requirements:
    - cmux must be running with CMUX_SOCKET_MODE=allowAll
"""

import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cmux import cmux, cmuxError


PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"

results = []


def check(name: str, condition: bool, detail: str = ""):
    icon = PASS if condition else FAIL
    print(f"  [{icon}] {name}" + (f" — {detail}" if detail else ""))
    results.append((name, condition))


def send_raw(client: cmux, cmd: str) -> str:
    """Send a raw socket command and return the response string."""
    return client._send_command(cmd)


def get_status_value(client: cmux, key: str) -> str | None:
    """Return the value of a status entry by key, or None if absent."""
    raw = send_raw(client, "list_status")
    for line in raw.splitlines():
        if line.startswith(f"{key}="):
            return line.split("=", 1)[1].split(" ")[0]  # strip trailing icon/color
    return None


def run_tests():
    client = cmux()
    client.connect()

    print("\n=== Agent Status E2E Tests ===\n")

    # --- Baseline: clear any existing agent status ---
    send_raw(client, "clear_agent_status")
    time.sleep(0.05)

    # 1. set_agent_status running
    print("1. Basic status setting")
    resp = send_raw(client, "set_agent_status running")
    check("set_agent_status running returns OK", resp.strip() == "OK", resp.strip())
    time.sleep(0.1)
    val = get_status_value(client, "agent")
    check("agent status entry is 'running'", val == "running", f"got: {val!r}")

    # 2. Transition: running → done
    print("\n2. Status transitions")
    for status in ["waiting", "done", "error"]:
        resp = send_raw(client, f"set_agent_status {status}")
        check(f"set_agent_status {status} returns OK", resp.strip() == "OK", resp.strip())
        time.sleep(0.1)
        val = get_status_value(client, "agent")
        check(f"agent status is now '{status}'", val == status, f"got: {val!r}")

    # 3. Case-insensitive parsing
    print("\n3. Case-insensitive input")
    resp = send_raw(client, "set_agent_status RUNNING")
    check("RUNNING (uppercase) accepted", resp.strip() == "OK", resp.strip())
    time.sleep(0.1)
    val = get_status_value(client, "agent")
    check("stored as lowercase 'running'", val == "running", f"got: {val!r}")

    # 4. Invalid status value
    print("\n4. Invalid status value")
    resp = send_raw(client, "set_agent_status invalid_status")
    check("unknown status returns ERROR", resp.strip().startswith("ERROR"), resp.strip())
    time.sleep(0.05)
    val = get_status_value(client, "agent")
    check("agent status unchanged after bad input", val == "running", f"got: {val!r}")

    # 5. Missing argument
    print("\n5. Missing argument")
    resp = send_raw(client, "set_agent_status")
    check("missing arg returns ERROR", resp.strip().startswith("ERROR"), resp.strip())

    # 6. Deduplication (same status → no-op)
    print("\n6. Deduplication")
    send_raw(client, "set_agent_status done")
    time.sleep(0.05)
    before = get_status_value(client, "agent")
    resp = send_raw(client, "set_agent_status done")  # same again
    check("same status returns OK (no-op)", resp.strip() == "OK", resp.strip())
    time.sleep(0.05)
    after = get_status_value(client, "agent")
    check("status unchanged after dedup call", before == after == "done", f"before={before!r} after={after!r}")

    # 7. clear_agent_status
    print("\n7. Clearing agent status")
    resp = send_raw(client, "clear_agent_status")
    check("clear_agent_status returns OK", resp.strip().startswith("OK"), resp.strip())
    time.sleep(0.1)
    val = get_status_value(client, "agent")
    check("agent status entry removed", val is None, f"got: {val!r}")

    # 8. clear when already empty
    print("\n8. Clear when already empty")
    resp = send_raw(client, "clear_agent_status")
    check("clear on empty returns OK", resp.strip().startswith("OK"), resp.strip())

    client.close()

    # --- Summary ---
    total = len(results)
    passed = sum(1 for _, ok in results if ok)
    print(f"\n{'='*34}")
    print(f"  {passed}/{total} tests passed")
    if passed < total:
        print(f"\n  Failed:")
        for name, ok in results:
            if not ok:
                print(f"    ✗ {name}")
    print()
    return passed == total


if __name__ == "__main__":
    ok = run_tests()
    sys.exit(0 if ok else 1)
