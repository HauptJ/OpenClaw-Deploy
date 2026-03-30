#!/usr/bin/env bash

secret_id=$1
aws_bin_path="/usr/bin/aws"

secret_val=$(${aws_bin_path} secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text | jq -r '.[]')

return_code=$?

if [ "$return_code" -eq 0 ]; then
    echo $secret_val
    exit 0
else
    exit $return_code
fi
