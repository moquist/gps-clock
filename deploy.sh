#!/usr/bin/env bash
set -ex

# Check required environment variables
if [ -z "$S3BUCKET" ]; then
    echo "❌ Error: S3BUCKET environment variable is not set"
    echo "   Please set it in your environment or in env.sh"
    exit 1
fi

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "❌ Error: GOOGLE_API_KEY environment variable is not set"
    echo "   Please set it in env.sh"
    exit 1
fi

echo "🚀 Starting OwnTracks Server deployment..."

npm run build:lambda
S3KEY="lambda-$(date -Iseconds)-$(sha256sum lambda.zip | cut -c1-10).zip"
aws s3 cp lambda.zip "s3://$S3BUCKET/$S3KEY"

# Parameters are now passed directly to cloudformation deploy command

# Use cloudformation deploy which handles both create and update automatically
echo "🚀 Deploying CloudFormation stack..."
aws cloudformation deploy \
  --stack-name OwnTracksServer \
  --template-file cloudformation.yaml \
  --parameter-overrides \
    GoogleApiKey="$GOOGLE_API_KEY" \
    LambdaCodeBucket="$S3BUCKET" \
    LambdaCodeKey="$S3KEY" \
    DomainWildcard="$DOMAIN_WILDCARD" \
    DomainName="$DOMAIN_NAME" \
    ClockConfig="$(echo "$CLOCK_CONFIG" | jq -c .)" \
  --capabilities CAPABILITY_IAM \
  --no-fail-on-empty-changeset

echo "✅ Stack deployment completed successfully!"

# Display stack outputs
echo ""
echo "📋 Stack Outputs:"
aws cloudformation describe-stacks --stack-name OwnTracksServer --query 'Stacks[0].Outputs' --output table

echo ""
echo "🎉 OwnTracks Server deployment finished!"
echo ""
echo "📝 Next steps:"
echo "   1. If you configured a custom domain, create a CNAME record pointing to the CustomDomainTarget output"
echo "   2. Your API endpoint is available at the OwnTracksApiEndpoint output"
echo "   3. You can now configure your OwnTracks app to use this endpoint"
