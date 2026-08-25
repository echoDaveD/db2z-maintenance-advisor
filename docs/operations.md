# Operations guide

## Suggested cycle

1. Externalize current RTS with `-ACCESS DB(*) SP(*) MODE(STATS)` when fresh values are required.
2. Run the DSNACCOX driver with a controlled `ACCOXPAR`.
3. Review ACCOXOUT, especially unknown triggers, restricted states, and objects blocked by policy.
4. Run DB2UTGEN with all utility preview switches enabled during rollout.
5. Review DSNUTILB PREVIEW output.
6. Enable execution only after the generated syntax and object scope are accepted.
7. Revisit thresholds from actual candidate volume and utility cost.

## Initial baseline

RTS columns often depend on a previous utility event. A newly introduced maintenance process can therefore produce unusual recommendations until COPY, REORG, and RUNSTATS baselines exist. Treat the first cycles as calibration.

## Objects loaded with REPLACE LOG NO

Some sites have staging or application-owned objects that are completely replaced on a schedule and can be reloaded at any time. If those objects are intentionally outside this workflow, add them with `EXCLUDE_OBJECT` rather than weakening global thresholds.

Remember that excluding an object from this generator also suppresses COPY generation. Recovery requirements must therefore be satisfied by the owning process or explicitly accepted.

## Db2 system objects

Catalog and directory recovery require dedicated planning. Use IBM's documented procedures and installation jobs as the primary design reference. Do not infer that generic application-object COPY or REORG patterns are appropriate for every DSNDB01/DSNDB06 object.
