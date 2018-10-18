`get_area()`
------------

Public: Get an area bounding box.

* $1 - An optional area id.

The trunk roads are divided up into various pre-defined areas. Given an (optional) area id, this function will return the coordinates of a bounding box(es). The function will return all areas if an area id argument has not been supplied.

Examples

    get_area 1
    get_area

Returns

    * id
    * name
    * description
    * x_lon
    * x_lat
    * y_lon
    * y_lat


`get_quality()`
---------------

Public: Get overall or daily quality.

* $1 - Comma seperated list of site ids. Or single site id if daily.
* $2 - ddmmyyyy start period.
* $3 - ddmmyyyy end period.
* $4 - overall or daily.

If overall quality has been specified, gets the quality in terms of a percentage score. The percentage represents aggregated site data availability for the specified time period. If daily has been specified, Gets the day by day percentage quality for each site.

Note that the orignal API contains a bug in which the overall quality is not calculated correctly. If CSV output has been specified (or jq is not present) This implementation will automatically correct for this bug.

Examples

get_quality 5688 01012018 04012018 daily get_quality 5688,5699 01012018 04012018 overall

Returns

    * date,quality (daily) or
    * quality (overall)


`get_report()`
--------------

Public: Get site report.

* $1 - Comma seperated list of site ids. Or single site id if daily.
* $2 - ddmmyyyy start period.
* $3 - ddmmyyyy end period.
* $4 - overall or daily.

This is the main part of the API. A site report consists of a number of variables for each time period (minimum 15 minute interval) covering vehicle lengths, speeds and total counts.

Examples

get_report 5688 daily 01012015 01012018 get_report 5688 daily 01012018 01012018

Returns

    * site_name
    * report_date
    * time_period_end,
    * interval
    * len_0_520_cm
    * len_521_660_cm
    * len_661_1160_cm
    * len_1160_plus_cm
    * speed_0_10_mph
    * speed_11_15_mph
    * speed_16_20_mph
    * speed_21_25_mph
    * speed_26_30_mph
    * speed_31_35_mph
    * speed_36_40_mph
    * speed_41_45_mph
    * speed_46_50_mph
    * speed_51_55_mph
    * speed_56_60_mph
    * speed_61_70_mph
    * speed_71_80_mph
    * speed_80_plus_mph
    * speed_avg_mph
    * total_vol


`get_sites()`
-------------

Public: Get sites.

* $1 - Comma seperated list of site ids. (optional)

Get all avaiable site details and status.

Examples

get_sites get_sites 5688 get_sites 5688,5689

Returns

    * id
    * name
    * description
    * longitude
    * latitude
    * status


`get_site_types()`
------------------

Public: Get site types.

Get site types. This is static info.

Examples

get_site_types

Returns

    * id
    * description


`get_site_by_type()`
--------------------

Public: Get sites by type.

* $1 - Site type.

Filter site information by site type. Use `get_site_types` function to see available options. The API currently returns:

1. Motorway Incident Detection and Automatic Signalling (MIDAS)     Predominantly inductive loops (though there are a few sites where radar
     technology is being trialled)

2. TAME (Traffic Appraisal, Modelling and Economics) which are inductive loops

3. Traffic Monitoring Units (TMU) (loops)

4. Highways Agency’s Traffic Flow Database System (TRADS)     Traffic Accident Database System (TRADS)? (legacy)

Examples

get_site_by_type get_site_by_type 1

Returns

    * id
    * name
    * description
    * longitude
    * latitude
    * status


