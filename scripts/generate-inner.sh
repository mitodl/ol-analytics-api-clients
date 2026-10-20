#!/usr/bin/env bash
#
status=0
for cfile in ol-analytics-api-clients/config/*.yaml; do
	# A config can land before the ol-analytics-api release that adds its spec.
	spec="$(sed -n 's/^inputSpec: *//p' "$cfile")"
	if [ ! -f "$spec" ]; then
		echo "Skipping: $cfile ($spec not found)"
		continue
	fi
	echo "Generating: $cfile"
	/usr/local/bin/docker-entrypoint.sh generate -c "$cfile" || status=1
done
exit $status
