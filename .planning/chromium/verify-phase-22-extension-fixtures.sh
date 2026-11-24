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
CATALOG_SOURCE="${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_extension_compatibility_catalog.cc"
WEB_UI_SOURCE="${CHROMIUM_DIR}/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc"
PHASE_DIR="${ROOT_DIR}/.planning/phases/22-chrome-extension-ecosystem-and-policy"
COMPAT_JSON="${PHASE_DIR}/22-COMPATIBILITY.json"
COMPAT_MD="${PHASE_DIR}/22-COMPATIBILITY.md"
MV2_OBSERVATION_JSON="${PHASE_DIR}/22-MV2-OBSERVATION.json"
LOG_DIR="${OUT_DIR}/phase22-extension-fixtures"
BUILD_LOG="${LOG_DIR}/build.log"
LIST_LOG="${LOG_DIR}/list.log"
TEST_LOG="${LOG_DIR}/test.log"
CATALOG_LIST_LOG="${LOG_DIR}/catalog-list.log"
CATALOG_TEST_LOG="${LOG_DIR}/catalog-test.log"
MV2_LIST_LOG="${LOG_DIR}/mv2-list.log"
MV2_TEST_LOG="${LOG_DIR}/mv2-test.log"
MV2_SUMMARY_JSON="${LOG_DIR}/mv2-observation-summary.json"
MV2_DIRECT_OUTPUT_JSON="${LOG_DIR}/mv2-observation-direct.json"
FOCUSED_RESPONSE="${LOG_DIR}/focused-browser-tests.rsp"
BINARY="${OUT_DIR}/prometheus_extension_fixture_tests"
FILTER='PrometheusExtensionFixturesBrowserTest.*:-PrometheusExtensionFixturesBrowserTest.ManifestV2PinnedPolicyObservation'
CATALOG_FILTER='PrometheusExtensionCompatibilityCatalogTest.*'
MV2_FILTER='PrometheusExtensionFixturesBrowserTest.ManifestV2PinnedPolicyObservation'
MV2_OBSERVATION_TEST_NAME='PrometheusExtensionFixturesBrowserTest.ManifestV2PinnedPolicyObservation'
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

verify_mv2_observation_fixture() {
  local manifest="${FIXTURE_DIR}/mv2_observation/manifest.json"
  local background="${FIXTURE_DIR}/mv2_observation/background.js"
  require_file "${manifest}"
  require_file "${background}"

  node -e '
    const fs = require("node:fs");
    const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (manifest.manifest_version !== 2) process.exit(1);
    if (typeof manifest.name !== "string" || !manifest.name) process.exit(1);
    if (typeof manifest.version !== "string" || !manifest.version) process.exit(1);
    if (!manifest.background ||
        !Array.isArray(manifest.background.scripts) ||
        manifest.background.scripts.length === 0) {
      process.exit(1);
    }
  ' "${manifest}" || fail 'mv2_observation manifest is not a valid observation-only MV2 manifest'

  if rg --pcre2 -n \
      'https?://(?!127\.0\.0\.1(?:[:/]|$)|localhost(?:[:/]|$))' \
      "${FIXTURE_DIR}/mv2_observation"; then
    fail 'mv2_observation fixture contains a non-local network URL'
  fi
  if rg -ni \
      'native[_ -]?messaging|externally_connectable|authorization:[[:space:]]*bearer|gateway[_ -]?bearer|vault[_ -]?value|real[_ -]?(account|secret)|verification[_ -]?bypass' \
      "${FIXTURE_DIR}/mv2_observation"; then
    fail 'mv2_observation fixture contains forbidden authority, external, or real-data text'
  fi

  note 'mv2_observation fixture is a bounded observation-only MV2 manifest'
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
      'ScopedIgnoreContentVerifier|ScopedTestMV2Enabler|AllowMV2ExtensionsForTesting|set_ignore_manifest_warnings|set_require_modern_manifest_version|disable.*(install|content).*verif|ShouldAllowMV2Extensions|ShouldEnableInstallVerification' \
      "${SOURCE}" "${BUILD_FILE}"; then
    fail 'Phase 22 fixture acceptance contains an MV2 or verification bypass'
  fi

  local test_name
  for test_name in "${EXPECTED_RED_FAILURES[@]}"; do
    rg -Fq "${test_name#*.}" "${SOURCE}" \
      || fail "missing category browser test: ${test_name}"
  done

  rg -Fq "${MV2_OBSERVATION_TEST_NAME#*.}" "${SOURCE}" \
    || fail 'missing MV2 pinned-policy observation test'
  rg -q 'extensions::UnpackedInstaller::Create' "${SOURCE}" \
    || fail 'MV2 observation test does not use the ordinary UnpackedInstaller path'
  rg -q 'RecordProperty\("mv2_observation_result"' "${SOURCE}" \
    || fail 'MV2 observation test does not record a closed accepted/rejected property'
  for required_flow in \
      'ExtensionActionTestHelper::Create' \
      'OpenGlobalExtensionSidePanel' \
      'SetGrantThroughControlPanel' \
      'ExecuteRoute'; do
    rg -Fq "${required_flow}" "${SOURCE}" \
      || fail "fixture browser tests do not exercise production flow: ${required_flow}"
  done
  if rg -q 'FixtureMatrixImplementedForTesting|EvaluateAdmissionForTesting' \
      "${SOURCE}"; then
    fail 'fixture acceptance still relies on marker or synthetic admission assertions'
  fi
  note 'fixture source and no-bypass contract passed'
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
  # Compile-command templates must be objects Siso's currently loaded graph
  # actually knows (i.e. wired into a `subninja` reachable from
  # toolchain.ninja). prometheus_extension_policy_service.o is itself only a
  # prior synthesized object -- never registered with Siso -- so it cannot be
  # queried as a template. prometheus_runtime_profile_service(_unittest).o
  # predate Phase 22 and are genuinely wired; every Phase 22 synthesized
  # object (including this one) ultimately derives from them.
  local policy_service_object='obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o'
  local catalog_object='obj/chrome/browser/prometheus/prometheus_extension_compatibility_catalog/prometheus_extension_compatibility_catalog.o'
  local runtime_service_template='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'
  local runtime_unittest_template='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_agent_route_unittest.o'
  local catalog_test_object='obj/chrome/browser/prometheus/prometheus_unittests/prometheus_extension_compatibility_catalog_unittest.o'
  local chrome_browser_main='obj/chrome/browser/core/chrome_browser_main.o'
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
    obj/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap/prometheus_extension_smoke_bootstrap.o
    obj/chrome/browser/prometheus/prometheus_extension_smoke_controller/prometheus_extension_smoke_controller.o
    obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o
    obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_types/prometheus_extension_policy_types.o
    obj/chrome/browser/prometheus/prometheus_extension_policy_prefs/prometheus_extension_policy_prefs.o
    "${policy_service_object}"
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service_factory.o
    "${catalog_object}"
    "${catalog_test_object}"
    obj/chrome/browser/prometheus/prometheus_extension_surface_resolver/prometheus_extension_surface_resolver.o
    obj/chrome/browser/prometheus/prometheus_extension_page_adapter/prometheus_extension_page_adapter.o
  )

  : >"${BUILD_LOG}"
  compile_synthesized_object \
    "${template_object}" "${fixture_object}" \
    prometheus_page_adapter_browsertest \
    prometheus_extension_fixtures_browsertest
  require_file "${OUT_DIR}/${fixture_object}"
  compile_synthesized_object \
    "${runtime_service_template}" "${catalog_object}" \
    prometheus_runtime_profile_service \
    prometheus_extension_compatibility_catalog
  require_file "${OUT_DIR}/${catalog_object}"
  compile_synthesized_object \
    "${runtime_unittest_template}" "${catalog_test_object}" \
    prometheus_agent_route_unittest \
    prometheus_extension_compatibility_catalog_unittest
  require_file "${OUT_DIR}/${catalog_test_object}"
  compile_exact_object "${chrome_browser_main}"

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

list_and_run_catalog_tests() {
  "${BINARY}" --gtest_list_tests --gtest_filter="${CATALOG_FILTER}" \
    >"${CATALOG_LIST_LOG}" 2>&1 || fail 'catalog unit test discovery failed'
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${CATALOG_LIST_LOG}")"
  [[ "${count}" -gt 0 ]] || fail "${CATALOG_FILTER} selected zero tests"
  if rg -q 'DISABLED_' "${CATALOG_LIST_LOG}"; then
    fail 'catalog unit test list contains a disabled test'
  fi

  "${BINARY}" --gtest_filter="${CATALOG_FILTER}" \
      --test-launcher-jobs=1 --test-launcher-retry-limit=0 \
      --test-launcher-timeout=90000 \
      >"${CATALOG_TEST_LOG}" 2>&1 || {
    tail -n 120 "${CATALOG_TEST_LOG}" >&2 || true
    fail 'catalog unit test suite failed'
  }
  rg -q '^\[  PASSED  \] [1-9][0-9]* test' "${CATALOG_TEST_LOG}" \
    || fail 'catalog unit test suite produced no passing summary'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' \
      "${CATALOG_TEST_LOG}"; then
    fail 'catalog unit test suite reported a failure or skip'
  fi
  note "closed compatibility-catalog unit suite passed ${count} test(s)"
}

run_mv2_observation_test() {
  rm -f "${MV2_SUMMARY_JSON}" "${MV2_DIRECT_OUTPUT_JSON}"
  "${BINARY}" --gtest_list_tests --gtest_filter="${MV2_FILTER}" \
    >"${MV2_LIST_LOG}" 2>&1 || fail 'MV2 observation test discovery failed'
  local count
  count="$(awk '/^  [^ ]/ && $0 !~ /DISABLED_/ { count += 1 }
                END { print count + 0 }' "${MV2_LIST_LOG}")"
  [[ "${count}" -eq 1 ]] \
    || fail "${MV2_FILTER} must select exactly one observation test, selected ${count}"
  if rg -q 'DISABLED_' "${MV2_LIST_LOG}"; then
    fail 'MV2 observation test is disabled'
  fi

  "${BINARY}" --gtest_filter="${MV2_FILTER}" \
      --test-launcher-jobs=1 --test-launcher-retry-limit=0 \
      --test-launcher-timeout=90000 \
      --test-launcher-summary-output="${MV2_SUMMARY_JSON}" \
      "--prometheus-mv2-observation-output=${MV2_DIRECT_OUTPUT_JSON}" \
      >"${MV2_TEST_LOG}" 2>&1 || {
    tail -n 120 "${MV2_TEST_LOG}" >&2 || true
    fail 'MV2 pinned-policy observation test did not exit 0'
  }
  rg -q '^\[  PASSED  \] 1 test' "${MV2_TEST_LOG}" \
    || fail 'MV2 observation test did not report exactly one pass'
  if rg -q '^\[  FAILED  \]|^\[  SKIPPED \] [1-9][0-9]* test' "${MV2_TEST_LOG}"; then
    fail 'MV2 observation test reported a failure or skip'
  fi
  require_file "${MV2_SUMMARY_JSON}"
  require_file "${MV2_DIRECT_OUTPUT_JSON}"
  note 'MV2 pinned-policy observation test executed with fresh summary output'
}

verify_catalog_matches_fixtures_on_disk() {
  require_file "${CATALOG_SOURCE}"
  local name hash
  for name in "${FIXTURE_NAMES[@]}"; do
    hash="$(sha256_file "${FIXTURE_DIR}/${name}/manifest.json")"
    rg -qF "${hash}" "${CATALOG_SOURCE}" \
      || fail "compiled catalog is stale: ${name} manifest.json sha256 ${hash} is not baked into ${CATALOG_SOURCE}"
    rg -qF "\"${name}\"" "${CATALOG_SOURCE}" \
      || fail "compiled catalog is missing the ${name} category key"
  done
  if rg -q \
      'kPrometheusBuild|kChromiumRevision|kLastVerified|\.prometheus_build|\.chromium_revision|\.last_verified' \
      "${CATALOG_SOURCE}"; then
    fail 'compiled catalog contains mutable build, revision, or timestamp metadata'
  fi
  rg -Fq 'See generated 22-COMPATIBILITY.json' "${CATALOG_SOURCE}" \
    || fail 'compiled catalog does not direct exact-run claims to generated evidence'
  note 'compiled catalog SHA-256 constants match the current on-disk fixtures'
}

generate_compatibility_evidence() {
  local revision build_version generated_at
  require_file "${TEST_LOG}"
  revision="$(git -C "${CHROMIUM_DIR}" rev-parse HEAD)"
  build_version="$(awk -F= '
      /^MAJOR=/ { major = $2 }
      /^MINOR=/ { minor = $2 }
      /^BUILD=/ { build = $2 }
      /^PATCH=/ { patch = $2 }
      END { printf "%s.%s.%s.%s", major, minor, build, patch }
    ' "${CHROMIUM_DIR}/chrome/VERSION")"
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  node -e '
    const fs = require("node:fs");
    const crypto = require("node:crypto");
    const path = require("node:path");
    const [fixtureDir, testLogPath, revision, buildVersion, generatedAt,
      outJson, outMd] =
        process.argv.slice(1);
    const testLog = fs.readFileSync(testLogPath, "utf8");
    const passedTests = new Set(
        [...testLog.matchAll(/^\[       OK \] ([^ ]+) \([0-9]+ ms\)$/gm)]
            .map(match => match[1]));

    const categories = [
      {
        key: "password_manager_like",
        label: "Password manager",
        actions: "Native action popup; local control-panel Blocked/Read " +
            "only/Interact grants with identity confirmation; Agent bounded " +
            "read; execute_js denial.",
        limitation: "Synthetic values only; no vault, session, or gateway " +
            "access.",
        regularMode: true,
        privateMode: false,
        evidence: "PrometheusExtensionFixturesBrowserTest." +
            "PasswordManagerLikeLifecycleAndIsolation",
      },
      {
        key: "ad_blocker",
        label: "Ad blocker",
        actions: "Unpacked load; static declarativeNetRequest rule blocks " +
            "the local target request; effective Agent grant confirmed " +
            "Blocked in both regular and Private mode.",
        limitation: "Blocks only the local test target; grants no Agent " +
            "access.",
        regularMode: true,
        privateMode: true,
        evidence: "PrometheusExtensionFixturesBrowserTest." +
            "AdBlockerLifecycleAndPermissionIsolation",
      },
      {
        key: "productivity_content_script",
        label: "Productivity content script",
        actions: "Unpacked load; content script mutates a local HTTP(S) " +
            "page; the page remains ordinary normal-page-adapter routed, " +
            "not extension-routed.",
        limitation: "Injected DOM stays untrusted; cannot claim extension " +
            "authority.",
        regularMode: true,
        privateMode: false,
        evidence: "PrometheusExtensionFixturesBrowserTest." +
            "ProductivityContentScriptRoutingAndIsolation",
      },
      {
        key: "side_panel_tooling",
        label: "Side panel and tooling",
        actions: "Native side panel; local control-panel Read only/Interact " +
            "grants with identity confirmation; Agent bounded read and typed " +
            "action; closed panel denied.",
        limitation: "Only the active, visible panel is Agent-routable.",
        regularMode: true,
        privateMode: false,
        evidence: "PrometheusExtensionFixturesBrowserTest." +
            "SidePanelToolingVisibilityAndIsolation",
      },
      {
        key: "developer_workflow",
        label: "Developer extension",
        actions: "Unpacked load; reload; disable; enable; uninstall; visible " +
            "options read through Agent routing; inactive tab denied.",
        limitation: "Background/service worker stays outside the Agent " +
            "route surface.",
        regularMode: true,
        privateMode: false,
        evidence: "PrometheusExtensionFixturesBrowserTest." +
            "DeveloperWorkflowLifecycleAndWorkerIsolation",
      },
    ];

    const rows = categories.map((category) => {
      if (!passedTests.has(category.evidence)) {
        throw new Error(
            `no fresh passing browser-test result for ${category.evidence}`);
      }
      const manifestPath = path.join(fixtureDir, category.key, "manifest.json");
      const manifestText = fs.readFileSync(manifestPath, "utf8");
      const manifest = JSON.parse(manifestText);
      if (manifest.manifest_version !== 3) {
        throw new Error(`${category.key} manifest is not manifest_version 3`);
      }
      const sha256 = crypto.createHash("sha256")
          .update(manifestText, "utf8").digest("hex");
      return {
        category: category.key,
        category_label: category.label,
        fixture_name: category.key,
        fixture_version: manifest.version,
        fixture_sha256: sha256,
        manifest_version: manifest.manifest_version,
        install_source: "Developer mode (unpacked)",
        prometheus_build: buildVersion,
        chromium_revision: revision,
        regular_mode_exercised: category.regularMode,
        private_mode_exercised: category.privateMode,
        actions_exercised: category.actions,
        result: "Verified",
        limitation: category.limitation,
        evidence_artifact:
            "chrome/browser/prometheus/prometheus_extension_fixtures_" +
            `browsertest.cc:${category.evidence}`,
        observed_test_status: "passed",
        last_verified: generatedAt,
      };
    });

    const record = {
      schema_version: 1,
      generated_at: generatedAt,
      chromium_revision: revision,
      prometheus_build: buildVersion,
      rows,
    };
    fs.writeFileSync(outJson, JSON.stringify(record, null, 2) + "\n");

    const lines = [];
    lines.push("# Phase 22 Extension Compatibility Evidence");
    lines.push("");
    lines.push(`Generated: ${generatedAt}`);
    lines.push(`Chromium revision: ${revision}`);
    lines.push(`Prometheus build: ${buildVersion}`);
    lines.push("");
    lines.push("| Category | Result | Fixture | Version | Manifest | " +
        "Install source | Regular | Private | Limitation |");
    lines.push("|---|---|---|---|---|---|---|---|---|");
    for (const row of rows) {
      lines.push(`| ${row.category_label} | ${row.result} | ` +
          `${row.fixture_name} | ${row.fixture_version} | ` +
          `Manifest V${row.manifest_version} | ${row.install_source} | ` +
          `${row.regular_mode_exercised} | ${row.private_mode_exercised} | ` +
          `${row.limitation} |`);
    }
    lines.push("");
    lines.push("Five representative Prometheus-owned unpacked MV3 " +
        "fixtures. This is not a Chrome Web Store or general " +
        "third-party extension compatibility claim.");
    fs.writeFileSync(outMd, lines.join("\n") + "\n");
  ' "${FIXTURE_DIR}" "${TEST_LOG}" "${revision}" "${build_version}" \
    "${generated_at}" "${COMPAT_JSON}" "${COMPAT_MD}"

  require_file "${COMPAT_JSON}"
  require_file "${COMPAT_MD}"
  note "22-COMPATIBILITY.json/.md generated at revision ${revision}"
}

verify_compatibility_json_schema() {
  node -e '
    const fs = require("node:fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const required = [
      "password_manager_like", "ad_blocker", "productivity_content_script",
      "side_panel_tooling", "developer_workflow",
    ];
    if (!Array.isArray(data.rows) || data.rows.length !== 5) {
      throw new Error("compatibility catalog must have exactly five rows");
    }
    if (typeof data.chromium_revision !== "string" || !data.chromium_revision) {
      throw new Error("missing chromium_revision");
    }
    if (typeof data.prometheus_build !== "string" || !data.prometheus_build) {
      throw new Error("missing prometheus_build");
    }
    const seen = new Set();
    const hexPattern = /^[0-9a-f]{64}$/;
    for (const row of data.rows) {
      if (!required.includes(row.category)) {
        throw new Error(`unexpected category key: ${row.category}`);
      }
      if (seen.has(row.category)) {
        throw new Error(`duplicate category key: ${row.category}`);
      }
      seen.add(row.category);
      if (row.manifest_version !== 3) {
        throw new Error(`row ${row.category} is not manifest_version 3`);
      }
      if (!hexPattern.test(row.fixture_sha256)) {
        throw new Error(`row ${row.category} has an invalid fixture_sha256`);
      }
      if (!["Verified", "Degraded", "Unsupported"].includes(row.result)) {
        throw new Error(
            `row ${row.category} has a non-closed result: ${row.result}`);
      }
      if (!row.evidence_artifact || !row.limitation) {
        throw new Error(`row ${row.category} is missing bounded evidence text`);
      }
      if (row.observed_test_status !== "passed") {
        throw new Error(`row ${row.category} lacks a fresh observed pass`);
      }
    }
    if (seen.size !== required.length) {
      throw new Error("compatibility catalog is missing a required category");
    }
  ' "${COMPAT_JSON}" || fail '22-COMPATIBILITY.json failed schema validation'
  note '22-COMPATIBILITY.json schema validated: five unique MV3 rows, closed results, current build/revision'
}

verify_markdown_matches_json() {
  node -e '
    const fs = require("node:fs");
    const [jsonPath, mdPath] = process.argv.slice(1);
    const data = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
    const md = fs.readFileSync(mdPath, "utf8");
    for (const row of data.rows) {
      for (const value of [
        row.category_label, row.result, row.fixture_name, row.fixture_version,
      ]) {
        if (!md.includes(String(value))) {
          throw new Error(`Markdown is missing value: ${value}`);
        }
      }
    }
    if (!md.includes(data.chromium_revision)) {
      throw new Error("Markdown is missing the chromium_revision");
    }
    if (!md.includes(data.prometheus_build)) {
      throw new Error("Markdown is missing the prometheus_build");
    }
  ' "${COMPAT_JSON}" "${COMPAT_MD}" \
    || fail 'Markdown evidence mirror does not match 22-COMPATIBILITY.json'
  note 'Markdown evidence mirror matches JSON values'
}

generate_mv2_observation_json() {
  require_file "${MV2_SUMMARY_JSON}"
  require_file "${MV2_DIRECT_OUTPUT_JSON}"
  local revision generated_at
  revision="$(git -C "${CHROMIUM_DIR}" rev-parse HEAD)"
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # The primary source is the exact file the browser test itself wrote via
  # --prometheus-mv2-observation-output (base::WriteFile inside the test
  # body). The --test-launcher-summary-output JSON is also required to exist
  # above (proves the launcher produced fresh per-test evidence for this
  # exact run) but this synthesized-binary harness does not reliably surface
  # RecordProperty() through that file's "properties", so it is not the
  # parse source here.
  node -e '
    const fs = require("node:fs");
    const [directPath, outputPath, revision, generatedAt, testName] =
        process.argv.slice(1);
    const direct = JSON.parse(fs.readFileSync(directPath, "utf8"));
    const result = direct.mv2_observation_result;
    const reason = direct.mv2_observation_reason;
    const manifestVersion = direct.mv2_observation_manifest_version;
    if (result !== "accepted" && result !== "rejected") {
      throw new Error(`unexpected mv2_observation_result: ${result}`);
    }
    if (typeof reason !== "string" || !reason || reason.length > 64) {
      throw new Error("mv2_observation_reason missing or unbounded");
    }
    if (manifestVersion !== "2") {
      throw new Error(
          `unexpected mv2_observation_manifest_version: ${manifestVersion}`);
    }
    const record = {
      schema_version: 1,
      generated_at: generatedAt,
      chromium_revision: revision,
      manifest_version: 2,
      fixture: "mv2_observation",
      result,
      reason,
      evidence_artifact:
          "chrome/browser/prometheus/prometheus_extension_fixtures_" +
          `browsertest.cc:${testName}`,
    };
    fs.writeFileSync(outputPath, JSON.stringify(record, null, 2) + "\n");
  ' "${MV2_DIRECT_OUTPUT_JSON}" "${MV2_OBSERVATION_JSON}" "${revision}" \
    "${generated_at}" "${MV2_OBSERVATION_TEST_NAME}"

  require_file "${MV2_OBSERVATION_JSON}"
  node -e '
    const fs = require("node:fs");
    const record = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (record.manifest_version !== 2) {
      throw new Error("22-MV2-OBSERVATION.json manifest_version must be 2");
    }
    if (record.result !== "accepted" && record.result !== "rejected") {
      throw new Error("22-MV2-OBSERVATION.json result must be closed");
    }
  ' "${MV2_OBSERVATION_JSON}" \
    || fail '22-MV2-OBSERVATION.json failed schema validation'
  note '22-MV2-OBSERVATION.json generated from the fresh gtest property summary'
}

verify_ui_projection_contract() {
  require_file "${WEB_UI_SOURCE}"
  rg -q 'GetExtensionCompatibilityCatalog' "${WEB_UI_SOURCE}" \
    || fail 'Control Panel WebUI does not project the compatibility catalog'
  rg -q 'ExtensionCompatibilityRowToValue' "${WEB_UI_SOURCE}" \
    || fail 'Control Panel WebUI does not use the catalog row projector'
  if rg -Fq 'No verified fixture' "${WEB_UI_SOURCE}"; then
    fail 'Control Panel WebUI still contains the retired compatibility placeholder'
  fi
  note 'Control Panel WebUI projects the real compatibility catalog'
}

verify_claim_language_gates() {
  local acceptance_sources=(
    "${CATALOG_SOURCE}"
    "${CHROMIUM_DIR}/chrome/browser/prometheus/prometheus_extension_compatibility_catalog.h"
    "${SOURCE}"
    "${WEB_UI_SOURCE}"
    "${COMPAT_JSON}"
    "${COMPAT_MD}"
    "${MV2_OBSERVATION_JSON}"
  )
  local file
  for file in "${acceptance_sources[@]}"; do
    require_file "${file}"
    if rg -qi 'chrome web store (is )?(supported|verified)\b' "${file}"; then
      fail "claim-language gate: ${file} implies unverified Web Store support"
    fi
    if rg -qi 'manifest v2 (is )?(supported|verified)\b' "${file}"; then
      fail "claim-language gate: ${file} implies blanket Manifest V2 support"
    fi
    if rg -qi \
        'chrome-compatible|universally compatible|works with (all|any) extension' \
        "${file}"; then
      fail "claim-language gate: ${file} makes a universal compatibility claim"
    fi
  done

  if rg -qi \
      'ScopedTestMV2Enabler|AllowMV2ExtensionsForTesting|set_require_modern_manifest_version|ScopedIgnoreContentVerifier|ShouldAllowMV2Extensions|ShouldEnableInstallVerification' \
      "${SOURCE}" "${CATALOG_SOURCE}" "${BUILD_FILE}"; then
    fail 'MV2 enabler or install-verification bypass found in Phase 22 acceptance sources'
  fi

  note 'claim-language and no-bypass static gates passed'
}

mkdir -p "${LOG_DIR}"
[[ -x "${SISO}" ]] || fail "Siso not found at ${SISO}"
require_file "${OUT_DIR}/build.ninja"
verify_fixture_inventory
verify_mv2_observation_fixture
verify_source_contract
capture_metadata
trap verify_metadata_on_exit EXIT
build_focused_binary
list_selected_tests
run_selected_tests

if [[ "${EXPECT_FAILURE}" == false ]]; then
  list_and_run_catalog_tests
  run_mv2_observation_test
fi

if [[ "${FOCUSED}" == false && "${EXPECT_FAILURE}" == false ]]; then
  verify_catalog_matches_fixtures_on_disk
  generate_compatibility_evidence
  verify_compatibility_json_schema
  verify_markdown_matches_json
  generate_mv2_observation_json
  verify_ui_projection_contract
  verify_claim_language_gates
fi

note "verification complete; logs: ${LOG_DIR}"
