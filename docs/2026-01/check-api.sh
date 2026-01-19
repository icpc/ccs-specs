#!/bin/bash
set -e -o pipefail

# This should match the API version this script tests as found at the
# URL https://ccs-specs.icpc.io/$API_VERSION/contest_api
API_VERSION=2026-01

ENDPOINTS='
contests
access
judgement-types
languages
problems
groups
organizations
persons
accounts
teams
state
submissions
judgements
runs
clarifications
awards
commentary
scoreboard
'

# Note: event-feed is an NDJSON endpoint which is treated specially.

ENDPOINTS_OPTIONAL='
persons
accounts
awards
commentary
'

ENDPOINTS_TO_FAIL='
404:doesnt-exist
404:doesnt-exist/42
404:submissions/999999
404:submissions/xyz9999
404:submissions/XYZ_999
404:submissions/XYZ-999
400:event-feed?since_id=999999
400:event-feed?since_id=xY-99_
'

# We later re-add optional endpoints to ENDPOINTS_CHECK_CONSISTENT if
# they were actually found.
ENDPOINTS_CHECK_CONSISTENT="$ENDPOINTS"
for endpoint in $ENDPOINTS_OPTIONAL scoreboard ; do
	ENDPOINTS_CHECK_CONSISTENT="${ENDPOINTS_CHECK_CONSISTENT/$endpoint/}"
done

error()
{
	echo "Error: $*"
	exit 1
}

verbose()
{
	if [ -z "$QUIET" ]; then
		if [ $# -eq 1 ]; then
			echo "$1"
		else
			# shellcheck disable=SC2059
			printf "$@"
		fi
	fi
}

version()
{
	PROGNAME=$(basename "$0")
	echo "$PROGNAME for Contest API version $API_VERSION"
}

usage()
{
	PROGNAME=$(basename "$0")
	cat <<EOF
$PROGNAME - Validate a Contest API implementation with JSON schema.

Usage: $PROGNAME [option]... URL

This program validates a Contest API implementation against the
specification at https://ccs-specs.icpc.io/$API_VERSION/contest_api

The URL must point to the base of the API, for example:

  $PROGNAME -n -c '-knS' -a 'strict=1' https://example.com/api

where the options -knS passed to curl make it ignore SSL certificate
errors, use ~/.netrc for credentials, and be verbose. The option -a
makes that 'strict=1' is appended as argument to each API call.

This script requires:
- the cURL command line client
- the \`yajsv\` binary from https://github.com/neilpa/yajsv
- the jq program from https://github.com/stedolan/jq
  which is available as the \`jq\` package in Debian and Ubuntu.
- the PHP command line executable to run the helper script \`check-api-consistency.php\`

Options:

  -a ARGS  Arguments to pass to the API request URLs. Separate arguments
             with '&', do not add initial '?'. (default: $URL_ARGS)
  -b       Bail out on first error detected.
  -C       Check internal consistency between REST endpoints and event feed.
  -c OPTS  Options to pass to curl to request API data (default: $CURL_OPTIONS)
  -d       Turn on shell script debugging.
  -e       Check correct HTTP error codes for non-existent endpoints.
  -j PROG  Specify the path to the 'yajsv' binary.
  -n       Require that all collection endpoints are non-empty.
  -p       Allow extra properties beyond those defined in the Contest API.
  -t TIME  Timeout in seconds for downloading event feed (default: $FEED_TIMEOUT)
  -q       Quiet mode: suppress all output except script errors.
  -h       Show this help output.
  -v       Show version information including API version.

The script reports endpoints checked and validations errors.
In quiet mode only the exit code indicates successful validation.

EOF
}

FEED_TIMEOUT=10
CURL_OPTIONS='-n -s'
URL_ARGS=''
YAJSV_BINARY='yajsv'

# Parse command-line options:
while getopts 'a:bCc:dej:npt:qhv' OPT ; do
	case "$OPT" in
		a) URL_ARGS="$OPTARG" ;;
		b) BAIL_OUT_ON_ERROR=1 ;;
		C) CHECK_CONSISTENCY=1 ;;
		c) CURL_OPTIONS="$OPTARG" ;;
		d) export DEBUG=1 ;;
		e) CHECK_ERRORS=1 ;;
		j) YAJSV_BINARY="$OPTARG" ;;
		n) NONEMPTY=1 ;;
		p) EXTRAPROP=1 ;;
		t) FEED_TIMEOUT="$OPTARG" ;;
		q) QUIET=1 ;;
		h) usage ; exit 0 ;;
		v) version ; exit 0 ;;
		:)
			error "option '$OPTARG' requires an argument."
			exit 1
			;;
		?)
			error "unknown option '$OPTARG'."
			exit 1
			;;
		*)
			error "unknown error reading option '$OPT', value '$OPTARG'."
			exit 1
			;;
	esac
done
shift $((OPTIND-1))

[ -n "$DEBUG" ] && set -x

API_URL="$1"

if [ -z "$API_URL" ]; then
	error "API URL argument expected."
	exit 1
fi

TMP=$(mktemp -d)

MYDIR=$(dirname "$0")

query_endpoint()
{
	local OUTPUT="$1"
	local URL="$2"
	local OPTIONAL="$3"
	local EXPECTED_HTTPCODE="$4"

	local HTTPCODE EXITCODE

	local CURLOPTS="$CURL_OPTIONS"
	[ -n "$DEBUG" ] && CURLOPTS="${CURLOPTS/ -s/} -S"

	local ARGS="$URL_ARGS"

	# Special case timeout for event-feed NDJSON endpoint.
	if [ "${URL/event-feed/}" != "$URL" ]; then
		TIMEOUT=1
		CURLOPTS="$CURLOPTS -N --max-time ${FEED_TIMEOUT}"
	fi

	set +e
	# shellcheck disable=SC2086
	HTTPCODE=$(curl $CURLOPTS -w "%{http_code}\n" -o "$OUTPUT" "${URL}${ARGS:+?$ARGS}")
	EXITCODE="$?"
	set -e

	if [ -n "$EXPECTED_HTTPCODE" ]; then
		if [ "$HTTPCODE" -ne "$EXPECTED_HTTPCODE" ]; then
			verbose "Warning: curl returned HTTP status $HTTPCODE != $EXPECTED_HTTPCODE for '$URL'."
			return 1;
		fi
		return 0
	fi

	if [ $EXITCODE -eq 28 ]; then # timeout
		if [ -z "$TIMEOUT" ]; then
			verbose "Warning: curl request timed out for '$URL'."
			return $EXITCODE
		fi
	elif [ $EXITCODE -ne 0 ]; then
		verbose "Warning: curl returned exitcode $EXITCODE for '$URL'."
		return $EXITCODE
	elif [ "$HTTPCODE" -ne 200 ]; then
		[ -n "$OPTIONAL" ] || verbose "Warning: curl returned HTTP status $HTTPCODE for '$URL'."
		return 1
	elif [ ! -e "$OUTPUT" ] || [ ! -s "$OUTPUT" ]; then
		[ -n "$OPTIONAL" ] || verbose "Warning: no or empty file downloaded by curl."
		return 1
	fi
	return 0
}

validate_schema()
{
	local DATA="$1" SCHEMA="$2" RESULT EXITCODE

	SCHEMADIR="$(dirname "$SCHEMA")"
	set +e
	RESULT=$($YAJSV_BINARY -q -s "$SCHEMA" -r "$SCHEMADIR"'/*.json' "$DATA")
	EXITCODE=$?
	set -e
	verbose '%s' "$RESULT"
	if [ $EXITCODE -eq 0 ]; then
		verbose 'OK'
	else
		verbose ''
	fi
	if [ $EXITCODE -ge 4 ]; then
		error "$YAJSV_BINARY detected usage or schema definiton errors"
	fi
	if [ $EXITCODE -ne 0 -a -n "$BAIL_OUT_ON_ERROR" ]; then
		exit $EXITCODE
	fi
}

# Copy schema files so we can modify common.json for the non-empty option
cp -a "$MYDIR/json-schema" "$TMP"

if [ -n "$NONEMPTY" ]; then
	# Don't understand why the first '\t' needs a double escape...
	sed -i '/ANCHOR_TO_INSERT_REQUIRE_NONEMPTY_ENDPOINTS/i \\t\t"minItems": 1,' "$TMP/json-schema/"*.json
fi
if [ -z "$EXTRAPROP" ]; then
	sed -i '/ANCHOR_TO_INSERT_REQUIRE_STRICT_PROPERTIES/i \\t\t"additionalProperties": false,' "$TMP/json-schema/"*.json
fi

# First check the API information endpoint
ENDPOINT='api_information'
URL="${API_URL%/}/"
SCHEMA="$TMP/json-schema/$ENDPOINT.json"
OUTPUT="$TMP/$ENDPOINT.json"
if query_endpoint "$OUTPUT" "$URL" ; then
	verbose '%20s: ' "$ENDPOINT"
	validate_schema "$OUTPUT" "$SCHEMA"
else
	verbose '%20s: Failed to download\n' "$ENDPOINT"
	exit 1
fi

# Then validate and get all contests
ENDPOINT='contests'
URL="${API_URL%/}/$ENDPOINT"
SCHEMA="$TMP/json-schema/$ENDPOINT.json"
OUTPUT="$TMP/$ENDPOINT.json"
if query_endpoint "$OUTPUT" "$URL" ; then
	verbose '%20s: ' "$ENDPOINT"
	validate_schema "$OUTPUT" "$SCHEMA"
	CONTESTS=$(jq -r '.[].id' "$OUTPUT")
else
	verbose '%20s: Failed to download\n' "$ENDPOINT"
	exit 1
fi

EXITCODE=0

for CONTEST in $CONTESTS ; do
	verbose "Validating contest '$CONTEST'..."
	CONTEST_URL="${API_URL%/}/contests/$CONTEST"
	mkdir -p "$TMP/$CONTEST"

	for ENDPOINT in $ENDPOINTS ; do
		if [ "${ENDPOINTS_OPTIONAL/${ENDPOINT}/}" != "$ENDPOINTS_OPTIONAL" ]; then
			OPTIONAL=1
		else
			unset OPTIONAL
		fi

		if [ "$ENDPOINT" = 'contests' ]; then
			URL="$CONTEST_URL"
			SCHEMA="$TMP/json-schema/contest.json"
		else
			URL="$CONTEST_URL/$ENDPOINT"
			SCHEMA="$TMP/json-schema/$ENDPOINT.json"
		fi

		OUTPUT="$TMP/$CONTEST/$ENDPOINT.json"

		if query_endpoint "$OUTPUT" "$URL" $OPTIONAL ; then
			verbose '%20s: ' "$ENDPOINT"
			validate_schema "$OUTPUT" "$SCHEMA"
			if [ -n "$OPTIONAL" ]; then
				ENDPOINTS_CHECK_CONSISTENT="$ENDPOINTS_CHECK_CONSISTENT
$ENDPOINT"
			fi
			EXIT=$?
			[ $EXIT -gt $EXITCODE ] && EXITCODE=$EXIT
		else
			if [ -n "$OPTIONAL" ]; then
				verbose '%20s: Optional, not present\n' "$ENDPOINT"
			else
				verbose '%20s: Failed to download\n' "$ENDPOINT"
				[ $EXITCODE -eq 0 ] && EXITCODE=1
			fi
		fi
	done

	# Now do special case event-feed endpoint
	ENDPOINT='event-feed'
	SCHEMA="$MYDIR/json-schema/$ENDPOINT-array.json"
	OUTPUT="$TMP/$CONTEST/$ENDPOINT.json"
	URL="$CONTEST_URL/$ENDPOINT"

	if query_endpoint "$OUTPUT" "$URL" ; then
		# Delete empty lines and transform NDJSON into a JSON array.
		sed -i '/^$/d;1 s/^/[/;s/$/,/;$ s/,$/]/' "$OUTPUT"

		verbose '%20s: ' "$ENDPOINT"
		validate_schema "$OUTPUT" "$SCHEMA"
		EXIT=$?
		[ $EXIT -gt $EXITCODE ] && EXITCODE=$EXIT
		[ $EXIT -ne 0 ] && [ -n "$DEBUG" ] && cat "$OUTPUT"
	else
		verbose '%20s: Failed to download\n' "$ENDPOINT"
	fi

	if [ -n "$CHECK_CONSISTENCY" ]; then
		ENDPOINTS_CHECK_CONSISTENT="${ENDPOINTS_CHECK_CONSISTENT/accounts/}"
		# shellcheck disable=SC2086
		eval ${EXTRAPROP:-STRICT=1} "$MYDIR"/check-api-consistency.php "$TMP/$CONTEST" $ENDPOINTS_CHECK_CONSISTENT
		EXIT=$?
		[ $EXIT -gt $EXITCODE ] && EXITCODE=$EXIT
	fi

done

if [ -n "$CHECK_ERRORS" ]; then
	verbose "Validating errors on missing endpoints..."
	for i in $ENDPOINTS_TO_FAIL ; do
		CODE=${i%%:*}
		ENDPOINT=${i#*:}
		URL="$CONTEST_URL/$ENDPOINT"
		verbose '%20s: ' "$ENDPOINT"
		if query_endpoint /dev/null "$URL" '' "$CODE" ; then
			verbose 'OK (returned %s)\n' "$CODE"
		else
			EXIT=1
			[ $EXIT -gt $EXITCODE ] && EXITCODE=$EXIT
		fi
	done
fi

[ -n "$DEBUG" ] || rm -rf "$TMP"

exit $EXITCODE
