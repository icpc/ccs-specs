#!/bin/bash
# Checks whether a Contest API conforms to the specification
# https://clics.ecs.baylor.edu/index.php/Contest_API

# Set path to json-validate binary if it's not in PATH:
#VALIDATE_JSON=/path/to/json-validate

# Optional extra arguments to append to the API URLs:
# Separate with '&', do not add initial '?'.
#URL_ARGS='strict=1'

ENDPOINTS='
contest
judgement-types
languages
problems
groups
organizations
team-members
teams
state
submissions
judgements
runs
clarifications
awards
scoreboard
'

# Note: event-feed is an NDJSON endpoint which is treated specially.

ENDPOINTS_OPTIONAL='
team-members
awards
'

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
			printf "$@"
		fi
	fi
}

usage()
{
	cat <<EOF
$(basename $0) - Validate a Contest API implementation with JSON schema.

Usage: $(basename $0) [option]... URL

This program validates a Contest API implementation against the
specification: https://clics.ecs.baylor.edu/index.php/Contest_API

It requires the validate-json binary from
https://github.com/justinrainbow/json-schema which can be installed
with \`composer require justinrainbow/json-schema\`.

For now, the URL must point to a specific single contest inside the
API, for example \`$(basename $0) https://example.com/api/contests/wf17\`
to validate the API endpoints under contest 'wf17'.

Options:

  -c OPTS  Options to pass to curl to request API data (default: $CURL_OPTIONS)
  -d       Turn on shell script debugging.
  -h       Snow this help output.
  -j PROG  Specify the path to the 'validate-json' binary.
  -n       Require that all collection endpoints are non-empty.
  -t TIME  Timeout in seconds for downloading event feed (default: $FEED_TIMEOUT)
  -q       Quiet mode: suppress all output except script errors.

The script reports endpoints checked and validations errors.
In quiet mode only the exit code indicates successful validation.

EOF
}

FEED_TIMEOUT=10
CURL_OPTIONS='-n -s'

# Parse command-line options:
while getopts 'c:dhj:nt:q' OPT ; do
	case "$OPT" in
		c) CURL_OPTIONS="$OPTARG" ;;
		d) DEBUG=1 ;;
		h) usage ; exit 0 ;;
		j) VALIDATE_JSON="$OPTARG" ;;
		n) NONEMPTY=1 ;;
		t) FEED_TIMEOUT="$OPTARG" ;;
		q) QUIET=1 ;;
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

MYDIR=$(dirname $0)

query_endpoint()
{
	local OUTPUT="$1"
	local URL="$2"
	local OPTIONAL="$3"
	local HTTPCODE EXITCODE

	local CURLOPTS="$CURL_OPTIONS"
	[ -n "$DEBUG" ] && CURLOPTS="${CURLOPTS/ -s/} -S"

	local ARGS="$URL_ARGS"

	# Special case timeout for event-feed NDJSON endpoint.
	if [ "${URL/event-feed/}" != "$URL" ]; then
		TIMEOUT=1
		CURLOPTS="$CURLOPTS -N --max-time ${FEED_TIMEOUT}"
		ARGS="${ARGS:+$ARGS&}stream=0"
	fi

	HTTPCODE=$(curl $CURLOPTS -w "%{http_code}\n" -o "$OUTPUT" "${URL}${ARGS:+?$ARGS}")
	EXITCODE="$?"
	if [ $EXITCODE -eq 28 ]; then # timeout
		if [ -z "$TIMEOUT" ]; then
			verbose "Warning: curl request timed out for '$URL'."
			return $EXITCODE
		fi
	elif [ $EXITCODE -ne 0 ]; then
		verbose "Warning: curl returned exitcode $EXITCODE for '$URL'."
		return $EXITCODE
	elif [ $HTTPCODE -ne 200 ]; then
		[ -n "$OPTIONAL" ] || verbose "Warning: curl returned HTTP status $HTTPCODE for '$URL'."
		return 1
	elif [ ! -e "$OUTPUT" -o ! -s "$OUTPUT" ]; then
		[ -n "$OPTIONAL" ] || verbose "Warning: no or empty file downloaded by curl."
		return 1
	fi
	return 0
}

validate_schema()
{
	local DATA="$1" SCHEMA="$2" RESULT EXITCODE

	RESULT=$(${VALIDATE_JSON:-validate-json} "$DATA" "$SCHEMA")
	EXITCODE=$?
	verbose '%s' "$RESULT"
	if [ $EXITCODE -eq 0 ]; then
		verbose 'OK'
	else
		verbose ''
	fi
	return $EXITCODE
}

# Copy schema files so we can modify common.json for the non-empty option
cp -a "$MYDIR/json-schema" "$TMP"

if [ -n "$NONEMPTY" ]; then
	# Don't understand why the first '\t' needs a double escape...
	sed -i '/"nonemptyarray":/a \\t\t"minItems": 1' "$TMP/json-schema/common.json"
fi

EXITCODE=0

for ENDPOINT in $ENDPOINTS ; do
	if [ "${ENDPOINTS_OPTIONAL/${ENDPOINT}/}" != "$ENDPOINTS_OPTIONAL" ]; then
		OPTIONAL=1
	else
		unset OPTIONAL
	fi

	if [ "$ENDPOINT" = 'contest' ]; then
		URL="$API_URL"
	else
		URL="${API_URL%/}/$ENDPOINT"
	fi

	SCHEMA="$TMP/json-schema/$ENDPOINT.json"
	OUTPUT="$TMP/$ENDPOINT.json"

	if query_endpoint "$OUTPUT" "$URL" $OPTIONAL ; then
		verbose '%20s: ' "$ENDPOINT"
		validate_schema "$OUTPUT" "$SCHEMA"
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
OUTPUT="$TMP/$ENDPOINT.json"
URL="${API_URL%/}/$ENDPOINT"

if query_endpoint "$OUTPUT" "$URL" ; then
	# Delete empty lines and transform NDJSON into a JSON array.
	sed -i '/^$/d;1 s/^/[/;s/$/,/;$ s/,$/]/' "$OUTPUT"

	verbose '%20s: ' "$ENDPOINT"
	validate_schema "$OUTPUT" "$SCHEMA"
	EXIT=$?
	[ $EXIT -gt $EXITCODE ] && EXITCODE=$EXIT
	[ $EXIT -ne 0 -a -n "$DEBUG" ] && cat "$OUTPUT"
else
	verbose '%20s: Failed to download\n' "$ENDPOINT"
fi

[ -n "$DEBUG" ] || rm -rf $TMP

exit $EXITCODE
