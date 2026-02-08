import os
import json
import boto3
import base64

sagemaker = boto3.client('sagemaker-runtime')
sns        = boto3.client('sns')

ENDPOINT_NAME     = os.environ['ENDPOINT_NAME']
SNS_TOPIC_ARN     = os.environ['SNS_TOPIC_ARN']
THRESHOLD         = float(os.environ['ANOMALY_THRESHOLD'])

def handler(event, context):
    for record in event['Records']:
        # Kinesis data is base64 encoded
        payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
        # Expected format: "vehicle_count,average_speed,occupancy"
        response = sagemaker.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType='text/csv',
            Body=payload
        )
        result = json.loads(response['Body'].read().decode())
        score = result['score']  # RCF returns a single score

        
        # Inside handler, after payload decode
        if ANOMALY_ENDPOINT:
            anomaly_resp = sagemaker.invoke_endpoint(
                EndpointName=os.environ['ANOMALY_ENDPOINT_NAME'],
                ContentType='text/csv',
                Body=payload.strip()
            )
            score = json.loads(anomaly_resp['Body'].read().decode())['score']

        if score > float(os.environ['ANOMALY_THRESHOLD']):
            sns.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Subject="Smart City Anomaly Alert",
                Message=f"High anomaly score {score:.3f} on data: {payload}"
            )
        if score > THRESHOLD:
            message = f"ANOMALY DETECTED!\nScore: {score:.3f}\nData: {payload}"
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message,
                Subject="Smart City Traffic Anomaly"
            )
    return {'status': 'processed'}

