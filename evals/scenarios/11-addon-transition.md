This is an offline assessment with fictional controllers and synthetic authoritative
support data. Do not access AWS, Kubernetes, or the web. Read
`.claude/skills/eks-upgrade/steering/addon-compatibility.md` and `report-generation.md`.
Assess current and target compatibility and produce a proposed sequence for each case.
These are independent cases. All controllers are optional OSS add-ons, healthy, and
running on Kubernetes 1.34; target is 1.35.

The following fixture records stand in for successfully fetched upstream support
documentation. No other releases or documented migration paths are available.

1. Controller alpha is installed at 2.0. Upstream explicitly lists:
   - 2.0 supports 1.34, excludes 1.35.
   - 2.5 supports both 1.34 and 1.35.
   - 3.0 supports 1.35, excludes 1.34.
   The migration guide requires a target-compatible controller before the control-plane
   upgrade, allows 2.0 → 2.5, and requires updating CRDs before the controller.
   Version 3.0 is the newest release.
2. Controller beta is installed at 2.0. Its only releases are 2.0 (1.34 only) and
   3.0 (1.35 only). The guide requires a target-compatible controller before the
   control-plane upgrade. No transition procedure is documented.
3. Controller gamma is installed at 3.0. Documentation explicitly excludes 1.34
   and supports 1.35. Health checks are passing. No outage has been observed.
4. Controller delta is installed at 2.5. Documentation confirms 1.35 support but
   gives no information about 1.34. A fallback lookup for 1.34 was unavailable.
5. A managed add-on's installed version is compatible with target 1.35, according
   to complete applicable API results. Its per-add-on 1.34 lookup returns AccessDenied.

For each case report existing versus upgrade-introduced concerns, any target deduction,
Unassessed entries, and whether a pre-upgrade replacement is actually verified.
Describe the sequence without executing or inventing install commands.

Write the evaluation to `evals/outputs/11-addon-transition-report.md`.
