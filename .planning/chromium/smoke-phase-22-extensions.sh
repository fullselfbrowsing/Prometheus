#!/usr/bin/env bash
set -euo pipefail

MODE=""

usage() {
  printf 'Usage: %s --deterministic\n' "$0" >&2
}

if [[ "$#" -ne 1 || "$1" != "--deterministic" ]]; then
  usage
  exit 2
fi
MODE="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
CHROMIUM_DIR="${ROOT_DIR}/.context/chromium/src"
OUT_DIR="${CHROMIUM_DIR}/out/Default"
APP_DIR="${OUT_DIR}/Prometheus.app"
APP_BIN="${APP_DIR}/Contents/MacOS/Prometheus"
APP_PLIST="${APP_DIR}/Contents/Info.plist"
CHROMIUM_BIN="${OUT_DIR}/Chromium.app/Contents/MacOS/Chromium"
LIBCHROME="${OUT_DIR}/libchrome_dll.dylib"
LIBCHROME_TOC="${OUT_DIR}/libchrome_dll.dylib.TOC"
SISO="${CHROMIUM_DIR}/third_party/siso/cipd/siso"
FIXTURE_DIR="${CHROMIUM_DIR}/chrome/test/data/prometheus/extensions/developer_workflow"
FIXTURE_MANIFEST="${FIXTURE_DIR}/manifest.json"

TEMP_ROOT=""
BROWSER_PID=""
LIB_INSTALLED=false
SOURCE_HEAD=""
NINJA_LOG_HASH=""
NINJA_DEPS_HASH=""
ORIGINAL_LIB_HASH=""
ORIGINAL_TOC_HASH=""
SMOKE_RSP="${OUT_DIR}/phase22-extension-smoke-app.rsp"
PRODUCTION_TEMPLATE='obj/chrome/browser/prometheus/prometheus_runtime_profile_service/prometheus_runtime_profile_service.o'

fail() {
  printf 'Phase 22 packaged extension smoke failed: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "required file missing: $1"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

terminate_owned_processes() {
  local pid="$1"
  local child
  [[ -n "${pid}" ]] || return 0
  for child in $(pgrep -P "${pid}" 2>/dev/null || true); do
    terminate_owned_processes "${child}"
  done
  kill -TERM "${pid}" 2>/dev/null || true
}

kill_owned_processes() {
  local pid="$1"
  local child
  [[ -n "${pid}" ]] || return 0
  for child in $(pgrep -P "${pid}" 2>/dev/null || true); do
    kill_owned_processes "${child}"
  done
  kill -KILL "${pid}" 2>/dev/null || true
}

restore_build_artifacts() {
  if [[ "${LIB_INSTALLED}" == true && -n "${TEMP_ROOT}" ]]; then
    cp -p "${TEMP_ROOT}/original-libchrome.dylib" "${LIBCHROME}"
    cp -p "${TEMP_ROOT}/original-libchrome.dylib.TOC" "${LIBCHROME_TOC}"
    LIB_INSTALLED=false
  fi
}

cleanup() {
  local status="$?"
  set +e
  if [[ -n "${BROWSER_PID}" ]] && kill -0 "${BROWSER_PID}" 2>/dev/null; then
    terminate_owned_processes "${BROWSER_PID}"
    local deadline=$((SECONDS + 8))
    while kill -0 "${BROWSER_PID}" 2>/dev/null && (( SECONDS < deadline )); do
      sleep 0.2
    done
    if kill -0 "${BROWSER_PID}" 2>/dev/null; then
      kill_owned_processes "${BROWSER_PID}"
    fi
    wait "${BROWSER_PID}" 2>/dev/null || true
  fi
  restore_build_artifacts
  rm -f -- \
    "${SMOKE_RSP}" \
    "${OUT_DIR}/phase22_libchrome_dll.dylib" \
    "${OUT_DIR}/phase22_libchrome_dll.dylib.TOC"
  if [[ -n "${TEMP_ROOT}" && -d "${TEMP_ROOT}" ]]; then
    rm -rf -- "${TEMP_ROOT}"
  fi
  exit "${status}"
}
trap cleanup EXIT INT TERM

assert_build_unchanged() {
  [[ "$(git -C "${CHROMIUM_DIR}" rev-parse HEAD)" == "${SOURCE_HEAD}" ]] \
    || fail 'nested Chromium source HEAD changed during smoke'
  [[ "$(sha256_file "${OUT_DIR}/.ninja_log")" == "${NINJA_LOG_HASH}" ]] \
    || fail '.ninja_log changed during smoke'
  [[ "$(sha256_file "${OUT_DIR}/.ninja_deps")" == "${NINJA_DEPS_HASH}" ]] \
    || fail '.ninja_deps changed during smoke'
  [[ "$(sha256_file "${LIBCHROME}")" == "${ORIGINAL_LIB_HASH}" ]] \
    || fail 'libchrome_dll.dylib was not restored byte-for-byte'
  [[ "$(sha256_file "${LIBCHROME_TOC}")" == "${ORIGINAL_TOC_HASH}" ]] \
    || fail 'libchrome_dll.dylib.TOC was not restored byte-for-byte'
}

query_link_command() {
  LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" libchrome_dll.dylib \
    2>/dev/null | LC_ALL=C awk '
      index($0, "linker_driver.py") &&
      index($0, "@./libchrome_dll.dylib.rsp") { command = $0 }
      END { print command }
    '
}

compile_current_object() {
  local object="$1"
  local label="$2"
  local query_object="${3:-${object}}"
  local command
  command="$(LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" "${query_object}" \
    2>/dev/null | LC_ALL=C awk -v output=" -o ${query_object}" \
      'index($0, output) { command = $0 } END { print command }')"
  [[ -n "${command}" ]] || fail "${label} compile command not found"
  command="${command//${query_object}/${object}}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${TEMP_ROOT}/current-runtime-build.log" 2>&1 || {
    tail -n 100 "${TEMP_ROOT}/current-runtime-build.log" >&2 || true
    fail "current ${label} compile failed"
  }
  require_file "${OUT_DIR}/${object}"
}

compile_current_prometheus_object() {
  local object="$1"
  local target_stem="$2"
  local command
  command="$(LC_ALL=C "${SISO}" query commands -C "${OUT_DIR}" \
    "${PRODUCTION_TEMPLATE}" 2>/dev/null | \
    LC_ALL=C awk -v output=" -o ${PRODUCTION_TEMPLATE}" \
      'index($0, output) { command = $0 } END { print command }')"
  [[ -n "${command}" ]] || fail 'Prometheus compile template not found'
  command="${command//prometheus_runtime_profile_service/${target_stem}}"
  [[ "${command}" == *" -o ${object}"* ]] \
    || fail "synthesized command does not produce ${object}"
  mkdir -p "${OUT_DIR}/$(dirname "${object}")"
  (
    cd "${OUT_DIR}"
    /bin/zsh -c "${command}"
  ) >>"${TEMP_ROOT}/current-runtime-build.log" 2>&1 || {
    tail -n 100 "${TEMP_ROOT}/current-runtime-build.log" >&2 || true
    fail "current ${target_stem} compile failed"
  }
  require_file "${OUT_DIR}/${object}"
}

append_production_objects() {
  local response_file="$1"
  local object
  local archive
  while IFS= read -r object; do
    case "${object}" in
      */prometheus_unittests/*|*/browser_tests/*|*_unittest.o|*_browsertest.o)
        continue
        ;;
      obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_browser_main_extra_parts.o)
        continue
        ;;
    esac
    archive="$(dirname "$(dirname "${object}")")/lib$(basename "$(dirname "${object}")").a"
    if grep -Fq -- "${archive}" "${response_file}"; then
      continue
    fi
    if ! grep -Fq -- "${object}" "${response_file}"; then
      printf '%s ' "${object}" >>"${response_file}"
    fi
  done < <(
    find \
      "${OUT_DIR}/obj/chrome/browser/prometheus" \
      "${OUT_DIR}/obj/chrome/browser/ui/views/prometheus" \
      -type f -name '*.o' -print \
      | sed "s#^${OUT_DIR}/##" \
      | LC_ALL=C sort
  )

  for object in \
    obj/third_party/blink/public/mojom/mojom_platform/prometheus_supervision_document.mojom.o \
    obj/third_party/blink/public/mojom/mojom_platform_shared_cpp_sources/prometheus_supervision_document.mojom-shared.o; do
    require_file "${OUT_DIR}/${object}"
    if ! grep -Fq -- "${object}" "${response_file}"; then
      printf '%s ' "${object}" >>"${response_file}"
    fi
  done
  printf '\n' >>"${response_file}"
}

link_current_runtime() {
  local original_rsp="${OUT_DIR}/libchrome_dll.dylib.rsp"
  local smoke_rsp="${SMOKE_RSP}"
  local link_log="${TEMP_ROOT}/link.log"
  local link_command
  require_file "${original_rsp}"

  perl -0777 -pe \
    's#(?:^|\s)obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_browser_main_extra_parts\.o(?=\s|$)# #g' \
    "${original_rsp}" >"${smoke_rsp}"
  append_production_objects "${smoke_rsp}"

  for object in \
    obj/chrome/browser/prometheus/prometheus_browser_main_extra_parts/prometheus_browser_main_extra_parts.o \
    obj/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap/prometheus_extension_smoke_bootstrap.o \
    obj/chrome/browser/prometheus/prometheus_extension_smoke_controller/prometheus_extension_smoke_controller.o \
    obj/chrome/browser/prometheus/prometheus_extension_policy_service/prometheus_extension_policy_service.o; do
    require_file "${OUT_DIR}/${object}"
    grep -Fq -- "${object}" "${smoke_rsp}" \
      || fail "current runtime response omitted ${object}"
  done
  if grep -Fq -- \
    'obj/chrome/browser/prometheus/prometheus_agent_gateway/prometheus_browser_main_extra_parts.o' \
    "${smoke_rsp}"; then
    fail 'stale browser-main object remained in runtime response'
  fi

  link_command="$(query_link_command)"
  [[ -n "${link_command}" ]] || fail 'libchrome link command not found'
  local original_output='-o "./libchrome_dll.dylib"'
  local smoke_output='-o "./phase22_libchrome_dll.dylib"'
  local original_marker='@./libchrome_dll.dylib.rsp'
  local smoke_marker='@./phase22-extension-smoke-app.rsp'
  local original_toc='./libchrome_dll.dylib.TOC'
  local smoke_toc='./phase22_libchrome_dll.dylib.TOC'
  [[ "${link_command}" == *"${original_output}"* ]] \
    || fail 'libchrome output argument not found'
  link_command="${link_command/${original_output}/${smoke_output}}"
  link_command="${link_command/${original_marker}/${smoke_marker}}"
  link_command="${link_command//${original_toc}/${smoke_toc}}"

  (
    cd "${OUT_DIR}"
    rm -f ./phase22_libchrome_dll.dylib ./phase22_libchrome_dll.dylib.TOC
    /bin/zsh -c "${link_command}" >"${link_log}" 2>&1 &&
      codesign --force --sign - ./phase22_libchrome_dll.dylib >>"${link_log}" 2>&1 &&
      codesign --verify --strict ./phase22_libchrome_dll.dylib >>"${link_log}" 2>&1
  ) || {
    tail -n 100 "${link_log}" >&2 || true
    fail 'current runtime link failed'
  }
  require_file "${OUT_DIR}/phase22_libchrome_dll.dylib"
}

plist_value() {
  /usr/bin/plutil -extract "$1" raw -o - "${APP_PLIST}" 2>/dev/null
}

validate_result() {
  [[ ! -L "${RESULT_FILE}" ]] || fail 'result is a symlink'
  [[ -f "${RESULT_FILE}" ]] || fail 'result is not a regular file'
  [[ "$(stat -f '%Lp' "${RESULT_FILE}")" == "600" ]] \
    || fail 'result permissions are not 0600'
  local size
  size="$(stat -f '%z' "${RESULT_FILE}")"
  (( size > 0 && size <= 4096 )) || fail 'result size is outside the bound'
  if ! perl -MJSON::PP -0777 -e '
    use strict;
    use warnings;
    my $record = decode_json(<>);
    die "result must be an object\n" unless ref($record) eq "HASH";
    my @expected = sort qw(
      hidden_target_denied inspected options_routing_visible outcome
      policy_default_blocked policy_interact_applied
      policy_read_only_applied reason reload_transitions_seen schema_version
      stage
    );
    my @actual = sort keys %{$record};
    die "result schema mismatch\n" unless "@actual" eq "@expected";
    die "bad schema version\n" unless $record->{schema_version} == 1;
    die "lifecycle incomplete\n" unless $record->{stage} eq "complete";
    die "lifecycle failed\n" unless $record->{outcome} eq "succeeded";
    die "bad lifecycle reason\n" unless $record->{reason} eq "ok";
    die "reload not observed\n"
      unless $record->{reload_transitions_seen} >= 1;
    for my $key (qw(
      inspected policy_default_blocked policy_read_only_applied
      policy_interact_applied options_routing_visible hidden_target_denied
    )) {
      die "$key not proven\n" unless JSON::PP::is_bool($record->{$key}) &&
        $record->{$key};
    }
  ' "${RESULT_FILE}"; then
    sed -n '1,80p' "${RESULT_FILE}" >&2 || true
    tail -n 120 "${LAUNCH_LOG}" >&2 || true
    fail 'result failed exact JSON validation'
  fi

  if LC_ALL=C grep -Eqi \
    '(authorization|cookie|credential|password|secret|token|https?://|extension_id)' \
    "${RESULT_FILE}"; then
    fail 'result contains prohibited credential, URL, or inventory material'
  fi
}

require_file "${APP_BIN}"
require_file "${APP_PLIST}"
require_file "${LIBCHROME}"
require_file "${LIBCHROME_TOC}"
require_file "${OUT_DIR}/.ninja_log"
require_file "${OUT_DIR}/.ninja_deps"
require_file "${FIXTURE_MANIFEST}"
[[ -x "${APP_BIN}" ]] || fail "packaged Prometheus executable is not executable"
[[ "${APP_BIN}" != "${CHROMIUM_BIN}" && "${APP_BIN}" != *'/Chromium.app/'* ]] \
  || fail 'Chromium.app is forbidden for Phase 22 acceptance'
[[ "$(plist_value CFBundleName)" == "Prometheus" ]] \
  || fail 'CFBundleName is not Prometheus'
[[ "$(plist_value CFBundleExecutable)" == "Prometheus" ]] \
  || fail 'CFBundleExecutable is not Prometheus'
[[ "$(plist_value CFBundleIdentifier)" == "com.fullselfbrowsing.prometheus" ]] \
  || fail 'CFBundleIdentifier is not com.fullselfbrowsing.prometheus'
grep -Eq '^is_component_build[[:space:]]*=[[:space:]]*true([[:space:]]*#.*)?$' \
  "${OUT_DIR}/args.gn" || fail 'out/Default is not a component build'
grep -Eq '^is_debug[[:space:]]*=[[:space:]]*false([[:space:]]*#.*)?$' \
  "${OUT_DIR}/args.gn" || fail 'out/Default is not a release build'

SOURCE_HEAD="$(git -C "${CHROMIUM_DIR}" rev-parse HEAD)"
APP_SHA256="$(sha256_file "${APP_BIN}")"
FIXTURE_SHA256="$(sha256_file "${FIXTURE_MANIFEST}")"
NINJA_LOG_HASH="$(sha256_file "${OUT_DIR}/.ninja_log")"
NINJA_DEPS_HASH="$(sha256_file "${OUT_DIR}/.ninja_deps")"
ORIGINAL_LIB_HASH="$(sha256_file "${LIBCHROME}")"
ORIGINAL_TOC_HASH="$(sha256_file "${LIBCHROME_TOC}")"

TEMP_BASE="${TMPDIR:-/tmp}"
TEMP_ROOT="$(mktemp -d "${TEMP_BASE%/}/prometheus-phase22-extension-smoke.XXXXXX")"
chmod 700 "${TEMP_ROOT}"
cp -p "${LIBCHROME}" "${TEMP_ROOT}/original-libchrome.dylib"
cp -p "${LIBCHROME_TOC}" "${TEMP_ROOT}/original-libchrome.dylib.TOC"

compile_current_prometheus_object \
  'obj/chrome/browser/prometheus/prometheus_extension_smoke_bootstrap/prometheus_extension_smoke_bootstrap.o' \
  'prometheus_extension_smoke_bootstrap'
compile_current_prometheus_object \
  'obj/chrome/browser/prometheus/prometheus_extension_smoke_controller/prometheus_extension_smoke_controller.o' \
  'prometheus_extension_smoke_controller'
compile_current_prometheus_object \
  'obj/chrome/browser/prometheus/prometheus_browser_main_extra_parts/prometheus_browser_main_extra_parts.o' \
  'prometheus_browser_main_extra_parts'
compile_current_object \
  'obj/chrome/browser/core/chrome_browser_main.o' \
  'chrome_browser_main'
link_current_runtime
CURRENT_LIB_SHA256="$(sha256_file "${OUT_DIR}/phase22_libchrome_dll.dylib")"
cp -p "${OUT_DIR}/phase22_libchrome_dll.dylib" "${LIBCHROME}"
LIB_INSTALLED=true

PROFILE_DIR="${TEMP_ROOT}/profile"
CONFIG_FILE="${TEMP_ROOT}/bootstrap.json"
RESULT_FILE="${TEMP_ROOT}/result.json"
ENDPOINT_FILE="${TEMP_ROOT}/endpoint.json"
LAUNCH_LOG="${TEMP_ROOT}/browser.log"
mkdir -m 700 "${PROFILE_DIR}"
umask 077
printf '{"schema_version":1,"fixture_path":"%s","fixture_sha256":"%s","result_path":"%s"}\n' \
  "${FIXTURE_DIR}" "${FIXTURE_SHA256}" "${RESULT_FILE}" >"${CONFIG_FILE}"
chmod 600 "${CONFIG_FILE}"
[[ "$(stat -f '%Lp' "${CONFIG_FILE}")" == "600" ]] \
  || fail 'bootstrap config permissions are not 0600'
[[ ! -L "${CONFIG_FILE}" && ! -L "${FIXTURE_DIR}" && ! -L "${FIXTURE_MANIFEST}" ]] \
  || fail 'bootstrap inputs may not be symlinks'

LAUNCH_ARGS=(
  "--test-type=prometheus-runtime"
  "--prometheus-extension-smoke-bootstrap=${CONFIG_FILE}"
  "--prometheus-agent-endpoint-descriptor=${ENDPOINT_FILE}"
  "--user-data-dir=${PROFILE_DIR}"
  "--no-first-run"
  "--no-default-browser-check"
  "--disable-background-networking"
  "--disable-component-update"
  "--no-proxy-server"
  "--use-mock-keychain"
  "--disable-features=DialMediaRouteProvider,LocalNetworkAccessChecks,LocalNetworkPermissionCheck"
  "about:blank"
)
for argument in "${LAUNCH_ARGS[@]}"; do
  case "${argument}" in
    --load-extension*|--disable-extensions-except*|--extensions-on-chrome-urls*|--remote-debugging*)
      fail "forbidden extension-loading or remote-control launch argument: ${argument}"
      ;;
  esac
done

(
  cd "${OUT_DIR}"
  exec env MAC_CHROMIUM_TMPDIR="${TEMP_ROOT}" \
    "${APP_BIN}" "${LAUNCH_ARGS[@]}"
) >"${LAUNCH_LOG}" 2>&1 &
BROWSER_PID="$!"

DEADLINE=$((SECONDS + 120))
while [[ ! -s "${RESULT_FILE}" ]] && (( SECONDS < DEADLINE )); do
  if ! kill -0 "${BROWSER_PID}" 2>/dev/null; then
    tail -n 120 "${LAUNCH_LOG}" >&2 || true
    fail 'Prometheus.app exited before producing a result'
  fi
  sleep 0.25
done
if [[ ! -s "${RESULT_FILE}" ]]; then
  tail -n 120 "${LAUNCH_LOG}" >&2 || true
  fail 'timed out waiting for the native extension lifecycle result'
fi

validate_result
terminate_owned_processes "${BROWSER_PID}"
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  kill -0 "${BROWSER_PID}" 2>/dev/null || break
  sleep 0.25
done
if kill -0 "${BROWSER_PID}" 2>/dev/null; then
  kill_owned_processes "${BROWSER_PID}"
fi
wait "${BROWSER_PID}" 2>/dev/null || true
BROWSER_PID=""

restore_build_artifacts
assert_build_unchanged

printf 'Phase 22 packaged extension smoke passed\n'
printf '  mode=%s\n' "${MODE}"
printf '  bundle=Prometheus.app\n'
printf '  executable=%s\n' "${APP_BIN}"
printf '  source_head=%s\n' "${SOURCE_HEAD}"
printf '  app_sha256=%s\n' "${APP_SHA256}"
printf '  runtime_sha256=%s\n' "${CURRENT_LIB_SHA256}"
printf '  fixture_sha256=%s\n' "${FIXTURE_SHA256}"
printf '  native_lifecycle=install,inspect,reload,disable,enable,remove\n'
printf '  policy=blocked,read-only,confirmed-interact\n'
printf '  surface=options-visible,hidden-target-denied\n'
printf '  store=Unverified (optional probe not run; use Load unpacked)\n'
