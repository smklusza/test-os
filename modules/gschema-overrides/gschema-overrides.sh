#!/usr/bin/env bash

set -euo pipefail

get_yaml_array INCLUDE '.include[]' "$1"

schema-test-location="/tmp/bluebuild-schema-test"
schema-location="/usr/share/glib-2.0/schemas"

echo "Applying gschema-overrides"

if [[ ${#INCLUDE[@]} -gt 0 ]] && [[ "${INCLUDE[@]}" == *.gschema.override ]]; then
  mkdir -p "$schema-test-location"
  find "$schema-location" -type f ! -name "*.gschema.override" -exec cp {} "$schema-test-location" \;
  for file in "${INCLUDE[@]}"; do
    cp "$schema_location/$file" "$schema_test_location"
  done
  echo "Running error test for your gschema-overrides. Aborting if failed."
  glib-compile-schemas --strict "$schema-test-location"
  echo "Compiling gschema to include your setting overrides"
  glib-compile-schemas "$schema-location" &>/dev/null
else
  echo "Module failed because no gschema-overrides were included into the module. Please ensure that those are included properly & try again."
fi  
