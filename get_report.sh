#!/bin/bash



href="http://webtris.highwaysengland.co.uk/api/v1.0/reports/Daily?sites=5688&start_date=01012015&end_date=01012018&page=1&page_size=40000"


echo '"Site Name","Report Date","Time Period Ending","Time Interval","0 - 520 cm","521 - 660 cm","661 - 1160 cm","1160+ cm","0 - 10 mph","11 - 15 mph","16 - 20 mph","21 - 25 mph","26 - 30 mph","31 - 35 mph","36 - 40 mph","41 - 45 mph","46 - 50 mph","51 - 55 mph","56 - 60 mph","61 - 70 mph","71 - 80 mph","80+ mph","Avg mph","Total Volume"'

while [ $href ] ;do

	curl -s -X GET --header "Accept: application/json" "$href" >report.json

	if [ $(jq -r 'type' report.json) != "object" ] ;then
		echo "=== error ==="
		cat report.json
		exit 1
	fi

	# get csv.
	# assume objects are in order, else can define exactly as:
	# jq -r '.Rows | map([."Site Name", ."etc..."]) | .[] | join(",")' report.json
	jq -r '.Rows | .[] | join(",")' report.json

	href=$(jq -r '.Header.links | .[] | select(.rel == "nextPage") |.href' report.json)

done
