import os
import boto3
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

client = boto3.client('ec2')

def handler(event, context):
    logger.info(event)

    return