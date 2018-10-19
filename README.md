# ./webtri.sh

<p align="center">
  <img src="na/meh.jpg" alt="highways england"/>
</p>

> Unofficial [Highways England](https://www.gov.uk/government/organisations/highways-england)
> [WebTRIS Traffic Flow API](http://webtris.highwaysengland.co.uk/api/swagger/ui/index) shell client.

This script wraps the Highways England webtris API. The webtris API enables one
to extract historical road traffic data for the main roads within the English
trunk road network at 15 minute intervals. The data has been recorded using
[induction loops](https://en.wikipedia.org/wiki/Induction_loop).

Features include:

* [POSIX](http://pubs.opengroup.org/onlinepubs/9699919799/) compliant, portable code between UNIX systems.
* Decoupled [./jq programming language](https://stedolan.github.io/jq/) JSON parsing. Option to produce CSV or JSON output.
* Unit tests with [Bash Automated Testing System](https://github.com/sstephenson/bats) (BATS). See code in [test/](https://github.com/phil8192/webtri.sh/tree/master/test) directory.
* Documented functions, borrowed from Ruby [Tomdoc](http://tomdoc.org/) format. documentation generated using [tomdoc.sh](https://github.com/tests-always-included/tomdoc.sh)
* Fixes a bug detected in official API: Site quality stats will be returned correctly.

## Running

Run

```sh
./webtri.sh
```

For help.

`webtri.sh` takes 2 arguments. `-f <function>` and `-a <args>`. For a summary
use: `./webtri.sh -h`:

```
./webtri.sh -f <function> -a "<args>"
Where <function> is one of:

  area, quality, report, sites, site_types, site_by_type.

  [area] Get an area bounding box.
    args
      1. An optional area id.

    The trunk roads are divided up into various pre-defined areas. Given an
    (optional) area id, return the coordinates of a bounding box(es). Return all
    areas if an area id argument has not been supplied.


  [quality] Get overall or daily quality.
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


  [report] Get site report.
    args
      1. Comma seperated list of site ids. Or single site id if daily.
      2. ddmmyyyy start period.
      3. ddmmyyyy end period.
      4. overall or daily.

    This is the main part of the API. A site report consists of a number of
    variables for each time period (minimum 15 minute interval) covering vehicle
    lengths, speeds and total counts.


  [sites] Get sites.
    args
      1. Comma seperated list of site ids. (optional)

    Get all avaiable site details and status.


  [site_types] Get site types.
    Get site types. This is static info.


  [site_by_type] Get sites by type.
    args
      1. Site type.
    Filter site information by site type.


<args> should be inclosed in double quotes.


Examples:

  ./webtri.sh -f get_area         -a 1
  ./webtri.sh -f get_area
  ./webtri.sh -f get_quality      -a "5688 01012018 04012018 daily"
  ./webtri.sh -f get_quality      -a "5688,5699 01012018 04012018 overall"
  ./webtri.sh -f get_report       -a "5688 daily 01012015 01012018"
  ./webtri.sh -f get_report       -a "5688 daily 01012018 01012018"
  ./webtri.sh -f get_sites
  ./webtri.sh -f get_sites        -a 5688
  ./webtri.sh -f get_site_by_type
  ./webtri.sh -f get_site_by_type -a 1
```

## documentation

`webtris.sh` can be sourced in/imported or run directly. see [docs](docs.md) for
full function info.

## Dependencies

* [Command-line JSON processor](https://stedolan.github.io/jq/) (otional) If not installed or specified, `webtri.sh` will return raw JSON data.

### Testing and Recommended

* [ShellCheck, a static analysis tool for shell scripts](https://github.com/koalaman/shellcheck)
* [Bash Automated Testing System (BATS)](https://github.com/sstephenson/bats)


## license

[GNU General Public License family](https://en.wikipedia.org/wiki/GNU_General_Public_License)
v([3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)).
