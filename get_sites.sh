#!/bin/bash
curl -X GET --header 'Accept: application/json' 'http://webtris.highwaysengland.co.uk/api/v1.0/sites' > sites.json
cat sites.json |jq -r '.sites | .[] .Id' > site_ids.txt
