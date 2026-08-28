#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

old_ifs=$IFS


#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
  IFS=$old_ifs
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

function validate_same_number_of_values {
  key1=$1
  key2=$2
  size1=$3
  size2=$4
  [ $size1 == $size2 ] || echo_fail "Invalid input: $key1 and $key2 must have the same number of values"
}

function trim_string {
  result=`echo -n $1 | xargs`
  echo $result
}

#=======================================
# Main
#=======================================

# Set font
default_font="/System/Library/Fonts/Supplemental/Arial.ttf"
font="${font:-$default_font}"

# Validate parameters
echo_info "Configs:"
echo_details "* iconsbundle_name: $iconsbundle_name"
echo_details "* project_location: $project_location"
echo_details "* overlay_text: $overlay_text"
echo_details "* font: $font"
echo

validate_required_input "iconsbundle_name" $iconsbundle_name
validate_required_input "project_location" $project_location
validate_required_input "overlay_text" $overlay_text
validate_required_input "font" $font

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_xcode_project_path="${xcode_project_path}"

# if [ ! -e "${expanded_xcode_project_path}/project.pbxproj" ]; then
#   echo_fail "No valid Xcode project found at path: ${expanded_xcode_project_path}"
# fi

echo_info "Setting up app icon's overlay"

trimmed_overlay=`echo $overlay_text | cut -c1-6`

export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# Stamps the trimmed caption at the bottom of a single PNG, in place.
function overlay_png {
  base_file="$1"
  target_file="${base_file}_temp"

  width=`identify -format %w "${base_file}"`
  height=`identify -format %h "${base_file}"`
  # Bar height is derived from the icon height so it stays proportional on
  # both square (iOS) and 1.67:1 (tvOS) icons.
  overlay_height=`echo "${height}/2.85" | bc`

  magick -background '#0008' \
    -fill white \
    -font "${font}" \
    -gravity center \
    -size "${width}x${overlay_height}" \
    caption:"${trimmed_overlay}" \
    "${base_file}" +swap \
    -gravity south \
    -composite \
    "${target_file}"

  rm "${base_file}"
  mv "${target_file}" "${base_file}"
}

find "$project_location" -type d -name "$iconsbundle_name" | while read -r icon_bundle; do
  case "$iconsbundle_name" in
  *.brandassets)
    # tvOS layered icon: stamp the top-most (Front) layer of every imagestack,
    # so the caption sits above the composited parallax icon.
    front_imagesets=`find "$icon_bundle" -type d -path "*.imagestack/Front.imagestacklayer/Content.imageset"`
    [ -n "$front_imagesets" ] || echo_fail "No Front.imagestacklayer found in ${icon_bundle}. Is it a valid tvOS .brandassets?"

    echo "$front_imagesets" | while read -r imageset; do
      stamped="0"
      for base_file in "${imageset}"/*.png; do
        [ -e "${base_file}" ] || continue
        stamped="1"
        echo_info "- Processing tvOS layer icon at: ${base_file}"
        overlay_png "${base_file}"
      done
      [ "${stamped}" == "1" ] || echo_warn "No PNG in ${imageset}, skipping."
    done
    ;;
  *)
    # iOS icon set: stamp every icon PNG directly inside the bundle.
    [[ $(ls -A "${icon_bundle}"/*.png 2>/dev/null) ]] || echo_fail "Xcasset present but empty. Forgot to add app icons?"
    for base_file in "${icon_bundle}"/*.png; do
      echo_info "- Processing icon at: ${base_file}"
      overlay_png "${base_file}"
    done
    ;;
  esac
done

