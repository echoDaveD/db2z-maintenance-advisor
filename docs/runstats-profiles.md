# RUNSTATS statistics profiles

A statistics profile stores statistics-collection options for a specific table in `SYSIBM.SYSTABLES_PROFILES`. Profiles can be created or updated explicitly and can also be affected by autonomic statistics feedback depending on subsystem configuration.

## Why DSNACCOX can recommend RUNSTATS with zero RTS changes

A table can have:

```text
STATSINSERTS = 0
STATSDELETES = 0
STATSUPDATES = 0
```

and still require RUNSTATS if its profile was updated after the last statistics collection. The profile describes *what statistics should be collected*, so an updated profile can make existing statistics incomplete for the new definition.

## Advisor behavior

For an otherwise unexplained table-space RUNSTATS recommendation, the driver looks up the newest RUNSTATS profile for the table space. If:

```text
PROFILE_UPDATE > STATSLASTTIME
```

it writes:

```text
PROFILE_TABLE = schema.table
RECOMMENDATION REASON = RUNSTATS PROFILE_UPDATE_AFTER_LAST_STATS ...
```

## Generator behavior

With `RUNSTATSPROFILE YES`, DB2UTGEN generates:

```text
RUNSTATS TABLESPACE APPDB.TS01
         TABLE (APP.TAB01)
         USE PROFILE
         SHRLEVEL CHANGE UPDATE ALL
```

It does not add `TABLE(ALL) INDEX(ALL)` or `TABLESAMPLE SYSTEM AUTO` to the profile branch because the stored profile supplies the statistics specifications.

The RUNSTATS JCL includes `RNPRIN01` and `STPRIN01` SYSOUT DDs so profile-driven distribution statistics have the expected report DDs available.

## Important behavior

IBM documents that `USE PROFILE` can remove existing statistics that are not included in the profile (subject to UPDATE options). Review profile contents and local statistics strategy before enabling unattended profile execution.
