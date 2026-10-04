#!/usr/bin/env bash
# Runs dart_code_3D's 3D visual tests on Linux desktop with software rendering
# (Xvfb + Mesa llvmpipe), like flutter_scene's own smoke-render CI.
# Captures go to apps/dart_code_3d/build/visual/, baselines live in
# apps/dart_code_3d/visual_baselines/.
# Usage: tool/visual_test.sh [--update]
# Set DC3D_SCENARIO=<id> to capture a single scenario.
set -euo pipefail
cd "$(dirname "$0")/../apps/dart_code_3d"
if [[ "${1:-}" == "--update" ]]; then
  export VISUAL_UPDATE=1
fi
for cmd in xvfb-run flutter; do
  command -v "$cmd" >/dev/null || { echo "missing $cmd (see docs/dart_code_3d/README.md, Prerequisites)" >&2; exit 1; }
done
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
xvfb-run -a -s "-screen 0 1600x1200x24" flutter drive \
  --driver=test_driver/visual_driver.dart \
  --target=integration_test/visual/visual_test.dart \
  ${DC3D_SCENARIO:+--dart-define=DC3D_SCENARIO=$DC3D_SCENARIO} \
  -d linux --enable-impeller --enable-flutter-gpu
