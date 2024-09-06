import os
import boto3
import openpyxl
import csv
import fnmatch

source_bucket = os.environ['SourceBucket']
source_path = os.environ['SourcePath'] 
source_pattern = os.environ['SourceFilePattern']
dest_bucket = os.environ['DestBucket']
dest_path =  os.environ['DestPath'] 

C_LOCAL_PATH='/tmp/'
s3 = boto3.resource('s3')
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print(event)
    if 'filename' in event:
        file_name=event['filename']
        s3_key=source_path +"/" + file_name
    else:
        s3_key = event['detail']['object']['key'] # event['Records'][0]['s3']['object']['key']
        file_name = os.path.basename(s3_key)
    print(" Filename: " + file_name)
    if file_name=="":
        return {'statusCode': 400 , 'file_name': file_name , 'numero_righe':'0' , 'flag_processo'  : False}
    if fnmatch.fnmatch(file_name, source_pattern ):
        print(" File matched!")
        file_name,numero_righe=convertExcel2csv( s3_key , file_name)
        return {'statusCode': 200 , 'file_name': file_name , 'numero_righe':str(numero_righe) , 'flag_processo'  : numero_righe%2==0 }
    return {'statusCode': 400 , 'file_name': file_name , 'numero_righe':'0' , 'flag_processo'  : False}

def convertExcel2csv(s3_key , file_name):
    print("File convertExcel2csv: " + s3_key)
    numero_righe=0
    file_local_path= C_LOCAL_PATH + file_name #os.chdir('/tmp')
    source_bucket_obj = s3.Bucket(source_bucket)
    source_bucket_obj.download_file(s3_key,file_local_path )
    wb = openpyxl.load_workbook(file_local_path)
    ws = wb.worksheets[0] #first sheet in the workbook
    csv_filename = os.path.splitext(file_name)[0] + '.csv'
    if "DestFileName" in os.environ:
        if os.environ['DestFileName'] !="":
            csv_filename =  os.environ['DestFileName'] 
    with open(C_LOCAL_PATH + csv_filename, 'w', newline="") as csvfile:
        writer = csv.writer(csvfile , delimiter =';')
        for row in ws.rows:
            row_data = [cell.value for cell in row]
            writer.writerow(row_data)
            numero_righe=numero_righe+1
    s3_client.upload_file(C_LOCAL_PATH + csv_filename, dest_bucket, dest_path + "/" + csv_filename)
    #boto3.client('s3').upload_file( "/tmp/" + fileName , BucketName,  destination_directory +"/" + fileName )
    return dest_path + "/" + csv_filename,numero_righe

#if __name__ == '__main__':
#    file_name="template.xls"
#    source_pattern='*.xlsx'
#    if fnmatch.fnmatch(file_name, source_pattern ):
#        print("File fnmatch : " + file_name)