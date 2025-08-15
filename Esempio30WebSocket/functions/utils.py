import json

def response(status, message=None, error=None):
    body = {}
    if message:
        body['message'] = message
    if error:
        body['error'] = error
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token"
        },
        "body": json.dumps(body)
    }
