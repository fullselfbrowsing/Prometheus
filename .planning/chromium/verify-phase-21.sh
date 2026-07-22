#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

FOCUS_FILTER=''
FOCUS_KIND=''
EXPECT_FAILURE=false

usage() {
  printf 'Usage: %s (--focus FILTER | --focus-browser FILTER | --focus-blink FILTER) [--expect-failure]\n' "$0" >&2
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
      FOCUS_KIND='browser'
      shift 2
      ;;
    --focus-browser)
      [[ "$#" -ge 2 ]] || {
        usage
        exit 2
      }
      [[ -z "${FOCUS_FILTER}" ]] || {
        usage
        exit 2
      }
      FOCUS_FILTER="$2"
      FOCUS_KIND='browser-integration'
      shift 2
      ;;
    --focus-blink)
      [[ "$#" -ge 2 ]] || {
        usage
        exit 2
      }
      [[ -z "${FOCUS_FILTER}" ]] || {
        usage
        exit 2
      }
      FOCUS_FILTER="$2"
      FOCUS_KIND='blink'
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
FOCUSED_BLINK_MODULES_DIR="${LOG_DIR}/blink-modules"
FOCUSED_BLINK_MODULES="${FOCUSED_BLINK_MODULES_DIR}/libblink_modules.dylib"
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
FOCUSED_BINARY="${OUT_DIR}/browser_tests"
TEMP_FOCUSED_BINARY="${OUT_DIR}/phase21_browser_tests"
LIST_LOG="${LOG_DIR}/phase21-focused-list.log"
TEST_LOG="${LOG_DIR}/phase21-focused-test.log"
BUILD_LOG="${LOG_DIR}/phase21-focused-build.log"
METADATA_CAPTURED=false

if [[ "${FOCUS_KIND}" == 'blink' ]]; then
  FOCUSED_BINARY="${OUT_DIR}/phase21_blink_tests"
  TEMP_FOCUSED_BINARY="${FOCUSED_BINARY}"
fi

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

require_literal() {
  local literal="$1"
  local file="$2"
  rg -q --fixed-strings -- "${literal}" "${file}" \
    || fail "missing composition contract '${literal}' in ${file}"
}

reject_pattern() {
  local pattern="$1"
  local description="$2"
  shift 2
  if rg -n -- "${pattern}" "$@" >"${LOG_DIR}/phase21-static-guard.log"; then
    tail -n 80 "${LOG_DIR}/phase21-static-guard.log" >&2 || true
    fail "${description}"
  fi
}

verify_composition_contract() {
  local agent_service="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_service.cc"
  local agent_profile="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_profile_service.cc"
  local supervision="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service.cc"
  local supervision_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service.h"
  local factory="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.cc"
  local factory_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service_factory.h"

  require_file "${agent_service}"
  require_file "${agent_profile}"
  require_file "${supervision}"
  require_file "${supervision_header}"
  require_file "${factory}"
  require_file "${factory_header}"

  require_literal 'agent_service_.ObserveOrCreateTabData(tab, observer)' "${agent_profile}"
  require_literal 'ProfileSelections::BuildForRegularProfile()' "${factory}"
  require_literal 'DependsOn(PrometheusAgentProfileServiceFactory::GetInstance())' "${factory}"
  require_literal 'PrometheusAgentProfileServiceFactory::GetForProfile(profile)' "${factory}"
  require_literal 'weak_factory_.GetWeakPtr()' "${factory}"

  reject_pattern \
    'GetOrCreateForTab|EnsureTabData|RegisterWillDetach|OnTabWillDetach|OwnedTabData|(^|[^[:alnum:]_])tab_data_|InvalidateTabObservations|PruneUnownedTabData' \
    'supervision gained an independent Agent tab-data ownership path' \
    "${agent_profile}" "${supervision}" "${supervision_header}" \
    "${factory}" "${factory_header}"
  reject_pattern 'PrometheusAgentProfileServiceFactory' \
    'supervision service bypassed its composition factory' \
    "${supervision}" "${supervision_header}"

  require_literal 'PrometheusAgentTabData::GetOrCreateForTab(tab)' "${agent_service}"
  require_literal 'std::make_unique<OwnedTabData>' "${agent_service}"
  require_literal 'tab->RegisterWillDetach' "${agent_service}"
  require_literal '&PrometheusAgentService::OnTabWillDetach' "${agent_service}"
  require_literal 'tab_data_.erase' "${agent_service}"
  note 'Agent ownership and keyed-service composition static guards passed'
}

verify_blink_contract() {
  local mojom="${CHROMIUM_DIR}/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom"
  local public_build="${CHROMIUM_DIR}/third_party/blink/public/mojom/BUILD.gn"
  local supplement_header="${CHROMIUM_DIR}/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.h"
  local supplement_source="${CHROMIUM_DIR}/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.cc"
  local supplement_test="${CHROMIUM_DIR}/third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement_unittest.cc"
  local content_build="${CHROMIUM_DIR}/third_party/blink/renderer/modules/content_extraction/BUILD.gn"
  local modules_build="${CHROMIUM_DIR}/third_party/blink/renderer/modules/BUILD.gn"
  local modules_initializer="${CHROMIUM_DIR}/third_party/blink/renderer/modules/modules_initializer.cc"

  require_file "${mojom}"
  require_file "${supplement_header}"
  require_file "${supplement_source}"
  require_file "${supplement_test}"
  require_file "${modules_initializer}"
  require_literal 'enum PrometheusSupervisionDirtySignal {' "${mojom}"
  require_literal 'kDirty,' "${mojom}"
  require_literal 'kOverflow,' "${mojom}"
  require_literal 'interface PrometheusSupervisionDocumentHost {' "${mojom}"
  require_literal 'OnDocumentDirty(PrometheusSupervisionDirtySignal signal);' "${mojom}"
  require_literal 'interface PrometheusSupervisionDocument {' "${mojom}"
  require_literal 'Enable(pending_remote<PrometheusSupervisionDocumentHost> host);' "${mojom}"
  require_literal 'Disable();' "${mojom}"
  reject_pattern \
    '(^|[^[:alnum:]_])(string|array|map|struct|union|url|origin|node|record|identity|epoch|sequence)([^[:alnum:]_]|$)' \
    'Blink supervision Mojo contract gained content or identity payloads' \
    "${mojom}"

  [[ "$(rg -c '^[[:space:]]*OnDocumentDirty\(' "${mojom}")" -eq 1 ]] \
    || fail 'Blink host contract must expose exactly one dirty callback'
  [[ "$(rg -c '^[[:space:]]*(Enable|Disable)\(' "${mojom}")" -eq 2 ]] \
    || fail 'Blink document contract must expose only Enable and Disable'

  require_literal '"content_extraction/prometheus_supervision_document.mojom"' "${public_build}"
  require_literal '"prometheus_supervision_document_supplement.cc"' "${content_build}"
  require_literal '"prometheus_supervision_document_supplement.h"' "${content_build}"
  require_literal '"content_extraction/prometheus_supervision_document_supplement_unittest.cc"' "${modules_build}"
  require_literal 'public Supplement<Document>' "${supplement_header}"
  require_literal 'PrometheusSupervisionDocumentSupplement::BindReceiver' "${supplement_source}"
  require_literal 'supplement_->OnMutationRecordCount(records.size());' "${supplement_source}"
  require_literal 'kMaxPendingMutationRecords = 256u' "${supplement_header}"
  require_literal 'kDirtyDebounce = base::Milliseconds(50)' "${supplement_header}"
  require_literal 'init->setChildList(true);' "${supplement_source}"
  require_literal 'init->setAttributes(true);' "${supplement_source}"
  require_literal 'init->setCharacterData(true);' "${supplement_source}"
  require_literal 'init->setSubtree(true);' "${supplement_source}"
  reject_pattern \
    '(record|records)[[:space:]]*(\[|->)|addedNodes|removedNodes|attributeName|oldValue|newValue|target\(' \
    'Blink supervision inspected MutationRecord content' \
    "${supplement_source}" "${supplement_header}"
  reject_pattern \
    'JSONReader|JSONWriter|Serialize|innerHTML|outerHTML|ExecuteScript|ScriptState' \
    'Blink supervision gained serialization or script execution' \
    "${supplement_source}" "${supplement_header}"
  require_literal \
    '#include "third_party/blink/renderer/modules/content_extraction/prometheus_supervision_document_supplement.h"' \
    "${modules_initializer}"
  require_literal \
    '&PrometheusSupervisionDocumentSupplement::BindReceiver' \
    "${modules_initializer}"
  require_literal \
    '&PrometheusSupervisionDocumentSupplement::OnReceiverDisconnected' \
    "${supplement_source}"
  require_literal \
    '&PrometheusSupervisionDocumentSupplement::OnHostDisconnected' \
    "${supplement_source}"
  note 'Blink document, Mojo privacy, and GN static guards passed'
}

verify_capture_hub_contract() {
  local hub_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub.h"
  local hub_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc"
  local hub_test="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub_unittest.cc"
  local hub_browser_test="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc"
  local profile_service="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service.cc"
  local profile_service_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service.h"
  local profile_service_test="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_profile_service_unittest.cc"
  local browser_build="${CHROMIUM_DIR}/chrome/browser/prometheus/BUILD.gn"
  local views_build="${CHROMIUM_DIR}/chrome/browser/ui/views/prometheus/BUILD.gn"

  require_file "${hub_header}"
  require_file "${hub_source}"
  require_file "${hub_test}"
  require_file "${hub_browser_test}"
  require_file "${profile_service_test}"
  require_literal 'class PrometheusSupervisionCaptureHub : public content::WebContentsObserver' "${hub_header}"
  require_literal 'SupervisionCaptureConsumerKind::kDashboard' "${hub_test}"
  require_literal 'SupervisionCaptureConsumerKind::kAgentCompatibility' "${hub_test}"
  require_literal 'using CaptureConsumerToken = uint64_t;' "${hub_header}"
  require_literal 'WaitForNextDiff' "${hub_header}"
  require_literal 'CancelDiffWait' "${hub_header}"
  require_literal 'DashboardLongPoll' "${hub_test}"
  require_literal 'mojo::Remote<blink::mojom::PrometheusSupervisionDocument>' "${hub_source}"
  require_literal 'mojo::Receiver<blink::mojom::PrometheusSupervisionDocumentHost>' "${hub_source}"
  require_literal 'content::WeakDocumentPtr requested_document' "${hub_source}"
  require_literal 'optimization_guide::GetAIPageContent(' "${hub_source}"
  require_literal 'options->include_same_site_only = true;' "${hub_source}"
  require_literal 'options->include_passwords_for_redaction = true;' "${hub_source}"
  require_literal 'options->include_sensitive_payments_for_redaction = true;' "${hub_source}"
  require_literal 'options->include_otps_for_redaction = true;' "${hub_source}"
  require_literal 'CollectRawFormValuesForSupervision' "${hub_source}"
  require_literal 'RemoveRawFormValuesForSupervision' "${hub_source}"
  require_literal 'net::test_server::ControllableHttpResponse' "${hub_browser_test}"
  require_literal 'TwoConsumersUseOneRendererEnableAndApcCapture' "${hub_browser_test}"
  require_literal 'TwoDashboardConsumersShareRealMutationsAndDetachIndependently' "${hub_browser_test}"
  require_literal 'TwoDashboardConsumersNavigationRequiresIndependentBaselines' "${hub_browser_test}"
  require_literal 'kSecondReleasePath' "${hub_browser_test}"
  require_literal 'kMutationMarker' "${hub_browser_test}"
  require_literal '"prometheus_supervision_capture_hub.cc"' "${browser_build}"
  require_literal '"prometheus_supervision_capture_hub_unittest.cc"' "${browser_build}"
  require_literal '"../../../prometheus/prometheus_supervision_capture_hub_browsertest.cc"' "${views_build}"
  require_literal '"//chrome/browser/prometheus:prometheus_supervision_profile_service"' "${views_build}"
  require_literal 'GetOrCreateCaptureHub(' "${profile_service}"
  require_literal 'SupervisionCaptureConsumerKind::kDashboard' "${profile_service}"
  require_literal 'capture_consumer_token' "${profile_service}"
  require_literal 'ReadDashboardBaseline' "${profile_service_header}"
  require_literal 'ReadDashboardDiff' "${profile_service_header}"
  require_literal 'BeginDashboardDiffWait' "${profile_service_header}"
  require_literal 'CancelDashboardDiffWait' "${profile_service_header}"
  require_literal 'AckDashboard' "${profile_service_header}"
  require_literal 'HubDashboardLongPoll' "${profile_service_test}"
  reject_pattern \
    'mojo::|PrometheusSupervisionDocument' \
    'capture-hub consumer API exposed a renderer or Mojo endpoint' \
    "${hub_header}"
  reject_pattern \
    'ExecuteScript|MutationObserver|MutationRecord|innerHTML|outerHTML' \
    'browser capture hub gained production script injection or raw mutation access' \
    "${hub_source}"
  reject_pattern \
    'ExecJs|EvalJs|ExecuteScript|MutationObserver' \
    'capture-hub browser proof used test-side script injection or a synthetic observer' \
    "${hub_browser_test}"
  reject_pattern \
    'mojo::|blink::mojom::PrometheusSupervisionDocument|optimization_guide::GetAIPageContent|SupervisionNormalizedNode|SharedBatch|document_remote_|capture_for_testing_|retained_batches_|acknowledged_sequence|next_sequence' \
    'profile service duplicated renderer, capture-tree, history, or cursor ownership' \
    "${profile_service}" "${profile_service_header}"
  [[ "$(rg -c --fixed-strings 'document_remote_->Enable' "${hub_source}")" -eq 1 ]] \
    || fail 'capture hub must own exactly one renderer Enable call site'
  note 'capture-hub ownership, consumer API, privacy, and GN static guards passed'
}

verify_gateway_contract() {
  local gateway_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_gateway.h"
  local gateway_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_gateway.cc"
  local contract_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_gateway_contract.h"
  local contract_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc"
  local browser_build="${CHROMIUM_DIR}/chrome/browser/prometheus/BUILD.gn"
  local gateway_build_block="${LOG_DIR}/phase21-gateway-build.gn"

  require_file "${gateway_header}"
  require_file "${gateway_source}"
  require_file "${contract_header}"
  require_file "${contract_source}"
  require_literal 'struct SupervisionGatewayDispatcher' "${contract_header}"
  require_literal 'SupervisionGatewayCancellationToken' "${contract_header}"
  require_literal 'SupervisionGatewayReadiness' "${contract_header}"
  require_literal 'base::RepeatingClosure shutdown;' "${contract_header}"
  require_literal '"/v1/supervision"' "${contract_source}"
  require_literal 'SetSupervisionGatewayDispatcher' "${gateway_source}"
  require_literal 'ParseSupervisionTransportRequest' "${gateway_source}"
  require_literal 'supervision_dispatcher_->dispatch.Run' "${gateway_source}"
  require_literal 'supervision_dispatcher_->cancel.Run' "${gateway_source}"
  require_literal 'supervision_dispatcher_->readiness.Run' "${gateway_source}"
  require_literal 'ShutdownSupervisionDispatcher' "${gateway_source}"
  require_literal 'OnTransportRequestTerminated' "${gateway_source}"
  require_literal '"prometheus_agent_gateway_contract.h"' "${browser_build}"
  sed -n '/source_set("prometheus_agent_gateway") {/,/^}/p' \
    "${browser_build}" >"${gateway_build_block}"
  require_file "${gateway_build_block}"
  reject_pattern \
    '#include .*prometheus_supervision_(profile_service|capture_hub)|#include .*(browser_window|web_contents|render_frame_host)|(^|[^[:alnum:]_])(raw_ptr|WeakPtr|unique_ptr)<(Profile|Browser|BrowserWindowInterface|WebContents|RenderFrameHost|PrometheusSupervisionProfileService|PrometheusSupervisionCaptureHub)>' \
    'gateway contract gained concrete profile, target, capture, or renderer authority' \
    "${contract_header}"
  reject_pattern \
    'prometheus_supervision_(profile_service|profile_service_factory|capture_hub)|PrometheusSupervision(ProfileService|ProfileServiceFactory|CaptureHub)|RenderFrameHost|WebContents|prometheus_supervision_document' \
    'Agent gateway gained a concrete supervision service, capture, or renderer edge' \
    "${gateway_header}" "${gateway_source}" "${gateway_build_block}"
  note 'gateway abstract-dispatch contract and GN static guards passed'
}

verify_agent_supervision_transport_contract() {
  local route_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_route.h"
  local route_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_route.cc"
  local codec_header="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_transport_codec.h"
  local codec_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_transport_codec.cc"
  local codec_test="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_transport_codec_unittest.cc"
  local browser_build="${CHROMIUM_DIR}/chrome/browser/prometheus/BUILD.gn"

  require_file "${route_header}"
  require_file "${route_source}"
  require_file "${codec_header}"
  require_file "${codec_source}"
  require_file "${codec_test}"
  require_literal 'kAgentSupervisionRouteCount = 5' "${route_header}"
  require_literal 'kCreateSupervisionPairing' "${route_header}"
  require_literal 'kStartSupervisionSession' "${route_header}"
  require_literal 'kGetSupervisionSnapshot' "${route_header}"
  require_literal 'kGetSupervisionDiff' "${route_header}"
  require_literal 'kEndSupervisionSession' "${route_header}"
  require_literal 'using AgentSupervisionPayload =' "${route_header}"
  require_literal 'AgentSupervisionLocalUiResult' "${route_header}"
  require_literal 'AgentSupervisionBaselineResult' "${route_header}"
  require_literal 'AgentSupervisionDiffResult' "${route_header}"
  require_literal 'AgentSupervisionNoChangeResult' "${route_header}"
  require_literal 'AgentSupervisionEndedResult' "${route_header}"
  require_literal 'SupervisionManifestHasExactlyFiveBijectiveRoutes' "${codec_test}"
  require_literal 'SupervisionRequestsAcceptOnlyEmptyCallerScopedObjects' "${codec_test}"
  require_literal 'SupervisionRejectsRecursiveAuthorityContentAndSecretSentinels' "${codec_test}"
  require_literal '"prometheus_agent_transport_codec_unittest.cc"' "${browser_build}"
  reject_pattern \
    'prometheus_supervision_(profile_service|profile_service_factory|capture_hub)|PrometheusSupervision(ProfileService|ProfileServiceFactory|CaptureHub)|prometheus_supervision_document|RenderFrameHost|WebContents' \
    'Agent route/codec contract gained concrete supervision service, capture, or renderer ownership' \
    "${route_header}" "${route_source}" "${codec_header}" "${codec_source}"
  reject_pattern \
    'start_visual_session|end_visual_session' \
    'legacy visual-session names re-entered the native Agent route or codec' \
    "${route_header}" "${route_source}" "${codec_header}" "${codec_source}"
  note 'Agent supervision route/result declarations, privacy fixture, and GN guards passed'
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

capture_build_metadata() {
  require_file "${OUT_DIR}/.ninja_log"
  require_file "${OUT_DIR}/.ninja_deps"
  require_file "${OUT_DIR}/libblink_modules.dylib"
  require_file "${OUT_DIR}/libblink_modules.dylib.TOC"
  NINJA_LOG_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_log")"
  NINJA_DEPS_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/.ninja_deps")"
  BLINK_MODULES_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/libblink_modules.dylib")"
  BLINK_MODULES_TOC_SHA256_BEFORE="$(sha256_file "${OUT_DIR}/libblink_modules.dylib.TOC")"
  METADATA_CAPTURED=true
}

verify_build_metadata_on_exit() {
  local status="$?"
  trap - EXIT
  if [[ "${METADATA_CAPTURED}" == true ]]; then
    local ninja_log_after ninja_deps_after blink_modules_after blink_modules_toc_after
    ninja_log_after="$(sha256_file "${OUT_DIR}/.ninja_log" 2>/dev/null || true)"
    ninja_deps_after="$(sha256_file "${OUT_DIR}/.ninja_deps" 2>/dev/null || true)"
    blink_modules_after="$(sha256_file "${OUT_DIR}/libblink_modules.dylib" 2>/dev/null || true)"
    blink_modules_toc_after="$(sha256_file "${OUT_DIR}/libblink_modules.dylib.TOC" 2>/dev/null || true)"
    printf '[phase21] .ninja_log SHA-256 before=%s after=%s\n' \
      "${NINJA_LOG_SHA256_BEFORE}" "${ninja_log_after}"
    printf '[phase21] .ninja_deps SHA-256 before=%s after=%s\n' \
      "${NINJA_DEPS_SHA256_BEFORE}" "${ninja_deps_after}"
    printf '[phase21] reviewed libblink_modules.dylib SHA-256 before=%s after=%s\n' \
      "${BLINK_MODULES_SHA256_BEFORE}" "${blink_modules_after}"
    printf '[phase21] reviewed libblink_modules.dylib.TOC SHA-256 before=%s after=%s\n' \
      "${BLINK_MODULES_TOC_SHA256_BEFORE}" "${blink_modules_toc_after}"
    if [[ "${ninja_log_after}" != "${NINJA_LOG_SHA256_BEFORE}" ||
          "${ninja_deps_after}" != "${NINJA_DEPS_SHA256_BEFORE}" ||
          "${blink_modules_after}" != "${BLINK_MODULES_SHA256_BEFORE}" ||
          "${blink_modules_toc_after}" != "${BLINK_MODULES_TOC_SHA256_BEFORE}" ]]; then
      printf 'Phase 21 focused verification failed: direct verification changed reviewed build artifacts\n' >&2
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
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  printf 'compile %s\n' "${object}" >>"${BUILD_LOG}"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${BUILD_LOG}" 2>&1 || {
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

query_blink_link_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" \
      prometheus_action_dispatcher_unittests 2>/dev/null \
    | LC_ALL=C awk \
        'index($0, "linker_driver.py") &&
         index($0, "@./prometheus_action_dispatcher_unittests.rsp") {
           command = $0
         }
         END { print command }'
}

query_blink_modules_link_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" \
      libblink_modules.dylib 2>/dev/null \
    | LC_ALL=C awk \
        'index($0, "linker_driver.py") &&
         index($0, " -o \"./libblink_modules.dylib\"") &&
         index($0, "@./libblink_modules.dylib.rsp") {
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
    perl -0777 -pe 's/\$\r?\n//g' "${OUT_DIR}/${target_ninja}" \
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
    perl -0777 -pe 's/\$\r?\n//g' "${OUT_DIR}/${target_ninja}" \
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
  } >"${OUT_DIR}/${response_file}"
  require_file "${OUT_DIR}/${response_file}"
}

generate_blink_mojo_bindings() {
  local mojom='../../third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom'
  local parser_rsp='phase21-focused/prometheus-supervision-parser.rsp'
  local blink_rsp='phase21-focused/prometheus-supervision-blink.rsp'
  local shared_rsp='phase21-focused/prometheus-supervision-shared.rsp'
  local message_ids_rsp='phase21-focused/prometheus-supervision-message-ids.rsp'
  local browser_rsp='phase21-focused/prometheus-supervision-browser.rsp'
  printf '%s\n' "${mojom}" >"${OUT_DIR}/${parser_rsp}"
  printf '%s\n' "${mojom}" >"${OUT_DIR}/${blink_rsp}"
  printf '%s\n' "${mojom}" >"${OUT_DIR}/${shared_rsp}"
  printf '%s\n' "${mojom}" >"${OUT_DIR}/${message_ids_rsp}"
  printf '%s\n' "${mojom}" >"${OUT_DIR}/${browser_rsp}"

  if ! (
    cd "${OUT_DIR}"
    python3 ../../mojo/public/tools/mojom/mojom_parser.py \
      --input-root ../.. --input-root gen --output-root gen \
      --mojom-file-list="${parser_rsp}" \
      --enable-feature is_posix --enable-feature is_mac --enable-feature is_apple
    python3 ../../mojo/public/tools/bindings/mojom_bindings_generator.py \
      --use_bundled_pylibs -o gen generate -d ../../ -I ../../ \
      --bytecode_path gen/mojo/public/tools/bindings \
      --filelist="${message_ids_rsp}" --generate_non_variant_code \
      --generate_message_ids -g c++
    python3 ../../mojo/public/tools/bindings/mojom_bindings_generator.py \
      --use_bundled_pylibs -o gen generate -d ../../ -I ../../ \
      --bytecode_path gen/mojo/public/tools/bindings \
      --export_attribute BLINK_COMMON_EXPORT \
      --export_header third_party/blink/public/common/common_export.h \
      --filelist="${browser_rsp}" -g c++
    python3 ../../mojo/public/tools/bindings/mojom_bindings_generator.py \
      --use_bundled_pylibs -o gen generate -d ../../ -I ../../ \
      --bytecode_path gen/mojo/public/tools/bindings \
      --export_attribute PLATFORM_EXPORT \
      --export_header third_party/blink/renderer/platform/platform_export.h \
      --filelist="${blink_rsp}" -g c++ --variant blink \
      --typemap gen/third_party/blink/public/mojom/mojom_platform_blink__type_mappings \
      --for_blink
    python3 ../../mojo/public/tools/bindings/mojom_bindings_generator.py \
      --use_bundled_pylibs -o gen generate -d ../../ -I ../../ \
      --bytecode_path gen/mojo/public/tools/bindings \
      --filelist="${shared_rsp}" --generate_non_variant_code -g c++ \
      --export_attribute 'COMPONENT_EXPORT(MOJOM_SHARED_BLINK_COMMON_EXPORT)' \
      --export_header base/component_export.h
  ) >>"${BUILD_LOG}" 2>&1; then
    tail -n 80 "${BUILD_LOG}" >&2 || true
    fail 'focused Blink Mojo generation failed'
  fi

  require_file "${OUT_DIR}/gen/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom-blink.cc"
  require_file "${OUT_DIR}/gen/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom.cc"
  require_file "${OUT_DIR}/gen/third_party/blink/public/mojom/content_extraction/prometheus_supervision_document.mojom-shared.cc"
}

build_blink_focused_binary() {
  local production_template='obj/third_party/blink/renderer/modules/content_extraction/content_extraction/frame_metadata_observer_registry.o'
  local production_object='obj/third_party/blink/renderer/modules/content_extraction/content_extraction/prometheus_supervision_document_supplement.o'
  local test_template='obj/third_party/blink/renderer/modules/unit_tests/frame_metadata_observer_registry_unittest.o'
  local test_object='obj/third_party/blink/renderer/modules/unit_tests/prometheus_supervision_document_supplement_unittest.o'
  local blink_template='obj/third_party/blink/public/mojom/mojom_platform_blink/frame_metadata_observer_registry.mojom-blink.o'
  local blink_object='obj/third_party/blink/public/mojom/mojom_platform_blink/prometheus_supervision_document.mojom-blink.o'
  local shared_template='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/frame_metadata_observer_registry.mojom-shared.o'
  local shared_object='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o'
  local frame_test_helpers_object='obj/third_party/blink/renderer/core/unit_test_support/frame_test_helpers.o'
  local fake_web_plugin_object='obj/third_party/blink/renderer/core/unit_test_support/fake_web_plugin.o'
  local blink_test_main_object='obj/third_party/blink/renderer/controller/blink_unittests_sources/run_all_tests.o'
  local modules_initializer_object='obj/third_party/blink/renderer/modules/modules/modules_initializer.o'
  local target_ninja='obj/chrome/renderer/prometheus_action_dispatcher_unittests.ninja'
  local response_file='phase21_blink_tests.rsp'
  local extra_objects=(
    "${production_object}"
    "${test_object}"
    "${blink_object}"
    "${shared_object}"
    "${frame_test_helpers_object}"
    "${fake_web_plugin_object}"
    "${blink_test_main_object}"
  )

  : >"${BUILD_LOG}"
  generate_blink_mojo_bindings
  compile_synthesized_object "${production_template}" "${production_object}" \
    frame_metadata_observer_registry prometheus_supervision_document_supplement
  compile_synthesized_object "${test_template}" "${test_object}" \
    frame_metadata_observer_registry_unittest prometheus_supervision_document_supplement_unittest
  compile_synthesized_object "${blink_template}" "${blink_object}" \
    frame_metadata_observer_registry prometheus_supervision_document
  compile_synthesized_object "${shared_template}" "${shared_object}" \
    frame_metadata_observer_registry prometheus_supervision_document
  compile_exact_object "${frame_test_helpers_object}"
  compile_exact_object "${fake_web_plugin_object}"
  compile_exact_object "${blink_test_main_object}"
  compile_exact_object "${modules_initializer_object}"

  local object
  for object in "${extra_objects[@]}"; do
    require_file "${OUT_DIR}/${object}"
  done
  write_link_response "${target_ninja}" \
    ./prometheus_action_dispatcher_unittests "${response_file}" \
    "${extra_objects[@]}"
  perl -0pi -e \
    's#obj/content/test/librun_all_unittests\.a[[:space:]]*##g' \
    "${OUT_DIR}/${response_file}"

  local link_command
  link_command="$(query_blink_link_command)"
  [[ -n "${link_command}" ]] \
    || fail 'Blink-capable direct link command not found'
  local original_output='-o "./prometheus_action_dispatcher_unittests"'
  local focused_output='-o "./phase21_blink_tests"'
  local original_response='@./prometheus_action_dispatcher_unittests.rsp'
  local focused_response="@./${response_file}"
  link_command="${link_command/${original_output}/${focused_output}}"
  link_command="${link_command/${original_response}/${focused_response}}"
  [[ "${link_command}" == *'-o "./phase21_blink_tests"'* ]] \
    || fail 'Blink-capable output argument was not replaced'
  [[ "${link_command}" == *"@./${response_file}"* ]] \
    || fail 'Blink-capable response file was not replaced'

  rm -f "${FOCUSED_BINARY}"
  if ! (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - ./phase21_blink_tests
    codesign --verify --strict ./phase21_blink_tests
  ) >>"${BUILD_LOG}" 2>&1; then
    tail -n 80 "${BUILD_LOG}" >&2 || true
    fail 'focused Blink unit-test link failed'
  fi
  require_file "${FOCUSED_BINARY}"
}

build_browser_focused_blink_modules() {
  local production_template='obj/third_party/blink/renderer/modules/content_extraction/content_extraction/frame_metadata_observer_registry.o'
  local production_object='obj/third_party/blink/renderer/modules/content_extraction/content_extraction/prometheus_supervision_document_supplement.o'
  local blink_template='obj/third_party/blink/public/mojom/mojom_platform_blink/frame_metadata_observer_registry.mojom-blink.o'
  local blink_object='obj/third_party/blink/public/mojom/mojom_platform_blink/prometheus_supervision_document.mojom-blink.o'
  local shared_template='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/frame_metadata_observer_registry.mojom-shared.o'
  local shared_object='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o'
  local modules_initializer_object='obj/third_party/blink/renderer/modules/modules/modules_initializer.o'
  local target_ninja='obj/third_party/blink/renderer/modules/modules.ninja'
  local response_file='phase21-focused/libblink_modules.dylib.rsp'
  local focused_output='./phase21-focused/blink-modules/libblink_modules.dylib'
  local focused_toc='./phase21-focused/blink-modules/libblink_modules.dylib.TOC'
  local original_output='-o "./libblink_modules.dylib"'
  local focused_output_argument="-o \"${focused_output}\""
  local original_toc='-Wcrl,tocname,"./libblink_modules.dylib.TOC"'
  local focused_toc_argument="-Wcrl,tocname,\"${focused_toc}\""
  local original_response='@./libblink_modules.dylib.rsp'
  local focused_response="@./${response_file}"

  generate_blink_mojo_bindings
  compile_synthesized_object "${production_template}" "${production_object}" \
    frame_metadata_observer_registry prometheus_supervision_document_supplement
  compile_synthesized_object "${blink_template}" "${blink_object}" \
    frame_metadata_observer_registry prometheus_supervision_document
  compile_synthesized_object "${shared_template}" "${shared_object}" \
    frame_metadata_observer_registry prometheus_supervision_document
  compile_exact_object "${modules_initializer_object}"

  write_link_response "${target_ninja}" ./libblink_modules.dylib \
    "${response_file}" "${production_object}" "${blink_object}" "${shared_object}"

  local link_command
  link_command="$(query_blink_modules_link_command)"
  [[ -n "${link_command}" ]] \
    || fail 'libblink_modules direct link command not found'
  link_command="${link_command/${original_toc}/${focused_toc_argument}}"
  link_command="${link_command/${original_output}/${focused_output_argument}}"
  link_command="${link_command/${original_response}/${focused_response}}"
  [[ "${link_command}" == *"${focused_toc_argument}"* ]] \
    || fail 'focused Blink modules TOC argument was not replaced'
  [[ "${link_command}" == *"${focused_output_argument}"* ]] \
    || fail 'focused Blink modules output argument was not replaced'
  [[ "${link_command}" == *"@./${response_file}"* ]] \
    || fail 'focused Blink modules response file was not replaced'

  mkdir -p "${FOCUSED_BLINK_MODULES_DIR}"
  rm -f "${FOCUSED_BLINK_MODULES}" "${FOCUSED_BLINK_MODULES}.TOC"
  if ! (
    cd "${OUT_DIR}"
    /bin/zsh -c "${link_command}"
    codesign --force --sign - "${focused_output}"
    codesign --verify --strict "${focused_output}"
  ) >>"${BUILD_LOG}" 2>&1; then
    tail -n 80 "${BUILD_LOG}" >&2 || true
    fail 'focused Blink modules link failed'
  fi
  require_file "${FOCUSED_BLINK_MODULES}"
  local symbol_manifest="${FOCUSED_BLINK_MODULES_DIR}/symbols.txt"
  nm -gU "${FOCUSED_BLINK_MODULES}" >"${symbol_manifest}"
  rg -q 'PrometheusSupervisionDocumentSupplement.*BindReceiver' \
    "${symbol_manifest}" \
    || fail 'focused Blink modules library omitted the supervision document binder'
  note 'temporary Blink modules library contains the supervision document endpoint'
}

build_focused_binary() {
  local route_object='obj/chrome/browser/prometheus/prometheus_agent_route/prometheus_agent_route.o'
  local route_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_route_unittest.o'
  local agent_codec_object='obj/chrome/browser/prometheus/prometheus_agent_transport_codec/prometheus_agent_transport_codec.o'
  local agent_codec_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_transport_codec_unittest.o'
  local agent_codec_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_agent_transport_codec_unittest.cc"
  local agent_transport_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_transport_unittest.o'
  local agent_service_object='obj/chrome/browser/prometheus/prometheus_agent_service/prometheus_agent_service.o'
  local agent_service_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_service_unittest.o'
  local agent_tab_data_object='obj/chrome/browser/prometheus/prometheus_agent_tab_data/prometheus_agent_tab_data.o'
  local agent_profile_object='obj/chrome/browser/prometheus/prometheus_agent_profile_service/prometheus_agent_profile_service.o'
  local agent_profile_factory_object='obj/chrome/browser/prometheus/prometheus_agent_profile_service/prometheus_agent_profile_service_factory.o'
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
  local supervision_hub_object='obj/chrome/browser/prometheus/prometheus_supervision_capture_hub/prometheus_supervision_capture_hub.o'
  local supervision_hub_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_supervision_capture_hub_unittest.o'
  local supervision_hub_browser_object='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_supervision_capture_hub_browsertest.o'
  local supervision_hub_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub.cc"
  local supervision_hub_test_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub_unittest.cc"
  local supervision_hub_browser_source="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub_browsertest.cc"
  local gateway_contract_object='obj/chrome/browser/prometheus/prometheus_agent_gateway_contract/prometheus_agent_gateway_contract.o'
  local gateway_object='obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_agent_gateway.o'
  local gateway_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_gateway_unittest.o'
  local gateway_browser_object='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_agent_gateway_browsertest.o'
  local browser_test_template='obj/chrome/browser/ui/views/prometheus/browser_tests/prometheus_page_adapter_browsertest.o'
  local mojom_template='obj/third_party/blink/public/mojom/mojom_platform/frame_metadata_observer_registry.mojom.o'
  local mojom_object='obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o'
  local mojom_shared_template='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/frame_metadata_observer_registry.mojom-shared.o'
  local mojom_shared_object='obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o'
  local extra_objects=()

  : >"${BUILD_LOG}"
  (
    cd "${OUT_DIR}"
    compile_exact_object "${route_object}"
    compile_exact_object "${route_test_object}"
    compile_exact_object "${agent_codec_object}"
    compile_exact_object "${agent_transport_test_object}"
    compile_exact_object "${agent_tab_data_object}"
    compile_exact_object "${agent_service_object}"
    compile_exact_object "${agent_service_test_object}"
    compile_exact_object "${agent_profile_object}"
    compile_exact_object "${agent_profile_factory_object}"
    compile_exact_object "${gateway_contract_object}"
    compile_exact_object "${gateway_object}"
    compile_exact_object "${gateway_test_object}"
    if [[ "${FOCUS_KIND}" == 'browser-integration' ]]; then
      compile_exact_object "${gateway_browser_object}"
    fi
  )

  [[ -s "${agent_codec_test_source}" ]] \
    || fail 'Agent supervision transport codec test is missing or empty'
  compile_synthesized_object "${agent_transport_test_object}" "${agent_codec_test_object}" \
    prometheus_agent_transport_unittest prometheus_agent_transport_codec_unittest

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

  if [[ -e "${supervision_hub_source}" || -e "${supervision_hub_test_source}" ]]; then
    [[ -s "${supervision_hub_source}" ]] \
      || fail 'supervision capture hub implementation is missing or empty'
    [[ -s "${supervision_hub_test_source}" ]] \
      || fail 'supervision capture hub unit test is missing or empty'
    generate_blink_mojo_bindings
    compile_synthesized_object "${runtime_profile_object}" "${supervision_hub_object}" \
      prometheus_runtime_profile_service prometheus_supervision_capture_hub
    compile_synthesized_object "${runtime_profile_test_object}" "${supervision_hub_test_object}" \
      prometheus_runtime_profile_service_unittest prometheus_supervision_capture_hub_unittest
    compile_synthesized_object "${mojom_template}" "${mojom_object}" \
      frame_metadata_observer_registry prometheus_supervision_document
    compile_synthesized_object "${mojom_shared_template}" "${mojom_shared_object}" \
      frame_metadata_observer_registry prometheus_supervision_document
    if [[ "${FOCUS_KIND}" == 'browser-integration' ]]; then
      [[ -s "${supervision_hub_browser_source}" ]] \
        || fail 'supervision capture hub browser test is missing or empty'
      compile_synthesized_object "${browser_test_template}" "${supervision_hub_browser_object}" \
        prometheus_page_adapter_browsertest prometheus_supervision_capture_hub_browsertest
      build_browser_focused_blink_modules
    fi
  fi

  require_file "${OUT_DIR}/browser_tests.rsp"
  local runtime_contract='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_tool_contract.o'
  local runtime_dialogs='obj/chrome/browser/ui/views/prometheus/runtime_dialogs/prometheus_runtime_dialogs.o'
  local candidates=(
    "${runtime_contract}"
    "${runtime_dialogs}"
    "${gateway_object}"
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
  if [[ -s "${supervision_hub_source}" ]]; then
    candidates+=("${supervision_hub_object}" "${mojom_object}" "${mojom_shared_object}")
  fi
  if [[ "${FOCUS_KIND}" == 'browser-integration' &&
        -s "${supervision_hub_browser_source}" ]]; then
    candidates+=("${supervision_hub_browser_object}")
  fi
  if [[ "${FOCUS_KIND}" == 'browser-integration' ]]; then
    candidates+=("${gateway_browser_object}")
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
  if [[ "${FOCUS_KIND}" == 'browser-integration' ]]; then
    local original_rpath='-Wl,-rpath,@loader_path/.'
    local focused_rpath="-Wl,-rpath,${FOCUSED_BLINK_MODULES_DIR} ${original_rpath}"
    [[ "${link_command}" == *"${original_rpath}"* ]] \
      || fail 'browser_tests loader rpath argument was not found'
    link_command="${link_command/${original_rpath}/${focused_rpath}}"
  fi
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
if [[ "${FOCUS_KIND}" == 'blink' ]]; then
  verify_blink_contract
  build_blink_focused_binary
else
  verify_composition_contract
  verify_gateway_contract
  verify_agent_supervision_transport_contract
  if [[ -e "${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_supervision_capture_hub.h" ]]; then
    verify_capture_hub_contract
  fi
  build_focused_binary
fi
list_selected_tests
run_selected_tests
note "focused verification complete; logs: ${LOG_DIR}"
