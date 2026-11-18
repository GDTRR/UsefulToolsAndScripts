#!/usr/bin/env bash
set -euo pipefail

SMTP_SERVER="${SMTP_SERVER:-smtp.enru.io}"
SMTP_PORT="${SMTP_PORT:-25}"

usage() {
  echo "Usage: $0 FROM TO SUBJECT [BODY]" >&2
  echo "If BODY is omitted, the message body is read from standard input." >&2
  exit 2
}

[[ $# -eq 3 || $# -eq 4 ]] || usage

from=$1
to=$2
subject=$3

# Prevent additional mail headers from being injected through arguments.
for value in "$from" "$to" "$subject"; do
  if [[ $value == *$'\r'* || $value == *$'\n'* ]]; then
    echo "Error: FROM, TO, and SUBJECT must each be a single line." >&2
    exit 2
  fi
done

if [[ $# -eq 4 ]]; then
  body=$4
else
  body=$(cat)
fi

message_file=$(mktemp "${TMPDIR:-/tmp}/send-email.XXXXXX")
trap 'rm -f "$message_file"' EXIT

printf 'From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s\r\n' \
  "$from" "$to" "$subject" "$body" > "$message_file"

curl --fail --show-error --silent \
  --url "smtp://${SMTP_SERVER}:${SMTP_PORT}" \
  --mail-from "$from" \
  --mail-rcpt "$to" \
  --upload-file "$message_file"

echo "Email accepted by ${SMTP_SERVER}:${SMTP_PORT} for ${to}."
