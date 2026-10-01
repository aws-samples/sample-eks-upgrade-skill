# Workload Risks

## Purpose
Assess workload resilience during the upgrade process. These are not upgrade blockers but affect the safety and smoothness of the upgrade.

## CRITICAL: Systematic Enumeration Rule

You MUST follow this process to avoid miscounting. Do NOT count from memory.

### Step A: Build the Master Workload Table

Before checking ANY risk, build a single table of ALL workloads in non-system namespaces.

**Non-system namespaces to EXCLUDE:** kube-system, kube-public, kube-node-lease, karpenter,
amazon-cloudwatch, amazon-guardduty, aws-observability.

**Workload types to INCLUDE:** Deployments, StatefulSets, DaemonSets.

**How to build the table:**
1. List ALL Deployments across all namespaces
2. List ALL StatefulSets across all namespaces
3. List ALL DaemonSets across all namespaces
4. Filter out workloads in system namespaces listed above
5. For EACH remaining workload, extract from its spec:
   - `name`, `namespace`, `kind` (Deployment/StatefulSet/DaemonSet)
   - `replicas` (for Deployments/StatefulSets; DaemonSets run on all nodes)
   - `strategy.type` (Deployments only: RollingUpdate or Recreate)
   - For EACH container: `readinessProbe` (present/absent), `livenessProbe` (present/absent),
     `resources.requests.cpu` (value or absent), `resources.requests.memory` (value or absent)

**Output format — you MUST produce this table before proceeding:**

```
| # | Name | Kind | NS | Replicas | Strategy | Probes | Requests | Notes |
|---|------|------|----|----------|----------|--------|----------|-------|
| 1 | app-a | Deployment | default | 3 | RollingUpdate | ✅ readiness+liveness | ✅ cpu+mem | |
| 2 | app-b | Deployment | default | 1 | Recreate | ❌ none | ❌ none | single-replica, recreate |
| 3 | mon-agent | DaemonSet | default | N/A | N/A | ❌ none | ✅ cpu+mem | |
```

### Step B: Check Each Risk Against the Table

Walk through each check below. For every finding, reference the row number from the table.
This prevents miscounting and ensures no workload is missed.

## Checks to Execute

### 6.1 — Single Replica Deployments and StatefulSets

**Why this matters:** Node drains during upgrade will cause downtime for single-replica workloads.

**How to check:** From the master table, filter for `kind IN (Deployment, StatefulSet) AND replicas == 1`. StatefulSets are collected in the master table (Step A above) and are scored identically to single-replica Deployments in `report-generation.md` — do NOT restrict this check to Deployments only, or single-replica StatefulSets will be collected but never scored.

**Rating:** Each match = HIGH severity (3 pts in score).

### 6.2 — Missing Pod Disruption Budgets

**Why this matters:** Without PDBs, node drain can evict all pods simultaneously.

**How to check:**
1. List PodDisruptionBudgets across all namespaces
2. From the master table, filter for `kind == Deployment AND replicas > 1` in non-system namespaces
3. Cross-reference: which multi-replica deployments have NO matching PDB?
4. Check for **drain-blocking PDBs** (see 6.2b below)

**IMPORTANT:** Only flag missing PDBs for workloads with replicas > 1. A PDB on a single-replica
deployment is meaningless — do NOT flag single-replica workloads for missing PDBs.

**Rating:** Each missing PDB on multi-replica deployment = MEDIUM severity (1 pt).

### 6.2b — Drain-Blocking PDBs (upgrade stall risk)

**Why this matters:** PDBs can prevent voluntary eviction during node maintenance.
`disruptionsAllowed: 0` alone does not establish that this upgrade's node drain will stall.

**How to check (read-only; never test by draining or evicting):**
1. Resolve each PDB's namespace and complete label selector (`matchLabels` AND
   `matchExpressions`) to actual pods and their owning workloads. For `policy/v1`, an
   empty selector matches all pods in that namespace. Do not infer coverage from names.
   Record `expectedPods`, `currentHealthy`, `desiredHealthy`, `disruptionsAllowed`,
   `observedGeneration`, and `unhealthyPodEvictionPolicy` (default: `IfHealthyBudget`).
2. Require fresh status (`status.observedGeneration == metadata.generation`). Missing,
   stale, inconsistent, or denied status/pod/node data is UNKNOWN / not-scored for this
   check, listed in Unassessed; do not substitute a spec-only scoring rule.
3. If `expectedPods == 0` AND there are no matching live pods, record “no protected pods
   currently present” and deduct 0 for this PDB. Scaling a Deployment to zero is not a
   PDB drain obstruction. Do not interpret zero as missing data, or assume intentionality.
   If expectedPods is zero but matching live pods exist, recheck once; if still inconsistent,
   report UNKNOWN rather than a clean pass. Require `expectedPods > 0` for a scored risk.
4. Establish the node-maintenance scope. For a specified node group, use matching pods'
   `spec.nodeName` and node-group membership. For a full data-plane upgrade, use all
   nodes in that declared scope. Exclude unscheduled, completed, and already-terminating
   pods from the candidate voluntary evictions. If protected pods exist only outside the
   scope, record no obstruction to THIS scope (0 pts). If scope is unspecified, ask which
   node groups are planned where interaction is available; otherwise list the affected
   nodes as a potential risk and mark drain-scope assessment Unassessed, not a proven stall.
5. When fresh `disruptionsAllowed == 0`, determine whether at least one matching pod on
   an affected node is subject to that restriction. Healthy pods require budget. For
   Running but unhealthy pods, account for `unhealthyPodEvictionPolicy`: `AlwaysAllow`
   permits eviction despite exhausted budget; `IfHealthyBudget` permits it when
   `currentHealthy >= desiredHealthy`. Do not score a PDB if every candidate pod is
   exempt from its restriction. If per-pod eviction eligibility is unclear, report UNKNOWN.
6. Set `confirmed_drain_risk = true` only when ALL preceding gates succeed and at least
   one candidate pod is restricted. Count once per PDB, not per pod, node, or workload.
   Apply the same non-system namespace exclusions as the workload score. Distinguish:
   - **Configured restriction:** the effective policy permits no disruptions even if all
     expected replicas are healthy, e.g. `maxUnavailable: 0` / `"0%"`, or effective
     `minAvailable >= expectedPods` (including `"100%"`). Account for percentage rounding
     and replica count; preferably use the controller's fresh `desiredHealthy` value.
     Waiting for recovery alone will not resolve this; review the availability requirement
     and maintenance procedure with the owner. Do not call it permanently unfixable.
   - **Health-related restriction:** the policy permits disruption at full health, but
     currently insufficient replicas are healthy. Recommend investigating/recovering
     unhealthy replicas and rechecking. Recovery may restore budget; do not promise it.
   - **Other/transient restriction:** recent disruptions or controller state may temporarily
     exhaust budget despite sufficient healthy replicas. Recheck and describe the observed
     state instead of inventing a health failure or prescribing a policy change.

**Report per PDB:** name/namespace, expected and healthy pod counts, allowed disruptions,
status freshness, affected pod/node names, maintenance scope, restriction type, and the
specific next step. Say “may stall node maintenance,” not “control-plane upgrade blocked.”
If policy changes are needed, recommend owner review; never automatically relax the PDB
or emit a blanket `maxUnavailable` patch (it can conflict with an existing `minAvailable`).

**Rating:** Each confirmed drain-risk PDB = MEDIUM severity (2 pts), once per PDB under
Category 6. Empty, out-of-scope, or eviction-exempt cases deduct 0; unknown cases are
Unassessed, not a clean pass. This is NOT a hard blocker and does not cap the score.
Recheck before actual node maintenance because pod health and placement can change.

**Source:** https://kubernetes.io/docs/tasks/run-application/configure-pdb/

### 6.3 — Missing Health Probes

**Why this matters:** Without readiness probes, traffic is sent to pods before they're ready.

**How to check:** From the master table, filter for workloads where ANY container is missing
a `readinessProbe`. Count ALL workload types (Deployments, StatefulSets, AND DaemonSets).

**Rating:** Each workload missing probes = MEDIUM severity (1 pt).

### 6.4 — Missing Resource Requests

**Why this matters:** Without resource requests, pods can't be properly rescheduled during node drains.

**How to check:** From the master table, filter for workloads where ANY container is missing
`resources.requests.cpu` OR `resources.requests.memory`.

**IMPORTANT:** Check the ACTUAL spec data. Do NOT assume a workload has or lacks requests
without verifying. If the deployment spec shows `requests: {cpu: "100m", memory: "128Mi"}`,
that workload HAS requests — do not flag it.

**Rating:** Each workload missing requests = MEDIUM severity (1 pt).

### 6.5 — Recreate Update Strategy

**Why this matters:** Recreate strategy causes full downtime during any rollout.

**How to check:** From the master table, filter for `kind == Deployment AND strategy == Recreate`.

**Rating:** Each match = HIGH severity (3 pts in score).

### 6.6 — Graceful Shutdown Configuration

**Why this matters:** Without preStop hooks, there's a race condition during node drain.

**How to check:**
1. From the master table, identify workloads exposed via Services (especially LoadBalancer type)
2. Check if those workloads have `lifecycle.preStop` hooks
3. Check `terminationGracePeriodSeconds`

**Externally-facing** = a workload backed by a LoadBalancer-type Service OR an Ingress (these receive external traffic and are sensitive to abrupt pod termination); ClusterIP-only workloads are NOT externally-facing.

**Rating:** Missing preStop on externally-facing workloads = MEDIUM severity (1 pt).
**Scoring home:** Category 6 (Workload Risks) MEDIUM — counted in the report-generation.md Category 6 pseudocode, subject to the 4-pt MEDIUM sub-cap.

### Fargate-only cluster caveat

**On a Fargate-only cluster** (no managed/self-managed node groups, no Karpenter nodes),
`kubectl get nodes` and node-group listings return empty. Category 3 (node readiness) is
therefore **N/A** and deducts 0 from empty inputs — this is the absence of nodes to assess,
NOT a clean bill of health. The data-plane assessment then relies entirely on pod-level
signals (preStop hooks, PDBs, readiness/liveness probes) from Category 8 / Category 6. When
reporting, explicitly note that node-level checks were N/A on Fargate and that a high READY
score reflects only what could be assessed from pod-level signals.

## Step C: Compile Findings with Row References

After all checks, produce a findings list that references the master table row numbers:

```
| Finding | Severity | Workloads (by row #) | Count |
|---------|----------|---------------------|-------|
| Single replica | HIGH | #2, #7 | 2 |
| Recreate strategy | HIGH | #2, #5 | 2 |
| Missing probes | MEDIUM | #2, #3, #5, #6, #8 | 5 |
| Missing requests | MEDIUM | #2, #6 | 2 |
```

This makes the count verifiable. If the count doesn't match the listed row numbers, something is wrong.

## Score Impact

> **Canonical scoring is defined in `steering/report-generation.md` §Category 6 (Workload Risks).**

| Finding | Deduction |
|---------|-----------|
| High-severity workload risk (single replica, Recreate) | 3 pts each (sub-cap 8) |
| Medium-severity workload risk (missing probes, requests, PDBs) | 1 pt each (sub-cap 4) |
| Confirmed drain-risk PDB (all §6.2b gates pass) | 2 pts each (sub-cap 4) |
| Max category | 10 pts |
