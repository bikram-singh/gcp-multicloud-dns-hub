#!/usr/bin/env bash
# DNS test matrix helper. Run it on the test VM in any environment (GCP, AWS, Azure, on-prem).
# It resolves each name and prints PASS or FAIL, so the output can go straight into the article.
#
# Usage:
#   ./test-dns.sh app1.gcp.gcpcloudhub.in app1.aws.gcpcloudhub.in app1.azure.gcpcloudhub.in app1.onprem.gcpcloudhub.in
#   ./test-dns.sh -s 10.10.0.2 app1.gcp.gcpcloudhub.in      # query a specific DNS server

set -u

SERVER=""
while getopts "s:" opt; do
  case "$opt" in
    s) SERVER="@${OPTARG}" ;;
    *) echo "Usage: $0 [-s dns_server_ip] name [name...]" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 [-s dns_server_ip] name [name...]" >&2
  exit 2
fi

if ! command -v dig >/dev/null 2>&1; then
  echo "dig not found. Install it: sudo apt-get install -y dnsutils (Debian/Ubuntu) or sudo yum install -y bind-utils" >&2
  exit 2
fi

fail=0
printf '%-45s %-8s %s\n' "NAME" "RESULT" "ANSWER"
printf '%-45s %-8s %s\n' "----" "------" "------"

for name in "$@"; do
  # shellcheck disable=SC2086
  answer="$(dig +short +time=3 +tries=1 $SERVER "$name" A | tr '\n' ' ' | sed 's/ *$//')"
  if [ -n "$answer" ]; then
    printf '%-45s %-8s %s\n' "$name" "PASS" "$answer"
  else
    printf '%-45s %-8s %s\n' "$name" "FAIL" "-"
    fail=1
  fi
done

exit "$fail"
