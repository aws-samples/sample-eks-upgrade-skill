This is an offline score-reporting evaluation. Do not call AWS, Kubernetes, MCP, or
the web. Read `.claude/skills/eks-upgrade/steering/report-generation.md` and apply
its score display and reconciliation rules to the independent cases below.
All supplied deductions are already verified category totals AFTER category caps;
do not re-derive findings or invent additional deductions. Unknown checks have
already been excluded. No case has a preflight failure unless explicitly stated.

For each case produce only the readiness headline, Score summary table, and the
Score Breakdown Total row. Explain adjustments using the supplied evidence.

| Case | Assessed category deductions | Verified hard blockers | Unassessed |
|------|-----------------------------|------------------------|------------|
| A | None | None | None |
| B | Karpenter 10; workload risks 4 | Karpenter incompatible with target | None |
| C | Breaking changes 25; deprecated APIs 20; add-ons 5 | User-written API removed in target; critical EBS CSI DEGRADED | None |
| D | Node readiness 2 | None | Deprecated API reads denied |
| E | Add-ons 5; workload risks 10 | Critical EBS CSI DEGRADED | Current-version add-on compatibility read denied |
| F | Breaking changes 25; deprecated APIs 20; node readiness 20; add-ons 15; Karpenter 10; workload risks 10; insights 10; AL2 5; unsupported version 15 | Karpenter incompatible with target | None |
| G | Breaking changes 25 | None | Deprecated API reads denied |

Finally, case H halted during preflight because the Kubernetes connection points to
a different cluster. No assessment has run. State the permitted output.

Write the evaluation to `evals/outputs/13-score-transparency-report.md`.
