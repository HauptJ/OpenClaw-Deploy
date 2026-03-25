#!/usr/bin/env bash

set -euo pipefail

# --- Argument validation ---

if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename "$0") <target-file> <secrets-list-file> <secret-retrieval-script>" >&2
    exit 1
fi

target_file="$1"
secrets_list="$2"
secret_retriever="$3"

if [ ! -f "$target_file" ]; then
    echo "Error: target file not found: $target_file" >&2
    exit 1
fi

if [ ! -f "$secrets_list" ]; then
    echo "Error: secrets list file not found: $secrets_list" >&2
    exit 1
fi

if [ ! -f "$secret_retriever" ]; then
    echo "Error: ${secret_retriever} not found at: $secret_retriever" >&2
    exit 1
fi

if [ ! -x "$secret_retriever" ]; then
    chmod +x "$secret_retriever"
fi

# --- Process each secret ---

while IFS= read -r secret_id || [ -n "$secret_id" ]; do
    # Skip blank lines and comments
    [[ -z "$secret_id" || "$secret_id" == \#* ]] && continue

    echo "Resolving secret: $secret_id"

    secret_val=$("$secret_retriever" "$secret_id")
    exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        echo "Error: ${secret_retriever} returned exit code $exit_code for secret: $secret_id" >&2
        exit "$exit_code"
    fi

    # Escape special regex characters in the secret ID for use in sed pattern
    escaped_id=$(printf '%s' "$secret_id" | sed 's/[]\/$*.^[]/\\&/g')

    # Escape special replacement characters in the secret value for use in sed replacement
    escaped_val=$(printf '%s' "$secret_val" | sed 's/[&/\]/\\&/g')

    # Build the sed expression using printf to avoid shell double-quote interpolation
    # of variables that may contain quotes or other shell-special characters
    sed_expr=$(printf 's/${%s}/%s/g' "$escaped_id" "$escaped_val")

    # Replace ${SECRET_ID} placeholder in the target file in-place
    sed -i "$sed_expr" "$target_file"

done < "$secrets_list"

echo "Done. Secrets written to: $target_file"