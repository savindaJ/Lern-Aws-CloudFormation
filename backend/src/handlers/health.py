import json
import os
from datetime import datetime, timezone


def handler(event, context):
    stage = os.environ.get("STAGE", "unknown")
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "status": "ok",
                "service": "health",
                "stage": stage,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "requestId": getattr(context, "aws_request_id", None),
            }
        ),
    }
