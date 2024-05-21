import json
import urllib.parse
import boto3


from pprint import pprint
import boto3
from botocore.exceptions import ClientError
#import requests


print('Loading function')

s3 = boto3.client('s3')
reko = boto3.client('rekognition')


def lambda_handler(event, context):
    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
        image = {'S3Object': {'Bucket': bucket, 'Name': key}}
        response = reko.detect_text(Image=image)
        
        texts = ''
        
        for text in response['TextDetections']:
            if(text.get('Type') == "WORD"):
                #print(text.get('DetectedText'))
                texts += text.get('DetectedText') + ' '
        
        print(texts)
        return 0
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e