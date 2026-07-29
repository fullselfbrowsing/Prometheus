#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

FOCUSED=false
EXPECT_FAILURE=false

usage() {
  printf 'Usage: %s [--focused] [--expect-failure]\n' "$0" >&2
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --focused)
      [[ "${FOCUSED}" == false ]] || {
        usage
        exit 2
      }
      FOCUSED=true
      shift
      ;;
    --expect-failure)
      [[ "${EXPECT_FAILURE}" == false ]] || {
        usage
        exit 2
      }
      EXPECT_FAILURE=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
LOG_DIR="${OUT_DIR}/phase22-mcp"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/native-list.log"
TEST_LOG="${LOG_DIR}/native-test.log"
NODE_LIST_LOG="${LOG_DIR}/node-list.log"
NODE_TEST_LOG="${LOG_DIR}/node-test.log"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
BINARY="${OUT_DIR}/phase22_mcp_tests"
NODE_TEST="${ROOT_DIR}/tools/prometheus-mcp/test/diagnostics.test.mjs"
NATIVE_FILTER='PrometheusGatewayHealthTest.*:PrometheusAgentGatewayBrowserTest.ExtensionHealthIsLiveBoundedAndInventoryFree'
METADATA_CAPTURED=false
NATIVE_RED_FAILURES=(
  'PrometheusAgentGatewayBrowserTest.ExtensionHealthIsLiveBoundedAndInventoryFree'
  'PrometheusGatewayHealthTest.LiveExtensionStateIsOrderedBoundedAndInventoryFree'
)
NODE_RED_FAILURES=(
  'Phase 22 extension diagnostics preserve live bounded status and recovery'
  'Phase 22 extension diagnostics reject malformed state and recursive inventory'
)

fail() {
  printf 'Phase 22 MCP verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-mcp] %s\n' "$1"
}

require_file() {
  [[ -s "$1" ]] || fail "missing or empty file: $1"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

capture_metadata() {
  require_file "${OUT_DIR}/.ninja_log"
  require_file "${OUT_DIR}/.ninja_deps"
  NINJA_LOG_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_log")"
  NINJA_DEPS_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_deps")"
  METADATA_CAPTURED=true
}

verify_metadata_on_exit() {
  local status="$?"
  trap - EXIT
  if [[ "${METADATA_CAPTURED}" == true ]]; then
    local ninja_log_after ninja_deps_after
    ninja_log_after="$(sha256_file "${OUT_DIR}/.ninja_log" 2>/dev/null || true)"
    ninja_deps_after="$(sha256_file "${OUT_DIR}/.ninja_deps" 2>/dev/null || true)"
    printf '[phase22-mcp] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_BEFORE}" "${ninja_log_after}"
    printf '[phase22-mcp] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_BEFORE}" ]]; then
      printf 'Phase 22 MCP verification failed: direct verification changed reviewed build metadata\n' >&2
      status=1
    fi
  fi
  exit "${status}"
}

query_compile_command() {
  local object="$1"
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${object}" 2>/dev/null |
    LC_ALL=C awk -v output=" -o ${object}" \
      'index($0, output) { command = $0 } END { print command }'
}

compile_exact_object() {
  local object="$1"
  local command
  command="$(query_compile_command "${object}" || true)"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail "direct compile failed for ${object}"
  }
}

compile_synthesized_object() {
  local template_object="$1"
  local object="$2"
  local template_stem="$3"
  local target_stem="$4"
  local command
  command="$(query_compile_command "${template_object}" || true)"
  [[ -n "${command}" ]] ||
    fail "compile template not found for ${template_object}"
  command="${command//${template_stem}/${target_stem}}"
  [[ "${command}" == *" -o ${object}"* ]] ||
    fail "synthesized command does not produce ${object}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail "direct synthesized compile failed for ${object}"
  }
}

query_browser_link_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" browser_tests 2>/dev/null |
    LC_ALL=C awk '
      index($0, "linker_driver.py") && index($0, "@./browser_tests.rsp") {
        command = $0
      }
      END { print command }
    '
}

build_focused_response() {
  require_file "${OUT_DIR}/browser_tests.rsp"
  LC_ALL=C awk '
    BEGIN { RS = "[[:space:]]+" }
    NF { print $0 }
  ' "${OUT_DIR}/browser_tests.rsp" >"${FOCUSED_RESPONSE}"
  require_file "${FOCUSED_RESPONSE}"
}

append_response_object() {
  local object="$1"
  require_file "${OUT_DIR}/${object}"
  if ! rg -Fxq -- "${object}" "${FOCUSED_RESPONSE}"; then
    printf '%s\n' "${object}" >>"${FOCUSED_RESPONSE}"
  fi
}

build_focused_binary() {
  local gateway='obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_agent_gateway.o'
  local gateway_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_gateway_unittest.o'
  local gateway_browser='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_agent_gateway_browsertest.o'
  local runtime_types='obj/chrome/browser/prometheus/prometheus_runtime_types/prometheus_runtime_types.o'
  local runtime_prefs='obj/chrome/browser/prometheus/prometheus_runtime_prefs/prometheus_runtime_prefs.o'
  local runtime_service='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
  local runtime_factory='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service_factory.o'
  local policy_types='obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o'
  local policy_prefs='obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o'
  local policy_service='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o'
  local policy_factory='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service_factory.o'
  local objects=(
    "${gateway}"
    "${gateway_test}"
    "${gateway_browser}"
    "${policy_types}"
    "${policy_prefs}"
    "${policy_service}"
    "${policy_factory}"
  )
  local link_extras=(
    obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o
    obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o
    obj/chrome/browser/prometheus/prometheus_supervision_types/prometheus_supervision_types.o
    obj/chrome/browser/prometheus/prometheus_supervision_transport_codec/prometheus_supervision_transport_codec.o
    obj/chrome/browser/prometheus/prometheus_supervision_projection/prometheus_supervision_projection.o
    obj/chrome/browser/prometheus/prometheus_supervision_diff/prometheus_supervision_diff.o
    obj/chrome/browser/prometheus/prometheus_supervision_profile_service/prometheus_supervision_profile_service.o
    obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_supervision_profile_service_factory.o
    obj/chrome/browser/prometheus/prometheus_supervision_capture_hub/prometheus_supervision_capture_hub.o
    obj/chrome/browser/prometheus/prometheus_supervision_action_controller/prometheus_supervision_action_controller.o
    obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o
    obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o
    obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o
    obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o
  )

  : >"${BUILD_LOG}"
  compile_exact_object "${gateway}"
  compile_exact_object "${gateway_test}"
  compile_exact_object "${gateway_browser}"
  compile_synthesized_object "${runtime_types}" "${policy_types}" \
    prometheus_runtime_types prometheus_extension_policy_types
  compile_synthesized_object "${runtime_prefs}" "${policy_prefs}" \
    prometheus_runtime_prefs prometheus_extension_policy_prefs
  compile_synthesized_object "${runtime_service}" "${policy_service}" \
    prometheus_runtime_profile_service prometheus_extension_policy_service
  compile_synthesized_object "${runtime_factory}" "${policy_factory}" \
    prometheus_runtime_profile_service prometheus_extension_policy_service
  build_focused_response
  local object
  for object in "${objects[@]}"; do
    append_response_object "${object}"
  done
  for object in "${link_extras[@]}"; do
    append_response_object "${object}"
  done

  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] ||
    fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output='-o "./phase22_mcp_tests"'
  local original_response='@./browser_tests.rsp'
  local focused_response='@./phase22-mcp/focused-browser-tests.rsp'
  [[ "${link_command}" == *"${original_output}"* ]] ||
    fail 'browser_tests output argument was not found'
  [[ "${link_command}" == *"${original_response}"* ]] ||
    fail 'browser_tests response argument was not found'
  link_command="${link_command/${original_output}/${focused_output}}"
  link_command="${link_command/${original_response}/${focused_response}}"

  rm -f "${BINARY}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - ./phase22_mcp_tests
    codesign --verify --strict ./phase22_mcp_tests
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 160 "${BUILD_LOG}" >&2 || true
    fail 'focused MCP native/browser link failed'
  }
  require_file "${BINARY}"
}

count_listed_gtests() {
  LC_ALL=C awk '
    /^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
    END { print count + 0 }
  ' "$1"
}

list_native_tests() {
  "${BINARY}" --gtest_list_tests --gtest_filter="${NATIVE_FILTER}" \
    >"${LIST_LOG}" 2>&1 ||
    fail 'native/browser focused test discovery failed'
  local count
  count="$(count_listed_gtests "${LIST_LOG}")"
  [[ "${count}" -eq 2 ]] ||
    fail "native/browser filter expected 2 runnable tests, found ${count}"
  rg -q '^PrometheusGatewayHealthTest\.' "${LIST_LOG}" ||
    fail 'native unit list guard selected zero gateway-health tests'
  rg -q '^PrometheusAgentGatewayBrowserTest\.' "${LIST_LOG}" ||
    fail 'browser list guard selected zero extension-health tests'
  if rg -q 'DISABLED_' "${LIST_LOG}"; then
    fail 'native/browser focused list contains a disabled test'
  fi
  note "selected ${count} runnable native/browser tests"
}

assert_expected_lines() {
  local expected_file="$1"
  local actual_file="$2"
  local label="$3"
  shift 3
  printf '%s\n' "$@" | LC_ALL=C sort -u >"${expected_file}"
  LC_ALL=C sort -u -o "${actual_file}" "${actual_file}"
  if ! diff -u "${expected_file}" "${actual_file}" \
      >"${actual_file}.diff"; then
    cat "${actual_file}.diff" >&2
    fail "${label} failures differ from the retained RED allowlist"
  fi
}

run_native_tests() {
  local status
  set +e
  "${BINARY}" --gtest_filter="${NATIVE_FILTER}" \
    --test-launcher-jobs=1 \
    --test-launcher-retry-limit=0 \
    >"${TEST_LOG}" 2>&1
  status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -eq 1 ]] || {
      tail -n 160 "${TEST_LOG}" >&2 || true
      fail "--expect-failure requires native assertion status 1, got ${status}"
    }
    local actual="${LOG_DIR}/native-red-failures.log"
    sed -nE \
      's/^\[  FAILED  \] ([^, ]+)(, where .*)? \([0-9]+ ms\)$/\1/p' \
      "${TEST_LOG}" >"${actual}"
    assert_expected_lines "${LOG_DIR}/native-red-expected.log" "${actual}" \
      native/browser "${NATIVE_RED_FAILURES[@]}"
    if rg -qi \
        'segmentation fault|received signal|check failed|fatal error|addresssanitizer|crash|timed out|timeout' \
        "${TEST_LOG}"; then
      tail -n 160 "${TEST_LOG}" >&2 || true
      fail 'native/browser RED cohort crashed or timed out'
    fi
    if rg -q '^\[  SKIPPED \] [1-9][0-9]* test' "${TEST_LOG}"; then
      fail 'native/browser RED cohort skipped a selected test'
    fi
    note 'native/browser RED failed only through retained assertions'
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 180 "${TEST_LOG}" >&2 || true
    fail "native/browser focused suite failed with status ${status}"
  }
  rg -q 'SUCCESS: all tests passed\.' "${TEST_LOG}" ||
    fail 'native/browser focused suite lacks launcher success marker'
  rg -q '\[2/2\]' "${TEST_LOG}" ||
    fail 'native/browser focused suite did not pass exactly 2/2'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' \
      "${TEST_LOG}"; then
    fail 'native/browser focused suite reported a failure or skip'
  fi
  note 'native/browser focused suite passed 2/2'
}

list_node_tests() {
  require_file "${NODE_TEST}"
  node --check "${NODE_TEST}" >"${LOG_DIR}/node-syntax.log" 2>&1 ||
    fail 'Node diagnostics syntax check failed'
  if rg -n --pcre2 \
      "(?:from|require\\()\\s*['\"]node:(?:http|https|net|tls|dns)|\\bfetch\\s*\\(" \
      "${NODE_TEST}" "${ROOT_DIR}/tools/prometheus-mcp/src/tool-handler.mjs" \
      >"${LOG_DIR}/node-network-guard.log"; then
    fail 'focused diagnostics cohort references an external network API'
  fi
  node --input-type=module - "${NODE_TEST}" >"${NODE_LIST_LOG}" <<'NODE_LIST'
import { readFileSync } from 'node:fs';

const source = readFileSync(process.argv[2], 'utf8');
const names = [...source.matchAll(/^\s*test\(\s*(['"])([^'"\n]+)\1\s*,/gmu)]
  .map((match) => match[2]);
if (names.length === 0 || new Set(names).size !== names.length) process.exit(1);
for (const name of names) process.stdout.write(`${name}\n`);
NODE_LIST
  local selected
  selected="$(rg -c '^Phase 22 extension diagnostics ' "${NODE_LIST_LOG}")"
  [[ "${selected}" -eq 2 ]] ||
    fail "Node list guard expected 2 Phase 22 tests, found ${selected}"
  note "selected ${selected} retained Phase 22 Node tests"
}

run_node_tests() {
  local status
  set +e
  node --test "${NODE_TEST}" >"${NODE_TEST_LOG}" 2>&1
  status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -eq 1 ]] || {
      tail -n 140 "${NODE_TEST_LOG}" >&2 || true
      fail "--expect-failure requires Node assertion status 1, got ${status}"
    }
    local actual="${LOG_DIR}/node-red-failures.log"
    sed -nE 's/^✖ (.*) \([^)]*ms\)$/\1/p' \
      "${NODE_TEST_LOG}" >"${actual}"
    assert_expected_lines "${LOG_DIR}/node-red-expected.log" "${actual}" \
      Node "${NODE_RED_FAILURES[@]}"
    if rg -qi \
        'segmentation fault|received signal|fatal error|addresssanitizer|crash|timed out|timeout' \
        "${NODE_TEST_LOG}"; then
      tail -n 140 "${NODE_TEST_LOG}" >&2 || true
      fail 'Node RED cohort crashed or timed out'
    fi
    for field in cancelled skipped todo; do
      rg -q "^(#|ℹ) ${field} 0$" "${NODE_TEST_LOG}" ||
        fail "Node RED cohort ${field} count is not zero"
    done
    note 'Node RED failed only through retained assertions'
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 160 "${NODE_TEST_LOG}" >&2 || true
    fail "Node diagnostics suite failed with status ${status}"
  }
  for field in fail cancelled skipped todo; do
    rg -q "^(#|ℹ) ${field} 0$" "${NODE_TEST_LOG}" ||
      fail "Node diagnostics ${field} count is not zero"
  done
  note 'Node diagnostics suite passed without failures or skips'
}

mkdir -p "${LOG_DIR}"
require_file "${SISO}"
require_file "${OUT_DIR}/build.ninja"
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_native_tests
list_node_tests
run_native_tests
run_node_tests

if [[ "${EXPECT_FAILURE}" == true ]]; then
  note 'retained live-health RED gate completed through assertion-only failures'
else
  note 'live bounded extension health verification passed'
fi
note "verification complete; logs: ${LOG_DIR}"
