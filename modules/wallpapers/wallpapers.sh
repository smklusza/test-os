#!/usr/bin/env bash

set -euo pipefail

MODULE_DIRECTORY="${MODULE_DIRECTORY:-"/tmp/modules"}"
wallpapers_module_dir="$MODULE_DIRECTORY"/wallpapers

get_yaml_array() {
  local variable_name=$1
  local yaml_path=$2
  local yaml_file=$3
  readarray -t "$variable_name" < <(yq eval "$yaml_path" "$yaml_file" | tr ' ' '_')
}

convert_whitespace_to_underscore() {
  local array_name=$1
  readarray -t "$array_name" < <(printf '%s\n' "${!array_name[@]}" | tr ' ' '_')
}

separate_light_dark_wallpapers() {
  local light_dark_array_name=$1
  local light_array_name=$2
  local dark_array_name=$3
  readarray -t "$light_array_name" < <(printf '%s\n' "${!light_dark_array_name[@]}" | awk '/-bb-light/')
  readarray -t "$dark_array_name" < <(printf '%s\n' "${!light_dark_array_name[@]}" | awk '/-bb-dark/')
}

copy_wallpapers() {
  local wallpaper_include_location=$1
  local wallpaper_location=$2
  if [ -d "$wallpaper_include_location" ]; then
    if [[ $(find "$wallpaper_include_location") ]]; then
      echo "Copying wallpapers into system backgrounds directory"
      find "$wallpaper_include_location" -depth -name "* *" -execdir bash -c 'mv "$0" "${0// /_}"' {} \;
      cp -r "$wallpaper_include_location"/* "$wallpaper_location"
    else
      echo "Module failed because wallpapers aren't included in config/wallpapers directory"
      exit 1
    fi
  fi
}

check_gnome_de() {
  local gnome_detection=$(find /usr/bin -type f -name "gnome-session" -printf "%f\n")
  if [[ ! $gnome_detection == gnome-session ]]; then
    echo "Wallpapers module installed successfully!"
    exit 0
  fi
}

write_xmls() {
  local wallpaper_array_name=$1
  local wallpaper_gnome_xml=$2
  local wallpaper_location=$3
  for wallpaper in "${!wallpaper_array_name[@]}"; do
    cp "$wallpapers_module_dir"/bluebuild.xml "$wallpaper_gnome_xml"
    yq -i '.wallpapers.wallpaper.name = "BlueBuild-'"$wallpaper"'"' "$wallpaper_gnome_xml"/bluebuild.xml
    yq -i '.wallpapers.wallpaper.filename = $wallpaper_location/$wallpaper' "$wallpaper_gnome_xml"/bluebuild.xml
    yq eval 'del(.wallpapers.wallpaper.filename-dark)' "$wallpaper_gnome_xml"/bluebuild.xml -i
    if [[ "$SCALING_NONE_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = none' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_SCALED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = scaled' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_STRETCHED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = stretched' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_ZOOM_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = zoom' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_CENTERED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = centered' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_SPANNED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = spanned' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_WALLPAPER_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = wallpaper' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    mv "$wallpaper_gnome_xml"/bluebuild.xml "$wallpaper_gnome_xml"/bluebuild-"$wallpaper".xml
  done
}

write_default_wallpaper() {
  local default_wallpaper_array_name=$1
  local wallpaper_gnome_xml=$2
  local wallpaper_location=$3
  for default_wallpaper in "${!default_wallpaper_array_name[@]}"; do
    cp "$wallpapers_module_dir"/bluebuild.xml "$wallpaper_gnome_xml"
    yq -i '.wallpapers.wallpaper.name = "BlueBuild-'"$default_wallpaper"'"' "$wallpaper_gnome_xml"/bluebuild.xml
    yq -i '.wallpapers.wallpaper.filename = $wallpaper_location/$default_wallpaper' "$wallpaper_gnome_xml"/bluebuild.xml
    yq eval 'del(.wallpapers.wallpaper.filename-dark)' "$wallpaper_gnome_xml"/bluebuild.xml -i
    if [[ "$SCALING_NONE_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = none' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_SCALED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = scaled' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_STRETCHED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = stretched' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_ZOOM_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = zoom' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_CENTERED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = centered' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_SPANNED_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = spanned' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    if [[ "$SCALING_WALLPAPER_ALL" = "all" ]]; then
      yq -i '.wallpapers.wallpaper.options = wallpaper' "$wallpaper_gnome_xml"/bluebuild.xml
    fi
    mv "$wallpaper_gnome_xml"/bluebuild.xml "$wallpaper_gnome_xml"/bluebuild-"$default_wallpaper".xml
  done
}

write_per_wallpaper_scaling_settings() {
  local scaling_array_name=$1
  local wallpaper_gnome_xml=$2
  for scaling in "${!scaling_array_name[@]}"; do
    yq -i '.wallpapers.wallpaper.options = '"$scaling"'' "$wallpaper_gnome_xml"/bluebuild-"$scaling".xml
  done
}

set_default_wallpaper_in_gschema_override() {
  local default_wallpaper_array_name=$1
  local wallpapers_module_dir=$2
  local wallpaper_location=$3
  if [[ ${#default_wallpaper_array_name[@]} == 1 ]]; then
    printf "%s" "Setting ${default_wallpaper_array_name[@]} as the default wallpaper in gschema override"
    printf  "picture-uri='file://$wallpaper_location/${default_wallpaper_array_name[@]}'" >> "$wallpapers_module_dir"/zz2-bluebuild-wallpapers.gschema.override
  elif [[ ${#default_wallpaper_array_name[@]} -gt 1 ]]; then
    echo "Module failed because you included more than 1 wallpaper to be set as default, which is not allowed"
    exit 1
  fi
}

set_default_light_dark_wallpaper_in_gschema_override() {
  local default_wallpaper_light_dark_array_name=$1
  local wallpapers_module_dir=$2
  local wallpaper_location=$3
  if [[ ${#default_wallpaper_light_dark_array_name[@]} == 1 ]]; then
    printf "%s" "Setting ${default_wallpaper_light_dark_array_name[@]} as the default light/dark wallpaper in gschema override"
    printf  "picture-uri='file://$wallpaper_location/${default_wallpaper_light_dark_array_name[@]}'" >> "$wallpapers_module_dir"/zz2-bluebuild-wallpapers.gschema.override
    printf  "picture-uri-dark='file://$wallpaper_location/${default_wallpaper_light_dark_array_name[@]}'" >> "$wallpapers_module_dir"/zz2-bluebuild-wallpapers.gschema.override 
  elif [[ ${#default_wallpaper_light_dark_array_name[@]} -gt 1 ]]; then
    echo "Module failed because you included more than 1 light & dark wallpaper to be set as default for light/dark theme, which is not allowed"
    exit 1
  fi
}

overwrite_scaling_value_in_gschema_override() {
  local scaling_all_variable_name=$1
  local scaling_variable_name=$2
  local wallpapers_module_dir=$3
  if [[ "${!scaling_all_variable_name}" = "all" ]]; then
    sed -i "s/picture-options=.*/picture-options='${!scaling_variable_name}'/" "$wallpapers_module_dir/zz2-bluebuild-wallpapers.gschema.override"
  fi
}

overwrite_scaling_value_per_wallpaper_in_gschema_override() {
  local default_wallpaper_array_name=$1
  local scaling_array_name=$2
  local wallpapers_module_dir=$3
  for value in "${!default_wallpaper_array_name[@]}"; do
    for match in "${!scaling_array_name[@]}"; do
      if [[ "$value" == "$match" ]]; then
        sed -i "s/picture-options=.*/picture-options='${!scaling_array_name}'/" "$wallpapers_module_dir/zz2-bluebuild-wallpapers.gschema.override"
      fi
    done
  done
}

install_wallpapers_module() {
  local wallpaper_include_location=$1
  local wallpaper_location=$2
  local wallpaper_gnome_xml=$3
  local wallpapers_module_dir=$4
  copy_wallpapers "$wallpaper_include_location" "$wallpaper_location"
  check_gnome_de
  separate_light_dark_wallpapers DEFAULT_WALLPAPER_LIGHT_DARK DEFAULT_WALLPAPER_LIGHT DEFAULT_WALLPAPER_DARK
  write_xmls WALLPAPER "$wallpaper_gnome_xml" "$wallpaper_location"
  write_xmls WALLPAPER_LIGHT "$wallpaper_gnome_xml" "$wallpaper_location"
  write_xmls WALLPAPER_DARK "$wallpaper_gnome_xml" "$wallpaper_location"
  write_default_wallpaper DEFAULT_WALLPAPER "$wallpaper_gnome_xml" "$wallpaper_location"
  write_default_wallpaper DEFAULT_WALLPAPER_LIGHT_DARK "$wallpaper_gnome_xml" "$wallpaper_location"
  write_per_wallpaper_scaling_settings SCALING_NONE "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_SCALED "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_STRETCHED "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_ZOOM "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_CENTERED "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_SPANNED "$wallpaper_gnome_xml"
  write_per_wallpaper_scaling_settings SCALING_WALLPAPER "$wallpaper_gnome_xml"
  set_default_wallpaper_in_gschema_override DEFAULT_WALLPAPER "$wallpapers_module_dir" "$wallpaper_location"
  set_default_light_dark_wallpaper_in_gschema_override DEFAULT_WALLPAPER_LIGHT_DARK "$wallpapers_module_dir" "$wallpaper_location"
  overwrite_scaling_value_in_gschema_override SCALING_NONE_ALL SCALING_NONE "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_SCALED_ALL SCALING_SCALED "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_STRETCHED_ALL SCALING_STRETCHED "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_ZOOM_ALL SCALING_ZOOM "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_CENTERED_ALL SCALING_CENTERED "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_SPANNED_ALL SCALING_SPANNED "$wallpapers_module_dir"
  overwrite_scaling_value_in_gschema_override SCALING_WALLPAPER_ALL SCALING_WALLPAPER "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_NONE "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_SCALED "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_STRETCHED "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_ZOOM "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_CENTERED "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_SPANNED "$wallpapers_module_dir"
  overwrite_scaling_value_per_wallpaper_in_gschema_override DEFAULT_WALLPAPER SCALING_WALLPAPER "$wallpapers_module_dir"
  echo "Copying gschema override to system & building it to include wallpaper defaults"
  cp "$wallpapers_module_dir"/zz2-bluebuild-wallpapers.gschema.override /usr/share/glib-2.0/schemas
  glib-compile-schemas --strict /usr/share/glib-2.0/schemas
  echo "Wallpapers module installed successfully!"
}

MODULE_DIRECTORY="${MODULE_DIRECTORY:-"/tmp/modules"}"
wallpapers_module_dir="$MODULE_DIRECTORY"/wallpapers
wallpaper_include_location="/tmp/config/wallpapers"
wallpaper_location="/usr/share/backgrounds/bluebuild"
wallpaper_gnome_xml="/usr/share/gnome-background-properties"

echo "Installing wallpapers module"
install_wallpapers_module "$wallpaper_include_location" "$wallpaper_location" "$wallpaper_gnome_xml" "$wallpapers_module_dir"
