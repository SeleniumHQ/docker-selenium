#!/bin/bash
# Checks that every recorded test session has an intact video on the FTP server.
#
# The tests write one session ID per line to SESSION_LOG. Each recorded video is
# uploaded to the ftp-server pod and named "<test name>_<session ID>.mp4". This
# script waits until every session has a video and the file sizes stop changing,
# copies the videos out of the pod, and checks that every session's video was copied
# and is intact with ffmpeg, copying again until VERIFY_TIMEOUT if not.
# On failure, it saves logs of the video and FTP pods to DIAG_DIR.

SELENIUM_NAMESPACE=${SELENIUM_NAMESPACE:-"selenium"}
SESSION_LOG=${SESSION_LOG:-"./tests/tests/sessions.txt"}
OUTPUT_DIR=${OUTPUT_DIR:-"./tests/collected-videos"}
DIAG_DIR=${DIAG_DIR:-"./tests/tests/video-check"}
UPLOAD_TIMEOUT=${UPLOAD_TIMEOUT:-300}
VERIFY_TIMEOUT=${VERIFY_TIMEOUT:-120}
POLL_INTERVAL=${POLL_INTERVAL:-10}
FTP_DIR=${FTP_DIR:-"/ftp/seluser"}
VIDEO_IMAGE=${VIDEO_IMAGE:?"VIDEO_IMAGE must be set to the video image that provides ffmpeg"}

collect_diagnostics() {
  mkdir -p "${DIAG_DIR}"
  echo "Saving diagnostics to ${DIAG_DIR}"
  kubectl get pods -n "${SELENIUM_NAMESPACE}" -o wide >"${DIAG_DIR}/pods.txt" 2>&1
  kubectl describe pod -n "${SELENIUM_NAMESPACE}" -l app=ftp-server >"${DIAG_DIR}/ftp-server-describe.txt" 2>&1
  kubectl logs -n "${SELENIUM_NAMESPACE}" -l app=ftp-server --all-containers --tail=-1 >"${DIAG_DIR}/ftp-server.log" 2>&1
  kubectl exec -n "${SELENIUM_NAMESPACE}" "${FTP_POD}" -- ls -laR "${FTP_DIR}" >"${DIAG_DIR}/ftp-files.txt" 2>&1
  cp -f "${SESSION_LOG}" "${DIAG_DIR}/sessions.txt" 2>/dev/null
  # Logs of every container that records, uploads or manages videos.
  kubectl get pods -n "${SELENIUM_NAMESPACE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .spec.containers[*]}{.name}{" "}{end}{"\n"}{end}' |
    while read -r pod containers; do
      for container in ${containers}; do
        case "${container}" in
          *video* | *recorder* | *uploader* | *manager*)
            kubectl logs -n "${SELENIUM_NAMESPACE}" "${pod}" -c "${container}" --tail=-1 \
              >"${DIAG_DIR}/${pod}_${container}.log" 2>&1
            ;;
        esac
      done
    done
}

fail() {
  echo "::error::$1"
  collect_diagnostics
  exit 1
}

list_videos() {
  kubectl exec -n "${SELENIUM_NAMESPACE}" "${FTP_POD}" -- \
    sh -c "find '${FTP_DIR}' -type f -name '*.mp4' -exec stat -c '%s %n' {} + 2>/dev/null" | sort
}

FTP_POD=$(kubectl get pods -n "${SELENIUM_NAMESPACE}" -l app=ftp-server \
  -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
[ -n "${FTP_POD}" ] || fail "No running ftp-server pod in namespace ${SELENIUM_NAMESPACE}"

[ -s "${SESSION_LOG}" ] || fail "No test sessions were logged in ${SESSION_LOG}"
SESSIONS=()
while IFS= read -r session; do
  [ -n "${session}" ] && SESSIONS+=("${session}")
done < <(sort -u "${SESSION_LOG}")
echo "Expecting a video for each of ${#SESSIONS[@]} test session(s)"

deadline=$((SECONDS + UPLOAD_TIMEOUT))
previous=""
while :; do
  current=$(list_videos)
  missing=()
  for session in "${SESSIONS[@]}"; do
    echo "${current}" | grep -qE "(/|_)${session}\.mp4$" || missing+=("${session}")
  done
  echo "Videos found for $((${#SESSIONS[@]} - ${#missing[@]})) of ${#SESSIONS[@]} session(s)"
  # Done when every session has a video and no file grew since the last poll.
  if [ ${#missing[@]} -eq 0 ] && [ "${current}" = "${previous}" ]; then
    break
  fi
  if [ ${SECONDS} -ge ${deadline} ]; then
    if [ ${#missing[@]} -gt 0 ]; then
      fail "No video after ${UPLOAD_TIMEOUT}s for ${#missing[@]} session(s): ${missing[*]}"
    fi
    fail "Video files were still changing after ${UPLOAD_TIMEOUT}s"
  fi
  previous=${current}
  sleep "${POLL_INTERVAL}"
done

# Copies the videos out of the pod and checks them. Sets PROBLEM and returns 1 when
# a session's video was not copied or a video is not intact.
copy_and_verify() {
  rm -rf "${OUTPUT_DIR}"
  mkdir -p "${OUTPUT_DIR}"
  if ! kubectl cp -n "${SELENIUM_NAMESPACE}" "${FTP_POD}:${FTP_DIR}" "${OUTPUT_DIR}" >/dev/null; then
    PROBLEM="Could not copy the videos out of pod ${FTP_POD}"
    return 1
  fi
  local copied missing=() corrupted=() file session
  copied=$(find "${OUTPUT_DIR}" -type f -name '*.mp4')
  for session in "${SESSIONS[@]}"; do
    echo "${copied}" | grep -qE "(/|_)${session}\.mp4$" || missing+=("${session}")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    PROBLEM="Videos of ${#missing[@]} session(s) were not copied: ${missing[*]}"
    return 1
  fi
  while IFS= read -r file; do
    if ! docker run --rm -u "$(id -u)" -v "$(pwd):$(pwd)" -w "$(pwd)" --entrypoint="" "${VIDEO_IMAGE}" \
      ffmpeg -v error -i "${file}" -f null - >/dev/null 2>"${file}.ffmpeg.txt"; then
      echo "Not intact: ${file}"
      cat "${file}.ffmpeg.txt"
      corrupted+=("${file}")
    fi
    rm -f "${file}.ffmpeg.txt"
  done <<<"${copied}"
  if [ ${#corrupted[@]} -gt 0 ]; then
    PROBLEM="${#corrupted[@]} video file(s) are not intact"
    return 1
  fi
  return 0
}

# The uploader writes each video in place under its final name, so a stable size does
# not prove an upload finished. Copy and check again until the videos are complete.
deadline=$((SECONDS + VERIFY_TIMEOUT))
until copy_and_verify; do
  if [ ${SECONDS} -ge ${deadline} ]; then
    fail "${PROBLEM}"
  fi
  echo "${PROBLEM}, checking again in ${POLL_INTERVAL}s"
  sleep "${POLL_INTERVAL}"
done
echo "All ${#SESSIONS[@]} session video(s) are present and intact"
