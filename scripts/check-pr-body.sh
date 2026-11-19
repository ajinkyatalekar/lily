#!/usr/bin/env bash
# Reads a PR body on stdin. Fails unless every required heading has real content under it.
set -euo pipefail

# Drop HTML comments (the template's prompts) and the CRs GitHub puts in PR bodies.
body=$(perl -0pe 's/<!--.*?-->//gs; s/\r//g')

fail=0
for h in "What shipped" "Why this way" "Caveats and shortcuts" "Verification" "For the next agent"; do
  section=$(awk -v h="## $h" '$0 == h {on = 1; next} /^## / {on = 0} on' <<<"$body")
  if ! grep -q '[^[:space:]]' <<<"$section"; then
    echo "PR body: \"## $h\" is missing or empty"
    fail=1
  fi
done
exit $fail
