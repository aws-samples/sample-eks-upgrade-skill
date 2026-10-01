This is an offline evaluation. Do not call AWS, Kubernetes, MCP, or the web.
Read the skill's workload-risks.md and report-generation.md. Assess only PDB
drain risks; assume all other scoring checks pass. No maintenance is authorized.

The maintenance scope is node group A. Node a-1 belongs to A; b-1 belongs to B.
Each case below is independent. PDBs and pods are in namespace apps except where
stated. All reads are complete. PDB generation and observedGeneration are 4.
All pods are Running, Ready, non-terminating, and on a-1 unless stated otherwise.
Every PDB status has expectedPods=3, currentHealthy=3, desiredHealthy=2, and
disruptionsAllowed=1 unless overridden; remaining selected pods exist on b-1.

For each case, identify affected PDBs/pods, raw PDB points, capped Category 6
points, any Unassessed checks, and whether a hard-blocker score cap applies.
Explain the owner action. Do not add points per pod or per pair.

1. **Positive budgets:** p1 and p2 both select the same three api pods through
   matchLabels app=api. Two api pods run on a-1 and one on b-1.
2. **Two causes:** Repeat case 1, but p1 has maxUnavailable=0,
   desiredHealthy=3, disruptionsAllowed=0. p2 still allows one disruption.
3. **Outside scope:** Repeat case 1, with all three selected pods on b-1.
4. **Unhealthy exemption:** Repeat case 1, but the two a-1 pods are not Ready.
   Both PDBs specify AlwaysAllow, currentHealthy=1, desiredHealthy=2,
   disruptionsAllowed=0.
5. **No candidate eviction:** Repeat case 1, except one a-1 pod is Pending and
   the other already has deletionTimestamp. The remaining pod is on b-1.
6. **Complete selectors:** p1 has an empty policy/v1 selector. p2 uses
   matchExpressions tier In [api] AND maintenance DoesNotExist.
   A pod on a-1 has labels tier=api, maintenance=hold; the only pods selected
   by both PDBs are on b-1. Then independently remove maintenance=hold from
   the a-1 pod and assess again.
7. **Budget freshness:** Repeat case 1 with p2 observedGeneration=3.
   Current selectors and pod/node reads succeeded; assess the structural
   overlap and budget-status coverage separately.
8. **Namespace boundary:** p1 in apps and p2 in another namespace have the
   same selector. The three selected pods in apps exist as in case 1.
   p2 protects three healthy pods in its own namespace, all on b-1.
9. **Partial inventory:** The PDB list failed with Forbidden; a cached snapshot
   contains p1. Current pod reads succeed. Assess whether that proves either
   overlap or absence of overlap.

Write the evaluation to `evals/outputs/15-overlapping-pdbs-report.md`.
