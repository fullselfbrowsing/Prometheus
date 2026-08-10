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
LOG_DIR="${OUT_DIR}/phase22-extension-smoke"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
BINARY="${OUT_DIR}/prometheus_extension_smoke_tests"
PROMETHEUS_DIR="${CHROMIUM_DIR}/chrome/browser/prometheus"
DEVELOPER_PRIVATE_DIR="${CHROMIUM_DIR}/chrome/browser/extensions/api/developer_private"
BOOTSTRAP_H="${PROMETHEUS_DIR}/prometheus_extension_smoke_bootstrap.h"
BOOTSTRAP_CC="${PROMETHEUS_DIR}/prometheus_extension_smoke_bootstrap.cc"
BOOTSTRAP_TEST_CC="${PROMETHEUS_DIR}/prometheus_extension_smoke_bootstrap_unittest.cc"
CONTROLLER_H="${PROMETHEUS_DIR}/prometheus_extension_smoke_controller.h"
CONTROLLER_CC="${PROMETHEUS_DIR}/prometheus_extension_smoke_controller.cc"
BROWSERTEST_CC="${PROMETHEUS_DIR}/prometheus_extension_smoke_browsertest.cc"
MAIN_EXTRA_PARTS_CC="${PROMETHEUS_DIR}/prometheus_browser_main_extra_parts.cc"
DEVELOPER_PRIVATE_FUNCTIONS_H="${DEVELOPER_PRIVATE_DIR}/developer_private_functions.h"
DEVELOPER_PRIVATE_FUNCTIONS_CC="${DEVELOPER_PRIVATE_DIR}/developer_private_functions.cc"
DEVELOPER_PRIVATE_UNITTEST_CC="${DEVELOPER_PRIVATE_DIR}/developer_private_api_unittest.cc"
BROWSER_BUILD="${CHROMIUM_DIR}/chrome/browser/prometheus/BUILD.gn"
VIEWS_BUILD="${CHROMIUM_DIR}/chrome/browser/ui/views/prometheus/BUILD.gn"

# Object paths. The bootstrap/controller/main-extra-parts objects are
# Prometheus-owned production translation units with no Siso-known compile
# command of their own (this out/Default was gn-gen'd once at an early
# baseline; every later Prometheus file is compiled by substituting its stem
# into an object Siso's loaded graph still recognizes -- see
# compile_synthesized_object()/TEMPLATE_* below, matching the precedent in
# verify-phase-22-extension-fixtures.sh). developer_private_api_unittest.o is
# a genuine pre-existing Chromium translation unit and does have its own
# Siso-known command, queried directly.
BOOTSTRAP_OBJECT='obj/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap/prometheus_extension_smoke_bootstrap.o'
CONTROLLER_OBJECT='obj/chrome/browser/prometheus/prometheus_extension_smoke_controller/prometheus_extension_smoke_controller.o'
MAIN_EXTRA_PARTS_OBJECT='obj/chrome/browser/prometheus/prometheus_browser_main_extra_parts/prometheus_browser_main_extra_parts.o'
OLD_MAIN_EXTRA_PARTS_OBJECT='obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_browser_main_extra_parts.o'
CHROME_BROWSER_MAIN_OBJECT='obj/chrome/browser/core/chrome_browser_main.o'
BOOTSTRAP_TEST_OBJECT='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_extension_smoke_bootstrap_unittest.o'
BROWSERTEST_OBJECT='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_smoke_browsertest.o'
DEVELOPER_PRIVATE_UNITTEST_OBJECT='obj/chrome/browser/extensions/unit_tests/developer_private_api_unittest.o'
PRODUCTION_TEMPLATE='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
UNITTEST_TEMPLATE='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_route_unittest.o'
BROWSERTEST_TEMPLATE='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_page_adapter_browsertest.o'

# Every Phase 20-22 Prometheus object this binary's transitive closure needs
# that predates this synthesis harness's base browser_tests.rsp (frozen at an
# earlier baseline -- see verify-phase-22-extension-fixtures.sh's identical
# comment on prometheus_runtime_profile_service.o). Reused verbatim from that
# script's proven link_extras plus this plan's own new objects.
LINK_EXTRAS=(
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
  obj/chrome/browser/prometheus/prometheus_extension_compatibility_catalog/prometheus_extension_compatibility_catalog.o
  obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o
  obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o
  "${BOOTSTRAP_OBJECT}"
  "${CONTROLLER_OBJECT}"
  "${MAIN_EXTRA_PARTS_OBJECT}"
  "${BOOTSTRAP_TEST_OBJECT}"
  "${BROWSERTEST_OBJECT}"
  "${DEVELOPER_PRIVATE_UNITTEST_OBJECT}"
)

# Bootstrap unit cohort (fast, no browser) plus the one-shot controller
# browser cohort. developer-private caller coverage is intentionally split:
# a source-retained TEST_F pair in developer_private_api_unittest.cc proves
# the contract for a real chrome/test:unit_tests binary (ExtensionServiceTest
# WithInstall's TestingProfile/no-Mojo process model), but that model is
# incompatible with this synthesized browser_tests-derived binary's already
# -initialized full browser process (mojo::core::Init() fatal mismatch) --
# see run_selected_tests()'s crash-line rejection below, which would catch
# this if it were ever included. PrometheusDeveloperPrivateCallerBrowserTest
# proves the exact same ShowSelectFileDialog() contract executably in this
# binary instead, using a real chrome://extensions tab.
FOCUSED_FILTER='PrometheusExtensionSmokeBootstrapTest.*:PrometheusExtensionSmokeControllerBrowserTest.*:PrometheusDeveloperPrivateCallerBrowserTest.*'
BOOTSTRAP_FILTER='PrometheusExtensionSmokeBootstrapTest.*'
CONTROLLER_FILTER='PrometheusExtensionSmokeControllerBrowserTest.*'
CALLER_FILTER='PrometheusDeveloperPrivateCallerBrowserTest.*'
# Historical note: at the commit that landed this script, exactly
# LoadUnpackedPassesCommittedManagerCallerToSelectFileDialog failed (RED)
# because DeveloperPrivateLoadUnpackedFunction::ShowSelectFileDialog() had not
# yet been given the committed-caller copy. A later commit in this same plan
# landed that narrow change, which flips the cohort GREEN; --expect-failure is
# retained for reference but is no longer the correct invocation for the
# current tree (it now correctly reports a failure itself, since there is no
# longer a RED assertion to match). Use the no-argument --focused mode.
EXPECTED_RED_FAILURES=(
  'PrometheusDeveloperPrivateCallerBrowserTest.LoadUnpackedPassesCommittedManagerCallerToSelectFileDialog'
)
METADATA_CAPTURED=false

fail() {
  printf 'Phase 22 extension-smoke verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-extension-smoke] %s\n' "$1"
}

require_file() {
  [[ -s "$1" ]] || fail "missing or empty file: $1"
}

require_literal() {
  local literal="$1"
  local file="$2"
  rg -q --fixed-strings -- "${literal}" "${file}" \
    || fail "missing contract '${literal}' in ${file}"
}

reject_pattern() {
  local pattern="$1"
  local description="$2"
  shift 2
  # Ignore matches on pure `//`-comment lines (design-note prose describing
  # what the code intentionally does NOT do) -- only real code lines count.
  if rg -nH -- "${pattern}" "$@" | rg -v '^[^:]+:[0-9]+:\s*//' \
      >"${LOG_DIR}/static-guard.log"; then
    if [[ -s "${LOG_DIR}/static-guard.log" ]]; then
      tail -n 80 "${LOG_DIR}/static-guard.log" >&2 || true
      fail "${description}"
    fi
  fi
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
    printf '[phase22-extension-smoke] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_BEFORE}" "${ninja_log_after}"
    printf '[phase22-extension-smoke] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_BEFORE}" ]]; then
      printf 'Phase 22 extension-smoke verification failed: direct verification changed reviewed build metadata\n' >&2
      status=1
    fi
  fi
  exit "${status}"
}

verify_source_contract() {
  require_file "${BOOTSTRAP_H}"
  require_file "${BOOTSTRAP_CC}"
  require_file "${BOOTSTRAP_TEST_CC}"
  require_file "${CONTROLLER_H}"
  require_file "${CONTROLLER_CC}"
  require_file "${BROWSERTEST_CC}"
  require_file "${MAIN_EXTRA_PARTS_CC}"
  require_file "${DEVELOPER_PRIVATE_UNITTEST_CC}"

  require_literal 'class PrometheusExtensionSmokeBootstrap' "${BOOTSTRAP_H}"
  require_literal 'class PrometheusExtensionSmokeController' "${CONTROLLER_H}"
  require_literal 'class OneShotChooser' "${CONTROLLER_H}"
  require_literal 'class OneShotChooserFactory' "${CONTROLLER_H}"
  require_literal '--expect-failure' "${SCRIPT_DIR}/verify-phase-22-extension-smoke.sh"
  require_literal 'ExtensionSmokeBrowserWaiter' "${MAIN_EXTRA_PARTS_CC}"
  require_literal 'LoadUnpackedPassesCommittedManagerCallerToSelectFileDialog' \
    "${DEVELOPER_PRIVATE_UNITTEST_CC}"
  require_literal 'LoadUnpackedPassesNoCallerForNonManagerSender' \
    "${DEVELOPER_PRIVATE_UNITTEST_CC}"
  require_literal 'LoadUnpackedPassesCommittedManagerCallerToSelectFileDialog' \
    "${BROWSERTEST_CC}"
  require_literal 'FullLifecycleInstallsInspectsAndReloads' \
    "${BROWSERTEST_CC}"

  reject_pattern 'accept_dialog_for_testing_' \
    'controller reached into the LoadUnpacked test-only accept-dialog shortcut' \
    "${CONTROLLER_CC}" "${CONTROLLER_H}"
  reject_pattern 'StartFileLoad|extensions::UnpackedInstaller|ExtensionRegistrar::' \
    'controller calls direct load/install/registrar mutation instead of the real DOM/developerPrivate path' \
    "${CONTROLLER_CC}" "${CONTROLLER_H}"
  reject_pattern 'NSAccessibility|AXUIElement|osascript|System Events|CGEventCreateKeyboardEvent' \
    'controller uses manual/macOS Accessibility or AppleScript automation' \
    "${CONTROLLER_CC}" "${CONTROLLER_H}"
  reject_pattern 'ExecuteJavaScriptForTests|ExecuteJavaScriptWithUserGestureForTests' \
    'controller uses an unrestricted test-only JavaScript execution entry point' \
    "${CONTROLLER_CC}"
  reject_pattern 'load-extension|disable-extensions-except' \
    'smoke relies on command-line extension loading instead of the native manager' \
    "${CONTROLLER_CC}" "${CONTROLLER_H}" "${MAIN_EXTRA_PARTS_CC}"
  note 'controller/bootstrap static no-bypass guards passed'
}

query_compile_command() {
  local object="$1"
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${object}" 2>/dev/null |
    LC_ALL=C awk -v output=" -o ${object}" \
      'index($0, output) { command = $0 } END { print command }'
}

compile_direct_object() {
  local object="$1"
  local command
  command="$(query_compile_command "${object}")"
  [[ -n "${command}" ]] || fail "no Siso-known compile command for ${object}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 150 "${BUILD_LOG}" >&2 || true
    fail "direct compile failed for ${object}"
  }
  require_file "${OUT_DIR}/${object}"
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
    tail -n 150 "${BUILD_LOG}" >&2 || true
    fail "direct synthesized compile failed for ${object}"
  }
  require_file "${OUT_DIR}/${object}"
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
  LC_ALL=C awk -v old_main_extra_parts="${OLD_MAIN_EXTRA_PARTS_OBJECT}" '
    BEGIN { RS = "[[:space:]]+" }
    NF {
      is_test_object = $0 ~ /\.o$/ &&
          ($0 ~ /\/browser_tests\// ||
           $0 ~ /\/interactive_ui_tests\// ||
           $0 ~ /\/unit_tests\// ||
           $0 ~ /\/integration_tests\// ||
           $0 ~ /(_browsertest|_unittest|_apitest|_uitest)\.o$/)
      is_stale_recompiled_object = ($0 == old_main_extra_parts)
      if (!is_test_object && !is_stale_recompiled_object) {
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
  : >"${BUILD_LOG}"
  compile_synthesized_object \
    "${PRODUCTION_TEMPLATE}" "${BOOTSTRAP_OBJECT}" \
    prometheus_runtime_profile_service prometheus_extension_smoke_bootstrap
  compile_synthesized_object \
    "${PRODUCTION_TEMPLATE}" "${CONTROLLER_OBJECT}" \
    prometheus_runtime_profile_service prometheus_extension_smoke_controller
  compile_synthesized_object \
    "${PRODUCTION_TEMPLATE}" "${MAIN_EXTRA_PARTS_OBJECT}" \
    prometheus_runtime_profile_service prometheus_browser_main_extra_parts
  compile_synthesized_object \
    "${UNITTEST_TEMPLATE}" "${BOOTSTRAP_TEST_OBJECT}" \
    prometheus_agent_route_unittest prometheus_extension_smoke_bootstrap_unittest
  compile_synthesized_object \
    "${BROWSERTEST_TEMPLATE}" "${BROWSERTEST_OBJECT}" \
    prometheus_page_adapter_browsertest prometheus_extension_smoke_browsertest
  compile_direct_object "${DEVELOPER_PRIVATE_UNITTEST_OBJECT}"
  compile_direct_object "${CHROME_BROWSER_MAIN_OBJECT}"

  build_focused_response
  local object
  for object in "${LINK_EXTRAS[@]}"; do
    append_response_object "${object}"
  done

  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] \
    || fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output="-o \"./$(basename "${BINARY}")\""
  local original_response='@./browser_tests.rsp'
  local focused_response="@./phase22-extension-smoke/$(basename "${FOCUSED_RESPONSE}")"
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
    codesign --force --sign - "$(basename "${BINARY}")"
    codesign --verify --strict "$(basename "${BINARY}")"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 150 "${BUILD_LOG}" >&2 || true
    fail 'focused smoke link failed'
  }
  require_file "${BINARY}"
}

count_selected() {
  local filter="$1"
  local out_log="$2"
  "${BINARY}" --gtest_list_tests --gtest_filter="${filter}" \
    >"${out_log}" 2>&1 || fail "test discovery failed for ${filter}"
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${out_log}")"
  [[ "${count}" -gt 0 ]] || fail "${filter} selected zero tests"
  if rg -q 'DISABLED_' "${out_log}"; then
    fail "${filter} test list contains a disabled test"
  fi
  echo "${count}"
}

list_selected_tests() {
  local bootstrap_count controller_count caller_count
  bootstrap_count="$(count_selected "${BOOTSTRAP_FILTER}" "${LOG_DIR}/bootstrap-list.log")"
  controller_count="$(count_selected "${CONTROLLER_FILTER}" "${LOG_DIR}/controller-list.log")"
  caller_count="$(count_selected "${CALLER_FILTER}" "${LOG_DIR}/caller-list.log")"
  note "selected ${bootstrap_count} bootstrap unit, ${caller_count} developer-private caller, and ${controller_count} controller browser test(s)"
  "${BINARY}" --gtest_list_tests --gtest_filter="${FOCUSED_FILTER}" \
    >"${LIST_LOG}" 2>&1 || fail 'combined focused test discovery failed'
}

run_selected_tests() {
  local status
  set +e
  "${BINARY}" \
    --gtest_filter="${FOCUSED_FILTER}" \
    --test-launcher-jobs=1 --test-launcher-retry-limit=0 \
    --test-launcher-timeout=90000 \
    >"${TEST_LOG}" 2>&1
  status="$?"
  set -e

  if rg -qi 'segmentation fault|received signal|check failed|fatal error|addresssanitizer|CRASHED\)|test timed out|\(TIMEOUT\)' \
      "${TEST_LOG}"; then
    tail -n 150 "${TEST_LOG}" >&2 || true
    fail 'focused run rejected crash, fatal, or timeout output'
  fi

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -ne 0 ]] || fail '--expect-failure requires a nonzero exit'
    local actual="${LOG_DIR}/actual-red-failures.log"
    local expected="${LOG_DIR}/expected-red-failures.log"
    sed -nE \
      's/^\[  FAILED  \] ([^, ]+)(, where .*)? \([0-9]+ ms\)$/\1/p' \
      "${TEST_LOG}" | LC_ALL=C sort -u >"${actual}"
    printf '%s\n' "${EXPECTED_RED_FAILURES[@]}" | LC_ALL=C sort >"${expected}"
    if ! diff -u "${expected}" "${actual}" >"${LOG_DIR}/red-failures.diff"; then
      cat "${LOG_DIR}/red-failures.diff" >&2
      fail 'RED failures differ from the frozen allowlist'
    fi
    note "focused suite failed only through the intended developer-private caller assertion"
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 150 "${TEST_LOG}" >&2 || true
    fail "focused suite failed with status ${status}"
  }
  rg -q '^SUCCESS: all tests passed\.$' "${TEST_LOG}" \
    || fail 'Chromium test launcher did not report success'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' "${TEST_LOG}"; then
    fail 'focused suite reported a failure or skip'
  fi
  note 'focused suite passed with zero retry, skip, or failure'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
verify_source_contract
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests

note "verification complete; logs: ${LOG_DIR}"
