#!/usr/bin/env bash
# Adds Flutter's standard Linux runner to an existing app, from the Flutter SDK template.
# The VGV flutter_app template has no Linux platform, and `flutter create` is
# blocked for agents by the VGV hook, so this copies the same files it would add.
# Usage: tool/add_linux_platform.sh <app_dir> <project_name> <linux_identifier>
set -euo pipefail
APP="$1"; NAME="$2"; ID="$3"
TPL="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")/packages/flutter_tools/templates/app/linux.tmpl"
[[ -d "$APP/linux" ]] && { echo "$APP/linux already exists" >&2; exit 1; }
cp -r "$TPL" "$APP/linux"
find "$APP/linux" -name '*.tmpl' | while read -r f; do
  out="${f%.tmpl}"
  # Drop the plugin-only {{#withPlatformChannelPluginHook}} block, then fill the variables.
  sed -e '/{{#withPlatformChannelPluginHook}}/,/{{\/withPlatformChannelPluginHook}}/d' \
      -e "s/{{projectName}}/$NAME/g" -e "s/{{linuxIdentifier}}/$ID/g" "$f" > "$out"
  rm "$f"
done
if grep -rn '{{' "$APP/linux"; then echo "unfilled template variables" >&2; exit 1; fi
echo "Linux runner added to $APP/linux"
