#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
INSTANCE_TYPE="${INSTANCE_TYPE:-p5.4xlarge}"
AMI_PARAMETER="${AMI_PARAMETER:-/aws/service/deeplearning/ami/x86_64/oss-nvidia-driver-gpu-pytorch-2.7-ubuntu-22.04/latest/ami-id}"
IMAGE_ID="${IMAGE_ID:-}"
INSTANCE_PROFILE="${INSTANCE_PROFILE:-}"
KEY_NAME="${KEY_NAME:-}"
NAME_TAG="${NAME_TAG:-parameter-golf-p5-1x}"
PROJECT_TAG="${PROJECT_TAG:-parameter-golf}"
VOLUME_SIZE="${VOLUME_SIZE:-200}"
VOLUME_TYPE="${VOLUME_TYPE:-gp3}"
SLEEP_SECONDS="${SLEEP_SECONDS:-60}"
MAX_ROUNDS="${MAX_ROUNDS:-0}"
WAIT_FOR_RUNNING="${WAIT_FOR_RUNNING:-0}"
SUBNET_IDS_CSV="${SUBNET_IDS:-}"
SECURITY_GROUP_IDS_CSV="${SECURITY_GROUP_IDS:-}"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

contains_value() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

if ! command -v aws >/dev/null 2>&1; then
  printf 'aws CLI is required\n' >&2
  exit 1
fi

if [[ -z "$IMAGE_ID" ]]; then
  IMAGE_ID="$(aws ssm get-parameter \
    --region "$REGION" \
    --name "$AMI_PARAMETER" \
    --query 'Parameter.Value' \
    --output text)"
fi

offered_azs=()
while IFS= read -r az; do
  [[ -n "$az" ]] || continue
  offered_azs+=("$az")
done < <(
  aws ec2 describe-instance-type-offerings \
    --region "$REGION" \
    --location-type availability-zone \
    --filters "Name=instance-type,Values=$INSTANCE_TYPE" \
    --query 'InstanceTypeOfferings[].Location' \
    --output text | tr '\t' '\n'
)

if [[ ${#offered_azs[@]} -eq 0 ]]; then
  printf 'No %s offerings found in %s\n' "$INSTANCE_TYPE" "$REGION" >&2
  exit 1
fi

subnet_ids=()
subnet_azs=()
subnet_vpcs=()

if [[ -n "$SUBNET_IDS_CSV" ]]; then
  IFS=',' read -r -a requested_subnets <<< "$SUBNET_IDS_CSV"
  for subnet_id in "${requested_subnets[@]}"; do
    subnet_id="$(printf '%s' "$subnet_id" | xargs)"
    subnet_info="$(aws ec2 describe-subnets \
      --region "$REGION" \
      --subnet-ids "$subnet_id" \
      --query 'Subnets[0].[SubnetId,AvailabilityZone,VpcId]' \
      --output text)"
    read -r resolved_subnet_id resolved_subnet_az resolved_subnet_vpc <<< "$subnet_info"
    subnet_ids+=("$resolved_subnet_id")
    subnet_azs+=("$resolved_subnet_az")
    subnet_vpcs+=("$resolved_subnet_vpc")
  done
else
  while IFS=$'\t' read -r subnet_id subnet_az subnet_vpc; do
    [[ -n "$subnet_id" ]] || continue
    if contains_value "$subnet_az" "${offered_azs[@]}"; then
      subnet_ids+=("$subnet_id")
      subnet_azs+=("$subnet_az")
      subnet_vpcs+=("$subnet_vpc")
    fi
  done < <(
    aws ec2 describe-subnets \
      --region "$REGION" \
      --filters 'Name=default-for-az,Values=true' \
      --query 'Subnets[].[SubnetId,AvailabilityZone,VpcId]' \
      --output text
  )
fi

if [[ ${#subnet_ids[@]} -eq 0 ]]; then
  printf 'No usable subnets found for %s in %s\n' "$INSTANCE_TYPE" "$REGION" >&2
  exit 1
fi

security_group_ids=()
if [[ -n "$SECURITY_GROUP_IDS_CSV" ]]; then
  IFS=',' read -r -a security_group_ids <<< "$SECURITY_GROUP_IDS_CSV"
  for i in "${!security_group_ids[@]}"; do
    security_group_ids[$i]="$(printf '%s' "${security_group_ids[$i]}" | xargs)"
  done
else
  default_sg="$(aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=${subnet_vpcs[0]}" 'Name=group-name,Values=default' \
    --query 'SecurityGroups[0].GroupId' \
    --output text)"
  if [[ -z "$default_sg" || "$default_sg" == "None" ]]; then
    printf 'Could not resolve default security group in VPC %s\n' "${subnet_vpcs[0]}" >&2
    exit 1
  fi
  security_group_ids=("$default_sg")
fi

printf 'Region: %s\n' "$REGION"
printf 'Instance type: %s\n' "$INSTANCE_TYPE"
printf 'Image id: %s\n' "$IMAGE_ID"
printf 'Subnets: %s\n' "${subnet_ids[*]}"
printf 'Security groups: %s\n' "${security_group_ids[*]}"
printf 'Sleep between rounds: %ss\n' "$SLEEP_SECONDS"
if [[ "$MAX_ROUNDS" == "0" ]]; then
  printf 'Max rounds: unlimited\n'
else
  printf 'Max rounds: %s\n' "$MAX_ROUNDS"
fi

attempt=0
round=0
while [[ "$MAX_ROUNDS" == "0" || "$round" -lt "$MAX_ROUNDS" ]]; do
  round=$((round + 1))
  printf '\n[%s] Round %d\n' "$(timestamp)" "$round"

  for i in "${!subnet_ids[@]}"; do
    attempt=$((attempt + 1))
    subnet_id="${subnet_ids[$i]}"
    subnet_az="${subnet_azs[$i]}"
    printf '[%s] Attempt %d: trying %s in %s (%s)\n' \
      "$(timestamp)" "$attempt" "$INSTANCE_TYPE" "$subnet_az" "$subnet_id"

    cmd=(
      aws ec2 run-instances
      --region "$REGION"
      --image-id "$IMAGE_ID"
      --instance-type "$INSTANCE_TYPE"
      --count 1
      --subnet-id "$subnet_id"
      --security-group-ids "${security_group_ids[@]}"
      --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$VOLUME_SIZE,\"VolumeType\":\"$VOLUME_TYPE\",\"DeleteOnTermination\":true}}]"
      --instance-initiated-shutdown-behavior terminate
      --metadata-options 'HttpTokens=required'
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME_TAG},{Key=Project,Value=$PROJECT_TAG}]"
      --query 'Instances[0].InstanceId'
      --output text
    )

    if [[ -n "$INSTANCE_PROFILE" ]]; then
      cmd+=(--iam-instance-profile "Name=$INSTANCE_PROFILE")
    fi
    if [[ -n "$KEY_NAME" ]]; then
      cmd+=(--key-name "$KEY_NAME")
    fi

    set +e
    output="$("${cmd[@]}" 2>&1)"
    rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
      instance_id="$output"
      printf '[%s] Success: %s\n' "$(timestamp)" "$instance_id"
      if [[ "$WAIT_FOR_RUNNING" == "1" ]]; then
        aws ec2 wait instance-running --region "$REGION" --instance-ids "$instance_id"
        printf '[%s] Instance is running\n' "$(timestamp)"
      fi
      printf '%s\n' "$instance_id"
      exit 0
    fi

    printf '[%s] Launch failed: %s\n' "$(timestamp)" "$output" >&2
    if [[ "$output" != *InsufficientInstanceCapacity* && "$output" != *'Insufficient capacity.'* ]]; then
      exit "$rc"
    fi
  done

  if [[ "$MAX_ROUNDS" != "0" && "$round" -ge "$MAX_ROUNDS" ]]; then
    break
  fi

  printf '[%s] No capacity yet; sleeping %ss\n' "$(timestamp)" "$SLEEP_SECONDS"
  sleep "$SLEEP_SECONDS"
done

printf '[%s] Exhausted retries without finding %s capacity in %s\n' \
  "$(timestamp)" "$INSTANCE_TYPE" "$REGION" >&2
exit 1
