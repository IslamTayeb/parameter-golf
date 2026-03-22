#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

print_quota() {
  local service_code="$1"
  local quota_code="$2"
  local label="$3"

  printf '\n== %s ==\n' "$label"
  aws service-quotas get-service-quota \
    --region "$REGION" \
    --service-code "$service_code" \
    --quota-code "$quota_code" \
    --query 'Quota.{QuotaName:QuotaName,Value:Value,Adjustable:Adjustable}' \
    --output table

  aws service-quotas list-requested-service-quota-change-history-by-quota \
    --region "$REGION" \
    --service-code "$service_code" \
    --quota-code "$quota_code" \
    --max-results 5 \
    --query 'RequestedQuotas[].{Desired:DesiredValue,Status:Status,CaseId:CaseId,Created:Created}' \
    --output table || true
}

printf 'Region: %s\n' "$REGION"
printf '\n== H100 / H200 Offerings ==\n'
aws ec2 describe-instance-type-offerings \
  --region "$REGION" \
  --location-type region \
  --filters "Name=instance-type,Values=p5.4xlarge,p5.48xlarge,p5en.48xlarge" \
  --query 'InstanceTypeOfferings[].InstanceType' \
  --output table

print_quota ec2 L-417A185B "EC2 Running On-Demand P instances"
print_quota ec2 L-7212CCBC "EC2 All P Spot Instance Requests"
print_quota sagemaker L-C2764A80 "SageMaker ml.p5.4xlarge training"
print_quota sagemaker L-82E1C851 "SageMaker ml.p5.48xlarge training"
