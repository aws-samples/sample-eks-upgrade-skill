I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: edge-services
- Region: ap-southeast-1
- Account: 555666777888
- Current Version: 1.32
- Target Version: 1.33
- Cluster Status: ACTIVE
- Assessment Date: 2026-05-09 15:00

## Findings from Assessment

### Version Validation (Step 1)
- Current: 1.32, Target: 1.33 — valid one-hop upgrade
- 1.32 is in STANDARD support (ends March 23, 2027)
- Node groups all at 1.32, skew against target = 1 (within policy)

### Breaking Changes (Step 2)
- Endpoints API Deprecated (target >= 1.33): MEDIUM severity
  - 2 custom Endpoints resources found (excluding default kubernetes endpoint)

### Deprecated APIs (Step 3)
- No removed APIs for 1.33

### Add-on Compatibility (Step 4)
- vpc-cni v1.21.0: ACTIVE, COMPATIBLE
- coredns v1.11.6: ACTIVE, COMPATIBLE
- kube-proxy v1.32.1: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.55.0: ACTIVE, COMPATIBLE
- Karpenter: not installed

### Node Readiness (Step 5)
- 1 node group: edge-ng, version 1.32, AL2023, t3.small, 4/4/8 scaling
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (3 available), subnet-bbb (12 available)
  - subnet-aaa has < 5 IPs — HARD BLOCKER

### Workload Risks (Step 6)
- 5 deployments in non-system namespaces:
  - edge-proxy: replicas=4, RollingUpdate, probes present, requests present
  - auth-service: replicas=2, RollingUpdate, probes present, requests present
  - rate-limiter: replicas=2, RollingUpdate, probes present, requests present
  - cache-warmer: replicas=1, RollingUpdate, probes present, requests present
  - log-shipper: replicas=2, RollingUpdate, no probes, requests present
- PDBs exist for edge-proxy, auth-service, rate-limiter
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 4 insights, all PASSING

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.33 target

## Instructions

Generate the full report to file: `evals/outputs/04-subnet-exhausted-report.md`
