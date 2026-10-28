# Extracts a Makeself 2.3.0 archive without executing it: reads the header
# line count and MD5 from the script, then untars the payload that follows.
#
# Adapted from upstream's extract_makeself_from_command, which re-streamed the
# installer through `head` several times; under pipefail the producer then
# dies of SIGPIPE (exit 141) on a ~1 GB payload. Working from a file avoids
# that.
function extract_makeself() {
  declare targetDir="$1"
  declare installer="$2"

  declare secondLine
  secondLine="$(sed -n 2p "$installer")"
  if [[ $secondLine != "# This script was generated using Makeself 2.3.0" ]]; then
    echo "Unexpected Makeself version, don't know how to extract this" >&2
    exit 1
  fi

  # The header is plain text, so the first MB covers it; read it once.
  declare header
  header="$(head --bytes=$((1000 * 1000)) "$installer" | tr -d '\0')"

  declare -i headerLineCount
  headerLineCount="$(
    grep --only-matching --max-count=1 --extended-regexp \
      '`head -n [0-9]+ "\$0"' <<<"$header" \
      | sed -e 's/^.*head -n \([0-9]\+\) "$0".*$/\1/'
  )"

  declare -i offset
  offset="$(head --lines=$headerLineCount "$installer" | wc --bytes)"

  declare md5_def
  md5_def="$(grep --max-count=1 --line-regexp --extended-regexp 'MD5="[0-9a-fA-F ]+"' <<<"$header")"
  declare MD5
  eval "$md5_def"

  declare computed_md5
  computed_md5="$(tail --bytes=+$((offset + 1)) "$installer" | md5sum - | cut -b-32)"
  if [[ $computed_md5 != "$MD5" ]]; then
    echo "Error: checksum failure, expected $MD5 but got $computed_md5" >&2
    exit 1
  fi

  tail --bytes=+$((offset + 1)) "$installer" | tar -xf - -C "$targetDir"
}
