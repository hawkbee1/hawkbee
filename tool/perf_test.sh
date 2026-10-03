#!/usr/bin/env bash
# Measures dart_code_3D's map opening time and frame times in a profile build
# on Linux desktop with software rendering (Xvfb + Mesa llvmpipe): a lower
# bound. The report goes to apps/dart_code_3d/build/perf/report.json.
# Usage: tool/perf_test.sh [map.dc3d ...]   (the bundled sample is always measured)
set -euo pipefail
maps="$(IFS=,; echo "$*")"
cd "$(dirname "$0")/../apps/dart_code_3d"
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
xvfb-run -a -s "-screen 0 1600x1200x24" flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/perf/perf_test.dart \
  --dart-define=DC3D_PERF_MAPS="$maps" \
  -d linux --enable-impeller --enable-flutter-gpu
cat build/perf/report.json
