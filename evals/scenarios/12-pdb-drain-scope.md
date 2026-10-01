This is an offline assessment. Do not access AWS, Kubernetes, or the web. Read
`.claude/skills/eks-upgrade/steering/workload-risks.md` and `report-generation.md`.
Assess only the drain-blocking PDB rule; do not infer other workload findings.

The user plans to upgrade worker group A only. Node a-1 belongs to A; b-1 belongs
to B. All PDBs and workloads below are in namespace apps. Selectors match exactly
the pods stated, each owned by its named Deployment. All pods are Running,
non-terminating, and scheduled unless specified. All reads succeed. Each PDB has
generation 4 and observedGeneration 4 unless noted. Values are synthetic.

| PDB | Spec | expectedPods | currentHealthy | desiredHealthy | disruptionsAllowed | Matching pods |
|-----|------|--------------|----------------|----------------|--------------------|---------------|
| paused | minAvailable: 1 | 0 | 0 | 1 | 0 | None; Deployment replicas=0 |
| recovering | minAvailable: 2 | 3 | 2 | 2 | 0 | Two Ready pods on a-1; one not Ready on b-1 |
| restrictive | maxUnavailable: 0 | 3 | 3 | 3 | 0 | Three Ready pods on a-1 |
| other-group | maxUnavailable: 0 | 2 | 2 | 2 | 0 | Two Ready pods on b-1 |
| exempt | maxUnavailable: 0; unhealthyPodEvictionPolicy: AlwaysAllow | 2 | 1 | 2 | 0 | One not Ready on a-1; one Ready on b-1 |
| stale | maxUnavailable: 0 | 2 | 2 | 2 | 0 | Two Ready on a-1; observedGeneration=3 |
| inconsistent | minAvailable: 1 | 0 | 1 | 1 | 0 | One Ready on a-1; same inconsistency after one reread |
| percentage | minAvailable: \"100%\" | 2 | 2 | 2 | 0 | Two Ready on a-1 |

Default unhealthy-pod eviction policy applies unless explicitly set. All workload
replica counts match expectedPods except the inconsistent case. For every PDB state
whether it contributes points, the restriction type if any, and the recommended action.
Give the uncapped PDB subtotal and the final Category 6 subtotal assuming no other
workload risks. List unknown checks separately.

Then evaluate recovering independently with node-maintenance scope unspecified.
The caller is an autonomous runtime and no further user input is available.

Write the evaluation to `evals/outputs/12-pdb-drain-scope-report.md`.
