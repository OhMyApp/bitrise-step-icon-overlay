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
#
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

# Set font
if [[ "$(uname)" == "Darwin" ]]; then
  default_font="/System/Library/Fonts/Supplemental/Arial.ttf"
elif [[ "$(uname)" == "Linux" ]]; then
  default_font="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
fi

font="${font:-$default_font}"
echo_info "Will use font: $font"

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_xcode_project_path="${xcode_project_path}"

# if [ ! -e "${expanded_xcode_project_path}/project.pbxproj" ]; then
#   echo_fail "No valid Xcode project found at path: ${expanded_xcode_project_path}"
# fi

echo_info "Setting up app icon's overlay"

trimmed_overlay=`echo $overlay_text | cut -c1-6`

find "$project_location" -type d -name "$iconsbundle_name" | while read -r image_files; do

  cd "${image_files}"
  [[ $(ls -A *.png) ]] || echo_fail "Xcasset present but empty. Forgot to add app icons?"

  export PATH=/usr/local/bin:/usr/local/sbin:$PATH
  for base_file in *.png; do
    overlay="$trimmed_overlay"
    echo_info "- Processing icon at: $base_file"
    target_file="${base_file}_temp"

    width=`identify -format %w "${base_file}"`
    overlay_height=`echo "${width}/2.85" | bc`

    convert -background '#0008' \
      -fill white \
      -font "${font}" \
      -gravity center \
      -size "${width}x${overlay_height}" \
      caption:"${overlay}" \
      "${base_file}" +swap \
      -gravity south \
      -composite \
      "${target_file}"

    rm "$base_file"
    mv "$target_file" "$base_file"
  done
  cd -
done

