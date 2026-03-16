#!/usr/bin/env bash

secret_id=$1
aws_bin_path="/snap/bin/aws"

secret_val=$(${aws_bin_path} secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text | jq '.[]')

return_code=$?

if [ "$return_code" -eq 0 ]; then
    echo $secret_val
    return 0
else
    return $return_code
fi
