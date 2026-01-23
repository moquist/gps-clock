#!/usr/bin/env bash
set -ex

npm run build:lambda
S3KEY="lambda-$(date -Iseconds)-$(sha256sum lambda.zip | cut -c1-10).zip"
aws s3 cp lambda.zip "s3://$S3BUCKET/$S3KEY"

cat > parameters.json <<END
[
    {"ParameterKey": "GoogleApiKey", "ParameterValue": "$GOOGLE_API_KEY"},
    {"ParameterKey": "LambdaCodeBucket", "ParameterValue": "$S3BUCKET"},
    {"ParameterKey": "LambdaCodeKey", "ParameterValue": "$S3KEY"},
    {"ParameterKey": "DomainWildcard", "ParameterValue": "$DOMAIN_WILDCARD"},
    {"ParameterKey": "DomainName", "ParameterValue": "$DOMAIN_NAME"},
    {"ParameterKey": "ClockConfig", "ParameterValue": $(echo "$CLOCK_CONFIG" | jq -R .)}
]
END

# Check if stack exists
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name OwnTracksServer --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" = "DOES_NOT_EXIST" ]; then
    echo "Stack does not exist. Creating new CloudFormation stack..."
    aws cloudformation create-stack \
      --stack-name OwnTracksServer \
      --template-body file://cloudformation.yaml \
      --capabilities CAPABILITY_IAM \
      --parameters file://parameters.json \
      --on-failure DO_NOTHING
    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete --stack-name OwnTracksServer
else
    echo "Stack exists with status: $STACK_STATUS. Updating CloudFormation stack..."
    aws cloudformation update-stack \
      --stack-name OwnTracksServer \
      --template-body file://cloudformation.yaml \
      --capabilities CAPABILITY_IAM \
      --parameters file://parameters.json
    echo "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete --stack-name OwnTracksServer
fi

echo "Stack deployment completed successfully!"
aws cloudformation describe-stacks --stack-name OwnTracksServer --query 'Stacks[0].Outputs' --output table
