#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

FOCUSED=false
EXPECT_FAILURE=false
FOCUS=''

usage() {
  printf 'Usage: %s [--focused] [--focus GTEST_FILTER] [--expect-failure]\n' "$0" >&2
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
    --focus)
      [[ -z "${FOCUS}" && "$#" -ge 2 && -n "$2" ]] || {
        usage
        exit 2
      }
      FOCUS="$2"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
LOG_DIR="${OUT_DIR}/phase22-extension-policy"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
BINARY="${OUT_DIR}/prometheus_unittests"
FILTER='PrometheusExtensionPolicy*'
REGISTRY_FILTER='PrometheusExtensionPolicy*Registry*:*Lifecycle*'
METADATA_CAPTURED=false
POLICY_RED_FAILURES=(
  'PrometheusExtensionPolicyLifecycleTest.NativePrivateEligibilityLossBlocksBeforeObserverNotification'
  'PrometheusExtensionPolicyLifecycleTest.ObserverReentrancyAdvancesGenerationBeforeEveryNotification'
  'PrometheusExtensionPolicyLifecycleTest.ProfileShutdownMakesLateCallbacksHarmless'
  'PrometheusExtensionPolicyRegistryTest.ReadyInstallEnableDisableTerminateAndReloadRequeryById'
  'PrometheusExtensionPolicyRegistryTest.ReplacementAndReorderRejectStaleOrdinalGeneration'
  'PrometheusExtensionPolicyRegistryTest.UninstallErasesPersistedChoiceBeforeNotification'
)
SURFACE_RED_FAILURES=(
  'PrometheusExtensionSurfaceBrowserTest.ActiveSidePanelContractIsBrowserOwned'
  'PrometheusExtensionSurfaceBrowserTest.HiddenContextsRemainDenied'
  'PrometheusExtensionSurfaceBrowserTest.ShownPopupContractIsBrowserOwned'
  'PrometheusExtensionSurfaceBrowserTest.VisibleTabContractIsBrowserOwned'
  'PrometheusExtensionSurfaceResolverTest.AcceptsCommittedVisibleOptionsPage'
  'PrometheusExtensionSurfaceResolverTest.AcceptsCommittedVisibleTopLevelExtensionTab'
  'PrometheusExtensionSurfaceResolverTest.AcceptsExactlyOneActiveSidePanelOwnedByAnchorTab'
  'PrometheusExtensionSurfaceResolverTest.AcceptsExactlyOneShownPopupOwnedByAnchorBrowser'
  'PrometheusExtensionSurfaceResolverTest.AcceptsPositivelyOwnedPrimaryOptionsGuest'
  'PrometheusExtensionSurfaceResolverTest.RegistryMembershipAndSystemReadinessDoNotAuthorizeVisibility'
  'PrometheusExtensionSurfaceResolverTest.RejectsAmbiguousOptionsGuest'
  'PrometheusExtensionSurfaceResolverTest.RejectsBackgroundContents'
  'PrometheusExtensionSurfaceResolverTest.RejectsBackgroundPage'
  'PrometheusExtensionSurfaceResolverTest.RejectsDeveloperTools'
  'PrometheusExtensionSurfaceResolverTest.RejectsDisabledExtension'
  'PrometheusExtensionSurfaceResolverTest.RejectsHiddenHost'
  'PrometheusExtensionSurfaceResolverTest.RejectsLifecycleTeardown'
  'PrometheusExtensionSurfaceResolverTest.RejectsMismatchedCommittedOrigin'
  'PrometheusExtensionSurfaceResolverTest.RejectsMultipleSelectorMatches'
  'PrometheusExtensionSurfaceResolverTest.RejectsNonExtensionOrigin'
  'PrometheusExtensionSurfaceResolverTest.RejectsNonPrimaryOptionsGuest'
  'PrometheusExtensionSurfaceResolverTest.RejectsOffscreenDocument'
  'PrometheusExtensionSurfaceResolverTest.RejectsPopupSelectedAsSidePanel'
  'PrometheusExtensionSurfaceResolverTest.RejectsSharedRegistryWrongOffTheRecordContext'
  'PrometheusExtensionSurfaceResolverTest.RejectsStalePolicyGeneration'
  'PrometheusExtensionSurfaceResolverTest.RejectsTerminatedExtension'
  'PrometheusExtensionSurfaceResolverTest.RejectsUncommittedPrimaryFrame'
  'PrometheusExtensionSurfaceResolverTest.RejectsUninstalledExtension'
  'PrometheusExtensionSurfaceResolverTest.RejectsUnknownFutureViewKind'
  'PrometheusExtensionSurfaceResolverTest.RejectsWrongBrowser'
  'PrometheusExtensionSurfaceResolverTest.RejectsWrongProfile'
  'PrometheusExtensionSurfaceResolverTest.RejectsZeroSelectorMatches'
)
ADAPTER_RED_FAILURES=(
  'PrometheusExtensionAgentAdapterTest.AuditProjectionIsSuffixOnlyClosedAndContentFree'
  'PrometheusExtensionAgentAdapterTest.BlockedDeniesEveryReadAndAction'
  'PrometheusExtensionAgentAdapterTest.ContentScriptHttpPageKeepsNormalPageProvenance'
  'PrometheusExtensionAgentAdapterTest.ExecutionRevalidatesPolicyVisibilityContextAndDocument'
  'PrometheusExtensionAgentAdapterTest.InteractAddsExactlySevenTypedActions'
  'PrometheusExtensionAgentAdapterTest.PrivatePolicyIsExplicitAndNeverInherited'
  'PrometheusExtensionAgentAdapterTest.ReadOnlyAllowsExactlyFiveReads'
  'PrometheusExtensionAgentAdapterTest.ScriptsDragAndDropRemainDenied'
  'PrometheusExtensionAgentAuditTest.ProjectionRejectsContentFullIdentityAndAuthoritySentinels'
  'PrometheusExtensionAgentBrowserTest.ContentScriptProvenanceRemainsNormalPage'
  'PrometheusExtensionAgentBrowserTest.ExactNonTabSurfaceRoutingContract'
  'PrometheusExtensionAgentBrowserTest.ReverseAuthorityAndScriptRemainUnreachable'
  'PrometheusExtensionAgentServiceContractTest.CommittedExtensionIsClassifiedBeforeNormalPageDispatch'
  'PrometheusExtensionAgentServiceContractTest.SelectorResolutionPrecedesExtensionAdapterDispatch'
)
RED_FAILURES=("${POLICY_RED_FAILURES[@]}")
if [[ -n "${FOCUS}" ]]; then
  FILTER="${FOCUS}"
fi
if [[ "${FOCUSED}" == true && -z "${FOCUS}" ]]; then
  FILTER='PrometheusExtensionPolicy*:*PrometheusExtensionSurface*:*PrometheusExtensionAgent*'
fi
if [[ "${FILTER}" == 'PrometheusExtensionSurface*' ]]; then
  RED_FAILURES=("${SURFACE_RED_FAILURES[@]}")
fi
if [[ "${FILTER}" == 'PrometheusExtensionAgent*' ]]; then
  RED_FAILURES=("${ADAPTER_RED_FAILURES[@]}")
fi

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
  note "compiling ${object}"
  command="$(query_compile_command "${object}")" \
    || fail "compile command query failed for ${object}"
  [[ -n "${command}" ]] || fail "compile command not found for ${object}"
  # The reviewed Siso graph predates the direct //components/tabs:public dep
  # on prometheus_agent_route. Supply Skia's exported include root while the
  # source-owned BUILD.gn fix remains intentionally ungenerated.
  if [[ "${command}" != *" -I../../third_party/skia"* ]]; then
    command="${command/ -o ${object}/ -I../../third_party/skia -o ${object}}"
  fi
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
  note "compiling ${object} from ${template_object}"
  command="$(query_compile_command "${template_object}")" \
    || fail "compile template query failed for ${template_object}"
  [[ -n "${command}" ]] || fail "compile template not found for ${template_object}"
  command="${command//${template_stem}/${target_stem}}"
  if [[ "${command}" != *" -I../../third_party/skia"* ]]; then
    command="${command/ -o ${object}/ -I../../third_party/skia -o ${object}}"
  fi
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
  local compatibility_catalog='obj/chrome/browser/prometheus/prometheus_extension_compatibility_catalog/prometheus_extension_compatibility_catalog.o'
  local route='obj/chrome/browser/prometheus/prometheus_agent_route/prometheus_agent_route.o'
  local route_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_route_unittest.o'
  local codec='obj/chrome/browser/prometheus/prometheus_agent_transport_codec/prometheus_agent_transport_codec.o'
  local codec_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_transport_codec_unittest.o'
  local surface_resolver='obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o'
  local surface_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_extension_surface_resolver_unittest.o'
  local extension_adapter='obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o'
  local extension_adapter_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_extension_page_adapter_unittest.o'
  local agent_service='obj/chrome/browser/prometheus/prometheus_agent_service/prometheus_agent_service.o'
  local agent_session='obj/chrome/browser/prometheus/prometheus_agent_session/prometheus_agent_session.o'
  local agent_profile_service='obj/chrome/browser/prometheus/prometheus_agent_profile_service/prometheus_agent_profile_service.o'
  local agent_profile_factory='obj/chrome/browser/prometheus/prometheus_agent_profile_service/prometheus_agent_profile_service_factory.o'
  local supervision_profile_factory='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_supervision_profile_service_factory.o'
  local agent_audit='obj/chrome/browser/prometheus/prometheus_agent_audit/prometheus_agent_audit.o'
  local page_adapter='obj/chrome/browser/prometheus/prometheus_page_adapter/prometheus_page_adapter.o'
  local page_action_dispatcher='obj/chrome/browser/prometheus/prometheus_page_adapter/prometheus_page_action_dispatcher.o'
  local page_element_reader='obj/chrome/browser/prometheus/prometheus_page_adapter/prometheus_page_element_reader.o'
  local agent_audit_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_audit_unittest.o'
  local agent_service_test='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_service_unittest.o'
  local browser_test_template='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_page_adapter_browsertest.o'
  local surface_browser_test='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_surface_browsertest.o'
  local extension_agent_browser_test='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_extension_agent_browsertest.o'
  local extension_popup='obj/chrome/browser/ui/ui/extension_popup.o'
  local side_panel_coordinator='obj/chrome/browser/ui/views/side_panel/side_panel/extension_side_panel_coordinator.o'
  local side_panel_manager='obj/chrome/browser/ui/views/side_panel/side_panel/extension_side_panel_manager.o'
  local browser_prefs='obj/chrome/browser/prefs/impl/browser_prefs.o'
  local chrome_browser_main='obj/chrome/browser/core/chrome_browser_main.o'
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
    obj/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap/prometheus_extension_smoke_bootstrap.o
    obj/chrome/browser/prometheus/prometheus_extension_smoke_controller/prometheus_extension_smoke_controller.o
    obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o
    obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o
    "${policy_types}"
    "${policy_prefs}"
    "${policy_service}"
    "${policy_factory}"
    "${policy_test}"
    "${compatibility_catalog}"
    "${route_test}"
    "${codec_test}"
    "${surface_resolver}"
    "${surface_test}"
    "${surface_browser_test}"
    "${extension_adapter}"
    "${extension_adapter_test}"
    "${agent_audit_test}"
    "${agent_service_test}"
    "${extension_agent_browser_test}"
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
  compile_synthesized_object "${runtime_types}" "${compatibility_catalog}" \
    prometheus_runtime_types prometheus_extension_compatibility_catalog
  compile_exact_object "${route}"
  compile_exact_object "${codec}"
  compile_exact_object "${route_test}"
  compile_synthesized_object "${route_test}" "${codec_test}" \
    prometheus_agent_route_unittest \
    prometheus_agent_transport_codec_unittest
  compile_synthesized_object "${runtime_service}" "${surface_resolver}" \
    prometheus_runtime_profile_service prometheus_extension_surface_resolver
  compile_synthesized_object "${runtime_test}" "${surface_test}" \
    prometheus_runtime_profile_service_unittest \
    prometheus_extension_surface_resolver_unittest
  compile_synthesized_object "${runtime_service}" "${extension_adapter}" \
    prometheus_runtime_profile_service prometheus_extension_page_adapter
  compile_synthesized_object "${runtime_test}" "${extension_adapter_test}" \
    prometheus_runtime_profile_service_unittest \
    prometheus_extension_page_adapter_unittest
  compile_exact_object "${agent_service}"
  compile_exact_object "${agent_session}"
  # AgentProfileService embeds PrometheusAgentService by value. Recompile both
  # composition objects whenever the Agent service layout changes so profile
  # teardown uses the same owning-sequence WeakPtrFactory layout.
  compile_exact_object "${agent_profile_service}"
  compile_exact_object "${agent_profile_factory}"
  compile_synthesized_object "${runtime_factory}" \
    "${supervision_profile_factory}" prometheus_runtime_profile_service_factory \
    prometheus_supervision_profile_service_factory
  compile_exact_object "${agent_audit}"
  compile_exact_object "${page_adapter}"
  compile_exact_object "${page_action_dispatcher}"
  compile_exact_object "${page_element_reader}"
  compile_exact_object "${agent_audit_test}"
  compile_exact_object "${agent_service_test}"
  compile_synthesized_object "${browser_test_template}" \
    "${surface_browser_test}" prometheus_page_adapter_browsertest \
    prometheus_extension_surface_browsertest
  compile_synthesized_object "${browser_test_template}" \
    "${extension_agent_browser_test}" prometheus_page_adapter_browsertest \
    prometheus_extension_agent_browsertest
  compile_exact_object "${extension_popup}"
  compile_exact_object "${side_panel_coordinator}"
  compile_exact_object "${side_panel_manager}"
  compile_exact_object "${browser_prefs}"
  compile_exact_object "${chrome_browser_main}"

  local extra
  for extra in "${extras[@]}"; do
    require_file "${OUT_DIR}/${extra}"
  done

  build_focused_response
  local link_command
  link_command="$(query_browser_link_command)"
  [[ -n "${link_command}" ]] \
    || fail 'browser_tests direct link command not found'
  local original_output='-o "./browser_tests"'
  local focused_output='-o "./prometheus_unittests"'
  local original_response='@./browser_tests.rsp'
  local focused_response='@./phase22-extension-policy/focused-browser-tests.rsp'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'browser_tests output argument was not found'
  [[ "${link_command}" == *"${original_response}"* ]] \
    || fail 'browser_tests response argument was not found'
  link_command="${link_command/${original_output}/${focused_output}}"
  link_command="${link_command/${original_response}/${focused_response}}"
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
  [[ "${count}" -gt 0 ]] || fail "${FILTER} selected zero tests"
  if rg -q 'DISABLED_' "${LIST_LOG}"; then
    fail 'focused policy list contains a disabled test'
  fi
  note "selected ${count} runnable test(s) for ${FILTER}"
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

verify_extension_dispatch_static_contract() {
  local adapter="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_extension_page_adapter.cc"
  local service="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_service.cc"
  local page_adapter="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_page_adapter.cc"
  local action_dispatcher="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_page_action_dispatcher.cc"
  local element_reader="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_page_element_reader.cc"

  rg -q 'SchemeIsHTTPOrHTTPS\(\)' "${page_adapter}" \
    || fail 'ordinary page adapter no longer has an HTTP(S)-only boundary'
  rg -q 'GetEffectiveGrant' "${adapter}" \
    || fail 'extension adapter does not re-read the effective grant'
  rg -q 'resolver\.Resolve' "${adapter}" \
    || fail 'extension adapter does not re-resolve browser-owned state'
  rg -q 'DispatchValidationCallback' "${action_dispatcher}" \
    || fail 'extension actions lack an immediate pre-mutation validator'
  rg -q 'DispatchValidationCallback' "${element_reader}" \
    || fail 'extension element reads lack an immediate dispatch validator'
  rg -q 'OnExtensionPageRouteComplete' "${service}" \
    || fail 'Agent service does not retain a distinct extension completion'
  rg -q 'RecordExtensionAudit' "${service}" \
    || fail 'Agent service does not emit the bounded extension audit'

  if rg -qi \
      'prometheus_page_js_executor|prometheus_agent_gateway|prometheus_vault_service|SetRequestedGrant|native_messaging' \
      "${adapter}"; then
    fail 'extension adapter references a forbidden script or reverse-authority path'
  fi

  local recovery_copy
  for recovery_copy in \
    'Extension no longer available.' \
    'Extension surface blocked.' \
    'Read access is blocked for this extension.' \
    'Interaction is blocked for this extension.' \
    'This extension context is not available to Agents.' \
    'Scripts are blocked on extension surfaces.' \
    'Extension policy changed before the action ran.' \
    'Agent access is blocked for this extension in Private mode.'; do
    rg -Fq "${recovery_copy}" "${adapter}" \
      || fail "missing extension recovery copy: ${recovery_copy}"
  done
  note 'extension dispatch static contract passed'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests
if [[ "${EXPECT_FAILURE}" == false ]]; then
  verify_extension_dispatch_static_contract
fi

if [[ "${FOCUSED}" == false && "${EXPECT_FAILURE}" == false &&
      -z "${FOCUS}" ]]; then
  "${BINARY}" --gtest_list_tests --gtest_filter="${REGISTRY_FILTER}" \
    >"${LOG_DIR}/registry-list.log" 2>&1
  if ! awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { found = 1 }
            END { exit(found ? 0 : 1) }' "${LOG_DIR}/registry-list.log"; then
    fail 'registry/lifecycle filter selected zero tests'
  fi
fi

note "verification complete; logs: ${LOG_DIR}"
