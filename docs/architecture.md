# Architecture

## Design principle

The project separates **recommendation**, **policy**, and **execution generation**.

### Recommendation: Db2 / DSNACCOX

DSNACCOX evaluates catalog and real-time statistics and returns recommendations for COPY, REORG, RUNSTATS, extents, and restricted states. The project does not attempt to replace those formulas.

### Policy: DSNACCOX driver REXX

The driver adds local controls that are intentionally outside the DSNACCOX stored-procedure inputs, including:

- minimum and maximum size for unattended REORG;
- minimum days since the previous REORG;
- handling of advisory and mandatory REORG-pending states;
- database exclusions;
- global object exclusions;
- diagnostics and recommendation reason text;
- statistics-profile lookup for otherwise unexplained RUNSTATS recommendations.

### Generation: DB2UTGEN

DB2UTGEN consumes the fixed-width ACCOXOUT interface and generates separate utility jobs. It does not call DSNACCOX or query the catalog.

This keeps the generator deterministic: the input file is the contract between analysis and generation.

## AUTO and POLICY semantics

`AUTO` originated as a REORG eligibility flag and is retained for compatibility.

- `AUTO=YES`: the REORG recommendation passed local unattended-REORG policy.
- `AUTO=NO`: the REORG recommendation is blocked by local policy, or the object is globally excluded.
- `AUTO=-`: no REORG eligibility decision was required.

DB2UTGEN must **not** treat every `AUTO=NO` as a global exclusion. For example, `LAST_REORG=0D<7` should block REORG but should not suppress a required COPY.

A global exclusion is encoded by the combination:

```text
AUTO=NO
POLICY contains OBJECT_EXCLUDED
```

Only that combination suppresses all generated utilities.

## PROFILE_TABLE

When DSNACCOX returns `RUNSTATS=YES` but the normal RTS criteria and timestamps do not explain the recommendation, the driver checks `SYSIBM.SYSTABLES_PROFILES` for a profile updated after `STATSLASTTIME`.

If found, it writes `schema.table` into `PROFILE_TABLE`. DB2UTGEN can then generate a table-specific `USE PROFILE` RUNSTATS statement without doing another catalog lookup.
