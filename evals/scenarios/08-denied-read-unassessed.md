I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

In this scenario one category's backing Kubernetes read was denied by RBAC. Treat the findings exactly as recorded below — do not assume the denied read would have been clean.

## Cluster Metadata

- Cluster: partial-access
- Region: us-east-1
- Account: 123456789012
- Current Version: 1.33
- Target Version: 1.34
- Cluster Status: ACTIVE
- Assessment Date: 2026-07-10 15:00

## Findings from Assessment

### Version Validation (Step 1)
- Current: 1.33, Target: 1.34 — valid one-hop upgrade
- 1.33 is in STANDARD support (ends July 29, 2026) — assessment date is before that
- Node groups all at 1.33, skew against target = 1 (within policy)

### Breaking Changes (Step 2)
- No breaking changes apply for target 1.34 (no gitRepo volumes, no IPVS mode, no externalIPs)

### Deprecated APIs (Step 3)
- The read backing this check was DENIED. `kubectl get` across the API-group discovery
  and the per-resource `managedFields` listing returned:
  `Error from server (Forbidden): flowschemas.flowcontrol.apiserver.k8s.io is forbidden:
  User "assessor" cannot list resource "flowschemas" in API group
  "flowcontrol.apiserver.k8s.io" at the cluster scope`
- No deprecated-API data could be collected — the same 403 applies to every API-group
  listing needed for this check, so nothing about removed/deprecated API usage could be
  determined for this cluster.

### Add-on Compatibility (Step 4)
- vpc-cni v1.21.0: ACTIVE, COMPATIBLE
- coredns v1.12.1: ACTIVE, COMPATIBLE
- kube-proxy v1.33.0: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.56.0: ACTIVE, COMPATIBLE
- Karpenter: not installed

### Node Readiness (Step 5)
- 1 node group: app-ng, version 1.33, AL2023, m5.xlarge, 3/3/6 scaling
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (12 available), subnet-bbb (40 available), subnet-ccc (55 available)

### Workload Risks (Step 6)
- 3 deployments in non-system namespaces:
  - web-app: replicas=3, RollingUpdate, probes present, requests present
  - api-gateway: replicas=2, RollingUpdate, probes present, requests present
  - worker: replicas=2, RollingUpdate, probes present, requests present
- PDBs exist for all three
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 4 insights, all PASSING

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.34 target

## Instructions

Generate the full report to file: `evals/outputs/08-denied-read-unassessed-report.md`
