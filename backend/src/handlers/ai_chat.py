import json
import os

import boto3


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _invoke_bedrock(message: str) -> str:
    model_id = os.environ.get(
        "BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0"
    )
    region = os.environ.get("AWS_REGION", "us-west-2")
    client = boto3.client("bedrock-runtime", region_name=region)

    payload = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 512,
        "messages": [{"role": "user", "content": message}],
    }

    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(payload),
    )
    result = json.loads(response["body"].read())
    return result["content"][0]["text"]


def handler(event, context):
    stage = os.environ.get("STAGE", "unknown")

    try:
        raw_body = event.get("body") or "{}"
        if event.get("isBase64Encoded"):
            import base64

            raw_body = base64.b64decode(raw_body).decode("utf-8")
        body = json.loads(raw_body) if isinstance(raw_body, str) else raw_body
    except json.JSONDecodeError:
        return _response(400, {"error": "Invalid JSON body"})

    message = (body.get("message") or "").strip()
    if not message:
        return _response(400, {"error": "Field 'message' is required"})

    use_bedrock = os.environ.get("USE_BEDROCK", "false").lower() == "true"

    try:
        if use_bedrock:
            reply = _invoke_bedrock(message)
            source = "bedrock"
        else:
            reply = f"[{stage}] Echo: {message}"
            source = "mock"
    except Exception as exc:
        return _response(
            502,
            {
                "error": "AI gateway invocation failed",
                "detail": str(exc),
                "stage": stage,
            },
        )

    return _response(
        200,
        {
            "reply": reply,
            "source": source,
            "stage": stage,
            "requestId": getattr(context, "aws_request_id", None),
        },
    )
