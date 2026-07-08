"""
Fire-and-forget sub-agent dispatch via AgentCore Runtime.

Called by the orchestrator to start a sub-agent in its own AgentCore
session. The sub-agent runs independently with its own IAM role and
idle timeout. Returns immediately after starting the session.

Requires SUBAGENT_RUNTIME_ARN environment variable.
"""

import argparse
import json
import os
import sys

import boto3


def dispatch(
    prompt: str,
    status_issue: int | None = None,
    session_id: str | None = None,
) -> str:
    """Invoke the sub-agent runtime and return the session ID."""
    runtime_arn = os.environ.get("SUBAGENT_RUNTIME_ARN")
    if not runtime_arn:
        print("ERROR: SUBAGENT_RUNTIME_ARN not set. Are you running in AgentCore?", file=sys.stderr)
        print("For local dispatch, use the Agent tool instead.", file=sys.stderr)
        sys.exit(1)

    region = os.environ.get("AWS_REGION", "us-west-2")
    orchestrator_session = os.environ.get("ORCHESTRATOR_SESSION_ID")

    client = boto3.client("bedrock-agentcore", region_name=region)

    payload: dict = {
        "prompt": prompt,
    }
    if status_issue is not None:
        payload["status_issue"] = status_issue
    if orchestrator_session:
        payload["orchestrator_session_id"] = orchestrator_session

    invoke_kwargs: dict = {
        "agentRuntimeArn": runtime_arn,
        "qualifier": "DEFAULT",
        "payload": json.dumps(payload).encode(),
    }
    if session_id:
        invoke_kwargs["runtimeSessionId"] = session_id

    response = client.invoke_agent_runtime(**invoke_kwargs)

    session_id_out = response.get("runtimeSessionId", "unknown")
    print(f"Sub-agent dispatched successfully.")
    print(f"  Session ID: {session_id_out}")
    print(f"  Runtime:    {runtime_arn}")
    if status_issue:
        print(f"  Status issue: #{status_issue}")
    if orchestrator_session:
        print(f"  Orchestrator: {orchestrator_session}")
    return session_id_out


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Dispatch a sub-agent via AgentCore")
    parser.add_argument("--prompt", required=True, help="Full sub-agent instruction prompt")
    parser.add_argument("--status-issue", type=int, help="GitHub issue number for status updates")
    parser.add_argument(
        "--session-id",
        help=(
            "Pin the AgentCore runtimeSessionId. Use when re-dispatching "
            "a sub-agent to maintain session continuity."
        ),
    )
    args = parser.parse_args()

    dispatch(
        prompt=args.prompt,
        status_issue=args.status_issue,
        session_id=args.session_id,
    )
