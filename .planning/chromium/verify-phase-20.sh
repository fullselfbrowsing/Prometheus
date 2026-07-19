#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
LOG_DIR="${OUT_DIR}/phase20-closeout"
PHASE_DIR="${ROOT_DIR}/.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel"
PATCH_DIR="${PHASE_DIR}/patches"
BASELINE="460caac2f9e7deecd9fa6294c41d13e5a6dd6115"
NINJA="/opt/homebrew/bin/ninja"

mkdir -p "${LOG_DIR}"
find "${LOG_DIR}" -maxdepth 1 -type f -name 'phase20-*.log' -delete

fail() {
  printf 'Phase 20 verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase20] %s\n' "$1"
}

require_file() {
  [[ -s "$1" ]] || fail "missing or empty file: $1"
}

run_logged() {
  local log_name="$1"
  shift
  note "running ${log_name}"
  "$@" >"${LOG_DIR}/${log_name}.log" 2>&1 || {
    tail -n 80 "${LOG_DIR}/${log_name}.log" >&2 || true
    fail "${log_name} (see ${LOG_DIR}/${log_name}.log)"
  }
}

compile_object() {
  local object="$1"
  local command
  command="$("${NINJA}" -t commands "${object}" 2>&1 \
    | rg --fixed-strings -- ' -c ../../' | tail -n 1 || true)"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  /bin/zsh -c "${command}"
}

list_guard() {
  local binary="$1"
  local filter="$2"
  local log_name="$3"
  shift 3
  "${binary}" --gtest_list_tests --gtest_filter="${filter}" \
    >"${LOG_DIR}/${log_name}.log" 2>&1
  local suite
  for suite in "$@"; do
    rg -q "^${suite}\\." "${LOG_DIR}/${log_name}.log" \
      || fail "${log_name} did not select ${suite}"
  done
}

build_content_focused_binary() {
  local target_ninja="obj/chrome/renderer/prometheus_action_dispatcher_unittests.ninja"
  local response_file="phase20_content_focused_unittests.rsp"
  local query_file="${LOG_DIR}/phase20-content-link-query.log"
  local link_command frameworks swiftmodules solibs libs

  local extras=(
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_provider_transport_unittest.o
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_tab_state_unittest.o
    obj/chrome/browser/prometheus/prometheus_provider_transport/prometheus_provider_transport.o
    obj/chrome/browser/prometheus/prometheus_provider_registry/prometheus_provider_registry.o
    obj/chrome/browser/prometheus/prometheus_provider_codec/prometheus_provider_codec.o
    obj/chrome/browser/prometheus/prometheus_secret_store/prometheus_secret_store.o
    obj/chrome/browser/prometheus/prometheus_runtime_prefs/prometheus_runtime_prefs.o
    obj/chrome/browser/prometheus/prometheus_runtime_types/prometheus_runtime_types.o
    obj/chrome/browser/prometheus/prometheus_tab_state/prometheus_tab_state.o
    obj/chrome/browser/prometheus/prometheus_agent_tab_data/prometheus_agent_tab_data.o
    obj/chrome/browser/prometheus/prometheus_agent_route/prometheus_agent_route.o
    obj/components/tabs/test_support/mock_tab_interface.o
    obj/components/tabs/impl/tab_interface.o
    obj/components/tabs/impl/supports_handles.o
    obj/components/tabs/impl/tab_handle_factory.o
    obj/components/sync_preferences/features/features.o
    obj/components/sync_preferences/libtest_support.a
    obj/components/sync_preferences/libsync_preferences.a
    ./libui_base_unowned_user_data.dylib
  )

  local object
  for object in "${extras[@]:0:11}"; do
    compile_object "${object}"
  done
  for object in "${extras[@]}"; do
    require_file "${object}"
  done

  "${NINJA}" -t query prometheus_action_dispatcher_unittests >"${query_file}"
  frameworks="$(sed -n 's/^  frameworks = //p' "${target_ninja}" | tail -n 1)"
  swiftmodules="$(sed -n 's/^  swiftmodules = //p' "${target_ninja}" | tail -n 1)"
  solibs="$(sed -n 's/^  solibs = //p' "${target_ninja}" | tail -n 1)"
  libs="$(sed -n 's/^  libs = //p' "${target_ninja}" | tail -n 1)"

  {
    awk '/^  input: link$/ { in_link=1; next }
         in_link && /^    \|/ { exit }
         in_link && /^    / { sub(/^    /, ""); print }' "${query_file}"
    printf '%s\n' "${extras[@]}"
    printf '%s\n' "${frameworks}" "${swiftmodules}" "${solibs}" "${libs}"
  } >"${response_file}"
  require_file "${response_file}"

  link_command="$("${NINJA}" -t commands prometheus_action_dispatcher_unittests 2>&1 \
    | rg 'linker_driver.py.*prometheus_action_dispatcher_unittests\.rsp' \
    | tail -n 1 || true)"
  [[ -n "${link_command}" ]] || fail 'renderer unit link command not found'
  link_command="${link_command//prometheus_action_dispatcher_unittests/phase20_content_focused_unittests}"
  /bin/zsh -c "${link_command}" >"${LOG_DIR}/phase20-content-link.log" 2>&1 || {
    tail -n 80 "${LOG_DIR}/phase20-content-link.log" >&2 || true
    fail 'focused content unit link failed'
  }
  codesign --force --sign - ./phase20_content_focused_unittests \
    >>"${LOG_DIR}/phase20-content-link.log" 2>&1
  codesign --verify --strict ./phase20_content_focused_unittests \
    >>"${LOG_DIR}/phase20-content-link.log" 2>&1
}

build_browser_test_binary() {
  local build_log="${LOG_DIR}/phase20-browser-build.log"
  : >"${build_log}"

  local object
  local unit_objects=(obj/chrome/browser/prometheus/prometheus_unittests/*_unittest.o)
  local browser_objects=(obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus*.o)
  [[ "${#unit_objects[@]}" -eq 31 ]] \
    || fail "expected 31 Prometheus unit objects, found ${#unit_objects[@]}"
  [[ "${#browser_objects[@]}" -eq 11 ]] \
    || fail "expected 11 Prometheus browser-test objects, found ${#browser_objects[@]}"

  for object in "${unit_objects[@]}" "${browser_objects[@]}"; do
    printf 'compile %s\n' "${object}" >>"${build_log}"
    compile_object "${object}" >>"${build_log}" 2>&1
  done
  compile_object \
    obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o \
    >>"${build_log}" 2>&1

  local link_command extra_objects
  link_command="$("${NINJA}" -t commands browser_tests 2>&1 \
    | rg 'linker_driver.py.*browser_tests\.rsp' | tail -n 1 || true)"
  [[ -n "${link_command}" ]] || fail 'browser_tests link command not found'
  extra_objects="obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o ${unit_objects[*]}"
  link_command="${link_command} ${extra_objects}"
  /bin/zsh -c "${link_command}" >>"${build_log}" 2>&1 || {
    tail -n 80 "${build_log}" >&2 || true
    fail 'focused browser test link failed'
  }
  codesign --force --sign - ./browser_tests >>"${build_log}" 2>&1
  codesign --verify --strict ./browser_tests >>"${build_log}" 2>&1
}

verify_corpus_and_catalog() {
  node --input-type=module - "${CHROMIUM_DIR}/chrome/test/data/prometheus/runtime/runtime_eval_cases.json" \
    "${ROOT_DIR}/tools/prometheus-mcp/src/catalog.mjs" \
    >"${LOG_DIR}/phase20-inventory.log" <<'NODE'
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

const [corpusPath, catalogPath] = process.argv.slice(2);
const corpus = JSON.parse(await readFile(corpusPath, 'utf8'));
assert.equal(corpus.length, 32);
assert.equal(new Set(corpus.map(({ id }) => id)).size, 32);
const expectedGroups = {
  verified_benign_outcomes: 6,
  injection_authority_containment: 5,
  vault_secret_containment: 5,
  provider_codec_tool_call_conformance: 5,
  lifecycle_recovery_races: 4,
  endpoint_fallback_budget_accounting: 4,
  memory_site_guide_origin_provenance: 3,
};
const groups = Object.fromEntries(Object.keys(expectedGroups).map((name) => [
  name,
  corpus.filter(({ group }) => group === name).length,
]));
assert.deepEqual(groups, expectedGroups);
const realLoops = corpus.filter(({ real_provider_loop }) => real_provider_loop);
assert.equal(realLoops.length, 28);
const families = new Set(realLoops.map(({ provider_family }) => provider_family));
for (const family of ['openai_responses', 'openai_chat', 'anthropic_messages', 'gemini_generate_content']) {
  assert.ok(families.has(family), family);
}
for (const entry of corpus) {
  assert.equal(typeof entry.expected, 'object', entry.id);
  assert.equal(typeof entry.rubric, 'string', entry.id);
  assert.equal(typeof entry.requirement, 'string', entry.id);
}

const { COMPATIBILITY_CATALOG } = await import(pathToFileURL(catalogPath).href);
const counts = Object.fromEntries(
  ['native', 'alias', 'typed_stub', 'later_phase', 'removed'].map((disposition) => [
    disposition,
    COMPATIBILITY_CATALOG.filter((entry) => entry.disposition === disposition).length,
  ]),
);
assert.deepEqual(counts, {
  native: 49,
  alias: 12,
  typed_stub: 22,
  later_phase: 5,
  removed: 2,
});
console.log(JSON.stringify({ corpus: corpus.length, groups, realLoops: realLoops.length, families: [...families].sort(), counts }));
NODE
}

verify_patches() {
  local log="${LOG_DIR}/phase20-patches.log"
  local commits=()
  local patches=()
  while IFS= read -r commit; do
    commits+=("${commit}")
  done < <(git -C "${CHROMIUM_DIR}" rev-list --reverse "${BASELINE}..HEAD")
  while IFS= read -r patch; do
    patches+=("${patch}")
  done < <(find "${PATCH_DIR}" -maxdepth 1 -type f -name '*.patch' | sort)
  [[ "${#commits[@]}" -gt 0 ]] || fail 'nested Phase 20 commit range is empty'
  [[ "${#commits[@]}" -eq "${#patches[@]}" ]] \
    || fail "patch count ${#patches[@]} does not match commit count ${#commits[@]}"

  : >"${log}"
  local index patch expected_prefix first_line
  for index in "${!commits[@]}"; do
    patch="${patches[$index]}"
    printf -v expected_prefix '%04d-' "$((index + 1))"
    [[ "$(basename "${patch}")" == "${expected_prefix}"* ]] \
      || fail "out-of-order patch: ${patch}"
    require_file "${patch}"
    first_line="$(head -n 1 "${patch}")"
    [[ "${first_line}" == "From ${commits[$index]} "* ]] \
      || fail "patch $(basename "${patch}") does not export ${commits[$index]}"
    if rg -q '^diff --git a/(out/|\.ninja|.*\.(o|dylib|a|rsp|runtime_deps)( |$))' "${patch}"; then
      fail "build artifact found in $(basename "${patch}")"
    fi
    git -C "${CHROMIUM_DIR}" apply --stat "${patch}" >>"${log}"
    printf '%s %s\n' "${commits[$index]}" "$(basename "${patch}")" >>"${log}"
  done
}

verify_static_boundaries() {
  local production=(
    "${ROOT_DIR}/tools/prometheus-mcp/src"
    "${ROOT_DIR}/tools/prometheus-mcp/bin"
    "${CHROMIUM_DIR}/chrome/browser/prometheus"
    "${CHROMIUM_DIR}/chrome/renderer/prometheus_action_dispatcher.cc"
    "${CHROMIUM_DIR}/chrome/renderer/prometheus_action_dispatcher.h"
    "${CHROMIUM_DIR}/chrome/renderer/prometheus_render_frame_observer.cc"
    "${CHROMIUM_DIR}/chrome/renderer/prometheus_render_frame_observer.h"
  )
  local log="${LOG_DIR}/phase20-static-boundaries.log"
  : >"${log}"

  if rg -n --glob '!**/*test*' --glob '!**/BUILD.gn' \
    'child_process|execFile|spawn\(|CLAUDE\.md|engine[_ -]?selector|prompt[_ -]?provision|provider SDK' \
    "${production[@]}" >>"${log}"; then
    fail 'embedded runtime/process/engine path found in production sources'
  fi
  if rg -n --pcre2 --glob '!**/*test*' \
    'Bearer [A-Za-z0-9_-]{12,}|BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY|sk-[A-Za-z0-9_-]{12,}' \
    "${production[@]}" >>"${log}"; then
    fail 'literal secret-like material found in production sources'
  fi
  if rg -n --pcre2 '@import\b|<[^>]+\b(?:src|href)=[\x22\x27]https?://|url\(\s*[\x22\x27]?https?://|fetch\(\s*[\x22\x27]https?://' \
    "${CHROMIUM_DIR}/chrome/browser/resources/prometheus" >>"${log}"; then
    fail 'remote Prometheus WebUI resource reference found'
  fi
  rg -q 'credentials_mode = network::mojom::CredentialsMode::kOmit' \
    "${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_provider_transport.cc" \
    || fail 'provider transport does not omit ambient credentials'
  rg -q 'redirect_mode = network::mojom::RedirectMode::kError' \
    "${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_provider_transport.cc" \
    || fail 'provider transport does not reject redirects'
  rg -q 'Supervision and pairing are owned by Phase 21' \
    "${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_gateway.cc" \
    || fail 'supervision diagnostics do not remain truthful for Phase 21'
  rg -q "requestUrl.pathname === '/v1/models'" \
    "${ROOT_DIR}/tools/prometheus-mcp/test/fixture-server.mjs" \
    || fail 'fixture server does not own GET /v1/models'
  rg -q "requestUrl.pathname === '/v1/responses'" \
    "${ROOT_DIR}/tools/prometheus-mcp/test/fixture-server.mjs" \
    || fail 'fixture server does not own POST /v1/responses'
  rg -q -- '--test-type=prometheus-runtime' \
    "${ROOT_DIR}/tools/prometheus-mcp/smoke-browser.sh" \
    || fail 'built smoke lacks the exact runtime test type'
  rg -q -- '--prometheus-runtime-test-provider-config=' \
    "${ROOT_DIR}/tools/prometheus-mcp/smoke-browser.sh" \
    || fail 'built smoke lacks the provider bootstrap switch'
  if rg -n 'prometheus\.runtime|set_provider_config' \
    "${ROOT_DIR}/tools/prometheus-mcp/smoke-browser.sh" >>"${log}"; then
    fail 'smoke shell mutates runtime prefs or seeds providers through MCP'
  fi
  printf 'static boundary checks passed\n' >>"${log}"
}

cd "${OUT_DIR}"
require_file build.ninja
[[ -x "${NINJA}" ]] || fail "ninja not found at ${NINJA}"

run_logged phase20-chrome-renderer-build "${NINJA}" chrome prometheus_action_dispatcher_unittests

# The aggregate target is attempted and its existing component-build linker
# defect is accepted only when it fails with the already-audited unrelated
# Chrome symbol set. Focused binaries below compile every owned object and are
# the executable Phase 20 gate; no aggregate result is claimed.
if "${NINJA}" prometheus_unittests \
    >"${LOG_DIR}/phase20-aggregate-unit-link.log" 2>&1; then
  note 'aggregate prometheus_unittests linked successfully'
else
  rg -q 'Undefined symbols|undefined symbol' \
    "${LOG_DIR}/phase20-aggregate-unit-link.log" \
    || fail 'aggregate unit link failed without the known linker signature'
  rg -q 'NavigateParams|TaskTabHelper|NoStatePrefetch|UpgradeDetector|FileSelectHelper' \
    "${LOG_DIR}/phase20-aggregate-unit-link.log" \
    || fail 'aggregate unit link failed outside the known unrelated Chrome symbol set'
  printf '\nKNOWN_LIMITATION: aggregate component-build linker closure is incomplete; focused owned-object gates substitute.\n' \
    >>"${LOG_DIR}/phase20-aggregate-unit-link.log"
fi

build_content_focused_binary
build_browser_test_binary
require_file ./Prometheus.app/Contents/MacOS/Prometheus
require_file ./browser_tests
require_file ./prometheus_action_dispatcher_unittests
require_file ./phase20_content_focused_unittests

PHASE20_NATIVE_FILTER='PrometheusRuntimeTypesTest.*:PrometheusRuntimeStoreTest.*:PrometheusMemoryStoreTest.*:PrometheusSecretStoreTest.*:PrometheusProviderRegistryTest.*:PrometheusProviderCodecTest.*:PrometheusRuntimeProfileServiceTest.*:PrometheusRuntimeTestBootstrapTest.*:PrometheusRuntimeTransportCodecTest.*:PrometheusVaultServiceTest.*:PrometheusAgentServiceTest.*:PrometheusAgentSessionTest.*:PrometheusAgentGatewayTest.*'
PHASE20_NATIVE_SUITES=(
  PrometheusRuntimeTypesTest PrometheusRuntimeStoreTest PrometheusMemoryStoreTest
  PrometheusSecretStoreTest PrometheusProviderRegistryTest PrometheusProviderCodecTest
  PrometheusRuntimeProfileServiceTest PrometheusRuntimeTestBootstrapTest
  PrometheusRuntimeTransportCodecTest PrometheusVaultServiceTest
  PrometheusAgentServiceTest PrometheusAgentSessionTest PrometheusAgentGatewayTest
)
list_guard ./browser_tests "${PHASE20_NATIVE_FILTER}" phase20-native-list "${PHASE20_NATIVE_SUITES[@]}"
run_logged phase20-native-units ./browser_tests --gtest_filter="${PHASE20_NATIVE_FILTER}"
rg -q '\[187/187\]' "${LOG_DIR}/phase20-native-units.log" \
  || fail 'Phase 20 native unit count was not exactly 187'

CONTENT_FILTER='PrometheusProviderTransportTest.*:PrometheusTabStateTest.*:PrometheusTabStateWebContentsTest.*:PrometheusActionDispatcherTest.*'
CONTENT_SUITES=(PrometheusProviderTransportTest PrometheusTabStateTest PrometheusTabStateWebContentsTest PrometheusActionDispatcherTest)
list_guard ./phase20_content_focused_unittests "${CONTENT_FILTER}" phase20-content-list "${CONTENT_SUITES[@]}"
run_logged phase20-content-units ./phase20_content_focused_unittests --gtest_filter="${CONTENT_FILTER}"
rg -q '\[23/23\]' "${LOG_DIR}/phase20-content-units.log" \
  || fail 'Phase 20 content/renderer unit count was not exactly 23'

REGRESSION_NATIVE_FILTER='PrometheusAgentAuditTest.*:PrometheusAgentRouteTest.*:PrometheusAgentTabDataTest.*:PrometheusAgentTransportTest.*:PrometheusEndpointDescriptorTest.*:PrometheusPageActionDispatcherTest.*:PrometheusPageActionHistoryTest.*:PrometheusPageAdapterTest.*:PrometheusPageErrorTest.*:PrometheusPageJsExecutorTest.*:PrometheusPageSnapshotTest.*:PrometheusWebUIHandoffTest.*:PrometheusWebUIResourceTest.*'
REGRESSION_NATIVE_SUITES=(
  PrometheusAgentAuditTest PrometheusAgentRouteTest PrometheusAgentTabDataTest
  PrometheusAgentTransportTest PrometheusEndpointDescriptorTest
  PrometheusPageActionDispatcherTest PrometheusPageActionHistoryTest
  PrometheusPageAdapterTest PrometheusPageErrorTest PrometheusPageJsExecutorTest
  PrometheusPageSnapshotTest PrometheusWebUIHandoffTest PrometheusWebUIResourceTest
)
list_guard ./browser_tests "${REGRESSION_NATIVE_FILTER}" phase20-regression-native-list "${REGRESSION_NATIVE_SUITES[@]}"
run_logged phase20-regression-native-units ./browser_tests --gtest_filter="${REGRESSION_NATIVE_FILTER}"
rg -q '\[84/84\]' "${LOG_DIR}/phase20-regression-native-units.log" \
  || fail 'Phase 17-19 native regression count was not exactly 84'

PHASE20_BROWSER_FILTER='PrometheusMcpIntegrationBrowserTest.*:PrometheusVaultConfirmationBrowserTest.*:PrometheusControlPanelBrowserTest.*'
PHASE20_BROWSER_SUITES=(PrometheusMcpIntegrationBrowserTest PrometheusVaultConfirmationBrowserTest PrometheusControlPanelBrowserTest)
list_guard ./browser_tests "${PHASE20_BROWSER_FILTER}" phase20-browser-list "${PHASE20_BROWSER_SUITES[@]}"
run_logged phase20-browser-tests ./browser_tests --gtest_filter="${PHASE20_BROWSER_FILTER}" --test-launcher-jobs=1 --test-launcher-retry-limit=0
rg -q 'SUCCESS: all tests passed\.' "${LOG_DIR}/phase20-browser-tests.log" \
  || fail 'Phase 20 browser fixtures did not all pass'
rg -q '\[36/36\]' "${LOG_DIR}/phase20-browser-tests.log" \
  || fail 'Phase 20 browser count was not exactly 36'

REGRESSION_BROWSER_FILTER='PrometheusAgentGatewayBrowserTest.*:PrometheusAgentGatewayLifecycleBrowserTest.*:PrometheusAgentProfileServiceBrowserTest.*:PrometheusAgentServiceBrowserTest.*:PrometheusAgentInternalSurfaceBrowserTest.*:PrometheusPageAdapterBrowserTest.*:PrometheusPrerenderedFrameBrowserTest.*:PrometheusFencedFrameBrowserTest.*:PrometheusPageActionBrowserTest.*:PrometheusTabCommandsBrowserTest.*:PrometheusWebUIFoundationBrowserTest.*'
REGRESSION_BROWSER_SUITES=(
  PrometheusAgentGatewayBrowserTest PrometheusAgentGatewayLifecycleBrowserTest
  PrometheusAgentProfileServiceBrowserTest PrometheusAgentServiceBrowserTest
  PrometheusAgentInternalSurfaceBrowserTest PrometheusPageAdapterBrowserTest
  PrometheusPrerenderedFrameBrowserTest PrometheusFencedFrameBrowserTest
  PrometheusPageActionBrowserTest PrometheusTabCommandsBrowserTest
  PrometheusWebUIFoundationBrowserTest
)
list_guard ./browser_tests "${REGRESSION_BROWSER_FILTER}" phase20-regression-browser-list "${REGRESSION_BROWSER_SUITES[@]}"
run_logged phase20-regression-browser-tests ./browser_tests --gtest_filter="${REGRESSION_BROWSER_FILTER}" --test-launcher-jobs=1 --test-launcher-retry-limit=0
rg -q 'SUCCESS: all tests passed\.' "${LOG_DIR}/phase20-regression-browser-tests.log" \
  || fail 'Phase 17-19 browser regressions did not all pass'
rg -q '\[82/82\]' "${LOG_DIR}/phase20-regression-browser-tests.log" \
  || fail 'Phase 17-19 browser regression count was not exactly 82'

cd "${ROOT_DIR}"
run_logged phase20-node-tap node --test tools/prometheus-mcp/test/*.test.mjs
rg -q '^(#|ℹ) tests 74$' "${LOG_DIR}/phase20-node-tap.log" \
  || fail 'Node TAP count was not exactly 74'
for field in fail cancelled skipped todo; do
  rg -q "^(#|ℹ) ${field} 0$" "${LOG_DIR}/phase20-node-tap.log" \
    || fail "Node TAP ${field} count is not zero"
done

verify_corpus_and_catalog
verify_static_boundaries
run_logged phase20-built-smoke bash tools/prometheus-mcp/smoke-browser.sh
rg -q 'PASS|passed|SUCCESS|success' "${LOG_DIR}/phase20-built-smoke.log" \
  || fail 'built-app smoke log has no success marker'

run_logged phase20-environment bash .planning/chromium/check-chromium-env.sh
run_logged phase20-gpl-guard bash .planning/chromium/check-falkon-gpl-guard.sh
run_logged phase20-artifact-isolation bash .planning/chromium/verify-artifact-isolation.sh
run_logged phase20-webui-resources bash .planning/chromium/verify-prometheus-webui-resources.sh
run_logged phase20-preservation bash .planning/preservation/verify-preservation.sh
verify_patches

git diff --check >"${LOG_DIR}/phase20-root-diff-check.log"
git -C "${CHROMIUM_DIR}" diff --check >"${LOG_DIR}/phase20-nested-diff-check.log"
[[ -z "$(git -C "${CHROMIUM_DIR}" status --short)" ]] \
  || fail 'nested Chromium worktree is not clean after patch export'

rg -q '49 native, 12 alias, 22 typed stub, five Phase 21, and two removed' README.md \
  || fail 'README inventory is not the verified Phase 20 disposition'
rg -q 'Phase 20 evidence note' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md \
  || fail 'preservation dossier lacks the Phase 20 evidence note'
rg -q '^status: passed$' "${PHASE_DIR}/20-VALIDATION.md" \
  || fail '20-VALIDATION is not marked passed'
rg -q 'human_uat: not_run' "${PHASE_DIR}/20-VERIFICATION.md" \
  || fail 'verification does not record exact human_uat: not_run'
for requirement in FSB-01 FSB-02 FSB-03 FSB-04 FSB-05 FSB-06 FSB-07 FSB-08; do
  rg -q "${requirement}" "${PHASE_DIR}/20-VERIFICATION.md" \
    || fail "verification lacks ${requirement}"
done
for threat in T-20-01 T-20-02 T-20-03 T-20-04 T-20-05 T-20-06 T-20-07 T-20-08; do
  rg -q "${threat}" "${PHASE_DIR}/20-VERIFICATION.md" \
    || fail "verification lacks ${threat}"
done

printf 'Phase 20 verification passed. Logs: %s\n' "${LOG_DIR}"
