import boto3

glue = boto3.client('glue')

def entrypoint(event, context):

    res = glue.start_workflow_run(
        Name=event['workflowName']
    )
    runId = res['RunId']
    if event.get("runProperties"):
        glue.put_workflow_run_properties(
            Name=event['workflowName'],
            RunId=runId,
            RunProperties=event['runProperties']
        )
    return res