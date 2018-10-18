#!/usr/bin/env bats

source "webtri.sh"


@test "get_area 1" {

  curl()
  {
    cat << EOF
    {
      "row_count": 1,
      "areas": [
        {
          "Id": "1",
          "Name": "lala",
          "Description": "descr",
          "XLongitude": "-1.123",
          "XLatitude": "53.123",
          "YLongitude": "-1.55",
          "YLatitude": "54.1"
        }
      ]
    }
EOF
  }

  run get_area 1

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "id,name,description,x_lon,x_lat,y_lon,y_lat" ]
  [ "${lines[1]}" = "1,lala,descr,-1.123,53.123,-1.55,54.1" ]
  [ ${#lines[@]} == 2 ]
}

@test "get_area" {

  curl()
  {
    cat << EOF
    {
      "row_count": 2,
      "areas": [
        {
          "Id": "1",
          "Name": "lala",
          "Description": "descr",
          "XLongitude": "-1.123",
          "XLatitude": "53.123",
          "YLongitude": "-1.55",
          "YLatitude": "54.1"
        },
        {
          "Id": "2",
          "Name": "heh",
          "Description": "x",
          "XLongitude": "1",
          "XLatitude": "2",
          "YLongitude": "3",
          "YLatitude": "4"
        }
      ]
    }
EOF
  }

  run get_area

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "id,name,description,x_lon,x_lat,y_lon,y_lat" ]
  [ "${lines[1]}" = "1,lala,descr,-1.123,53.123,-1.55,54.1" ]
  [ "${lines[2]}" = "2,heh,x,1,2,3,4" ]
  [ ${#lines[@]} == 3 ]
}

@test "get_quality 5688 01012018 04012018 daily" {

  curl()
  {
    cat << EOF
    {
      "row_count": 4,
      "Qualities": [
      {
        "Date": "2018-01-01T00:00:00",
        "Quality": 100
      },
      {
        "Date": "2018-01-02T00:00:00",
        "Quality": 100
      },
      {
        "Date": "2018-01-03T00:00:00",
        "Quality": 100
      },
      {
        "Date": "2018-01-04T00:00:00",
        "Quality": 100
      }
      ]
    }
EOF
  }

  run get_quality 5688 01012018 04012018 daily

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "date,quality" ]
  [ "${lines[1]}" = "2018-01-01T00:00:00,100" ]
  [ "${lines[2]}" = "2018-01-02T00:00:00,100" ]
  [ "${lines[3]}" = "2018-01-03T00:00:00,100" ]
  [ "${lines[4]}" = "2018-01-04T00:00:00,100" ]
  [ ${#lines[@]} == 5 ]
}

@test "get_quality 5688,5699 01012018 04012018 overall" {

  curl()
  {
    cat << EOF
    {
      "row_count": 1,
      "start_date": "01012018",
      "end_date": "04012018",
      "data_quality": 67,
      "sites": "5688,5699"
    }
EOF
  }

  run get_quality 5688,5699 01012018 04012018 overall

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "quality" ]

  # note that remote will actually return 67 due to bug.
  # client corrects for this.
  [ "${lines[1]}" = "50" ]
  [ ${#lines[@]} == 2 ]
}

@test "get_report 5688 daily 01012015 01012018" {
  return
  # disabled for now (as curl invocations are from sub-shell, chained
  # curl() trick broken.
  curl()
  {
    # just 2 rows here.
    cat << EOF
    {
      "Header": {
        "row_count": 2,
        "start_date": "01012015",
        "end_date": "01012018",
        "links": [
          {
            "href": "http://webtris.highwaysengland.co.uk/api/v1.0/reports/Daily?sites=5688&start_date=01012015&end_date=01012018&page=2&page_size=40000",
            "rel": "nextPage"
          }
        ]
      },
      "Rows": [
        {
          "Site Name": "M602/6051A",
          "Report Date": "2015-01-01T00:00:00",
          "Time Period Ending": "00:59:00",
          "Time Interval": "",
          "0 - 520 cm": "",
          "521 - 660 cm": "",
          "661 - 1160 cm": "",
          "1160+ cm": "",
          "0 - 10 mph": "",
          "11 - 15 mph": "",
          "16 - 20 mph": "",
          "21 - 25 mph": "",
          "26 - 30 mph": "",
          "31 - 35 mph": "",
          "36 - 40 mph": "",
          "41 - 45 mph": "",
          "46 - 50 mph": "",
          "51 - 55 mph": "",
          "56 - 60 mph": "",
          "61 - 70 mph": "",
          "71 - 80 mph": "",
          "80+ mph": "",
          "Avg mph": "",
          "Total Volume": "332"
        },
        {
          "Site Name": "M602/6051A",
          "Report Date": "2015-01-01T00:00:00",
          "Time Period Ending": "01:59:00",
          "Time Interval": "",
          "0 - 520 cm": "",
          "521 - 660 cm": "",
          "661 - 1160 cm": "",
          "1160+ cm": "",
          "0 - 10 mph": "",
          "11 - 15 mph": "",
          "16 - 20 mph": "",
          "21 - 25 mph": "",
          "26 - 30 mph": "",
          "31 - 35 mph": "",
          "36 - 40 mph": "",
          "41 - 45 mph": "",
          "46 - 50 mph": "",
          "51 - 55 mph": "",
          "56 - 60 mph": "",
          "61 - 70 mph": "",
          "71 - 80 mph": "",
          "80+ mph": "",
          "Avg mph": "",
          "Total Volume": "396"
        }
      ]
    }
EOF
    # next curl call from nextPage ^
    curl()
    {
      cat << EOF
      {
        "Header": {
          "row_count": 1,
          "start_date": "01012015",
          "end_date": "01012018",
          "links": [
            {
              "href": "http://webtris.highwaysengland.co.uk/api/v1.0/reports/Daily?sites=5688&start_date=01012015&end_date=01012018&page=1&page_size=40000",
              "rel": "prevPage"
            }
          ]
        },
        "Rows": [
          {
            "Site Name": "M602/6051A",
            "Report Date": "2015-01-01T00:00:00",
            "Time Period Ending": "00:59:00",
            "Time Interval": "",
            "0 - 520 cm": "",
            "521 - 660 cm": "",
            "661 - 1160 cm": "",
            "1160+ cm": "",
            "0 - 10 mph": "",
            "11 - 15 mph": "",
            "16 - 20 mph": "",
            "21 - 25 mph": "",
            "26 - 30 mph": "",
            "31 - 35 mph": "",
            "36 - 40 mph": "5",
            "41 - 45 mph": "",
            "46 - 50 mph": "",
            "51 - 55 mph": "",
            "56 - 60 mph": "",
            "61 - 70 mph": "",
            "71 - 80 mph": "",
            "80+ mph": "",
            "Avg mph": "",
            "Total Volume": "100"
          }
        ]
      }
EOF
    }
  }

  run get_report 5688 daily 01012015 01012018

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "site_name,report_date,time_period_end,interval,len_0_520_cm,len_521_660_cm,len_661_1160_cm,len_1160_plus_cm,speed_0_10_mph,speed_11_15_mph,speed_16_20_mph,speed_21_25_mph,speed_26_30_mph,sped_31_35_mph,speed_36_40_mph,speed_41_45_mph,speed_46_50_mph,speed_51_55_mph,speed_56_60_mph,speed_61_70_mph,speed_71_80_mph,speed_80_plus_mph,speed_avg_mph,total_vol" ]
  [ ${lines[1]} = "M602/6051A,2015-01-01T00:00:00,00:59:00,,,,,,,,,,,,,,,,,,,,,332" ]
  [ ${lines[2]} = "M602/6051A,2015-01-01T00:00:00,01:59:00,,,,,,,,,,,,,,,,,,,,,396" ]
  [ ${lines[3]} = "M602/6051A,2015-01-01T00:00:00,00:59:00,,,,,,,,,,,,5,,,,,,,,,100" ]
  [ ${#lines[@]} == 4 ]
}

@test "get_report 5688 daily 01012018 01012018" {

  curl()
  {
    cat << EOF
    {
      "Header": {
        "row_count": 2,
        "start_date": "01012018",
        "end_date": "01012018",
        "links": []
      },
      "Rows": [
        {
          "Site Name": "M602/6051A",
          "Report Date": "2018-01-01T00:00:00",
          "Time Period Ending": "00:14:00",
          "Time Interval": "0",
          "0 - 520 cm": "78",
          "521 - 660 cm": "2",
          "661 - 1160 cm": "0",
          "1160+ cm": "0",
          "0 - 10 mph": "",
          "11 - 15 mph": "",
          "16 - 20 mph": "",
          "21 - 25 mph": "",
          "26 - 30 mph": "",
          "31 - 35 mph": "",
          "36 - 40 mph": "",
          "41 - 45 mph": "",
          "46 - 50 mph": "",
          "51 - 55 mph": "",
          "56 - 60 mph": "",
          "61 - 70 mph": "",
          "71 - 80 mph": "",
          "80+ mph": "",
          "Avg mph": "62",
          "Total Volume": "80"
        },
        {
          "Site Name": "M602/6051A",
          "Report Date": "2018-01-01T00:00:00",
          "Time Period Ending": "00:29:00",
          "Time Interval": "1",
          "0 - 520 cm": "72",
          "521 - 660 cm": "1",
          "661 - 1160 cm": "0",
          "1160+ cm": "0",
          "0 - 10 mph": "",
          "11 - 15 mph": "",
          "16 - 20 mph": "",
          "21 - 25 mph": "",
          "26 - 30 mph": "",
          "31 - 35 mph": "",
          "36 - 40 mph": "",
          "41 - 45 mph": "",
          "46 - 50 mph": "",
          "51 - 55 mph": "",
          "56 - 60 mph": "",
          "61 - 70 mph": "",
          "71 - 80 mph": "",
          "80+ mph": "",
          "Avg mph": "62",
          "Total Volume": "73"
        }
      ]
    }
EOF
  }

  run get_report 5688 daily 01012018 01012018

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "site_name,report_date,time_period_end,interval,len_0_520_cm,len_521_660_cm,len_661_1160_cm,len_1160_plus_cm,speed_0_10_mph,speed_11_15_mph,speed_16_20_mph,speed_21_25_mph,speed_26_30_mph,sped_31_35_mph,speed_36_40_mph,speed_41_45_mph,speed_46_50_mph,speed_51_55_mph,speed_56_60_mph,speed_61_70_mph,speed_71_80_mph,speed_80_plus_mph,speed_avg_mph,total_vol" ]
  [ ${lines[1]} = "M602/6051A,2018-01-01T00:00:00,00:14:00,0,78,2,0,0,,,,,,,,,,,,,,,62,80" ]
  [ ${lines[2]} = "M602/6051A,2018-01-01T00:00:00,00:29:00,1,72,1,0,0,,,,,,,,,,,,,,,62,73" ]
  [ ${#lines[@]} == 3 ]
}

@test "get_sites" {

  curl()
  {
    cat << EOF
    {
      "row_count": 2,
      "sites": [
        {
          "Id": "1",
          "Name": "MIDAS site at M4/2295A2 priority 1 on link 105009001; GPS Ref: 502816;178156; Westbound",
          "Description": "M4/2295A2",
          "Longitude": -0.520379557723297,
          "Latitude": 51.4930115367112,
          "Status": "Inactive"
        },
        {
          "Id": "2",
          "Name": "MIDAS site at A1M/2259B priority 1 on link 126046101; GPS Ref: 514029;294356; Southbound",
          "Description": "A1M/2259B",
          "Longitude": -0.320275451712423,
          "Latitude": 52.5351577963853,
          "Status": "Active"
        }
      ]
    }
EOF
  }

  run get_sites

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,name,description,longitude,latitude,status" ]
  [ ${lines[1]} = "1,MIDAS site at M4/2295A2 priority 1 on link 105009001; GPS Ref: 502816;178156; Westbound,M4/2295A2,-0.520379557723297,51.4930115367112,Inactive" ]
  [ ${lines[2]} = "2,MIDAS site at A1M/2259B priority 1 on link 126046101; GPS Ref: 514029;294356; Southbound,A1M/2259B,-0.320275451712423,52.5351577963853,Active" ]
  [ ${#lines[@]} == 3 ]
}

@test "get_sites 5688" {

  curl()
  {
    cat << EOF
    {
      "row_count": 1,
      "sites": [
        {
          "Id": "5688",
          "Name": "MIDAS site at M602/6051A priority 1 on link 115042101; GPS Ref: 379545;398603; Eastbound",
          "Description": "M602/6051A",
          "Longitude": -2.30971169539053,
          "Latitude": 53.4837600708868,
          "Status": "Active"
        }
      ]
    }
EOF
  }

  run get_sites 5688

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,name,description,longitude,latitude,status" ]
  [ ${lines[1]} = "5688,MIDAS site at M602/6051A priority 1 on link 115042101; GPS Ref: 379545;398603; Eastbound,M602/6051A,-2.30971169539053,53.4837600708868,Active" ]
  [ ${#lines[@]} == 2 ]
}

@test "get_sites 5688,5689" {

  curl()
  {
    cat << EOF
    {
      "row_count": 2,
      "sites": [
        {
          "Id": "5688",
          "Name": "MIDAS site at M602/6051A priority 1 on link 115042101; GPS Ref: 379545;398603; Eastbound",
          "Description": "M602/6051A",
          "Longitude": -2.30971169539053,
          "Latitude": 53.4837600708868,
          "Status": "Active"
        },
        {
          "Id": "5689",
          "Name": "MIDAS site at A168/9022M priority 1 on link 118013602; GPS Ref: 437757;473402; Southbound",
          "Description": "A168/9022M",
          "Longitude": -1.42335955807952,
          "Latitude": 54.1550672365429,
          "Status": "Active"
        }
      ]
    }
EOF
  }

  run get_sites 5688,5689

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,name,description,longitude,latitude,status" ]
  [ ${lines[1]} = "5688,MIDAS site at M602/6051A priority 1 on link 115042101; GPS Ref: 379545;398603; Eastbound,M602/6051A,-2.30971169539053,53.4837600708868,Active" ]
  [ ${lines[2]} = "5689,MIDAS site at A168/9022M priority 1 on link 118013602; GPS Ref: 437757;473402; Southbound,A168/9022M,-1.42335955807952,54.1550672365429,Active" ]
  [ ${#lines[@]} == 3 ]

}

@test "get_site_by_type 1" {

  curl()
  {
    cat << EOF
    {
      "row_count": 2,
      "sites": [
        {
          "Id": "1",
          "Name": "MIDAS site at M4/2295A2 priority 1 on link 105009001; GPS Ref: 502816;178156; Westbound",
          "Description": "M4/2295A2",
          "Longitude": -0.520379557723297,
          "Latitude": 51.4930115367112,
          "Status": "Inactive"
        },
        {
          "Id": "2",
          "Name": "MIDAS site at A1M/2259B priority 1 on link 126046101; GPS Ref: 514029;294356; Southbound",
          "Description": "A1M/2259B",
          "Longitude": -0.320275451712423,
          "Latitude": 52.5351577963853,
          "Status": "Active"
        }
      ]
    }
EOF
  }

  run get_site_by_type 1

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,name,description,longitude,latitude,status" ]
  [ ${lines[1]} = "1,MIDAS site at M4/2295A2 priority 1 on link 105009001; GPS Ref: 502816;178156; Westbound,M4/2295A2,-0.520379557723297,51.4930115367112,Inactive" ]
  [ ${lines[2]} = "2,MIDAS site at A1M/2259B priority 1 on link 126046101; GPS Ref: 514029;294356; Southbound,A1M/2259B,-0.320275451712423,52.5351577963853,Active" ]
  [ ${#lines[@]} == 3 ]
}

@test "get_site_by_type 31337" {

  curl()
  {
    echo ""
  }

  run get_site_by_type 31337

  echo "result = $output"

  # error dropped gracefully.
  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,name,description,longitude,latitude,status" ]
  [ ${#lines[@]} == 1 ]
}

@test "get_site_types" {

  # intercept curl call, return mock.
  curl()
  {
    cat << EOF
    {
      "row_count": 4,
      "sitetypes": [
        {
          "Id": "1",
          "Description": "MIDAS"
        },
        {
          "Id": "2",
          "Description": "TAME"
        },
        {
          "Id": "3",
          "Description": "TMU"
        },
        {
          "Id": "4",
          "Description": "Legacy"
        }
      ]
    }
EOF
  }

  run get_site_types

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ ${lines[0]} = "id,description" ]
  [ ${lines[1]} = "1,MIDAS" ]
  [ ${lines[2]} = "2,TAME" ]
  [ ${lines[3]} = "3,TMU" ]
  [ ${lines[4]} = "4,Legacy" ]
  [ ${#lines[@]} == 5 ]
}
