#!/bin/bash

ENDPOINT="http://webtris.highwaysengland.co.uk/api/v1.0/reports"
MAX_ROWS=40000


function get_report {
	site_id=$1
	interval=$2
	start=$3
	end=$4

	href="${ENDPOINT}/${interval}?sites=${site_id}&start_date=${start}&end_date=${end}&page=1&page_size=$MAX_ROWS"

	echo -n '"Site Name","Report Date","Time Period Ending","Time Interval",'
	echo -n '"0 - 520 cm","521 - 660 cm","661 - 1160 cm","1160+ cm",'
	echo -n '"0 - 10 mph","11 - 15 mph","16 - 20 mph","21 - 25 mph",'
	echo -n '"26 - 30 mph","31 - 35 mph","36 - 40 mph","41 - 45 mph",'
	echo -n '"46 - 50 mph","51 - 55 mph","56 - 60 mph","61 - 70 mph",'
	echo '"71 - 80 mph","80+ mph","Avg mph","Total Volume"'

	while [ $href ] ;do
		curl -s -X GET --header "Accept: application/json" "$href" >report.json
		if [ $(jq -r 'type' report.json) != "object" ] ;then
			echo "=== error ===" >&2
			cat report.json >&2
			exit 1
		fi
		jq -r '.Rows |.[] |join(",")' report.json
		href=$(jq -r '.Header.links |.[] |select(.rel == "nextPage") |.href' report.json)
	done
}


get_report 5688 Daily 01012015 01012018
