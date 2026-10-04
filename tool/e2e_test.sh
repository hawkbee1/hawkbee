#!/usr/bin/env bash
# Opt-in end-to-end test of dart_code_3D on Linux desktop with software
# rendering (Xvfb + Mesa llvmpipe): analyzes a public git repository through
# the UI (it needs the network and takes minutes), opens it in 3D and checks
# the home screen lists it. The capture and the timings go to
# apps/dart_code_3d/build/e2e/ (viewer.png, report.json).
# Usage: tool/e2e_test.sh
# Set DC3D_E2E_URL and DC3D_E2E_REF to analyze another repository.
set -euo pipefail
cd "$(dirname "$0")/../apps/dart_code_3d"
for cmd in xvfb-run flutter; do
  command -v "$cmd" >/dev/null || { echo "missing $cmd (see docs/dart_code_3d/README.md, Prerequisites)" >&2; exit 1; }
done
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
xvfb-run -a -s "-screen 0 1600x1200x24" flutter drive --profile \
  --driver=test_driver/e2e_driver.dart \
  --target=integration_test/e2e/analyze_test.dart \
  ${DC3D_E2E_URL:+--dart-define=DC3D_E2E_URL=$DC3D_E2E_URL} \
  ${DC3D_E2E_REF:+--dart-define=DC3D_E2E_REF=$DC3D_E2E_REF} \
  -d linux --enable-impeller --enable-flutter-gpu
cat build/e2e/report.json
