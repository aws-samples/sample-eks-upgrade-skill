I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: legacy-platform
- Region: us-east-1
- Account: 222333444555
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
- gitRepo Volume Removed (target >= 1.36): HIGH severity
  - 1 Deployment (`config-loader`) uses a `gitRepo` volume in its pod template
- Service externalIPs Deprecated (target >= 1.36): LOW severity
  - 1 Service uses `spec.externalIPs`

### Deprecated APIs (Step 3)
- No removed APIs in use for 1.36

### Add-on Compatibility (Step 4)
- vpc-cni v1.21.0: ACTIVE, COMPATIBLE
- coredns v1.13.2: ACTIVE, COMPATIBLE
- kube-proxy v1.35.0: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.56.0: ACTIVE, COMPATIBLE
- Karpenter: not installed

### Node Readiness (Step 5)
- 1 node group: legacy-ng — **self-managed** (custom AMI), version 1.35
- Nodes are on **containerd 1.7.x** (custom AMI pinned to containerd 1.x)
- Node type: self-managed / custom AMI (NOT an EKS managed node group)
- Subnet IPs: subnet-aaa (40 available), subnet-bbb (38 available)
- containerd 1.x on self-managed nodes with target 1.36 → HARD BLOCKER (kubelet 1.36 won't run on containerd 1.x; custom AMI must be rebuilt with containerd 2.0+)

### Workload Risks (Step 6)
- 3 deployments in non-system namespaces:
  - config-loader: replicas=2, RollingUpdate, probes present, requests present (also has gitRepo volume - counted in Breaking Changes)
  - api-server: replicas=3, RollingUpdate, probes present, requests present
  - batch-runner: replicas=1, RollingUpdate, no probes, requests present
- PDBs exist for config-loader, api-server
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 4 insights, all PASSING

### AL2 / Behavioral
- No AL2 nodes (custom AMI is AL2023-based but pinned to containerd 1.x)
- No other behavioral changes

## Instructions

Generate the full report to file: `evals/outputs/06-k8s-136-selfmanaged-containerd-report.md`
