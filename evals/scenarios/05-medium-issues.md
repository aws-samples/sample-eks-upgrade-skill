I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: staging-apps
- Region: us-east-2
- Account: 999888777666
- Current Version: 1.30
- Target Version: 1.31
- Cluster Status: ACTIVE
- Assessment Date: 2026-05-09 15:00

## Findings from Assessment

### Version Validation (Step 1)
- Current: 1.30, Target: 1.31 — valid one-hop upgrade
- 1.30 is in EXTENDED support (ends July 23, 2026) — assessment date is before that
- Node groups all at 1.30, skew against target = 1 (within policy)

### Breaking Changes (Step 2)
- No breaking changes apply for the 1.30 → 1.31 hop. (Anonymous Auth Restriction fires only
  when the upgrade crosses INTO 1.32+, so it does NOT apply here.)

### Deprecated APIs (Step 3)
- flowcontrol.apiserver.k8s.io/v1beta3 FlowSchema: deprecated but still served in 1.31, 5 resources — LOW (1 API path)
- flowcontrol.apiserver.k8s.io/v1beta3 PriorityLevelConfiguration: deprecated but still served in 1.31, 3 resources — LOW (1 API path)
- **Step 3b writer-identity scan (managedFields):** both API paths have a user-tool writer of v1beta3, so they are REAL findings (not false positives):
  - `flowschemas`: `default-flowschema` has `managedFields` entry `manager=kubectl-client-side-apply, apiVersion=flowcontrol.apiserver.k8s.io/v1beta3`
  - `prioritylevelconfigurations`: `custom-plc` has `managedFields` entry `manager=helm, apiVersion=flowcontrol.apiserver.k8s.io/v1beta3`
  - (No internal APF-controller-only objects among the counted paths.)

### Add-on Compatibility (Step 4)
- vpc-cni v1.18.5: ACTIVE, UPDATE_RECOMMENDED (behind but compatible)
- coredns v1.11.4: ACTIVE, COMPATIBLE
- kube-proxy v1.30.2: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.45.0: ACTIVE, UPDATE_RECOMMENDED (behind but compatible)
- external-dns v0.14.0: COMPATIBLE (verified via upstream)
- Karpenter: not installed

### Node Readiness (Step 5)
- 2 node groups: staging-ng-1 (1.30, AL2023, t3.medium, 3/3/5), staging-ng-2 (1.30, AL2023, t3.large, 2/2/4)
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (22 available), subnet-bbb (19 available), subnet-ccc (31 available)

### Workload Risks (Step 6)
- 8 deployments in non-system namespaces:
  - web-frontend: replicas=3, RollingUpdate, probes present, requests present
  - api-backend: replicas=2, RollingUpdate, probes present, requests present
  - worker-queue: replicas=2, RollingUpdate, probes present, requests present
  - cron-scheduler: replicas=1, RollingUpdate, probes present, requests present (single replica)
  - legacy-importer: replicas=1, Recreate, no probes, no requests (single replica + recreate + no probes + no requests)
  - report-generator: replicas=2, RollingUpdate, no probes, requests present
  - email-sender: replicas=2, RollingUpdate, probes present, requests present
  - admin-panel: replicas=1, RollingUpdate, probes present, requests present (single replica)
- PDBs exist for web-frontend, api-backend, worker-queue
- No PDB for report-generator or email-sender (multi-replica without PDB)
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 6 insights, all PASSING (no WARNING/ERROR insights for this hop)

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.31

## Expected Score Calculation (for verification)

- Breaking Changes: none apply (Anonymous Auth only fires target >= 1.32). Total: 0
- Deprecated APIs: 2 API paths deprecated but still served, BOTH with user-tool writers (Step 3b) = 1+1 = 2 pts. Capped at 20. Total: 2
- Node Readiness: skew=1 (ok), all subnets >15. Total: 0
- Add-on: 2 UPDATE_RECOMMENDED = 1+1 = 2 pts. Capped at 15. Total: 2
- Karpenter: not installed. Total: 0
- Workload HIGH: cron-scheduler(3) + legacy-importer(3+3) + admin-panel(3) = 12 → cap 8
- Workload MEDIUM: legacy-importer(1+1) + report-generator(1) + report-generator no PDB(1) + email-sender no PDB(1) = 5 → cap 4
- Workload total: min(8+4, 10) = 10
- Insights: all PASSING = 0. (Any insight that merely confirms the deprecated-API finding is suppressed to 0 per the no-double-count rule; here all insights are PASSING anyway.) Total: 0
- AL2: 0
- Behavioral: 0
- Unsupported: 0
- Total deductions: 0+2+0+2+0+10+0+0+0+0 = 14
- Score: 100-14 = 86%
- Hard blocker check: no blockers (APIs are deprecated-but-served, NOT removed-in-target) → no override
- Final: 86% GOOD

## Instructions

Generate the full report to file: `evals/outputs/05-medium-issues-report.md`
