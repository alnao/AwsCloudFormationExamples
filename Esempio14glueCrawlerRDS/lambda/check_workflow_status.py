import boto3

glue = boto3.client('glue')

def entrypoint(event, context):
    response = glue.get_workflow_run(Name=event['workflowName'],
                          RunId=event['Payload']['glueWf']['RunId'],
                          IncludeGraph=True)
    
    errors = []
    if response['Run']['Statistics']['FailedActions']  > 0:
        nodes = response['Run']['Graph']['Nodes']
        for node in nodes:
            if node['Type'] == 'JOB' and node['JobDetails']['JobRuns'][0]['JobRunState'] == 'FAILED':
                job_name = node['JobDetails']['JobRuns'][0]['JobName']
                message = node['JobDetails']['JobRuns'][0]['ErrorMessage']
                errors.append("Job %s failed with message: %s " % (job_name, message ) )
    if errors:
        error_info = " || ".join(errors)
    else:
        error_info=""
    

    return {'Status': response['Run']['Status'],
            'Statistics': response['Run']['Statistics'],
            'RunProperties': response['Run']['WorkflowRunProperties'],
            'error_info': error_info
            }
    