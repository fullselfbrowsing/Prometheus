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
LOG_DIR="${OUT_DIR}/phase22-extension-policy"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
BINARY="${OUT_DIR}/prometheus_unittests"
FILTER='PrometheusExtensionPolicy*'
REGISTRY_FILTER='PrometheusExtensionPolicy*Registry*:*Lifecycle*'
METADATA_CAPTURED=false
RED_FAILURES=(
  'PrometheusExtensionPolicyLifecycleTest.NativePrivateEligibilityLossBlocksBeforeObserverNotification'
  'PrometheusExtensionPolicyLifecycleTest.ObserverReentrancyAdvancesGenerationBeforeEveryNotification'
  'PrometheusExtensionPolicyLifecycleTest.ProfileShutdownMakesLateCallbacksHarmless'
  'PrometheusExtensionPolicyRegistryTest.ReadyInstallEnableDisableTerminateAndReloadRequeryById'
  'PrometheusExtensionPolicyRegistryTest.ReplacementAndReorderRejectStaleOrdinalGeneration'
  'PrometheusExtensionPolicyRegistryTest.UninstallErasesPersistedChoiceBeforeNotification'
)

fail() {
  printf 'Phase 22 extension-policy verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-extension-policy] %s\n' "$1"
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
    printf '[phase22-extension-policy] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_BEFORE}" "${ninja_log_after}"
    printf '[phase22-extension-policy] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_BEFORE}" ]]; then
      printf 'Phase 22 extension-policy verification failed: direct verification changed reviewed build metadata\n' >&2
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
  command="$(query_compile_command "${object}")"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 100 "${BUILD_LOG}" >&2 || true
    fail "direct compile failed for ${object}"
  }
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
    tail -n 100 "${BUILD_LOG}" >&2 || true
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

build_focused_binary() {
  local runtime_types='obj/chrome/browser/prometheus/prometheus_runtime_types/prometheus_runtime_types.o'
  local runtime_prefs='obj/chrome/browser/prometheus/prometheus_runtime_prefs/prometheus_runtime_prefs.o'
  local runtime_service='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
  local runtime_factory='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service_factory.o'
  local runtime_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_runtime_profile_service_unittest.o'
  local policy_types='obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o'
  local policy_prefs='obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o'
  local policy_service='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o'
  local policy_factory='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service_factory.o'
  local policy_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_extension_policy_service_unittest.o'
  local browser_prefs='obj/chrome/browser/prefs/impl/browser_prefs.o'
  local extras=(
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
    "${policy_types}"
    "${policy_prefs}"
    "${policy_service}"
    "${policy_factory}"
    "${policy_test}"
  )

  : >"${BUILD_LOG}"
  compile_synthesized_object "${runtime_types}" "${policy_types}" \
    prometheus_runtime_types prometheus_extension_policy_types
  compile_synthesized_object "${runtime_prefs}" "${policy_prefs}" \
    prometheus_runtime_prefs prometheus_extension_policy_prefs
  compile_synthesized_object "${runtime_service}" "${policy_service}" \
    prometheus_runtime_profile_service prometheus_extension_policy_service
  compile_synthesized_object "${runtime_factory}" "${policy_factory}" \
    prometheus_runtime_profile_service prometheus_extension_policy_service
  compile_synthesized_object "${runtime_test}" "${policy_test}" \
    prometheus_runtime_profile_service_unittest \
    prometheus_extension_policy_service_unittest
  compile_exact_object "${browser_prefs}"

  local extra
  for extra in "${extras[@]}"; do
    require_file "${OUT_DIR}/${extra}"
  done

  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] || fail 'browser_tests direct link command not found'
  link_command="$(
    printf '%s\n' "${link_command}" |
      sed 's|-o "./browser_tests"|-o "./prometheus_unittests"|'
  )"
  [[ "${link_command}" == *'-o "./prometheus_unittests"'* ]] \
    || fail 'focused output argument was not replaced'
  link_command="${link_command} ${extras[*]}"

  rm -f "${BINARY}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - ./prometheus_unittests
    codesign --verify --strict ./prometheus_unittests
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 100 "${BUILD_LOG}" >&2 || true
    fail 'focused policy link failed'
  }
  require_file "${BINARY}"
}

list_selected_tests() {
  "${BINARY}" --gtest_list_tests --gtest_filter="${FILTER}" \
    >"${LIST_LOG}" 2>&1 || fail 'focused test discovery failed'
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${LIST_LOG}")"
  [[ "${count}" -gt 0 ]] || fail 'PrometheusExtensionPolicy* selected zero tests'
  if rg -q 'DISABLED_' "${LIST_LOG}"; then
    fail 'focused policy list contains a disabled test'
  fi
  note "selected ${count} runnable policy test(s)"
}

run_selected_tests() {
  local status
  set +e
  "${BINARY}" --gtest_filter="${FILTER}" >"${TEST_LOG}" 2>&1
  status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -eq 1 ]] || {
      tail -n 100 "${TEST_LOG}" >&2 || true
      fail "--expect-failure requires assertion status 1, got ${status}"
    }
    if rg -qi 'segmentation fault|received signal|check failed|fatal error|addresssanitizer|crash|timeout' \
        "${TEST_LOG}"; then
      fail '--expect-failure rejected crash, fatal, or timeout output'
    fi
    local actual="${LOG_DIR}/actual-red-failures.log"
    local expected="${LOG_DIR}/expected-red-failures.log"
    sed -nE \
      's/^\[  FAILED  \] ([^, ]+)(, where .*)? \([0-9]+ ms\)$/\1/p' \
      "${TEST_LOG}" | LC_ALL=C sort -u >"${actual}"
    printf '%s\n' "${RED_FAILURES[@]}" | LC_ALL=C sort >"${expected}"
    if ! diff -u "${expected}" "${actual}" >"${LOG_DIR}/red-failures.diff"; then
      cat "${LOG_DIR}/red-failures.diff" >&2
      fail 'focused policy RED failures differ from the frozen allowlist'
    fi
    note 'retained RED failed only through the intended policy assertions'
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 100 "${TEST_LOG}" >&2 || true
    fail "focused policy suite failed with status ${status}"
  }
  rg -q '^\[  PASSED  \] [1-9][0-9]* test' "${TEST_LOG}" \
    || fail 'focused policy suite produced no passing summary'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' \
      "${TEST_LOG}"; then
    fail 'focused policy suite reported a failure or skip'
  fi
  note 'focused policy suite passed'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests

if [[ "${FOCUSED}" == false && "${EXPECT_FAILURE}" == false ]]; then
  "${BINARY}" --gtest_list_tests --gtest_filter="${REGISTRY_FILTER}" \
    >"${LOG_DIR}/registry-list.log" 2>&1
  if ! awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { found = 1 }
            END { exit(found ? 0 : 1) }' "${LOG_DIR}/registry-list.log"; then
    fail 'registry/lifecycle filter selected zero tests'
  fi
fi

note "verification complete; logs: ${LOG_DIR}"
