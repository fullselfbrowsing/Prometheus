#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

FOCUSED=false
EXPECT_FAILURE=false
FILTER='PrometheusWebUI*ExtensionPolicy*:*PrometheusExtensionConfirmation*'

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
LOG_DIR="${OUT_DIR}/phase22-webui"
LOG_DIR_RELATIVE="${LOG_DIR#"${OUT_DIR}/"}"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
FOCUSED_RESOURCE_DIR="${LOG_DIR}/resources"
FOCUSED_PROMETHEUS_PAK="${FOCUSED_RESOURCE_DIR}/prometheus/prometheus_resources.pak"
FOCUSED_FRAMEWORK_RESOURCES_PAK="${FOCUSED_RESOURCE_DIR}/framework-resources.pak"
FRAMEWORK_RESOURCES_PAK="${OUT_DIR}/Prometheus Framework.framework/Resources/resources.pak"
FRAMEWORK_RESOURCES_PAK_BACKUP="${FOCUSED_RESOURCE_DIR}/framework-resources.before-phase22-webui.pak"
BINARY="${OUT_DIR}/prometheus_webui_tests"
METADATA_CAPTURED=false
FRAMEWORK_RESOURCES_SWAPPED=false

fail() {
  printf 'Phase 22 WebUI verification failed: %s\n' "$1" >&2
  exit 1
}

note() {
  printf '[phase22-webui] %s\n' "$1"
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
  if [[ "${FRAMEWORK_RESOURCES_SWAPPED}" == true ]]; then
    if ! cp -p "${FRAMEWORK_RESOURCES_PAK_BACKUP}" \
        "${FRAMEWORK_RESOURCES_PAK}"; then
      printf 'Phase 22 WebUI verification failed: could not restore framework resources.pak\n' >&2
      status=1
    fi
    FRAMEWORK_RESOURCES_SWAPPED=false
  fi
  if [[ "${METADATA_CAPTURED}" == true ]]; then
    local ninja_log_after ninja_deps_after
    ninja_log_after="$(sha256_file "${OUT_DIR}/.ninja_log" 2>/dev/null || true)"
    ninja_deps_after="$(sha256_file "${OUT_DIR}/.ninja_deps" 2>/dev/null || true)"
    printf '[phase22-webui] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_BEFORE}" "${ninja_log_after}"
    printf '[phase22-webui] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_BEFORE}" "${ninja_deps_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_BEFORE}" ]]; then
      printf 'Phase 22 WebUI verification failed: direct verification changed reviewed build metadata\n' >&2
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
  command="$(query_compile_command "${template_object}")"
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

query_framework_resource_repack_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" \
      gen/repack/resources.pak 2>/dev/null |
    LC_ALL=C awk '
      index($0, "pak_util.py repack gen/repack/resources.pak ") {
        command = $0
      }
      END { print command }
    '
}

build_and_install_focused_resources() {
  local prometheus_output="${FOCUSED_RESOURCE_DIR}/prometheus"
  mkdir -p "${prometheus_output}"
  (
    cd "${OUT_DIR}"
    python3 ../../tools/grit/grit.py \
      -i ../../chrome/browser/resources/prometheus/prometheus_resources.grd \
      build -o "${LOG_DIR_RELATIVE}/resources/prometheus" \
      --depdir . \
      --depfile "${LOG_DIR_RELATIVE}/resources/prometheus/prometheus_resources_grit.d" \
      --write-only-new=1 \
      -D DEVTOOLS_GRD_PATH=gen/third_party/devtools-frontend/src/front_end/devtools_resources \
      -D SHARED_INTERMEDIATE_DIR=gen \
      -D _google_chrome=false \
      -D _is_chrome_for_testing_branded=false \
      -D reven=false \
      -D toolkit_views=true \
      -D use_aura=false \
      -D use_ozone=false \
      -D use_titlecase=true \
      -D is_desktop_android=false \
      -D scale_factors=2x \
      -E branding_path_component=chromium \
      -E root_gen_dir=gen \
      -E root_src_dir=../../ \
      -E CHROMIUM_BUILD=chromium \
      -t darwin \
      -f gen/tools/gritsettings/default_resource_ids \
      -p ../../tools/gritsettings/startup_resources_mac.txt
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail 'focused Prometheus GRIT build failed'
  }
  require_file "${FOCUSED_PROMETHEUS_PAK}"
  cmp -s \
      "${OUT_DIR}/gen/chrome/grit/prometheus_resources.h" \
      "${prometheus_output}/grit/prometheus_resources.h" ||
    fail 'focused Prometheus GRIT build changed reviewed resource IDs'

  local repack_command
  repack_command="$(query_framework_resource_repack_command)"
  [[ -n "${repack_command}" ]] ||
    fail 'framework resource repack command not found'
  local original_output='repack gen/repack/resources.pak'
  local focused_output="repack ${LOG_DIR_RELATIVE}/resources/framework-resources.pak"
  local original_prometheus=' gen/chrome/prometheus_resources.pak '
  local focused_prometheus=" ${LOG_DIR_RELATIVE}/resources/prometheus/prometheus_resources.pak "
  [[ "${repack_command}" == *"${original_output}"* &&
     "${repack_command}" == *"${original_prometheus}"* ]] ||
    fail 'framework resource repack command lacks expected Prometheus input'
  repack_command="${repack_command/${original_output}/${focused_output}}"
  repack_command="${repack_command/${original_prometheus}/${focused_prometheus}}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${repack_command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail 'focused framework resource repack failed'
  }
  require_file "${FOCUSED_FRAMEWORK_RESOURCES_PAK}"
  require_file "${FRAMEWORK_RESOURCES_PAK}"
  cp -p "${FRAMEWORK_RESOURCES_PAK}" "${FRAMEWORK_RESOURCES_PAK_BACKUP}"
  FRAMEWORK_RESOURCES_SWAPPED=true
  cp -p "${FOCUSED_FRAMEWORK_RESOURCES_PAK}" "${FRAMEWORK_RESOURCES_PAK}"
  note 'focused framework resource pack contains current Prometheus HTML, JS, and CSS'
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
    NF {
      is_test_object = $0 ~ /\.o$/ &&
          ($0 ~ /\/browser_tests\// ||
           $0 ~ /\/interactive_ui_tests\// ||
           $0 ~ /\/unit_tests\// ||
           $0 ~ /\/integration_tests\// ||
           $0 ~ /(_browsertest|_unittest|_apitest|_uitest)\.o$/)
      if (!is_test_object) {
        print $0
      }
    }
  ' "${OUT_DIR}/browser_tests.rsp" >"${FOCUSED_RESPONSE}"
  printf '%s\n' \
    'obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_web_ui_browsertest.o' \
    >>"${FOCUSED_RESPONSE}"
  require_file "${FOCUSED_RESPONSE}"
}

run_direct_build() {
  local web_ui='obj/chrome/browser/ui/webui/prometheus/side_panel_ui/prometheus_web_ui.o'
  local tab_control_web_ui='obj/chrome/browser/ui/webui/prometheus/prometheus/prometheus_tab_control_web_ui.o'
  local side_panel_runtime='obj/chrome/browser/ui/webui/prometheus/side_panel_ui/prometheus_side_panel_runtime.o'
  local runtime_dialogs='obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o'
  local browser_test='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_web_ui_browsertest.o'
  local runtime_types='obj/chrome/browser/prometheus/prometheus_runtime_types/prometheus_runtime_types.o'
  local runtime_service='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
  local policy_types='obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o'
  local policy_prefs='obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o'
  local policy_service='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o'
  local browser_composition='obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_browser_main_extra_parts.o'
  local profiles_factories='obj/chrome/browser/profiles/profiles_extra_parts_impl/chrome_browser_main_extra_parts_profiles.o'
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
    obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service_factory.o
    obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o
    obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_audit_unittest.o
    obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_service_unittest.o
    obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_surface_browsertest.o
    obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_agent_browsertest.o
  )

  : >"${BUILD_LOG}"
  compile_synthesized_object "${runtime_types}" "${policy_types}" \
    prometheus_runtime_types prometheus_extension_policy_types
  require_file "${OUT_DIR}/${policy_prefs}"
  compile_synthesized_object "${runtime_service}" "${policy_service}" \
    prometheus_runtime_profile_service prometheus_extension_policy_service
  compile_exact_object "${side_panel_runtime}"
  compile_exact_object "${web_ui}"
  compile_exact_object "${tab_control_web_ui}"
  compile_exact_object "${runtime_dialogs}"
  compile_exact_object "${browser_composition}"
  compile_exact_object "${profiles_factories}"
  compile_exact_object "${browser_test}"
  build_and_install_focused_resources

  build_focused_response
  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] ||
    fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output='-o "./prometheus_webui_tests"'
  local original_response='@./browser_tests.rsp'
  local focused_response='@./phase22-webui/focused-browser-tests.rsp'
  [[ "${link_command}" == *"${original_output}"* ]] ||
    fail 'browser_tests output argument was not found'
  [[ "${link_command}" == *"${original_response}"* ]] ||
    fail 'browser_tests response argument was not found'
  link_command="${link_command/${original_output}/${focused_output}}"
  link_command="${link_command/${original_response}/${focused_response}}"
  local extra
  for extra in "${extras[@]}"; do
    require_file "${OUT_DIR}/${extra}"
  done
  link_command="${link_command} ${extras[*]}"

  rm -f "${BINARY}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - ./prometheus_webui_tests
    codesign --verify --strict ./prometheus_webui_tests
  ) >>"${BUILD_LOG}" 2>&1 || {
    tail -n 120 "${BUILD_LOG}" >&2 || true
    fail 'focused WebUI link failed'
  }
  require_file "${BINARY}"
}

list_selected_tests() {
  "${BINARY}" --gtest_list_tests --gtest_filter="${FILTER}" \
    >"${LIST_LOG}" 2>&1 || fail 'focused test discovery failed'
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${LIST_LOG}")"
  [[ "${count}" -gt 0 ]] || fail "${FILTER} selected zero tests"
  if rg -q 'DISABLED_' "${LIST_LOG}"; then
    fail 'focused WebUI list contains a disabled test'
  fi
  note "selected ${count} runnable test(s) for ${FILTER}"
}

run_selected_tests() {
  local status
  set +e
  "${BINARY}" \
    --gtest_filter="${FILTER}" \
    --test-launcher-jobs=1 \
    --test-launcher-retry-limit=0 \
    >"${TEST_LOG}" 2>&1
  status="$?"
  set -e

  if [[ "${EXPECT_FAILURE}" == true ]]; then
    [[ "${status}" -eq 1 ]] || {
      tail -n 120 "${TEST_LOG}" >&2 || true
      fail "--expect-failure requires assertion status 1, got ${status}"
    }
    rg -q '\[  FAILED  \].*(ExtensionPolicy|ExtensionConfirmation)' \
      "${TEST_LOG}" ||
      fail 'expected assertion-only extension policy failures were not found'
    if rg -qi 'crash|timeout|timed out|signal [0-9]+|asan:|check failed' \
        "${TEST_LOG}"; then
      tail -n 120 "${TEST_LOG}" >&2 || true
      fail 'RED cohort crashed or timed out instead of failing assertions'
    fi
    note 'observed intended assertion-only RED failure'
    return
  fi

  [[ "${status}" -eq 0 ]] || {
    tail -n 160 "${TEST_LOG}" >&2 || true
    fail "focused WebUI cohort failed with status ${status}"
  }
  if rg -q '\[  FAILED  \]|DISABLED_|SKIPPED' "${TEST_LOG}"; then
    tail -n 160 "${TEST_LOG}" >&2 || true
    fail 'focused WebUI cohort was not fully enabled and passing'
  fi
  note 'focused WebUI cohort passed'
}

mkdir -p "${LOG_DIR}"
require_file "${SISO}"
require_file "${OUT_DIR}/browser_tests.rsp"
capture_metadata
trap verify_metadata_on_exit EXIT
bash "${SCRIPT_DIR}/verify-prometheus-webui-resources.sh"
run_direct_build
list_selected_tests
run_selected_tests
