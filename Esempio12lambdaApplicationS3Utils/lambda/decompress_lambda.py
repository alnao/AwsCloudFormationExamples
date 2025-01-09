import boto3
import zipfile
import tarfile
from io import BytesIO
import io
import os
from boto3 import resource

s3_client = boto3.client('s3')
s3_resource = resource('s3')

def handler(event, context):
    print(event)
    # Get bucket name and file key from the S3 event
    if 'Records' in event:
        bucket = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']
    else:
        bucket = event['detail']['bucket']['name']
        s3_key = event['detail']['object']['key']
    
    print("Bucket: " , bucket , " S3Key: ", s3_key )
    file_name = os.path.basename( s3_key )
    print("Filename: " + file_name )

    destination_bucket = s3_resource.Bucket( bucket ) 
    dest_path=os.environ['DezippedFolderName'] # "UNZIPPED"

    if file_name=="":
        return {'statusCode': 400}
    if file_name.lower().endswith('.zip'):
        unzip_files(s3_key, bucket, destination_bucket,dest_path)
    elif file_name.lower().endswith(('.tar', '.tar.gz', '.tgz')):
        untar_files(s3_key, bucket, destination_bucket,dest_path)
    else:
        copy_file_as_is(s3_key, bucket, destination_bucket,dest_path)
    return {
        'statusCode': 200,
        'body': f'Successfully unzipped and uploaded contents of {s3_key}'
    }

def copy_file_as_is(file_key, source_bucketname, destination_bucket ,dest_path):
    source_file = s3_resource.Object(bucket_name=source_bucketname, key=file_key)
    file_content = source_file.get()["Body"].read()
    
    # Get just the filename without the path
    file_name = os.path.basename(file_key)
    final_file_path = dest_path + "/" + file_name
    
    print(f"Copying file directly: {file_key} --> {final_file_path}")
    
    # Upload the file to the destination
    destination_bucket.upload_fileobj(
        io.BytesIO(file_content),
        final_file_path,
        ExtraArgs={"ContentType": "text/plain"}
    )

def unzip_files(file_key, source_bucketname, destination_bucket , dest_path):
    zipped_file = s3_resource.Object(bucket_name=source_bucketname, key=file_key)
    buffer = BytesIO(zipped_file.get()["Body"].read())
    zipped = zipfile.ZipFile(buffer,allowZip64=True)
    print(" unzip_files" + file_key)
    for file in zipped.namelist():
        #logger.info(f'current file in zipfile: {file}')
        final_file_path = dest_path + "/" + file # + '.gzip'
        print(" to file " + file + "-->" + final_file_path)
        with zipped.open(file, "r") as f_in:
            content = f_in.read()
            #gzipped_content = gzip.compress(f_in.read())
            destination_bucket.upload_fileobj(io.BytesIO(content),
                                                    final_file_path,
                                                    ExtraArgs={"ContentType": "text/plain"}
                                            )
            
def untar_files(file_key, source_bucketname, destination_bucket , dest_path):
    tar_file = s3_resource.Object(bucket_name=source_bucketname, key=file_key)
    buffer = BytesIO(tar_file.get()["Body"].read())
    with tarfile.open(fileobj=buffer, mode='r:*') as tar:
        print(" untar_files " + file_key)
        for member in tar.getmembers():
            if member.isfile():  # Process only files, skip directories
                final_file_path = dest_path + "/" + member.name
                print(" to file " + member.name + "-->" + final_file_path)
                f_in = tar.extractfile(member)
                if f_in is not None:
                    content = f_in.read()
                    destination_bucket.upload_fileobj(
                        io.BytesIO(content),
                        final_file_path,
                        ExtraArgs={"ContentType": "text/plain"}
                    )


"""
    # OLD VERSION 
    # Download the zip file from S3
    zip_obj = s3_client.get_object(Bucket=bucket, Key=key)
    buffer = io.BytesIO(zip_obj['Body'].read())
    
    # Unzip the contents
    with zipfile.ZipFile(buffer) as zip_file:
        for filename in zip_file.namelist():
            file_content = zip_file.read(filename)
            
            # Upload each file to the DEZIPPED folder
            dezipped_key = os.path.join('DEZIPPED', os.path.basename(filename))
            s3_client.put_object(Bucket=bucket, Key=dezipped_key, Body=file_content)
"""