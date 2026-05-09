I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: clean-prod
- Region: us-west-2
- Account: 123456789012
- Current Version: 1.31
- Target Version: 1.32
- Cluster Status: ACTIVE
- Assessment Date: 2026-05-09 15:00

## Findings from Assessment

### Version Validation (Step 1)
- Current: 1.31, Target: 1.32 — valid one-hop upgrade
- 1.31 is in EXTENDED support (ends November 26, 2026) — assessment date is before that
- Node groups all at 1.31, skew against target = 1 (within policy)

### Breaking Changes (Step 2)
- No breaking changes apply for target 1.32

### Deprecated APIs (Step 3)
- No deprecated or removed APIs found in cluster

### Add-on Compatibility (Step 4)
- vpc-cni v1.19.2: ACTIVE, COMPATIBLE
- coredns v1.11.4: ACTIVE, COMPATIBLE
- kube-proxy v1.31.4: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.40.0: ACTIVE, COMPATIBLE
- No OSS add-ons found
- Karpenter: not installed

### Node Readiness (Step 5)
- 1 node group: clean-prod-ng, version 1.31, AL2023, t3.large, 3/3/6 scaling
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (52 available), subnet-bbb (48 available), subnet-ccc (61 available)

### Workload Risks (Step 6)
- 4 deployments in default namespace, all have: replicas >= 2, RollingUpdate, readiness+liveness probes, cpu+mem requests
- All multi-replica deployments have matching PDBs
- No DaemonSets or StatefulSets in non-system namespaces
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 4 insights, all PASSING

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.32 target

## Instructions

Generate the full report to file: `evals/outputs/01-clean-cluster-report.md`
