import json

def response(status, message=None, error=None):
    body = {}
    if message:
        body['message'] = message
    if error:
        body['error'] = error
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }
