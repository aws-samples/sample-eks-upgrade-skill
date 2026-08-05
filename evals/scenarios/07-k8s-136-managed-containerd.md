I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

This scenario is the CONTRAST to scenario 06: same containerd 1.x runtime, same target 1.36,
but the nodes are EKS-managed instead of self-managed. The expected outcome is that containerd
1.x here is NOT a hard blocker — managed node groups pull containerd 2.0+ automatically when
upgraded to 1.36. It should be reported as INFO, and the score should NOT be capped at 59%.

## Cluster Metadata

- Cluster: managed-platform
- Region: us-east-1
- Account: 666777888999
- Current Version: 1.35
- Target Version: 1.36
- Cluster Status: ACTIVE
- Assessment Date: 2026-06-18 15:00

## Findings from Assessment

### Version Validation (Step 1)
- Current: 1.35, Target: 1.36 — valid one-hop upgrade
- 1.35 is in STANDARD support (ends March 27, 2027)
- 1.36 exists on EKS (released June 2, 2026, STANDARD support)
- Node groups all at 1.35, skew against target = 1 (within policy)

### Breaking Changes (Step 2)
- No breaking changes apply (no gitRepo volumes, no IPVS mode, no externalIPs, canonical IPs)

### Deprecated APIs (Step 3)
- No removed APIs in use for 1.36

### Add-on Compatibility (Step 4)
- vpc-cni v1.21.0: ACTIVE, COMPATIBLE
- coredns v1.13.2: ACTIVE, COMPATIBLE
- kube-proxy v1.35.0: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.56.0: ACTIVE, COMPATIBLE
- Karpenter: not installed

### Node Readiness (Step 5)
- 1 node group: managed-ng — **EKS managed node group**, AL2023, version 1.35
- Nodes currently report **containerd 1.7.x** (older AL2023 AMI release)
- Node type: EKS managed node group (NOT self-managed, NOT custom AMI)
- Subnet IPs: subnet-aaa (40 available), subnet-bbb (38 available)
- containerd 1.x on a MANAGED node group with target 1.36 → warning-tier (INFO-severity)
  finding, +2 under Category 3 (NOT a hard blocker, does NOT cap the score). Upgrading the
  node group to 1.36 replaces the AMI and pulls containerd 2.0+ automatically.

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
- No behavioral changes

## Instructions

The report should explicitly note the containerd runtime jump happens automatically during
node group upgrade (managed node group is exempt from the containerd-1.x hard blocker).

Generate the full report to file: `evals/outputs/07-k8s-136-managed-containerd-report.md`
