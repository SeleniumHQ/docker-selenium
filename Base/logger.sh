#!/usr/bin/env bash

# Log functions shared by the scripts in the images.
# Each line has the same layout as the Selenium server logs:
#   <timestamp> <LEVEL> [<process>] - <message>
# The timestamp uses SE_LOG_TIMESTAMP_FORMAT (a `date` format).
# The process name is $process_name when the script sets it, otherwise the script name.

SE_LOG_TIMESTAMP_FORMAT=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}

_se_log() {
  local level="${1}"
  shift
  local name="${process_name:-$(basename "${0}" .sh)}"
  printf '%s %s [%s] - %s\n' "$(date +"${SE_LOG_TIMESTAMP_FORMAT}")" "${level}" "${name}" "$*"
}

log_info() {
  _se_log INFO "$@"
}

log_warn() {
  _se_log WARN "$@"
}

log_error() {
  _se_log ERROR "$@" >&2
}

# Converts a `date` format to a Java SimpleDateFormat pattern, so the Selenium server
# logs use the same timestamp as the scripts. Returns 1 for unsupported `date` tokens.
to_java_timestamp_format() {
  local input="${1}"
  local output=""
  local literal=""
  local i char token
  for ((i = 0; i < ${#input}; i++)); do
    char="${input:i:1}"
    if [ "${char}" = "%" ]; then
      token="${input:i+1:1}"
      if [ "${token}" = "3" ] && [ "${input:i+2:1}" = "N" ]; then
        token="3N"
      fi
      case "${token}" in
      Y) output+="yyyy" ;;
      y) output+="yy" ;;
      m) output+="MM" ;;
      d) output+="dd" ;;
      H) output+="HH" ;;
      I) output+="hh" ;;
      M) output+="mm" ;;
      S) output+="ss" ;;
      3N) output+="SSS" ;;
      p) output+="a" ;;
      z) output+="Z" ;;
      Z) output+="z" ;;
      b) output+="MMM" ;;
      B) output+="MMMM" ;;
      a) output+="EEE" ;;
      A) output+="EEEE" ;;
      j) output+="DDD" ;;
      %) output+="%" ;;
      *) return 1 ;;
      esac
      i=$((i + ${#token}))
    elif [[ "${char}" =~ [A-Za-z] ]]; then
      # Letters are pattern characters in Java, so quote them to keep them as text
      literal="${char}"
      while [[ "${input:i+1:1}" =~ [A-Za-z] ]]; do
        i=$((i + 1))
        literal+="${input:i:1}"
      done
      output+="'${literal}'"
    elif [ "${char}" = "'" ]; then
      output+="''"
    else
      output+="${char}"
    fi
  done
  echo "${output}"
}

# Sets LOG_TIMESTAMP_OPTS with the --log-timestamp-format option for the Selenium server.
# It stays empty when SE_OPTS already sets the option or the format cannot be converted.
LOG_TIMESTAMP_OPTS=()
set_log_timestamp_opts() {
  local java_format
  if [[ "${SE_OPTS}" == *"--log-timestamp-format"* ]]; then
    return 0
  fi
  if java_format="$(to_java_timestamp_format "${SE_LOG_TIMESTAMP_FORMAT}")"; then
    log_info "Appending Selenium option: --log-timestamp-format ${java_format}"
    LOG_TIMESTAMP_OPTS=(--log-timestamp-format "${java_format}")
  else
    log_warn "SE_LOG_TIMESTAMP_FORMAT '${SE_LOG_TIMESTAMP_FORMAT}' cannot be used for the Selenium server logs. Keeping their default timestamp format"
  fi
}
