#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

FOCUS_FILTER=''
EXPECT_FAILURE=false

usage() {
  printf 'Usage: %s --focus FILTER [--expect-failure]\n' "$0" >&2
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --focus)
      [[ "$#" -ge 2 ]] || {
        usage
        exit 2
      }
      [[ -z "${FOCUS_FILTER}" ]] || {
        usage
        exit 2
      }
      FOCUS_FILTER="$2"
      shift 2
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

if [[ -z "${FOCUS_FILTER//[[:space:]]/}" ]]; then
  printf 'Phase 21 focused verification failed: --focus requires a non-empty filter\n' >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
LOG_DIR="${OUT_DIR}/phase21-focused"
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
FOCUSED_BINARY="${OUT_DIR}/browser_tests"
TEMP_FOCUSED_BINARY="${OUT_DIR}/phase21_browser_tests"
LIST_LOG="${LOG_DIR}/phase21-focused-list.log"
TEST_LOG="${LOG_DIR}/phase21-focused-test.log"
BUILD_LOG="${LOG_DIR}/phase21-focused-build.log"
METADATA_CAPTURED=false

fail() {
  printf 'Phase 21 focused verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase21] %s\n' "$1"
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
  METADATA_CAPTURED=true
}

verify_build_metadata_on_exit() {
  local status="$?"
  trap - EXIT
  if [[ "${METADATA_CAPTURED}" == true ]]; then
    local ninja_log_after ninja_deps_after
    ninja_log_after="$(sha256_file "${OUT_DIR}/.ninja_log" 2>/dev/null || true)"
    ninja_deps_after="$(sha256_file "${OUT_DIR}/.ninja_deps" 2>/dev/null || true)"
    printf '[phase21] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_SHA256_BEFORE}" "${ninja_log_after}"
    printf '[phase21] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_SHA256_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_SHA256_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_SHA256_BEFORE}" ]]; then
      printf 'Phase 21 focused verification failed: direct verification changed reviewed Ninja metadata\n' >&2
      status=1
    fi
  fi
  exit "${status}"
}

query_compile_command() {
  local object="$1"
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${object}" 2>/dev/null \
    | LC_ALL=C awk -v output=" -o ${object}" \
        'index($0, output) { command = $0 } END { print command }'
}

compile_exact_object() {
  local object="$1"
  local command
  command="$(query_compile_command "${object}")"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  printf 'compile %s\n' "${object}" >>"${BUILD_LOG}"
  /bin/zsh -c "${command}" >>"${BUILD_LOG}" 2>&1 || {
    tail -n 80 "${BUILD_LOG}" >&2 || true
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
  printf 'compile %s from exact same-target template %s\n' \
    "${object}" "${template_object}" >>"${BUILD_LOG}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 80 "${BUILD_LOG}" >&2 || true
    fail "direct synthesized compile failed for ${object}"
  }
}

query_browser_link_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" browser_tests 2>/dev/null \
    | LC_ALL=C awk \
        'index($0, "linker_driver.py") && index($0, "@./browser_tests.rsp") {
           command = $0
         }
         END { print command }'
}

build_focused_binary() {
  local route_object='obj/chrome/browser/prometheus/prometheus_agent_route/prometheus_agent_route.o'
  local route_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_route_unittest.o'
  local agent_service_object='obj/chrome/browser/prometheus/prometheus_agent_service/prometheus_agent_service.o'
  local agent_service_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_service_unittest.o'
  local agent_tab_data_object='obj/chrome/browser/prometheus/prometheus_agent_tab_data/prometheus_agent_tab_data.o'
  local agent_profile_object='obj/chrome/browser/prometheus/prometheus_agent_profile_service/prometheus_agent_profile_service.o'
  local agent_profile_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_profile_service_unittest.o'
  local agent_profile_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_profile_service_unittest.cc"
  local runtime_object='obj/chrome/browser/prometheus/prometheus_runtime_types/prometheus_runtime_types.o'
  local runtime_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_runtime_types_unittest.o'
  local supervision_object='obj/chrome/browser/prometheus/prometheus_supervision_types/prometheus_supervision_types.o'
  local supervision_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_types_unittest.o'
  local supervision_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_types.cc"
  local supervision_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_types_unittest.cc"
  local runtime_codec_object='obj/chrome/browser/prometheus/prometheus_runtime_transport_codec/prometheus_runtime_transport_codec.o'
  local runtime_codec_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_runtime_transport_codec_unittest.o'
  local supervision_codec_object='obj/chrome/browser/prometheus/prometheus_supervision_transport_codec/prometheus_supervision_transport_codec.o'
  local supervision_codec_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_transport_codec_unittest.o'
  local supervision_codec_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_transport_codec.cc"
  local supervision_codec_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_transport_codec_unittest.cc"
  local supervision_projection_object='obj/chrome/browser/prometheus/prometheus_supervision_projection/prometheus_supervision_projection.o'
  local supervision_projection_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_projection_unittest.o'
  local supervision_projection_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_projection.cc"
  local supervision_projection_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_projection_unittest.cc"
  local supervision_diff_object='obj/chrome/browser/prometheus/prometheus_supervision_diff/prometheus_supervision_diff.o'
  local supervision_diff_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_diff_unittest.o'
  local supervision_diff_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_diff.cc"
  local supervision_diff_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_diff_unittest.cc"
  local runtime_profile_object='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
  local runtime_profile_factory_object='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service_factory.o'
  local runtime_profile_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_runtime_profile_service_unittest.o'
  local supervision_profile_object='obj/chrome/browser/prometheus/prometheus_supervision_profile_service/prometheus_supervision_profile_service.o'
  local supervision_profile_factory_object='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_supervision_profile_service_factory.o'
  local supervision_profile_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_profile_service_unittest.o'
  local supervision_profile_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service.cc"
  local supervision_profile_factory_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.cc"
  local supervision_profile_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc"
  local extra_objects=()

  : >"${BUILD_LOG}"
  (
    cd "${OUT_DIR}"
    compile_exact_object "${route_object}"
    compile_exact_object "${route_test_object}"
    compile_exact_object "${agent_tab_data_object}"
    compile_exact_object "${agent_service_object}"
    compile_exact_object "${agent_service_test_object}"
    compile_exact_object "${agent_profile_object}"
  )

  if [[ -e "${agent_profile_test_source}" ]]; then
    [[ -s "${agent_profile_test_source}" ]] \
      || fail 'Agent profile service test is missing or empty'
    compile_synthesized_object "${runtime_profile_test_object}" "${agent_profile_test_object}" \
      prometheus_runtime_profile_service_unittest prometheus_agent_profile_service_unittest
  fi

  if [[ -e "${supervision_source}" || -e "${supervision_test_source}" ]]; then
    [[ -s "${supervision_source}" ]] \
      || fail 'supervision type implementation is missing or empty'
    [[ -s "${supervision_test_source}" ]] \
      || fail 'supervision type test is missing or empty'
    compile_synthesized_object "${runtime_object}" "${supervision_object}" \
      prometheus_runtime_types prometheus_supervision_types
    compile_synthesized_object "${runtime_test_object}" "${supervision_test_object}" \
      prometheus_runtime_types_unittest prometheus_supervision_types_unittest
  fi

  if [[ -e "${supervision_codec_source}" || -e "${supervision_codec_test_source}" ]]; then
    [[ -s "${supervision_codec_source}" ]] \
      || fail 'supervision transport codec implementation is missing or empty'
    [[ -s "${supervision_codec_test_source}" ]] \
      || fail 'supervision transport codec test is missing or empty'
    compile_synthesized_object "${runtime_codec_object}" "${supervision_codec_object}" \
      prometheus_runtime_transport_codec prometheus_supervision_transport_codec
    compile_synthesized_object "${runtime_codec_test_object}" "${supervision_codec_test_object}" \
      prometheus_runtime_transport_codec_unittest prometheus_supervision_transport_codec_unittest
  fi

  if [[ -e "${supervision_projection_source}" || -e "${supervision_projection_test_source}" ]]; then
    [[ -s "${supervision_projection_source}" ]] \
      || fail 'supervision projection implementation is missing or empty'
    [[ -s "${supervision_projection_test_source}" ]] \
      || fail 'supervision projection test is missing or empty'
    compile_synthesized_object "${runtime_object}" "${supervision_projection_object}" \
      prometheus_runtime_types prometheus_supervision_projection
    compile_synthesized_object "${runtime_test_object}" "${supervision_projection_test_object}" \
      prometheus_runtime_types_unittest prometheus_supervision_projection_unittest
  fi

  if [[ -e "${supervision_diff_source}" || -e "${supervision_diff_test_source}" ]]; then
    [[ -s "${supervision_diff_source}" ]] \
      || fail 'supervision diff implementation is missing or empty'
    [[ -s "${supervision_diff_test_source}" ]] \
      || fail 'supervision diff test is missing or empty'
    compile_synthesized_object "${runtime_object}" "${supervision_diff_object}" \
      prometheus_runtime_types prometheus_supervision_diff
    compile_synthesized_object "${runtime_test_object}" "${supervision_diff_test_object}" \
      prometheus_runtime_types_unittest prometheus_supervision_diff_unittest
  fi

  if [[ -e "${supervision_profile_source}" || -e "${supervision_profile_test_source}" ]]; then
    [[ -s "${supervision_profile_source}" ]] \
      || fail 'supervision profile service implementation is missing or empty'
    [[ -s "${supervision_profile_test_source}" ]] \
      || fail 'supervision profile service test is missing or empty'
    compile_synthesized_object "${runtime_profile_object}" "${supervision_profile_object}" \
      prometheus_runtime_profile_service prometheus_supervision_profile_service
    compile_synthesized_object "${runtime_profile_test_object}" "${supervision_profile_test_object}" \
      prometheus_runtime_profile_service_unittest prometheus_supervision_profile_service_unittest
  fi

  if [[ -e "${supervision_profile_factory_source}" ]]; then
    [[ -s "${supervision_profile_factory_source}" ]] \
      || fail 'supervision profile factory implementation is missing or empty'
    compile_synthesized_object "${runtime_profile_factory_object}" "${supervision_profile_factory_object}" \
      prometheus_runtime_profile_service_factory prometheus_supervision_profile_service_factory
  fi

  require_file "${OUT_DIR}/browser_tests.rsp"
  local runtime_contract='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o'
  local runtime_dialogs='obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o'
  local candidates=(
    "${runtime_contract}"
    "${runtime_dialogs}"
  )
  local unit_object_path
  for unit_object_path in \
      "${OUT_DIR}"/obj/chrome/browser/prometheus/prometheus_unittests/*_unittest.o; do
    candidates+=("${unit_object_path#${OUT_DIR}/}")
  done
  if [[ -s "${supervision_source}" ]]; then
    candidates+=("${supervision_object}")
  fi
  if [[ -s "${supervision_codec_source}" ]]; then
    candidates+=("${supervision_codec_object}")
  fi
  if [[ -s "${supervision_projection_source}" ]]; then
    candidates+=("${supervision_projection_object}")
  fi
  if [[ -s "${supervision_diff_source}" ]]; then
    candidates+=("${supervision_diff_object}")
  fi
  if [[ -s "${supervision_profile_source}" ]]; then
    candidates+=("${supervision_profile_object}")
  fi
  if [[ -s "${supervision_profile_factory_source}" ]]; then
    candidates+=("${supervision_profile_factory_object}")
  fi
  local candidate
  for candidate in "${candidates[@]}"; do
    require_file "${OUT_DIR}/${candidate}"
    if ! rg -q --fixed-strings -- "${candidate}" "${OUT_DIR}/browser_tests.rsp"; then
      extra_objects+=("${candidate}")
    fi
  done

  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] || fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output='-o "./phase21_browser_tests"'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'browser_tests output argument was not found'
  link_command="${link_command/${original_output}/${focused_output}}"
  if [[ "${#extra_objects[@]}" -gt 0 ]]; then
    link_command="${link_command} ${extra_objects[*]}"
  fi

  rm -f "${TEMP_FOCUSED_BINARY}"
  if ! (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}" &&
      codesign --force --sign - ./phase21_browser_tests &&
      codesign --verify --strict ./phase21_browser_tests &&
      mv -f ./phase21_browser_tests ./browser_tests
  ) >>"${BUILD_LOG}" 2>&1; then
    tail -n 80 "${BUILD_LOG}" >&2 || true
    fail 'focused browser-test link failed'
  fi
  require_file "${FOCUSED_BINARY}"
}

list_selected_tests() {
  if ! "${FOCUSED_BINARY}" --gtest_list_tests \
      --gtest_filter="${FOCUS_FILTER}" >"${LIST_LOG}" 2>&1; then
    tail -n 80 "${LIST_LOG}" >&2 || true
    fail 'focused test discovery failed'
  fi
  local selected_count
  selected_count="$(LC_ALL=C awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 } END { print count + 0 }' \
    "${LIST_LOG}")"
  [[ "${selected_count}" -gt 0 ]] \
    || fail "filter selected zero runnable tests: ${FOCUS_FILTER}"
  note "selected ${selected_count} runnable test(s)"
}

run_selected_tests() {
  local test_status
  set +e
  "${FOCUSED_BINARY}" --gtest_filter="${FOCUS_FILTER}" \
    >"${TEST_LOG}" 2>&1
  test_status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${test_status}" -eq 1 ]] || {
      tail -n 80 "${TEST_LOG}" >&2 || true
      fail "--expect-failure requires normal GTest assertion status 1, got ${test_status}"
    }
    rg -q '^\[  FAILED  \].*\([0-9]+ ms\)' "${TEST_LOG}" \
      || fail '--expect-failure did not observe an assertion-failing test'
    rg -q '[0-9]+ FAILED TEST' "${TEST_LOG}" \
      || fail '--expect-failure did not observe the GTest failure summary'
    if rg -qi 'segmentation fault|received signal|check failed|fatal error|addresssanitizer|crash' \
        "${TEST_LOG}"; then
      fail '--expect-failure rejected a crash or fatal process failure'
    fi
    note 'selected suite failed only by intended GTest assertion'
    return
  fi

  if [[ "${test_status}" -ne 0 ]]; then
    tail -n 80 "${TEST_LOG}" >&2 || true
    fail "selected suite failed with status ${test_status}"
  fi
  rg -q '^\[  PASSED  \] [1-9][0-9]* test' "${TEST_LOG}" \
    || fail 'selected suite produced no passing GTest summary'
  note 'selected suite passed'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
capture_build_metadata
trap verify_build_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests
note "focused verification complete; logs: ${LOG_DIR}"
