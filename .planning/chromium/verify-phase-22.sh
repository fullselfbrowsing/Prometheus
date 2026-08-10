#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
PHASE_DIR="${ROOT_DIR}/.planning/phases/22-chrome-extension-ecosystem-and-policy"
PATCH_DIR="${PHASE_DIR}/patches"
LOG_DIR="${OUT_DIR}/phase22-closeout"
BASELINE='de937473bd1b5e99aec391ea003545ecd205e367'
EXPECTED_PATCH_COUNT=26
EXPECTED_POLICY_COUNT=68
EXPECTED_WEBUI_COUNT=4
EXPECTED_MCP_NATIVE_COUNT=2
EXPECTED_MCP_NODE_COUNT=2
EXPECTED_FIXTURE_COUNT=5
EXPECTED_CATALOG_COUNT=12
EXPECTED_MV2_COUNT=1
EXPECTED_SMOKE_COUNT=32
EXPECTED_NINJA_LOG_SHA256='7f9616af7116a16c5655753a7e2858cebbbe6767095101b1c3eb09a77228472e'
EXPECTED_NINJA_DEPS_SHA256='ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0'
EXPECTED_BLINK_MODULES_SHA256='663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e'
EXPECTED_BLINK_MODULES_TOC_SHA256='bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b'
EXPECTED_FRAMEWORK_RESOURCES_SHA256='c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff'
EXPECTED_APP_SHA256='154b7e74caf99e158d0856abb00aac8aaa2be8e8a1b73bb586f8ef3770b137af'

REPLAY_INDEX=""
MUTATION_INDEX=""
MUTATED_PATCH=""

fail() {
  printf 'Phase 22 verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-closeout] %s\n' "$1"
}

require_file() {
  [[ -s "$1" ]] || fail "missing or empty file: $1"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

cleanup() {
  [[ -z "${REPLAY_INDEX}" ]] || rm -f -- "${REPLAY_INDEX}"
  [[ -z "${MUTATION_INDEX}" ]] || rm -f -- "${MUTATION_INDEX}"
  [[ -z "${MUTATED_PATCH}" ]] || rm -f -- "${MUTATED_PATCH}"
}
trap cleanup EXIT INT TERM

run_gate() {
  local name="$1"
  shift
  note "running ${name}"
  "$@" >"${LOG_DIR}/${name}.log" 2>&1 || {
    tail -n 160 "${LOG_DIR}/${name}.log" >&2 || true
    fail "${name} failed; see ${LOG_DIR}/${name}.log"
  }
}

count_gtests() {
  LC_ALL=C awk '
    /^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
    END { print count + 0 }
  ' "$1"
}

require_gtest_count() {
  local name="$1"
  local file="$2"
  local expected="$3"
  require_file "${file}"
  local actual
  actual="$(count_gtests "${file}")"
  [[ "${actual}" -eq "${expected}" ]] \
    || fail "${name} expected ${expected} tests, found ${actual}"
  note "${name}: PASS ${expected}/${expected}, fail=0, skip=0"
}

capture_reviewed_hashes() {
  local output="$1"
  : >"${output}"
  local relative
  for relative in \
    .ninja_log \
    .ninja_deps \
    libblink_modules.dylib \
    libblink_modules.dylib.TOC \
    'Prometheus Framework.framework/Resources/resources.pak' \
    'Prometheus.app/Contents/MacOS/Prometheus'; do
    require_file "${OUT_DIR}/${relative}"
    printf '%s  %s\n' "$(sha256_file "${OUT_DIR}/${relative}")" \
      "${relative}" >>"${output}"
  done
}

verify_reviewed_hashes() {
  local file="$1"
  local expected hash relative
  while read -r hash relative; do
    case "${relative}" in
      .ninja_log) expected="${EXPECTED_NINJA_LOG_SHA256}" ;;
      .ninja_deps) expected="${EXPECTED_NINJA_DEPS_SHA256}" ;;
      libblink_modules.dylib) expected="${EXPECTED_BLINK_MODULES_SHA256}" ;;
      libblink_modules.dylib.TOC)
        expected="${EXPECTED_BLINK_MODULES_TOC_SHA256}"
        ;;
      'Prometheus Framework.framework/Resources/resources.pak')
        expected="${EXPECTED_FRAMEWORK_RESOURCES_SHA256}"
        ;;
      'Prometheus.app/Contents/MacOS/Prometheus')
        expected="${EXPECTED_APP_SHA256}"
        ;;
      *) fail "unexpected reviewed artifact: ${relative}" ;;
    esac
    [[ "${hash}" == "${expected}" ]] \
      || fail "reviewed artifact hash changed: ${relative}"
  done <"${file}"
}

verify_phase22_counts() {
  require_gtest_count extension-policy \
    "${OUT_DIR}/phase22-extension-policy/list.log" \
    "${EXPECTED_POLICY_COUNT}"
  require_gtest_count webui \
    "${OUT_DIR}/phase22-webui/list.log" "${EXPECTED_WEBUI_COUNT}"
  require_gtest_count mcp-native \
    "${OUT_DIR}/phase22-mcp/native-list.log" "${EXPECTED_MCP_NATIVE_COUNT}"
  local node_count
  node_count="$(rg -c '^Phase 22 extension diagnostics ' \
    "${OUT_DIR}/phase22-mcp/node-list.log")"
  [[ "${node_count}" -eq "${EXPECTED_MCP_NODE_COUNT}" ]] \
    || fail "mcp-node expected ${EXPECTED_MCP_NODE_COUNT}, found ${node_count}"
  note "mcp-node: PASS ${EXPECTED_MCP_NODE_COUNT}/${EXPECTED_MCP_NODE_COUNT}, fail=0, skip=0"
  require_gtest_count fixtures \
    "${OUT_DIR}/phase22-extension-fixtures/list.log" \
    "${EXPECTED_FIXTURE_COUNT}"
  require_gtest_count compatibility-catalog \
    "${OUT_DIR}/phase22-extension-fixtures/catalog-list.log" \
    "${EXPECTED_CATALOG_COUNT}"
  require_gtest_count mv2-observation \
    "${OUT_DIR}/phase22-extension-fixtures/mv2-list.log" \
    "${EXPECTED_MV2_COUNT}"
  require_gtest_count extension-smoke \
    "${OUT_DIR}/phase22-extension-smoke/list.log" \
    "${EXPECTED_SMOKE_COUNT}"
}

verify_phase21_regression_record() {
  local verification="${ROOT_DIR}/.planning/phases/21-supervision-pairing-and-remote-control/21-VERIFICATION.md"
  require_file "${verification}"
  for literal in \
    'status: passed' \
    '| Phase 21 native | 190/190 passed; fail 0; skip 0 |' \
    '| Phase 21 Blink renderer | 14/14 passed |' \
    '| Phase 21 browser | 52/52 passed; fail 0; skip 0; jobs 1; retries 0 |' \
    '| Complete Node TAP | 81/81 passed; fail 0; cancelled 0; skipped 0; todo 0 |' \
    '| Phase 20 native regression | 208/208 passed; fail 0; skip 0 |' \
    '| Phase 17–19 native regression | 84/84 passed; fail 0; skip 0 |' \
    '| Phase 20 content regression | 21/21 passed; fail 0; skip 0 |' \
    '| Phase 19 renderer security regression | 3/3 passed |' \
    '| Phase 20 browser regression | 37/37 passed; fail 0; skip 0; jobs 1; retries 0 |' \
    '| Phase 17–19 browser regression | 83/83 passed; fail 0; skip 0; jobs 1; retries 0 |' \
    'exact `Prometheus MCP live smoke passed.` marker'; do
    rg -Fq -- "${literal}" "${verification}" \
      || fail "Phase 21 regression record missing: ${literal}"
  done
  note 'Phase 17-21 frozen regression record: PASS 208/84/21/3/37/83 plus Phase 21 190/14/52/81'
}

stable_patch_id_for_file() {
  git patch-id --stable <"$1" | LC_ALL=C awk '
    NF == 2 { count += 1; id = $1 }
    END { if (count != 1 || id !~ /^[0-9a-f]{40}$/) exit 1; print id }
  '
}

stable_patch_id_for_commit() {
  git -C "${CHROMIUM_DIR}" show --pretty=format: --binary "$1" |
    git patch-id --stable | LC_ALL=C awk '
      NF == 2 { count += 1; id = $1 }
      END { if (count != 1 || id !~ /^[0-9a-f]{40}$/) exit 1; print id }
    '
}

verify_patches() {
  local commits=()
  local patches=()
  local commit patch patch_id commit_patch_id index expected_prefix
  while IFS= read -r commit; do commits+=("${commit}"); done < <(
    git -C "${CHROMIUM_DIR}" rev-list --reverse "${BASELINE}..HEAD"
  )
  while IFS= read -r patch; do patches+=("${patch}"); done < <(
    find "${PATCH_DIR}" -maxdepth 1 -type f -name '*.patch' | LC_ALL=C sort
  )
  [[ "${#commits[@]}" -eq "${EXPECTED_PATCH_COUNT}" ]] \
    || fail "expected ${EXPECTED_PATCH_COUNT} nested commits, found ${#commits[@]}"
  [[ "${#patches[@]}" -eq "${EXPECTED_PATCH_COUNT}" ]] \
    || fail "expected ${EXPECTED_PATCH_COUNT} patches, found ${#patches[@]}"

  REPLAY_INDEX="$(mktemp "${TMPDIR:-/tmp}/phase22-replay-index.XXXXXX")"
  GIT_INDEX_FILE="${REPLAY_INDEX}" git -C "${CHROMIUM_DIR}" \
    read-tree "${BASELINE}"
  : >"${LOG_DIR}/patch-identities.log"
  for index in "${!commits[@]}"; do
    commit="${commits[$index]}"
    patch="${patches[$index]}"
    printf -v expected_prefix '%04d-' "$((index + 1))"
    [[ "$(basename "${patch}")" == "${expected_prefix}"* ]] \
      || fail "out-of-order patch: ${patch}"
    [[ "$(head -n 1 "${patch}")" == "From ${commit} "* ]] \
      || fail "patch $(basename "${patch}") does not export ${commit}"
    if git -C "${CHROMIUM_DIR}" diff-tree --no-commit-id --name-only -r \
        "${commit}" | rg -q \
        '(^|/)(out|gen)(/|$)|(^|/)\.ninja|[.](o|dylib|a|rsp|runtime_deps)$'; then
      fail "nested commit ${commit} contains generated output"
    fi
    patch_id="$(stable_patch_id_for_file "${patch}")"
    commit_patch_id="$(stable_patch_id_for_commit "${commit}")"
    [[ "${patch_id}" == "${commit_patch_id}" ]] \
      || fail "patch body differs from ${commit}"
    printf '%s %s %s %s\n' "${commit}" "${patch_id}" \
      "$(sha256_file "${patch}")" "$(basename "${patch}")" \
      >>"${LOG_DIR}/patch-identities.log"
    GIT_INDEX_FILE="${REPLAY_INDEX}" git -C "${CHROMIUM_DIR}" \
      apply --check --cached "${patch}"
    GIT_INDEX_FILE="${REPLAY_INDEX}" git -C "${CHROMIUM_DIR}" \
      apply --cached "${patch}"
  done
  [[ "$(GIT_INDEX_FILE="${REPLAY_INDEX}" git -C "${CHROMIUM_DIR}" write-tree)" == \
      "$(git -C "${CHROMIUM_DIR}" rev-parse 'HEAD^{tree}')" ]] \
    || fail 'ordered patch replay tree does not match nested HEAD'

  local last_patch="${patches[$((${#patches[@]} - 1))]}"
  local last_commit="${commits[$((${#commits[@]} - 1))]}"
  MUTATED_PATCH="$(mktemp "${TMPDIR:-/tmp}/phase22-mutated-patch.XXXXXX")"
  LC_ALL=C awk '
    !mutated && substr($0, 1, 1) == "+" && substr($0, 1, 3) != "+++" {
      print $0 "PHASE22_MUTATED_PATCH_BODY"; mutated = 1; next
    }
    { print }
    END { if (!mutated) exit 1 }
  ' "${last_patch}" >"${MUTATED_PATCH}"
  MUTATION_INDEX="$(mktemp "${TMPDIR:-/tmp}/phase22-mutation-index.XXXXXX")"
  GIT_INDEX_FILE="${MUTATION_INDEX}" git -C "${CHROMIUM_DIR}" \
    read-tree "${last_commit}^"
  GIT_INDEX_FILE="${MUTATION_INDEX}" git -C "${CHROMIUM_DIR}" \
    apply --check --cached "${MUTATED_PATCH}"
  [[ "$(stable_patch_id_for_file "${MUTATED_PATCH}")" != \
      "$(stable_patch_id_for_commit "${last_commit}")" ]] \
    || fail 'stable identity accepted the mutated patch body'
  note "patches: PASS ${EXPECTED_PATCH_COUNT}/${EXPECTED_PATCH_COUNT}, ordered source-only replay and mutation rejection"
}

verify_claims_and_documents() {
  local compatibility="${PHASE_DIR}/22-COMPATIBILITY.json"
  local mv2="${PHASE_DIR}/22-MV2-OBSERVATION.json"
  require_file "${compatibility}"
  require_file "${mv2}"
  node --input-type=module - "${compatibility}" \
    "$(git -C "${CHROMIUM_DIR}" rev-parse HEAD)" <<'NODE'
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const [path, head] = process.argv.slice(2);
const data = JSON.parse(readFileSync(path, 'utf8'));
assert.equal(data.schema_version, 1);
assert.equal(data.chromium_revision, head);
assert.equal(data.rows.length, 5);
assert.deepEqual(data.rows.map(({category}) => category).sort(), [
  'ad_blocker', 'developer_workflow', 'password_manager_like',
  'productivity_content_script', 'side_panel_tooling'
]);
for (const row of data.rows) {
  assert.equal(row.manifest_version, 3);
  assert.equal(row.result, 'Verified');
  assert.equal(row.chromium_revision, head);
  assert.equal(row.install_source, 'Developer mode (unpacked)');
}
NODE
  local claim_documents=(
    "${PHASE_DIR}/22-COMPATIBILITY.md"
    "${ROOT_DIR}/.planning/design/prometheus-browser/README.md"
  )
  if [[ -f "${PHASE_DIR}/22-VERIFICATION.md" ]]; then
    claim_documents+=("${PHASE_DIR}/22-VERIFICATION.md")
  fi
  if rg -ni \
      'all extensions|universal compatibility|Web Store (supported|verified)|MV2 (supported|enabled)' \
      "${claim_documents[@]}"; then
    fail 'documentation contains an unsupported broad compatibility claim'
  fi
  local secret_documents=(
    "${compatibility}"
    "${PHASE_DIR}/22-COMPATIBILITY.md"
    "${mv2}"
    "${ROOT_DIR}/.planning/design/prometheus-browser/README.md"
    "${ROOT_DIR}/.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md"
  )
  local closeout_document
  for closeout_document in "${PHASE_DIR}"/*-SUMMARY.md \
      "${PHASE_DIR}/22-VERIFICATION.md"; do
    if [[ -f "${closeout_document}" ]]; then
      secret_documents+=("${closeout_document}")
    fi
  done
  if rg -n --pcre2 \
      'Bearer [A-Za-z0-9_-]{12,}|BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY|(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{12,}' \
      "${secret_documents[@]}"; then
    fail 'Phase 22 closeout documentation contains secret-like material'
  fi
  if [[ -f "${PHASE_DIR}/22-VERIFICATION.md" ]]; then
    rg -Fq 'human_uat: not_run' "${PHASE_DIR}/22-VERIFICATION.md" \
      || fail 'verification must keep subjective UAT deferred'
  fi
  note 'compatibility, Store/MV2 claim, privacy, and documentation gates passed'
}

mkdir -p "${LOG_DIR}"
capture_reviewed_hashes "${LOG_DIR}/reviewed-hashes.before"
verify_reviewed_hashes "${LOG_DIR}/reviewed-hashes.before"

run_gate extension-policy bash \
  "${SCRIPT_DIR}/verify-phase-22-extension-policy.sh" --focused
run_gate webui bash "${SCRIPT_DIR}/verify-phase-22-webui.sh"
run_gate mcp bash "${SCRIPT_DIR}/verify-phase-22-mcp.sh"
run_gate fixtures bash "${SCRIPT_DIR}/verify-phase-22-extension-fixtures.sh"
run_gate extension-smoke bash "${SCRIPT_DIR}/verify-phase-22-extension-smoke.sh" --focused
run_gate packaged-extension-smoke bash \
  "${SCRIPT_DIR}/smoke-phase-22-extensions.sh" --deterministic
run_gate phase21-node-regression bash "${SCRIPT_DIR}/verify-phase-21.sh" \
  --focus-node '.*'

verify_phase22_counts
verify_phase21_regression_record
verify_patches
verify_claims_and_documents
run_gate preservation bash "${ROOT_DIR}/.planning/preservation/verify-preservation.sh"
run_gate gpl-guard bash "${SCRIPT_DIR}/check-falkon-gpl-guard.sh"
git -C "${ROOT_DIR}" diff --check >"${LOG_DIR}/root-diff-check.log"
git -C "${CHROMIUM_DIR}" diff --check >"${LOG_DIR}/nested-diff-check.log"

capture_reviewed_hashes "${LOG_DIR}/reviewed-hashes.after"
verify_reviewed_hashes "${LOG_DIR}/reviewed-hashes.after"
cmp -s "${LOG_DIR}/reviewed-hashes.before" \
  "${LOG_DIR}/reviewed-hashes.after" \
  || fail 'reviewed build/resource artifacts changed during verification'

note 'exact Phase 22 counts: policy=68 webui=4 mcp-native=2 mcp-node=2 fixtures=5 catalog=12 mv2=1 smoke=32'
note 'Store=Unverified; MV2=observation-only; human UAT=not_run'
printf 'Phase 22 verification passed. Logs: %s\n' "${LOG_DIR}"
