#!/bin/bash

# Deploy production launch monitoring for We Connect.
# Prerequisites:
#   1. Deploy DynamoDB stack exports.
#   2. Deploy App Runner stack exports.
#   3. Wait for App Runner CloudWatch log groups to exist.

set -euo pipefail

REGION="${AWS_REGION:-eu-west-3}"
STACK_NAME="${MONITORING_STACK_NAME:-we-connect-monitoring}"
APP_RUNNER_STACK="${APP_RUNNER_STACK_NAME:-we-counsel-apprunner}"
TEMPLATE_FILE="cloudformation-monitoring.yaml"

echo "======================================="
echo "We Connect - Monitoring Deployment"
echo "======================================="
echo ""

echo "1. Checking AWS CLI configuration..."
aws sts get-caller-identity >/dev/null
echo "AWS CLI is configured"
echo ""

if [ -z "${ALERT_EMAIL:-}" ]; then
  read -r -p "Alert email address: " ALERT_EMAIL
fi

if [ -z "$ALERT_EMAIL" ]; then
  echo "Alert email is required."
  exit 1
fi

echo "2. Reading App Runner exports..."
SERVICE_ID=$(aws cloudformation describe-stacks \
  --stack-name "$APP_RUNNER_STACK" \
  --region "$REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceId`].OutputValue' \
  --output text)

SERVICE_NAME="we-counsel-backend"
APPLICATION_LOG_GROUP="/aws/apprunner/${SERVICE_NAME}/${SERVICE_ID}/application"
SERVICE_LOG_GROUP="/aws/apprunner/${SERVICE_NAME}/${SERVICE_ID}/service"

if [ -z "$SERVICE_ID" ] || [ "$SERVICE_ID" = "None" ]; then
  echo "Could not resolve App Runner service ID from stack: $APP_RUNNER_STACK"
  exit 1
fi

echo "App Runner service ID: $SERVICE_ID"
echo ""

echo "3. Checking App Runner log groups..."
for LOG_GROUP in "$APPLICATION_LOG_GROUP" "$SERVICE_LOG_GROUP"; do
  if ! aws logs describe-log-groups \
    --region "$REGION" \
    --log-group-name-prefix "$LOG_GROUP" \
    --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName | [0]" \
    --output text | grep -qx "$LOG_GROUP"; then
    echo "Missing log group: $LOG_GROUP"
    echo ""
    echo "Deploy or start the App Runner service first, then retry monitoring."
    echo "Metric filters require the target log groups to already exist."
    exit 1
  fi
done
echo "App Runner log groups exist"
echo ""

echo "4. Validating CloudFormation template..."
aws cloudformation validate-template \
  --region "$REGION" \
  --template-body "file://${TEMPLATE_FILE}" >/dev/null
echo "Template is valid"
echo ""

echo "5. Deploying monitoring stack..."
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    AlertEmail="$ALERT_EMAIL" \
    AppRunnerServiceName="$SERVICE_NAME" \
    MonthlyBudgetUsd="${MONTHLY_BUDGET_USD:-100}" \
    FourXxThreshold="${FOUR_XX_THRESHOLD:-20}" \
    LatencyThresholdMs="${LATENCY_THRESHOLD_MS:-5000}" \
  --region "$REGION"

echo ""
echo "Monitoring stack deployed."
echo ""
echo "Next steps:"
echo "1. Confirm the SNS subscription email sent to: $ALERT_EMAIL"
echo "2. Open CloudWatch dashboard: we-connect-prod-launch"
echo "3. Trigger one test alarm and confirm delivery"
