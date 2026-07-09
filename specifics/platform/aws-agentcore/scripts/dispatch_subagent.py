"""
Fire-and-forget sub-agent dispatch via AgentCore Runtime.

Called by the orchestrator to start a sub-agent in its own AgentCore
session. `invoke_agent_runtime` is SYNCHRONOUS — it blocks until the
sub-agent finishes streaming its full response (minutes for a real task).
The orchestrator invokes this script through a Bash tool that has a short
timeout, so a blocking call would be killed mid-flight and the sub-agent
would never receive its payload.

To make dispatch truly fire-and-forget, the parent process pins a session
ID, spawns a fully detached worker (new session, no controlling terminal)
that performs the blocking invoke, then returns immediately. The worker's
output goes to a log file under the workspace for post-hoc inspection.

Requires SUBAGENT_RUNTIME_ARN environment variable.
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import boto3


def _pin_session_id(status_issue: int | None) -> str:
    """Deterministic-ish, >=33 char session ID (AgentCore minimum).

    Includes the status issue and a coarse timestamp so re-dispatches are
    distinguishable in logs. No randomness (unavailable in some contexts).
    """
    stamp = int(time.time())
    base = f"subagent-issue-{status_issue or 'none'}-{stamp}"
    # AgentCore requires runtimeSessionId >= 33 chars; pad if short.
    return base.ljust(33, "-")


def _worker(runtime_arn: str, region: str, payload_json: str, session_id: str):
    """Blocking invoke — runs in the detached child. Never returns to caller."""
    client = boto3.client("bedrock-agentcore", region_name=region)
    try:
        client.invoke_agent_runtime(
            agentRuntimeArn=runtime_arn,
            qualifier="DEFAULT",
            runtimeSessionId=session_id,
            payload=payload_json.encode(),
        )
        print(f"[worker] sub-agent invocation completed: session={session_id}")
    except Exception as exc:  # noqa: BLE001 — worker is detached, log and exit
        print(f"[worker] sub-agent invocation FAILED: {exc}", file=sys.stderr)
        sys.exit(1)


def dispatch(
    prompt: str,
    status_issue: int | None = None,
    spec_pr: int | None = None,
    session_id: str | None = None,
) -> str:
    """Spawn a detached worker to invoke the sub-agent; return the session ID.

    Returns immediately — does NOT wait for the sub-agent to finish.
    """
    runtime_arn = os.environ.get("SUBAGENT_RUNTIME_ARN")
    if not runtime_arn:
        print("ERROR: SUBAGENT_RUNTIME_ARN not set. Are you running in AgentCore?", file=sys.stderr)
        print("For local dispatch, use the Agent tool instead.", file=sys.stderr)
        sys.exit(1)

    region = os.environ.get("AWS_REGION", "us-west-2")
    orchestrator_session = os.environ.get("ORCHESTRATOR_SESSION_ID")

    payload: dict = {"prompt": prompt}
    # Unconditional marker: this script only ever runs to dispatch a sub-agent,
    # so every payload it emits is, by definition, an orchestrator dispatch. The
    # sub-agent's /multi-repo-loop cloud guard keys off the exported
    # $DISPATCHED_BY_ORCHESTRATOR to distinguish itself from a top-level session.
    # (Do NOT overload orchestrator_session_id for this — it is optional parent
    # pinning and is absent unless the orchestrator's own env carries it.)
    payload["dispatched_by_orchestrator"] = True
    if status_issue is not None:
        payload["status_issue"] = status_issue
    if spec_pr is not None:
        payload["spec_pr"] = spec_pr
    if orchestrator_session:
        payload["orchestrator_session_id"] = orchestrator_session

    sid = session_id or _pin_session_id(status_issue)
    payload_json = json.dumps(payload)

    # Log dir for the detached worker's stdout/stderr.
    workspace = Path(os.environ.get("WORKSPACE_DIR", "/tmp/workspace"))
    log_dir = workspace / "dispatch-logs"
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
    except Exception:
        log_dir = Path("/tmp")
    log_path = log_dir / f"dispatch-{sid}.log"

    # Spawn a fully detached worker (new session → survives parent exit and
    # the orchestrator's Bash-tool timeout). It re-invokes this same script
    # in --worker mode with the pinned session ID.
    log_fh = open(log_path, "ab", buffering=0)
    subprocess.Popen(
        [
            sys.executable,
            os.path.abspath(__file__),
            "--worker",
            "--prompt",
            prompt,
            "--session-id",
            sid,
            "--runtime-arn",
            runtime_arn,
            "--region",
            region,
            "--payload-json",
            payload_json,
        ],
        stdout=log_fh,
        stderr=log_fh,
        stdin=subprocess.DEVNULL,
        start_new_session=True,  # detach: no controlling terminal, own process group
        close_fds=True,
    )

    print("Sub-agent dispatched (detached, fire-and-forget).")
    print(f"  Session ID: {sid}")
    print(f"  Runtime:    {runtime_arn}")
    print(f"  Worker log: {log_path}")
    if status_issue:
        print(f"  Status issue: #{status_issue}")
    if spec_pr:
        print(f"  Spec PR: #{spec_pr}")
    if orchestrator_session:
        print(f"  Orchestrator: {orchestrator_session}")
    return sid


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Dispatch a sub-agent via AgentCore")
    parser.add_argument("--prompt", required=True, help="Full sub-agent instruction prompt")
    parser.add_argument("--status-issue", type=int, help="GitHub issue number for status updates")
    parser.add_argument("--spec-pr", type=int, help="Metarepo spec PR number (sub-agent labels this PR on completion)")
    parser.add_argument(
        "--session-id",
        help=(
            "Pin the AgentCore runtimeSessionId. Use when re-dispatching "
            "a sub-agent to maintain session continuity."
        ),
    )
    # Internal: detached worker mode. Not for direct use by the orchestrator.
    parser.add_argument("--worker", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--runtime-arn", help=argparse.SUPPRESS)
    parser.add_argument("--region", help=argparse.SUPPRESS)
    parser.add_argument("--payload-json", help=argparse.SUPPRESS)
    args = parser.parse_args()

    if args.worker:
        _worker(
            runtime_arn=args.runtime_arn,
            region=args.region,
            payload_json=args.payload_json,
            session_id=args.session_id,
        )
    else:
        dispatch(
            prompt=args.prompt,
            status_issue=args.status_issue,
            spec_pr=args.spec_pr,
            session_id=args.session_id,
        )
