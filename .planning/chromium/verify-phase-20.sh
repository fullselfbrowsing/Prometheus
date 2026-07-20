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
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
EXPECTED_NINJA_LOG_SHA256="eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce"
EXPECTED_NINJA_DEPS_SHA256="ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0"
COMPILE_COMMANDS="${LOG_DIR}/phase20-direct-compile-commands.log"
COMPILE_OBJECTS="${LOG_DIR}/phase20-direct-compile-objects.log"

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

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

capture_build_metadata() {
  require_file "${OUT_DIR}/.ninja_log"
  require_file "${OUT_DIR}/.ninja_deps"
  NINJA_LOG_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_log")"
  NINJA_DEPS_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_deps")"
  [[ "${NINJA_LOG_SHA256_BEFORE}" == "${EXPECTED_NINJA_LOG_SHA256}" ]] \
    || fail 'the restored .ninja_log does not match the reviewed build metadata'
  [[ "${NINJA_DEPS_SHA256_BEFORE}" == "${EXPECTED_NINJA_DEPS_SHA256}" ]] \
    || fail 'the restored .ninja_deps does not match the reviewed build metadata'
}

verify_build_metadata_preserved() {
  [[ "$(sha256_file "${OUT_DIR}/.ninja_log")" == "${NINJA_LOG_SHA256_BEFORE}" ]] \
    || fail 'direct verification changed .ninja_log'
  [[ "$(sha256_file "${OUT_DIR}/.ninja_deps")" == "${NINJA_DEPS_SHA256_BEFORE}" ]] \
    || fail 'direct verification changed .ninja_deps'
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
  command="$(awk -v output=" -o ${object}" \
    'index($0, output) { command = $0 } END { print command }' \
    "${COMPILE_COMMANDS}")"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  /bin/zsh -c "${command}"
}

collect_compile_objects() {
  PHASE20_PRODUCTION_OBJECTS=()
  while IFS= read -r object; do
    PHASE20_PRODUCTION_OBJECTS+=("${object}")
  done < <(find obj/chrome/browser/prometheus -mindepth 2 -maxdepth 3 \
    -type f -name 'prometheus*.o' \
    ! -path '*/prometheus_unittests/*' | sort)
  PHASE20_UNIT_OBJECTS=(
    obj/chrome/browser/prometheus/prometheus_unittests/*_unittest.o
  )
  PHASE20_BROWSER_OBJECTS=(
    obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus*.o
  )
  PHASE20_RENDERER_OBJECTS=(
    obj/chrome/renderer/prometheus_action_dispatcher_unittests/prometheus_action_dispatcher.o
    obj/chrome/renderer/prometheus_action_dispatcher_unittests/prometheus_action_dispatcher_unittest.o
    obj/chrome/renderer/renderer/prometheus_action_dispatcher.o
    obj/chrome/renderer/renderer/prometheus_render_frame_observer.o
  )
  PHASE20_OTHER_OBJECTS=(
    obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o
  )

  [[ "${#PHASE20_PRODUCTION_OBJECTS[@]}" -eq 39 ]] \
    || fail "expected 39 Prometheus production objects, found ${#PHASE20_PRODUCTION_OBJECTS[@]}"
  [[ "${#PHASE20_UNIT_OBJECTS[@]}" -eq 31 ]] \
    || fail "expected 31 Prometheus unit objects, found ${#PHASE20_UNIT_OBJECTS[@]}"
  [[ "${#PHASE20_BROWSER_OBJECTS[@]}" -eq 11 ]] \
    || fail "expected 11 Prometheus browser-test objects, found ${#PHASE20_BROWSER_OBJECTS[@]}"

  PHASE20_COMPILE_OBJECTS=(
    "${PHASE20_PRODUCTION_OBJECTS[@]}"
    "${PHASE20_UNIT_OBJECTS[@]}"
    "${PHASE20_BROWSER_OBJECTS[@]}"
    "${PHASE20_RENDERER_OBJECTS[@]}"
    "${PHASE20_OTHER_OBJECTS[@]}"
  )
}

prepare_compile_commands() {
  note 'querying exact direct compile commands with Siso'
  local runtime_contract="obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o"
  local runtime_template="obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o"
  local query_objects=()
  local object
  for object in "${PHASE20_COMPILE_OBJECTS[@]}"; do
    if [[ "${object}" != "${runtime_contract}" ]]; then
      query_objects+=("${object}")
    fi
  done
  printf '%s\n' "${PHASE20_COMPILE_OBJECTS[@]}" >"${COMPILE_OBJECTS}"
  printf '%s\n' "${query_objects[@]}" >"${COMPILE_OBJECTS}.query"
  if ! LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" \
      "${query_objects[@]}" \
      2>"${LOG_DIR}/phase20-direct-compile-query-errors.log" \
      | LC_ALL=C awk '
          NR == FNR { wanted[$0] = 1; next }
          {
            for (field = 1; field < NF; ++field) {
              if ($field == "-o" && wanted[$(field + 1)]) {
                print
                break
              }
            }
          }
        ' "${COMPILE_OBJECTS}.query" - >"${COMPILE_COMMANDS}"; then
    fail 'Siso compile-command query failed'
  fi
  local template_command
  template_command="$(awk -v output=" -o ${runtime_template}" \
    'index($0, output) { command = $0 } END { print command }' \
    "${COMPILE_COMMANDS}")"
  [[ -n "${template_command}" ]] \
    || fail 'runtime tool contract compile template was not found'
  local old_stem="${runtime_template%.o}"
  local new_stem="${runtime_contract%.o}"
  template_command="${template_command//${old_stem}/${new_stem}}"
  template_command="${template_command//..\/..\/chrome\/browser\/prometheus\/prometheus_runtime_profile_service.cc/..\/..\/chrome\/browser\/prometheus\/prometheus_runtime_tool_contract.cc}"
  printf '%s\n' "${template_command}" >>"${COMPILE_COMMANDS}"
  require_file "${COMPILE_COMMANDS}"
  [[ "$(wc -l <"${COMPILE_COMMANDS}" | tr -d ' ')" -eq \
      "${#PHASE20_COMPILE_OBJECTS[@]}" ]] \
    || fail 'Siso query did not return one command per owned object'
}

compile_phase20_objects() {
  local log="${LOG_DIR}/phase20-direct-build.log"
  : >"${log}"
  local object
  for object in "${PHASE20_COMPILE_OBJECTS[@]}"; do
    printf 'compile %s\n' "${object}" >>"${log}"
    compile_object "${object}" >>"${log}" 2>&1 || {
      tail -n 80 "${log}" >&2 || true
      fail "direct compile failed for ${object}"
    }
  done
}

query_link_command() {
  local target="$1"
  local response_file="$2"
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${target}" 2>/dev/null \
    | LC_ALL=C awk -v marker="@./${response_file}" \
        'index($0, "linker_driver.py") && index($0, marker) {
           command = $0
         }
         END { print command }'
}

write_link_response() {
  local target_ninja="$1"
  local edge_output="$2"
  local response_file="$3"
  shift 3

  {
    perl -0777 -pe 's/\$\r?\n//g' "${target_ninja}" \
      | awk -v output="${edge_output}" '
          $1 == "build" {
            first = $2
            sub(/:$/, "", first)
            if (first != output) next
            start = 0
            for (i = 1; i <= NF; ++i) {
              if ($i == "link" || $i == "solink" ||
                  $i == "solink_module") {
                start = i + 1
                break
              }
            }
            if (!start) exit 2
            for (i = start; i <= NF; ++i) {
              if ($i == "|" || $i == "||") break
              printf "%s ", $i
            }
            found = 1
            exit
          }
          END { if (!found) exit 2 }
        '
    local extra
    for extra in "$@"; do
      printf '%s ' "${extra}"
    done
    perl -0777 -pe 's/\$\r?\n//g' "${target_ninja}" \
      | awk -v output="${edge_output}" '
          function value(prefix) {
            return substr($0, length(prefix) + 1)
          }
          $1 == "build" {
            if (active) exit
            first = $2
            sub(/:$/, "", first)
            if (first == output) {
              active = 1
              found = 1
            }
            next
          }
          active && /^  frameworks = / { frameworks = value("  frameworks = ") }
          active && /^  swiftmodules = / { swiftmodules = value("  swiftmodules = ") }
          active && /^  solibs = / { solibs = value("  solibs = ") }
          active && /^  libs = / { libs = value("  libs = ") }
          END {
            if (!found) exit 2
            printf "%s %s %s %s\n", frameworks, swiftmodules, solibs, libs
          }
        '
  } >"${response_file}"
  require_file "${response_file}"
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
  local link_command

  local extras=(
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_provider_transport_unittest.o
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_tab_state_unittest.o
    obj/chrome/browser/prometheus/prometheus_provider_transport/prometheus_provider_transport.o
    obj/chrome/browser/prometheus/prometheus_provider_registry/prometheus_provider_registry.o
    obj/chrome/browser/prometheus/prometheus_provider_codec/prometheus_provider_codec.o
    obj/chrome/browser/prometheus/prometheus_secret_store/prometheus_secret_store.o
    obj/chrome/browser/prometheus/prometheus_runtime_prefs/prometheus_runtime_prefs.o
    obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o
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
  for object in "${extras[@]}"; do
    require_file "${object}"
  done

  write_link_response "${target_ninja}" \
    ./prometheus_action_dispatcher_unittests "${response_file}" \
    "${extras[@]}"
  link_command="$(query_link_command prometheus_action_dispatcher_unittests \
    prometheus_action_dispatcher_unittests.rsp)"
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

  require_file ./browser_tests.rsp
  local runtime_dialogs="obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o"
  local runtime_contract="obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o"

  local candidates=(
    "${runtime_dialogs}"
    "${runtime_contract}"
    "${PHASE20_UNIT_OBJECTS[@]}"
  )
  local extra_objects=()
  local object
  for object in "${candidates[@]}"; do
    require_file "${object}"
    if ! rg -q --fixed-strings -- "${object}" ./browser_tests.rsp; then
      extra_objects+=("${object}")
    fi
  done

  local link_command
  link_command="$(query_link_command browser_tests browser_tests.rsp)"
  [[ -n "${link_command}" ]] || fail 'browser_tests link command not found'
  local original_output='-o "./browser_tests"'
  local temporary_output='-o "./phase20_browser_tests"'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'browser_tests output argument was not found'
  link_command="${link_command/${original_output}/${temporary_output}}"
  link_command="${link_command} ${extra_objects[*]}"
  rm -f ./phase20_browser_tests
  /bin/zsh -c "${link_command}" >>"${build_log}" 2>&1 || {
    tail -n 80 "${build_log}" >&2 || true
    fail 'focused browser test link failed'
  }
  require_file ./phase20_browser_tests
  codesign --force --sign - ./phase20_browser_tests >>"${build_log}" 2>&1
  codesign --verify --strict ./phase20_browser_tests >>"${build_log}" 2>&1
  mv -f ./phase20_browser_tests ./browser_tests
}

build_app_runtime() {
  local build_log="${LOG_DIR}/phase20-app-runtime-link.log"
  local target_ninja="obj/chrome/chrome_dll.ninja"
  local runtime_contract="obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o"
  require_file "${target_ninja}"
  require_file "${runtime_contract}"

  write_link_response "${target_ninja}" ./libchrome_dll.dylib \
    ./libchrome_dll.dylib.rsp "${runtime_contract}"
  local link_command
  link_command="$(query_link_command libchrome_dll.dylib \
    libchrome_dll.dylib.rsp)"
  [[ -n "${link_command}" ]] || fail 'libchrome_dll link command not found'
  local original_output='-o "./libchrome_dll.dylib"'
  local temporary_output='-o "./phase20_libchrome_dll.dylib"'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'libchrome_dll output argument was not found'
  link_command="${link_command/${original_output}/${temporary_output}}"

  rm -f ./phase20_libchrome_dll.dylib
  /bin/zsh -c "${link_command}" >"${build_log}" 2>&1 || {
    tail -n 80 "${build_log}" >&2 || true
    fail 'direct libchrome_dll link failed'
  }
  require_file ./phase20_libchrome_dll.dylib
  codesign --force --sign - ./phase20_libchrome_dll.dylib \
    >>"${build_log}" 2>&1
  codesign --verify --strict ./phase20_libchrome_dll.dylib \
    >>"${build_log}" 2>&1
  mv -f ./phase20_libchrome_dll.dylib ./libchrome_dll.dylib
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
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
shopt -s nullglob
capture_build_metadata
collect_compile_objects
prepare_compile_commands
compile_phase20_objects
printf '%s\n' \
  'NOT_RUN: the aggregate component-build unit closure is unrelated to the owned focused gates.' \
  >"${LOG_DIR}/phase20-aggregate-unit-link.log"

build_content_focused_binary
build_browser_test_binary
build_app_runtime
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
rg -q '\[202/202\]' "${LOG_DIR}/phase20-native-units.log" \
  || fail 'Phase 20 native unit count was not exactly 202'

CONTENT_FILTER='PrometheusProviderTransportTest.*:PrometheusTabStateTest.*:PrometheusTabStateWebContentsTest.*:PrometheusActionDispatcherTest.*'
CONTENT_SUITES=(PrometheusProviderTransportTest PrometheusTabStateTest PrometheusTabStateWebContentsTest PrometheusActionDispatcherTest)
list_guard ./phase20_content_focused_unittests "${CONTENT_FILTER}" phase20-content-list "${CONTENT_SUITES[@]}"
run_logged phase20-content-units ./phase20_content_focused_unittests --gtest_filter="${CONTENT_FILTER}"
rg -q '\[24/24\]' "${LOG_DIR}/phase20-content-units.log" \
  || fail 'Phase 20 content/renderer unit count was not exactly 24'

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
rg -q '\[83/83\]' "${LOG_DIR}/phase20-regression-browser-tests.log" \
  || fail 'Phase 17-19 browser regression count was not exactly 83'

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
verify_build_metadata_preserved

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
