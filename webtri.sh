#!/bin/sh
# ==============================================================================
# Highways England webtris API shell client.
# ------------------------------------------------------------------------------
# http://webtris.highwaysengland.co.uk/
# http://webtris.highwaysengland.co.uk/api/swagger/ui/index
# ------------------------------------------------------------------------------
# Phil Stubbings <phil@parasec.net>
# https://github.com/phil8192
# ==============================================================================

# Conf.
ENDPOINT="http://webtris.highwaysengland.co.uk/api/v1.0"
MAX_ROWS=40000
JQ=true

# Internal: Check if bounding box contains point.
#
# $1 - Bounding box South East Longitude
# $2 - Bounding box South East Latitude
# $3 - Bounding box North West Longitude
# $4 - Bounding box North West Latitude
# $5 - Query point Longitude
# $6 - Query point Latitude
#
# Examples
#
#   _in_bounding_box -2.007464 53.344107 2.485731 53.612572 -2.244581 53.477487
#
# Returns true if point in bounding box, false otherwise.
_in_bounding_box() {
  se_lon=$1
  se_lat=$2
  nw_lon=$3
  nw_lat=$4
  qp_lon=$5
  qp_lat=$6

  if [ "$(echo "$nw_lon <= $qp_lon" |bc)" -eq 1 ] &&
     [ "$(echo "$qp_lon <= $se_lon" |bc)" -eq 1 ] &&
     [ "$(echo "$se_lat <= $qp_lat" |bc)" -eq 1 ] &&
     [ "$(echo "$qp_lat <= $nw_lat" |bc)" -eq 1 ] ;then
    echo true
  else
    echo false
  fi
}

# Internal: Get seconds since epoch for ddmmyyyy formated date.
#
# $1 - ddmmyyyy date
#
# Get seconds since epoch for the date (at midnight) in a portable way. This
# function works on both Unix and Linux environments.
#
# Examples
#
#   _seconds_since_epoch 04012018
#
# Returns seconds since the epoch.
_seconds_since_epoch() {
  if [ "$(uname)" = "Linux"  ] ;then
    date -u -d "$(echo "$1" \
        |awk '{print substr($1,5,4) substr($1,3,2) substr($1,1,2)}')" +%s
  else
    date -u -j -f "%d%m%Y:%H:%M:%S" "$1:00:00:00" +%s
  fi
}

# Internal: Get overall quality for specified sites.
#
# $1 - Comma seperated list of site ids.
# $2 - ddmmyyyy start period.
# $3 - ddmmyyyy end period.
#
# Gets the overall quality in terms of a percentage score. The percentage
# represents aggregated site data availability for the specified time period.
#
# Examples
#
#   _get_overall_quality 5688,5699 01012018 04012018
#
# Returns
#
#   * quality
_get_overall_quality() {
  sites=$1
  start=$2
  end=$3

  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/quality/overall?sites=$sites&start_date=$start&end_date=$end")

  if [ "$JQ" = true ] ;then
    start_secs=$(_seconds_since_epoch "$start")
    end_secs=$(_seconds_since_epoch "$end")
    days=$((1 + ((end_secs - start_secs) / 86400)))
    echo "quality"
    printf "%.f\\n" "$(echo "$raw" \
        |jq -r --arg days $days \
        '.data_quality * (([$days |tonumber, 2] |max) -1) / ($days |tonumber)')"
  else
    # note, does not correct for remote bug.
    echo "$raw"
  fi
}

# Internal: Get daily quality for specified site.
#
# $1 - Site id.
# $2 - ddmmyyyy start period.
# $3 - ddmmyyyy end period.
#
# Gets the daily quality in terms of a percentage score.
#
# Examples
#
#   _get_overall_quality 5688 01012018 04012018
#
# Returns
#
#   * date
#   * quality
_get_daily_quality() {
  sites=$1
  start=$2
  end=$3
  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/quality/daily?siteId=$sites&start_date=$start&end_date=$end")
  if [ "$JQ" = true ] ;then
    echo "date,quality"
    echo "$raw" \
        |jq -r '.Qualities |.[] |map(.) |@csv' \
        |sed 's/\"//g'
  else
    echo "$raw"
  fi
}

# Public: Get an area bounding box.
#
# $1 - An optional area id.
#
# The trunk roads are divided up into various pre-defined areas. Given an
# (optional) area id, this function will return the coordinates of a bounding
# box(es). The function will return all areas if an area id argument has not
# been supplied.
#
# Examples
#
#   get_area 1
#   get_area
#
# Returns
#
#   * id
#   * name
#   * description
#   * x_lon (South East longitude)
#   * x_lat (South East latitude)
#   * y_lon (North West longitude)
#   * y_lat (North West latitude)
get_area() {
  id=$1
  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/areas/$id")
  if [ "$JQ" = true ] ;then
    echo "id,name,description,x_lon,x_lat,y_lon,y_lat"
    echo "$raw" |jq -r '.areas? |.[] // [] |join(",")'
  else
    echo "$raw"
  fi
}

# Public: Get overall or daily quality.
#
# $1 - Comma seperated list of site ids. Or single site id if daily.
# $2 - ddmmyyyy start period.
# $3 - ddmmyyyy end period.
# $4 - overall or daily.
#
# If overall quality has been specified, gets the quality in terms of a
# percentage score. The percentage represents aggregated site data availability
# for the specified time period. If daily has been specified, Gets the day by
# day percentage quality for each site.
#
# Note that the orignal API contains a bug in which the overall quality is not
# calculated correctly. If CSV output has been specified (or jq is not present)
# This implementation will automatically correct for this bug.
#
# Examples
#
#   get_quality 5688 01012018 04012018 daily
#   get_quality 5688,5699 01012018 04012018 overall
#
# Returns
#
#   * date,quality (daily) or
#   * quality (overall)
get_quality() {
  sites=$1
  start=$2
  end=$3
  breakdown=$4

  if [ "$breakdown" = "overall" ] ;then
    _get_overall_quality "$sites" "$start" "$end"
  elif [ "$breakdown" = "daily" ] ;then
    _get_daily_quality "$sites" "$start" "$end"
  else
    echo "=== error ===" >&2
    echo "expected 'overall' or 'daily'" >&2
  fi
}

# Public: Get site report.
#
# $1 - Comma seperated list of site ids. Or single site id if daily. (max 30)
# $2 - ddmmyyyy start period.
# $3 - ddmmyyyy end period.
# $4 - overall or daily.
#
# This is the main part of the API. A site report consists of a number of
# variables for each time period (minimum 15 minute interval) covering vehicle
# lengths, speeds and total counts.
#
# Examples
#
#   get_report 5688 daily 01012015 01012018
#   get_report 5688 daily 01012018 01012018
#
# Returns
#
#   * site_name
#   * report_date
#   * time_period_end,
#   * interval
#   * len_0_520_cm
#   * len_521_660_cm
#   * len_661_1160_cm
#   * len_1160_plus_cm
#   * speed_0_10_mph
#   * speed_11_15_mph
#   * speed_16_20_mph
#   * speed_21_25_mph
#   * speed_26_30_mph
#   * speed_31_35_mph
#   * speed_36_40_mph
#   * speed_41_45_mph
#   * speed_46_50_mph
#   * speed_51_55_mph
#   * speed_56_60_mph
#   * speed_61_70_mph
#   * speed_71_80_mph
#   * speed_80_plus_mph
#   * speed_avg_mph
#   * total_vol
get_report() {
  site_id=$1
  interval=$2 # daily, monthly, annual
  start=$3
  end=$4

  href="${ENDPOINT}/reports/${interval}?sites=${site_id}&start_date=${start}&end_date=${end}&page=1&page_size=$MAX_ROWS"

  if [ "$JQ" = true ] ;then
    printf "site_name,report_date,time_period_end,interval,"
    printf "len_0_520_cm,len_521_660_cm,len_661_1160_cm,len_1160_plus_cm,"
    printf "speed_0_10_mph,speed_11_15_mph,speed_16_20_mph,speed_21_25_mph,"
    printf "speed_26_30_mph,sped_31_35_mph,speed_36_40_mph,speed_41_45_mph,"
    printf "speed_46_50_mph,speed_51_55_mph,speed_56_60_mph,speed_61_70_mph,"
    printf "speed_71_80_mph,speed_80_plus_mph,speed_avg_mph,total_vol\\n"
  else
    echo "["
  fi

  while [ "$href" ] ;do
    raw=$(curl -s -X GET --header "Accept: application/json" "$href")
    if [ "$(echo "$raw" |jq -r 'type')" != "object" ] ;then
      echo "=== error ===" >&2
      echo "$raw" >&2
      exit 1
    fi
    href=$(echo "$raw" \
        |jq -r '.Header.links |.[] |select(.rel == "nextPage") |.href')
    if [ "$JQ" = true ] ;then
      echo "$raw" |jq -r '.Rows |.[] |join(",")'
    else
      if [ "$href" ] ;then
        echo "$raw,"
      else
        echo "$raw"
      fi
    fi
  done

  if [ "$JQ" = false ] ;then
    echo "]"
  fi
}

# Public: Get sites.
#
# $1 - Comma seperated list of site ids. (optional)
#
# Get all avaiable site details and status.
#
# Examples
#
#   get_sites
#   get_sites 5688
#   get_sites 5688,5689
#
# Returns
#
#   * id
#   * name
#   * description
#   * longitude
#   * latitude
#   * status
get_sites() {
  site_ids=$1

  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/sites/$site_ids")
  if [ "$JQ" = true ] ;then
    echo "id,name,description,longitude,latitude,status"
    echo "$raw" \
        |sed "s/\\\\//g" \
        |jq -r '.sites | .[] | map(.) |@csv'
  else
    echo "$raw"
  fi
}

# Public: Get site types.
#
# Get site types. This is static info.
#
# Examples
#
#   get_site_types
#
# Returns
#
#   * id
#   * description
get_site_types() {
  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/sitetypes")
  if [ "$JQ" = true ] ;then
    echo "id,description"
    echo "$raw" |jq -r '.sitetypes | .[] |join(",")'
  else
    echo "$raw"
  fi
}

# Public: Get sites by type.
#
# $1 - Site type.
#
# Filter site information by site type. Use `get_site_types` function to see
# available options. The API currently returns:
#
# 1. Motorway Incident Detection and Automatic Signalling (MIDAS)
#    Predominantly inductive loops (though there are a few sites where radar
#    technology is being trialled)
#
# 2. TAME (Traffic Appraisal, Modelling and Economics) which are inductive loops
#
# 3. Traffic Monitoring Units (TMU) (loops)
#
# 4. Highways Agency’s Traffic Flow Database System (TRADS)
#    Traffic Accident Database System (TRADS)? (legacy)
#
# Examples
#
#   get_site_by_type
#   get_site_by_type 1
#
# Returns
#
#   * id
#   * name
#   * description
#   * longitude
#   * latitude
#   * status
get_site_by_type() {
  site_type=$1
  if [ "$site_type" -lt 1 ] || [ "$site_type" -gt 3 ] ;then
    echo "error: site type must be 1-3.">&2
    echo "id,name,description,longitude,latitude,status"
    exit 1
  fi
  raw=$(curl -s -X GET --header 'Accept: application/json' \
      "$ENDPOINT/sitetypes/$site_type/sites")
  if [ "$JQ" = true ] ;then
    echo "id,name,description,longitude,latitude,status"
    echo "$raw" \
        |sed "s/\\\'/\'/g" \
        |jq -r '.sites | .[] | map(.) |@csv'
  else
    echo "$raw"
  fi
}

# Public: Get sites in a bounding box.
#
# $1 - Bounding box South East Longitude
# $2 - Bounding box South East Latitude
# $3 - Bounding box North West Longitude
# $4 - Bounding box North West Latitude
#
# Get all sites inside a defined bounding box.
#
# Examples
#
#   get_sites_in_box 2.007464 53.344107 -2.485731 53.612572
#
# Returns
#
#   * id
#   * name
#   * description
#   * longitude
#   * latitude
#   * status
get_sites_in_box() {
  # note that this is pretty slow. probably better off doing this elsewhere.
  se_lon=$1
  se_lat=$2
  nw_lon=$3
  nw_lat=$4

  sites="$(get_sites)"
  echo "$sites" |head -1
  echo "$sites" |tail +2 |while read -r row ;do
    # remove everything inside quotes up until lon,lat then get lon,lat.
    # (quoted string may contain commas which would break awk -F ',')
    lon_lat="$(echo "$row" \
        |sed 's/\".*\",//' \
        |awk -F ',' '{print $1 " " $2}')"
    qp_lon="$(echo "$lon_lat" |cut -f 1 -d ' ')"
    qp_lat="$(echo "$lon_lat" |cut -f 2 -d ' ')"
    if [ "$(_in_bounding_box "$se_lon" "$se_lat" \
                             "$nw_lon" "$nw_lat" \
                             "$qp_lon" "$qp_lat")" = true ] ;then
      echo "$row"
    fi
  done
}

usage() {
  echo "./webtri.sh -f <function> -a \"<args>\""
  cat << EOF
Where <function> is one of:

  get_area, get_quality, get_report, get_sites, get_site_types, get_site_by_type.

  [get_area] Get an area bounding box.
    args
      1. An optional area id.

    The trunk roads are divided up into various pre-defined areas. Given an
    (optional) area id, return the coordinates of a bounding box(es). Return all
    areas if an area id argument has not been supplied.


  [get_quality] Get overall or daily quality.
    args
      1. Comma seperated list of site ids. Or single site id if daily.
      2. ddmmyyyy start period.
      3. ddmmyyyy end period.
      4. overall or daily.

    If overall quality has been specified, gets the quality in terms of a
    percentage score. The percentage represents aggregated site data
    availability for the specified time period. If daily has been specified,
    Gets the day by day percentage quality for each site.

    Note that the orignal API contains a bug in which the overall quality is not
    calculated correctly. If CSV output has been specified (or jq is not
    present) This implementation will automatically correct for this bug.


  [get_report] Get site report.
    args
      1. Comma seperated list of site ids. Or single site id if daily. (max 30)
      2. ddmmyyyy start period.
      3. ddmmyyyy end period.
      4. overall or daily.

    This is the main part of the API. A site report consists of a number of
    variables for each time period (minimum 15 minute interval) covering vehicle
    lengths, speeds and total counts.


  [get_sites] Get sites.
    args
      1. Comma seperated list of site ids. (optional)

    Get all avaiable site details and status.


  [get_site_types] Get site types.
    Get site types. This is static info.


  [get_site_by_type] Get sites by type.
    args
      1. Site type.
    Filter site information by site type.


  [get_sites_in_box] Get sites within a defined bounding box.
    args
      1. Bounding box South East Longitude
      2. Bounding box South East Latitude
      3. Bounding box North West Longitude
      4. Bounding box North West Latitude


<args> should be inclosed in double quotes.


Examples:

  ./webtri.sh -f get_area         -a 1
  ./webtri.sh -f get_area
  ./webtri.sh -f get_quality      -a "5688 01012018 04012018 daily"
  ./webtri.sh -f get_quality      -a "5688,5699 01012018 04012018 overall"
  ./webtri.sh -f get_report       -a "5688 daily 01012015 01012018"
  ./webtri.sh -f get_sites
  ./webtri.sh -f get_sites        -a 5688
  ./webtri.sh -f get_site_types
  ./webtri.sh -f get_site_by_type -a 1
  ./webtri.sh -f get_sites_in_box -a "-2.007464 53.344107 -2.485731 53.612572"

EOF

}

while getopts "hf:a:" opt; do
  case $opt in
    f)
      fun=$OPTARG
      ;;
    a)
      args=$OPTARG
      ;;
    h)
      usage
      exit 0
    ;;
    \?)
      usage
      exit 1
    ;;
  esac
done

if [ -z "$fun" ] ; then
  if [ "$0" = "./webtri.sh" ] ;then
    usage
    exit 1
  fi
else
  if [ "$fun" != "get_area"         ] &&
     [ "$fun" != "get_quality"      ] &&
     [ "$fun" != "get_report"       ] &&
     [ "$fun" != "get_sites"        ] &&
     [ "$fun" != "get_site_types"   ] &&
     [ "$fun" != "get_site_by_type" ] &&
     [ "$fun" != "get_sites_in_box" ] ;then
    echo "Must specify:" >&2
    echo "get_{area,quality,report,sites,site_types,site_by_type,get_sites_in_box}" >&2
    exit 1
  else
    # need to parse args in a nicer way.
    # (this will of course fail shellcheck)
    $fun $args
  fi
fi
