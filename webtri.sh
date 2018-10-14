#!/bin/bash

ENDPOINT="http://webtris.highwaysengland.co.uk/api/v1.0"
MAX_ROWS=40000


function get_area {
	id=$1 # note: api supposed to accept comma separated list of ids. however only works for 1 id.
	echo '"Id","Name","Description","XLongitude","YLongitude","YLatitude"'
	curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/areas/$id" \
			|jq -r '.areas? |.[] // [] |join(",")'
}

function get_quality {
	sites=$1 # only 1 site for daily
	start=$2
	end=$3
	breakdown=$4 # overall, daily

	if [ $breakdown == "overall" ] ;then
		# there is a bug in the api:
		# curl -X GET --header 'Accept: application/json' 'http://webtris.highwaysengland.co.uk/api/v1.0/quality/overall?sites=5688%2C5801&start_date=01012018&end_date=03012018'
		# will return 133.
		# it should between [0, 100] according to their FAQ:
		# Data Quality Calculation
		# The calculation for the Data Quality is as follows:
		# (Sum the total number of minutes’ worth of data) / (Total number of days in the selected date range * 1440) * 100 to give a percentage. This calculation is the same for all reports.
		#
		# so for these 4 days of complete data, we have 4 days * (4 15 min intervals) * 24 hours of complete data.
		# to get the % they probably divide by max possible complete data, however
		# they incorrectly calculate days as: end_date - start_date, which is exclusive.
		# they should instead do somthing like: 1 + end_date - start_date.
		#
		# rows_data / (days
		# (4*4*24) / (3*4*24) = 1.333.. wrong.
		# fix:
		# 4/3 * 3/4 = 1.
		#
		# correct by:
		# (days-1)/days * result.
		#
		# note: have to round this up with printf since jq does not support ceil.
		start_date=$(date -d $(echo $start |awk '{print substr($1,5,4) substr($1,3,2) substr($1,1,2)}') +%Y%m%d)
		end_date=$(date -d $(echo $end |awk '{print substr($1,5,4) substr($1,3,2) substr($1,1,2)}') +%Y%m%d)
		days=$((1 + end_date - start_date))
		printf "%.f\n" $(curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/quality/overall?sites=$sites&start_date=$start&end_date=$end" \
				|jq -r --arg days $days '.data_quality * (([$days |tonumber, 2] |max) -1) / ($days |tonumber)')
	elif [ $breakdown == "daily" ] ;then
		curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/quality/daily?siteId=$sites&start_date=$start&end_date=$end" \
			|jq -r '.Qualities |.[] |map(.) |@csv' # mixed string + int, join does not work.
	else
		echo "=== error ===" >&2
		echo "expected 'overall' or 'daily'" >&2
	fi
}

function get_report {
	site_id=$1
	interval=$2
	start=$3
	end=$4

	href="${ENDPOINT}/reports/${interval}?sites=${site_id}&start_date=${start}&end_date=${end}&page=1&page_size=$MAX_ROWS"

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
		exit 0
	done
}

#get_report 5688 Daily 01012015 01012018
#get_report 5688 Daily 01012018 05012018
#get_area 1
#get_area
#get_quality 5688 01012018 04012018 daily
get_quality 5688 01012018 04012018 overall
