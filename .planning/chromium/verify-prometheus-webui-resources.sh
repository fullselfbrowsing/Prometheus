#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOURCE_DIR="$ROOT_DIR/.context/chromium/src/chrome/browser/resources/prometheus"

FILES=(
  "$RESOURCE_DIR/prometheus_newtab.html"
  "$RESOURCE_DIR/prometheus_side_panel.html"
  "$RESOURCE_DIR/prometheus_control_panel.html"
  "$RESOURCE_DIR/prometheus_webui.css"
  "$RESOURCE_DIR/prometheus_webui.js"
)

for file in "${FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "missing Prometheus WebUI resource: $file" >&2
    exit 1
  fi
done

failures=0

check_absent() {
  local pattern="$1"
  local label="$2"
  if rg -n --pcre2 "$pattern" "${FILES[@]}"; then
    echo "Prometheus WebUI resource gate failed: $label" >&2
    failures=1
  fi
}

check_absent '@import\b' 'CSS @import'
check_absent '<[^>]+\b(?:src|href)=["'\'']https?://' 'external src/href'
check_absent 'url\(\s*["'\'']?https?://|fetch\(\s*["'\'']https?://|import\(\s*["'\'']https?://' \
  'executable remote http/https URL'
check_absent '\bURLSearchParams\b|location\.search|history\.(?:pushState|replaceState)' \
  'prompt or state transport through URL/history'
check_absent 'api[_-]?key|vault secret|BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY|sk-test' \
  'secret-like fixture'

if (( failures != 0 )); then
  exit 1
fi

echo "Prometheus WebUI resource gate passed (${#FILES[@]} files)."
