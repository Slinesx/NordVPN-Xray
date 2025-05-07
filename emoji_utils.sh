#!/usr/bin/env bash
# emoji_utils.sh — generate a stylized country tag using mappings

# source the data file (assumes same directory)
source "$(dirname "${BASH_SOURCE[0]}")/emoji_data.sh"

# generate_tag srv_code → TAG
generate_tag() {
  local srv="$1"
  local cc2="${srv:0:2}"
  local num="${srv:2}"
  local cc="${cc2^^}"

  local emoji="${ISO_EMOJI[$cc]:-🏳️}"
  local iso3="${ISO3[$cc]:-$cc}"

  local styled_cur=""
  for ((i=0;i<${#iso3};i++)); do
    ch="${iso3:i:1}"
    styled_cur+="${BOLD[$ch]:-$ch}"
  done

  local styled_nrd="${BOLD[N]}${BOLD[R]}${BOLD[D]}"

  local styled_num=""
  for ((i=0;i<${#num};i++)); do
    d="${num:i:1}"
    styled_num+="${SUB[$d]:-$d}"
  done

  TAG="${emoji} ${styled_cur}·${styled_nrd} ${styled_num}"
}
