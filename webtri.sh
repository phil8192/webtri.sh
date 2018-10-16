#!/bin/sh

ENDPOINT="http://webtris.highwaysengland.co.uk/api/v1.0"
MAX_ROWS=40000


_to_date()
{
	date -d "$(echo "$1" \
		|awk '{print substr($1,5,4) substr($1,3,2) substr($1,1,2)}')" +%Y%m%d
}

get_area()
{
	id=$1 # note: api supposed to accept comma separated list of ids. however only works for 1 id.
	raw=$(curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/areas/$id")
	if [ "$JQ" = true ] ;then
		echo "id,name,description,x_lon,x_lat,y_lon,y_lat"
		echo "$raw" |jq -r '.areas? |.[] // [] |join(",")'
	else
		echo "$raw"
	fi
}

get_quality()
{
	sites=$1 # only 1 site for daily
	start=$2
	end=$3
	breakdown=$4 # overall, daily

	if [ "$breakdown" = "overall" ] ;then
		raw=$(curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/quality/overall?sites=$sites&start_date=$start&end_date=$end")

		if [ "$JQ" = true ] ;then
			start_date=$(_to_date "$start")
			end_date=$(_to_date "$end")
			days=$((1 + end_date - start_date))
			echo "quality"
			# note: have to round this up with printf since jq does not support ceil.
			printf "%.f\\n" "$(echo "$raw" \
					|jq -r --arg days $days '.data_quality * (([$days |tonumber, 2] |max) -1) / ($days |tonumber)')"
		else
			# note, does not correct for remote bug.
			echo "$raw"
		fi

	elif [ "$breakdown" = "daily" ] ;then
		raw=$(curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/quality/daily?siteId=$sites&start_date=$start&end_date=$end")
		if [ "$JQ" = true ] ;then
			echo "date,quality"
			echo "$raw" \
					|jq -r '.Qualities |.[] |map(.) |@csv' \
					|sed 's/\"//g'
		else
			echo "$raw"
		fi

	else
		echo "=== error ===" >&2
		echo "expected 'overall' or 'daily'" >&2
	fi
}

get_report()
{
	site_id=$1
	interval=$2 # daily, monthly, annual
	start=$3
	end=$4

	href="${ENDPOINT}/reports/${interval}?sites=${site_id}&start_date=${start}&end_date=${end}&page=1&page_size=$MAX_ROWS"

	printf "site_name,report_date,time_period_end,interval,"
	printf "length_0_520_cm,length_521_660_cm,length_661_1160_cm,length_1160_plus_cm,"
	printf "speed_0_10_mph,speed_11_15_mph,speed_16_20_mph,speed_21_25_mph,"
	printf "speed_26_30_mph,sped_31_35_mph,speed_36_40_mph,speed_41_45_mph,"
	printf "speed_46_50_mph,speed_51_55_mph,speed_56_60_mph,speed_61_70_mph,"
	printf "speed_71_80_mph,speed_80_plus_mph,speed_avg_mph,total_volume\\n"

	while [ "$href" ] ;do
		curl -s -X GET --header "Accept: application/json" "$href" >report.json
		if [ "$(jq -r 'type' report.json)" != "object" ] ;then
			echo "=== error ===" >&2
			cat report.json >&2
			rm -f report.json
			exit 1
		fi
		jq -r '.Rows |.[] |join(",")' report.json
		href=$(jq -r '.Header.links |.[] |select(.rel == "nextPage") |.href' report.json)
	done
	rm -f report.json
}

get_sites()
{
	site_ids=$1
	echo "id,name,description,longitude,latitude,status"
	curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/sites/$site_ids" \
			|jq -r '.sites | .[] | map(.) |@csv' \
			|sed 's/\"//g'
}

get_site_by_type()
{
	# 1 = Motorway Incident Detection and Automatic Signalling (MIDAS) https://en.wikipedia.org/wiki/Motorway_Incident_Detection_and_Automatic_Signalling (mainly predominantly inductive loops (though there are a few sites where radar technology is being trialled))
	# 2 = TAME (Traffic Appraisal, Modelling and Economics) which are inductive loops
	# 3 = Traffic Monitoring Units (TMU) (loops)
	# 4 = Highways Agency’s Traffic Flow Database System (TRADS) (Traffic Accident Database System (TRADS)?) (legacy)
	site_type=$1
	if [ -z "$site_type" ] ;then
		echo "id,description"
		curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/sitetypes" \
				|jq -r '.sitetypes | .[] |join(",")'
	else
		echo "id,name,description,longitude,latitude,status"
		curl -s -X GET --header 'Accept: application/json' "$ENDPOINT/sitetypes/$site_type/sites" \
				|jq -r '.sites | .[] | map(.) |@csv' \
				|sed 's/\"//g'
	fi
}

JQ=false
#get_area 1
#get_area
get_quality 5688 01012018 04012018 daily
#get_quality 5688,5699 01012018 04012018 overall
#get_report 5688 daily 01012015 01012018
#get_report 5688 daily 01012018 01012018
#get_sites
#get_sites 5688
#get_sites 5688,5689
#get_site_by_type
#get_site_by_type 1
