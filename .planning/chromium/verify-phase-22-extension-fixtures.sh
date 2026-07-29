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
FIXTURE_DIR="${CHROMIUM_DIR}/chrome/test/data/prometheus/extensions"
SOURCE="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_extension_fixtures_browsertest.cc"
BUILD_FILE="${CHROMIUM_DIR}/chrome/browser/ui/views/prometheus/BUILD.gn"
LOG_DIR="${OUT_DIR}/phase22-extension-fixtures"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
BINARY="${OUT_DIR}/prometheus_extension_fixture_tests"
FILTER='PrometheusExtensionFixturesBrowserTest.*'
METADATA_CAPTURED=false

EXPECTED_RED_FAILURES=(
  'PrometheusExtensionFixturesBrowserTest.AdBlockerLifecycleAndPermissionIsolation'
  'PrometheusExtensionFixturesBrowserTest.DeveloperWorkflowLifecycleAndWorkerIsolation'
  'PrometheusExtensionFixturesBrowserTest.PasswordManagerLikeLifecycleAndIsolation'
  'PrometheusExtensionFixturesBrowserTest.ProductivityContentScriptRoutingAndIsolation'
  'PrometheusExtensionFixturesBrowserTest.SidePanelToolingVisibilityAndIsolation'
)

FIXTURE_NAMES=(
  password_manager_like
  ad_blocker
  productivity_content_script
  side_panel_tooling
  developer_workflow
)

fail() {
  printf 'Phase 22 extension-fixture verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-extension-fixtures] %s\n' "$1"
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
    printf '[phase22-extension-fixtures] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_BEFORE}" "${ninja_log_after}"
    printf '[phase22-extension-fixtures] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_BEFORE}" ]]; then
      printf 'Phase 22 extension-fixture verification failed: direct verification changed reviewed build metadata\n' >&2
      status=1
    fi
  fi
  exit "${status}"
}

verify_fixture_inventory() {
  local manifests=()
  local name manifest
  for name in "${FIXTURE_NAMES[@]}"; do
    manifest="${FIXTURE_DIR}/${name}/manifest.json"
    require_file "${manifest}"
    manifests+=("${manifest}")
    node -e '
      const fs = require("node:fs");
      const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      if (manifest.manifest_version !== 3) process.exit(1);
      if (typeof manifest.name !== "string" || !manifest.name) process.exit(1);
      if (typeof manifest.version !== "string" || !manifest.version) process.exit(1);
    ' "${manifest}" || fail "${name} is not a valid MV3 fixture manifest"
  done

  local discovered
  discovered="$(
    find "${FIXTURE_DIR}" -mindepth 2 -maxdepth 2 -name manifest.json \
      ! -path '*/mv2_observation/*' -print | LC_ALL=C sort
  )"
  local expected
  expected="$(printf '%s\n' "${manifests[@]}" | LC_ALL=C sort)"
  [[ "${discovered}" == "${expected}" ]] \
    || fail 'acceptance inventory is not exactly the five required MV3 fixtures'

  local fixture_file
  while IFS= read -r fixture_file; do
    require_file "${fixture_file}"
  done < <(
    find "${FIXTURE_DIR}" -type f ! -path '*/mv2_observation/*' -print |
      LC_ALL=C sort
  )

  if rg --pcre2 -n \
      'https?://(?!127\.0\.0\.1(?:[:/]|$)|localhost(?:[:/]|$))' \
      "${FIXTURE_DIR}" -g '!mv2_observation/**'; then
    fail 'fixture contains a non-local network URL'
  fi
  if rg -ni \
      'native[_ -]?messaging|externally_connectable|authorization:[[:space:]]*bearer|gateway[_ -]?bearer|vault[_ -]?value|real[_ -]?(account|secret)|verification[_ -]?bypass' \
      "${FIXTURE_DIR}" -g '!mv2_observation/**'; then
    fail 'fixture contains forbidden authority, external, or real-data text'
  fi

  if [[ -e "${FIXTURE_DIR}/mv2_observation" &&
        ! -s "${FIXTURE_DIR}/mv2_observation/manifest.json" ]]; then
    fail 'MV2 observation directory exists without its separate manifest'
  fi

  note 'exactly five nonempty deterministic MV3 fixtures passed static checks'
}

verify_source_contract() {
  require_file "${SOURCE}"
  require_file "${BUILD_FILE}"
  rg -q 'ChromeTestExtensionLoader' "${SOURCE}" \
    || fail 'browser fixture does not use ChromeTestExtensionLoader'
  rg -q 'TestExtensionDir' "${SOURCE}" \
    || fail 'browser fixture does not use TestExtensionDir'
  rg -q 'ExtensionTestMessageListener' "${SOURCE}" \
    || fail 'browser fixture does not use ExtensionTestMessageListener'
  rg -Fq '../../../prometheus/prometheus_extension_fixtures_browsertest.cc' \
    "${BUILD_FILE}" || fail 'browser fixture is not registered in BUILD.gn'

  if rg -ni \
      'ScopedIgnoreContentVerifier|ScopedTestMV2Enabler|set_ignore_manifest_warnings|disable.*(install|content).*verif|ShouldAllowMV2Extensions|ShouldEnableInstallVerification' \
      "${SOURCE}" "${BUILD_FILE}"; then
    fail 'Phase 22 fixture acceptance contains an MV2 or verification bypass'
  fi

  local test_name
  for test_name in "${EXPECTED_RED_FAILURES[@]}"; do
    rg -Fq "${test_name#*.}" "${SOURCE}" \
      || fail "missing category browser test: ${test_name}"
  done
  note 'fixture source and no-bypass contract passed'
}

query_compile_command() {
  local object="$1"
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${object}" 2>/dev/null |
    LC_ALL=C awk -v output=" -o ${object}" \
      'index($0, output) { command = $0 } END { print command }'
}

compile_synthesized_object() {
  local template_object="$1"
  local object="$2"
  local template_stem="$3"
  local target_stem="$4"
  local command
  command="$(query_compile_command "${template_object}")"
  [[ -n "${command}" ]] || fail "compile template not found for ${template_object}"
  command="${command//${template_stem}/${target_stem}}"
  [[ "${command}" == *" -o ${object}"* ]] \
    || fail "synthesized command does not produce ${object}"
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
    LC_ALL=C awk \
      'index($0, "linker_driver.py") && index($0, "@./browser_tests.rsp") {
         command = $0
       }
       END { print command }'
}

build_focused_response() {
  require_file "${OUT_DIR}/browser_tests.rsp"
  LC_ALL=C awk '
    BEGIN { RS = "[[:space:]]+" }
    NF {
      is_test_object = $0 ~ /\.o$/ &&
          ($0 ~ /\/browser_tests\// ||
           $0 ~ /\/interactive_ui_tests\// ||
           $0 ~ /\/unit_tests\// ||
           $0 ~ /\/integration_tests\// ||
           $0 ~ /(_browsertest|_unittest|_apitest|_uitest)\.o$/)
      if (!is_test_object) {
        print
      }
    }
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
  local template_object='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_page_adapter_browsertest.o'
  local fixture_object='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_fixtures_browsertest.o'
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
    obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o
    obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service_factory.o
    obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o
    obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o
  )

  : >"${BUILD_LOG}"
  compile_synthesized_object \
    "${template_object}" "${fixture_object}" \
    prometheus_page_adapter_browsertest \
    prometheus_extension_fixtures_browsertest
  require_file "${OUT_DIR}/${fixture_object}"

  build_focused_response
  append_response_object "${fixture_object}"
  local object
  for object in "${link_extras[@]}"; do
    append_response_object "${object}"
  done
  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] \
    || fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output='-o "./prometheus_extension_fixture_tests"'
  local original_response='@./browser_tests.rsp'
  local focused_response='@./phase22-extension-fixtures/focused-browser-tests.rsp'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'browser_tests output argument was not found'
  [[ "${link_command}" == *"${original_response}"* ]] \
    || fail 'browser_tests response argument was not found'
  link_command="${link_command/${original_output}/${focused_output}}"
  link_command="${link_command/${original_response}/${focused_response}}"

  rm -f "${BINARY}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - ./prometheus_extension_fixture_tests
    codesign --verify --strict ./prometheus_extension_fixture_tests
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail 'focused fixture link failed'
  }
  require_file "${BINARY}"
}

list_selected_tests() {
  "${BINARY}" --gtest_list_tests --gtest_filter="${FILTER}" \
    >"${LIST_LOG}" 2>&1 || fail 'fixture test discovery failed'
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${LIST_LOG}")"
  [[ "${count}" -eq 5 ]] \
    || fail "${FILTER} must select exactly five category tests, selected ${count}"
  if rg -q 'DISABLED_' "${LIST_LOG}"; then
    fail 'fixture test list contains a disabled test'
  fi
  note 'selected exactly five runnable category tests'
}

run_selected_tests() {
  local status
  set +e
  "${BINARY}" \
    --gtest_filter="${FILTER}" \
    --test-launcher-jobs=1 \
    --test-launcher-retry-limit=0 >"${TEST_LOG}" 2>&1
  status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -eq 1 ]] || {
      tail -n 120 "${TEST_LOG}" >&2 || true
      fail "--expect-failure requires assertion status 1, got ${status}"
    }
    if rg -qi \
        'segmentation fault|received signal|check failed|fatal error|addresssanitizer|crash|timeout' \
        "${TEST_LOG}"; then
      fail '--expect-failure rejected crash, fatal, or timeout output'
    fi
    local actual="${LOG_DIR}/actual-red-failures.log"
    local expected="${LOG_DIR}/expected-red-failures.log"
    sed -nE \
      's/^\[  FAILED  \] ([^, ]+)(, where .*)? \([0-9]+ ms\)$/\1/p' \
      "${TEST_LOG}" | LC_ALL=C sort -u >"${actual}"
    printf '%s\n' "${EXPECTED_RED_FAILURES[@]}" | LC_ALL=C sort >"${expected}"
    if ! diff -u "${expected}" "${actual}" >"${LOG_DIR}/red-failures.diff"; then
      cat "${LOG_DIR}/red-failures.diff" >&2
      fail 'fixture RED failures differ from the frozen five-category allowlist'
    fi
    note 'retained RED failed only through the intended category assertions'
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 120 "${TEST_LOG}" >&2 || true
    fail "fixture suite failed with status ${status}"
  }
  local passed_count
  passed_count="$(
    rg -c \
      '^\[       OK \] PrometheusExtensionFixturesBrowserTest\.[^ ]+ \([0-9]+ ms\)$' \
      "${TEST_LOG}"
  )"
  [[ "${passed_count}" -eq 5 ]] \
    || fail "fixture suite reported ${passed_count} passing category tests"
  rg -q '^SUCCESS: all tests passed\.$' "${TEST_LOG}" \
    || fail 'Chromium test launcher did not report success'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' \
      "${TEST_LOG}"; then
    fail 'fixture suite reported a failure or skip'
  fi
  note 'five-category fixture suite passed with zero retry, skip, or failure'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
verify_fixture_inventory
verify_source_contract
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests

if [[ "${FOCUSED}" == false && "${EXPECT_FAILURE}" == false ]]; then
  note 'catalog and MV2 evidence gates are deferred until Plan 22-04 Task 3'
fi

note "verification complete; logs: ${LOG_DIR}"
