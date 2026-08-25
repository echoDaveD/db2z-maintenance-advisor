# Parameter guide

## ACCOXPAR

`ACCOXPAR` contains two classes of parameters.

### DSNACCOX inputs

Examples include `CRUPDATEDPAGESPCT`, `RRTDELETESPCT`, `SRTINSDELUPDPCT`, and `EXTENTLIMIT`. If a supported parameter is omitted, the driver passes SQL NULL so that DSNACCOX can use its IBM default.

`RRIEMPTYLIMIT` and `RRTHASHOVRFLWRATIO` are placed into the Db2 13 `SPECIALPARM` structure by the driver.

### Local policy inputs

These are evaluated only by the REXX driver:

- `MIN_REORG_SIZE_MB`
- `MAX_REORG_SIZE_GB`
- `MIN_DAYS_SINCE_REORG`
- `PROCESS_AREO`
- `PROCESS_REORP`
- `REORP_OVERRIDE_LIMITS`
- `REQUIRE_SIZE_KNOWN`
- `OUTPUT_ONLY_AUTO_REORG`
- `EXCLUDE_DBNAME`
- `EXCLUDE_OBJECT`

`EXCLUDE_OBJECT` accepts the project's simple wildcard matching and is intended for objects managed by a separate maintenance process.

## UTGENPAR

The generator supports independent job names, member names, object limits, copy retention, units, HLQs, SHRLEVEL settings, and preview switches for each utility type.

A job name of `NONE`, `-`, or blank disables that utility.

### RUNSTATSPROFILE

- `YES`: if `PROFILE_TABLE` is populated, generate `TABLE (schema.table) USE PROFILE`.
- `NO`: ignore `PROFILE_TABLE` for JCL syntax and generate the normal RUNSTATS statement.

The recommendation itself is not discarded when this parameter is `NO`.

## Threshold tuning

Do not copy sample thresholds into production without measurement. In particular, percentage-only criteria can be surprisingly aggressive for tiny objects. Where Db2 offers a percentage plus an absolute threshold, using both can reduce maintenance triggered by only a handful of changed rows/pages.
