#!/bin/bash
# Checks whether a Contest API conforms to the specification
# https://clics.ecs.baylor.edu/index.php/Contest_API
#
# Currently only checks a single contest under api/contests/{id}/
#
# Rquires https://github.com/justinrainbow/json-schema
# which can be installed with: composer require justinrainbow/json-schema

# Set path to json-validate binary if it's not in PATH:
#VALIDATE_JSON=/path/to/json-validate

# Optional extra arguments to append to the API URLs:
#URL_EXTRA='?strict=1'

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

API_URL="$1"

if [ -z "$API_URL" ]; then
	echo "Error: API URL argument expected."
	exit 1
fi

TMP=$(mktemp -d)

MYDIR=$(dirname $0)

query_endpoint()
{
	local OUTPUT="$1"
	local URL="$2"
	local OPTIONAL="$3"

	# Special case timeout for event-feed NDJSON endpoint.
	if [ "${URL/event-feed/}" != "$URL" ]; then
		TIMEOUT='--max-time 10'
	fi

	local HTTPCODE=$(curl -kns $TIMEOUT -w "%{http_code}\n" -o "$OUTPUT" "${URL}${URL_EXTRA}")
	local EXITCODE="$?"
	if [ $EXITCODE -eq 28 ]; then # timeout
		if [ -z "$TIMEOUT" ]; then
			echo "Warning curl request timed out for '$URL'."
			return $EXITCODE
		fi
	elif [ $EXITCODE -ne 0 ]; then
		echo "Warning: curl returned exitcode $EXITCODE for '$URL'."
		return $EXITCODE
	elif [ $HTTPCODE -ne 200 ]; then
		[ -n "$OPTIONAL" ] || echo "Warning: curl returned HTTP status $HTTPCODE for '$URL'."
		return 1
	elif [ ! -e "$OUTPUT" -o ! -s "$OUTPUT" ]; then
		[ -n "$OPTIONAL" ] || echo "Warning: no or empty file downloaded by curl."
		return 1
	fi
	return 0
}

validate_schema()
{
	local DATA="$1" SCHEMA="$2"

	${VALIDATE_JSON:-validate-json} "$DATA" "$SCHEMA"
	local EXITCODE=$?
	[ $EXITCODE -eq 0 ] && echo "OK"
	return $EXITCODE
}

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

	SCHEMA="$MYDIR/json-schema/$ENDPOINT.json"
	OUTPUT="$TMP/$ENDPOINT.json"

	if query_endpoint "$OUTPUT" "$URL" $OPTIONAL ; then
		printf '%20s: ' "$ENDPOINT"
		validate_schema "$OUTPUT" "$SCHEMA"
	else
		if [ -n "$OPTIONAL" ]; then
			printf '%20s: Optional, not present\n' "$ENDPOINT"
		else
			printf '%20s: Failed to download\n' "$ENDPOINT"
		fi
	fi
done

# Now do special case event-feed endpoint
ENDPOINT='event-feed'
SCHEMA="$MYDIR/json-schema/$ENDPOINT.json"
OUTPUT="$TMP/$ENDPOINT.json"
URL="${API_URL%/}/$ENDPOINT"

if query_endpoint "$OUTPUT" "$URL" ; then
	printf '%20s: ' "$ENDPOINT"
	# Do line by line validation of NDJSON, quit at first failure.
	TMPOUTPUT="$TMP/event-feed-line.json"
	TMPRESULT="$TMP/event-feed-tmp.txt"
	VALID=1
	while read LINE ; do
		# Skip empty lines that may be inserted as heartbeat.
		[ -z "$LINE" ] && continue
		echo "$LINE" > "$TMPOUTPUT"
		if ! validate_schema "$TMPOUTPUT" "$SCHEMA" > "$TMPRESULT"; then
			printf "Failed to validate:\n%s\n" "$LINE"
			cat "$TMPRESULT"
			VALID=0
			break
		fi
	done < "$OUTPUT"
	[ "$VALID" -eq 1 ] && echo "OK"
else
	printf '%20s: Failed to download\n' "$ENDPOINT"
fi

rm -rf $TMP

exit 0
