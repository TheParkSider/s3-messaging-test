import os
import boto3
import logging
from datetime import datetime
from zoneinfo import ZoneInfo
from aws_xray_sdk.core import patch_all

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

patch_all()
client = boto3.client('s3')

def handler(event, context):
    bucket = os.environ['S3_Bucket']
    date = datetime.now(ZoneInfo("Asia/Tokyo")).strftime('%Y-%m-%d-%H-%M-%S-%f')
    key = 'file_' + date + '.txt'
    
    response = client.put_object(Bucket=bucket, Key=key, Body=date)

    return response