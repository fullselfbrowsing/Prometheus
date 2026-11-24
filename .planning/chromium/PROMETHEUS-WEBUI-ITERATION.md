# Prometheus WebUI Iteration

Prometheus production WebUI resources currently ship through GRIT and
`prometheus_resources.pak`. Keep the default loop package-backed so browser
tests exercise the same paths as the app:

1. Edit files under `.context/chromium/src/chrome/browser/resources/prometheus/`.
2. Run `bash .planning/chromium/verify-prometheus-webui-resources.sh`.
3. Rebuild with `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests`.
4. Run focused filters such as `./out/Default/browser_tests --gtest_filter='*PrometheusControlPanel*'`.

Do not switch Prometheus surfaces to disk-loaded resources by default. Chromium
supports disk-backed WebUI development in some surfaces, but Prometheus has
phase gates around packaged resource IDs, no remote assets, and prompt/security
leak scanning. Add a dedicated documented flag path only if a later phase wires
it through these same gates.
