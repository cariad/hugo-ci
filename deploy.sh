#!/bin/bash -e

domain=devops.recipes
site_id=devopsreci

fq_domain="${domain:?}."

export AWS_ACCESS_KEY_ID=AKIA3XZ3NGD7IENZ6K54
export AWS_SECRET_ACCESS_KEY=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

assume() {
  echo "Assuming \"${1:?}\"..." 1>&2
  aws sts assume-role --role-arn "${1:?}" --role-session-name "ci"
}

extract_access_key_id() {
  echo "${1:?} "| jq -r '.Credentials.AccessKeyId'
}

extract_secret_key() {
  echo "${1:?} "| jq -r '.Credentials.SecretAccessKey'
}

extract_session_token() {
  echo "${1:?} "| jq -r '.Credentials.SessionToken'
}

echo "Discovering account ID..."
account_id=$(echo "$(aws sts get-caller-identity)" | jq -r .Account)
role_prefx="arn:aws:iam::${account_id:?}:role/hugositeci-"

infra_deployer_arn="${role_prefx:?}InfrastructureDeployer"

infra_deployer=$(assume                     "${infra_deployer_arn:?}")
infra_access_key_id=$(extract_access_key_id "${infra_deployer:?}")
infra_secret_key=$(extract_secret_key       "${infra_deployer:?}")
infra_session_token=$(extract_session_token "${infra_deployer:?}")

echo "Discovering hosted zone..."
hosted_zone=$(AWS_DEFAULT_REGION=us-east-1                                   \
              AWS_ACCESS_KEY_ID="${infra_access_key_id:?}"                   \
              AWS_SECRET_ACCESS_KEY="${infra_secret_key:?}"                  \
              AWS_SESSION_TOKEN="${infra_session_token:?}"                   \
              aws route53 list-hosted-zones-by-name --dns-name "${domain:?}" \
              | jq -r '.HostedZones[0]')

found_name=$(echo "${hosted_zone:?}" | jq -r '.Name')

if [ "${found_name:?}" != "${fq_domain:?}" ]; then
  echo "Expected \"${fq_domain:?}\" but found \"${found_name:?}\"."
  exit 1
fi

fq_hosted_zone_id=$(echo "${hosted_zone:?}" | jq -r '.Id')
hosted_zone_id=$(basename "${fq_hosted_zone_id}")

stack_deployer=$(assume                     "${role_prefx:?}StackDeployer")
stack_access_key_id=$(extract_access_key_id "${stack_deployer:?}")
stack_secret_key=$(extract_secret_key       "${stack_deployer:?}")
stack_session_token=$(extract_session_token "${stack_deployer:?}")

stack_name="hugositeci-site-${site_id:?}"

echo "Deploying website infrastructure..."
set +e
AWS_DEFAULT_REGION=us-east-1                                                 \
AWS_ACCESS_KEY_ID="${stack_access_key_id:?}"                                 \
AWS_SECRET_ACCESS_KEY="${stack_secret_key:?}"                                \
AWS_SESSION_TOKEN="${stack_session_token:?}"                                 \
aws cloudformation deploy                                                    \
  --no-fail-on-empty-changeset                                               \
  --parameter-overrides        Domain="${domain:?}"                          \
                               HostedZoneId="${hosted_zone_id:?}"            \
                               SiteID="${site_id:?}"                         \
  --stack-name                 "${stack_name:?}"                             \
  --template-file              ./cloudformation/infrastructure.cf.yml        \
  --role-arn                   "${infra_deployer_arn:?}"
last_return="$?"
set -e

if [ "${last_return}" != "0" ]; then
  AWS_DEFAULT_REGION=us-east-1                  \
  AWS_ACCESS_KEY_ID="${stack_access_key_id:?}"  \
  AWS_SECRET_ACCESS_KEY="${stack_secret_key:?}" \
  AWS_SESSION_TOKEN="${stack_session_token:?}"  \
  aws cloudformation describe-stack-events --stack-name "${stack_name:?}"
  exit 1
fi
