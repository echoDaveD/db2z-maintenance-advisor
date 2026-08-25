# Db2 for z/OS Maintenance Advisor

A policy-driven reference implementation for turning **Db2 for z/OS 13 real-time statistics (RTS)** and **DSNACCOX recommendations** into reviewable utility JCL.

The project has two main REXX programs:

- `DSNACCOX.rexx` calls `SYSPROC.DSNACCOX`, explains recommendations where possible, applies local automation policy, detects RUNSTATS profile changes, and writes a fixed-width `ACCOXOUT` file.
- `DB2UTGEN.rexx` consumes `ACCOXOUT` and generates separate JCL members for REORG, incremental COPY, full COPY, and RUNSTATS.

The goal is **controlled automation**, not blind execution. DSNACCOX remains the Db2 recommendation engine; the local policy layer decides which recommendations are eligible for unattended processing.

> **Status:** Reference implementation. Test with `OPTIONS PREVIEW`, validate against your Db2 maintenance level and local standards, and review generated JCL before production use.

## Why this project exists

Db2 already provides the building blocks for condition-based maintenance:

1. Real-time statistics describe object activity and physical state.
2. `-ACCESS DB(*) SP(*) MODE(STATS)` can externalize in-memory RTS before analysis.
3. DSNACCOX evaluates RTS and catalog information and recommends COPY, REORG, RUNSTATS, and extent-related actions.
4. A site still needs policy, exclusions, limits, diagnostics, and a safe way to turn recommendations into executable utility work.

This project implements that last layer.

## Architecture

```text
Db2 objects
    |
    v
-ACCESS DB(*) SP(*) MODE(STATS)
    |
    v
Real-Time Statistics / Catalog
    |
    v
SYSPROC.DSNACCOX
    |
    +--> recommendation reason enrichment
    +--> local REORG automation policy
    +--> object exclusions
    +--> RUNSTATS profile detection
    |
    v
ACCOXOUT
    |
    v
DB2UTGEN
    |
    +--> REORG JCL
    +--> Incremental COPY JCL
    +--> Full COPY JCL
    +--> RUNSTATS JCL
```

## Key features

- Configurable DSNACCOX thresholds through `ACCOXPAR`.
- Separate percentage and absolute thresholds where DSNACCOX supports both.
- Local REORG guardrails for object size and minimum days since the last REORG.
- Mandatory REORG-pending override support.
- `EXCLUDE_OBJECT` rules that can block all generated utilities while preserving the recommendation in `ACCOXOUT`.
- `EXCLUDE_DBNAME` rules for REORG automation policy.
- Support for TS, LOB, XML, and index-space recommendations.
- Full and incremental COPY generation.
- RUNSTATS generation with `TABLESAMPLE SYSTEM AUTO` for normal UTS processing.
- RUNSTATS statistics-profile detection. If DSNACCOX recommends RUNSTATS because a profile was updated after the last statistics collection, `PROFILE_TABLE` is carried into `ACCOXOUT` and DB2UTGEN can generate `TABLE (schema.table) USE PROFILE`.
- `RUNSTATSPROFILE YES|NO` controls whether detected profiles are used by generated RUNSTATS JCL.
- Diagnostic reason text and unknown-trigger dumps for investigation.
- Preview switches for generated utility jobs.

## Repository layout

```text
rexx/
  DSNACCOX.rexx       DSNACCOX driver and policy layer
  DB2UTGEN.rexx       Utility JCL generator
config/
  ACCOXPAR.sample     DSNACCOX and local policy example
  UTGENPAR.sample     JCL generator example
jcl/
  01-access-stats.jcl Example RTS externalization step
  02-dsnaccox.jcl     Example DSNACCOX REXX invocation
  03-db2utgen.jcl     Example generator invocation
docs/
  architecture.md
  parameters.md
  operations.md
  runstats-profiles.md
  ibm-references.md
examples/
  ACCOXOUT.sample
  generated-runstats.jcl
```

## Quick start

### 1. Customize the samples

Copy `config/ACCOXPAR.sample` and `config/UTGENPAR.sample` into site-controlled datasets. Replace all example values such as `DB2A`, `USER.DB2MAINT`, load-library names, output libraries, job names, and thresholds.

### 2. Externalize current RTS

Before invoking DSNACCOX, externalize in-memory statistics if current values are required:

```text
-ACCESS DB(*) SP(*) MODE(STATS)
```

IBM documents `MODE(STATS)` specifically for externalizing real-time statistics and optimizer recommendations before processes such as DSNACCOX.

### 3. Run the DSNACCOX driver

Allocate:

- `ACCOXPAR` to the policy/threshold member.
- `ACCOXOUT` to a sequential output data set.
- the REXX library through your normal SYSEXEC/SYSPROC setup.

Run `DSNACCOX` for the target subsystem.

### 4. Review ACCOXOUT

Important columns include:

- `COPY`, `RUN`, `REO`, `EXT`: DSNACCOX recommendations.
- `AUTO`: local automation eligibility. `AUTO=NO` is not automatically a global exclusion.
- `POLICY`: local policy reason.
- `PROFILE_TABLE`: populated when a RUNSTATS profile update explains the recommendation.
- `RECOMMENDATION REASON`: diagnostic explanation assembled by the driver.

A global exclusion is represented as:

```text
AUTO=NO
POLICY=OBJECT_EXCLUDED
```

DB2UTGEN recognizes this combination and skips the object for all generated utilities.

### 5. Generate utility JCL

Allocate `ACCOXOUT` and `UTGENPAR`, then run `DB2UTGEN`. Each enabled utility receives its own output member.

Use the preview switches during rollout:

```text
REORGPREVIEW      YES
ICOPYPREVIEW      YES
FULLCOPYPREVIEW   YES
RUNSTATSPREVIEW   YES
```

## Threshold philosophy

The values in `ACCOXPAR.sample` are examples, not universal recommendations. They intentionally demonstrate a policy that avoids reacting to high percentages caused by only a few changes on very small objects.

For example, the sample combines percentage and absolute thresholds for updated pages and for change counts where DSNACCOX provides both inputs. Percentage-only COPY change criteria are disabled in the sample because they can be overly sensitive for very small tables.

Tune thresholds from observed workload behavior, recovery objectives, maintenance windows, object sizes, and utility cost.

## RUNSTATS profiles

Statistics profiles are a saved set of statistics-collection options for a table. Db2 can create or modify profiles, including through autonomic statistics feedback. A profile update after the last statistics collection can lead to a RUNSTATS recommendation even when RTS insert/delete/update counters are zero.

The advisor detects this condition and records the table in `PROFILE_TABLE`. With:

```text
RUNSTATSPROFILE YES
```

DB2UTGEN generates syntax similar to:

```text
RUNSTATS TABLESPACE APPDB.TS01
         TABLE (APP.TAB01)
         USE PROFILE
         SHRLEVEL CHANGE UPDATE ALL
```

The generated RUNSTATS job also includes `RNPRIN01` and `STPRIN01` output DDs because profiles can request distribution statistics such as FREQVAL/COLGROUP processing.

See `docs/runstats-profiles.md` for details.

## Object exclusions

Use `EXCLUDE_OBJECT` for objects maintained by a separate application-controlled process, for example tablespaces that are completely replaced every day and are intentionally outside this maintenance workflow.

```text
EXCLUDE_OBJECT APPLOAD.TSDAILY
EXCLUDE_OBJECT STAGE*.TS*
```

The recommendation remains visible, but the local policy writes `AUTO=NO` and `POLICY=OBJECT_EXCLUDED`. DB2UTGEN then suppresses REORG, COPY, and RUNSTATS generation for that object.

## Safety and limitations

- Always validate against the exact Db2 13 function level and maintenance level used by your subsystem.
- Start with PREVIEW and a restricted object scope.
- The sample JCL contains placeholder subsystem, load-library, HLQ, class, and output-library values.
- `ACCOXOUT` is a fixed-width interface between the two REXX programs. If you change a field width or column order, update both programs together.
- `PROFILE_TABLE` is 64 characters in this reference format. Sites using very long schema/table identifiers should increase the field width in both programs.
- DSNACCOX can make recommendations for reasons that are not exposed as a non-NULL numeric criterion in its result set. The driver contains fallback diagnostics, but an `UNKNOWN_TRIGGER` should be investigated rather than assumed to be an error.
- Db2 catalog and directory backup/recovery have special operational requirements. Treat them as a separate recovery design topic; do not assume generic application-object JCL is appropriate for every system object.
- This project is not an IBM product and is not supported by IBM.

## IBM documentation

See `docs/ibm-references.md` for the primary IBM documentation used by the project, including DSNACCOX, RTS externalization, and RUNSTATS profiles.

## Contributing

Issues and pull requests are welcome. When reporting behavior, include the Db2 version/function level, relevant DSNU messages, sanitized ACCOXOUT rows, and the effective parameter values. Do not publish company identifiers, credentials, dataset names, or sensitive application data.

## License

MIT. See `LICENSE`.

---

**AI disclosure:** The English project description and documentation in this repository were generated with assistance from OpenAI ChatGPT.
