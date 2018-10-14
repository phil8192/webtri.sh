#!/usr/bin/env bats

source "../webtri.sh"


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
