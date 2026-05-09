I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: payment-prod
- Region: us-east-1
- Account: 987654321098
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
- No breaking changes apply for target 1.31

### Deprecated APIs (Step 3)
- No deprecated or removed APIs found in cluster

### Add-on Compatibility (Step 4)
- vpc-cni v1.20.4: ACTIVE, COMPATIBLE
- coredns v1.11.4: ACTIVE, COMPATIBLE
- kube-proxy v1.30.14: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.53.0: ACTIVE, COMPATIBLE
- Karpenter v0.37.0 installed — INCOMPATIBLE with K8s 1.31 (requires >= 1.0.5)

### Node Readiness (Step 5)
- 1 node group: payment-prod-ng, version 1.30, AL2023, t3.medium, 2/2/4 scaling
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (35 available), subnet-bbb (42 available)

### Workload Risks (Step 6)
- 3 deployments in default namespace:
  - order-service: replicas=3, RollingUpdate, probes present, requests present
  - payment-api: replicas=2, RollingUpdate, probes present, requests present
  - notification-worker: replicas=1, RollingUpdate, no probes, requests present
- No DaemonSets or StatefulSets in non-system namespaces
- No drain-blocking PDBs
- PDB exists for order-service and payment-api

### AWS Upgrade Insights (Step 7)
- 5 insights, all PASSING

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.31 target

## Instructions

Generate the full report to file: `evals/outputs/02-karpenter-blocker-report.md`
