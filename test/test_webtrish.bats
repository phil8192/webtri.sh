#!/usr/bin/env bats

source "webtri.sh"


@test "get_area 1" {

}

@test "get_area" {

}

@test "get_quality 5688 01012018 04012018 daily" {

}

@test "get_quality 5688,5699 01012018 04012018 overall" {

}

@test "get_report 5688 Daily 01012015 01012018" {

}

@test "get_report 5688 daily 01012018 01012018" {

}

@test "get_sites" {

}

@test "get_sites 5688" {

}

@test "get_sites 5688,5689" {

}

@test "get_site_by_type 1" {

}

@test "get_site_by_type" {

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

  expected=$(cat << EOF
id,description
1,MIDAS
2,TAME
3,TMU
4,Legacy
EOF
)

  run get_site_by_type

  echo "result = $output"

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}
