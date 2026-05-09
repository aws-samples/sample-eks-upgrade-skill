I'm testing the EKS upgrade skill scoring logic with mock data. Do NOT run any aws or kubectl commands. Use the findings below as if you had already executed all checks.

Read `.claude/skills/eks-upgrade/steering/report-generation.md` for the scoring algorithm and report template, then generate the report.

## Cluster Metadata

- Cluster: data-platform
- Region: eu-west-1
- Account: 111222333444
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
- Anonymous Auth Restricted (target >= 1.32): MEDIUM severity
  - Found 1 ClusterRoleBinding granting access to system:unauthenticated for a monitoring endpoint

### Deprecated APIs (Step 3)
- flowcontrol.apiserver.k8s.io/v1beta3 FlowSchema: removed in 1.32, 3 resources found — HIGH severity
- flowcontrol.apiserver.k8s.io/v1beta3 PriorityLevelConfiguration: removed in 1.32, 2 resources found — HIGH severity

### Add-on Compatibility (Step 4)
- vpc-cni v1.19.0: ACTIVE, COMPATIBLE
- coredns v1.11.4: ACTIVE, COMPATIBLE
- kube-proxy v1.31.2: ACTIVE, COMPATIBLE
- aws-ebs-csi-driver v1.48.0: DEGRADED — controller pods crash-looping, no IAM credentials
- Karpenter: not installed

### Node Readiness (Step 5)
- 2 node groups: data-ng-1 (1.31, AL2023, m5.xlarge, 3/3/6), data-ng-2 (1.31, AL2023, r5.2xlarge, 2/2/4)
- All nodes on containerd 2.x
- No self-managed nodes
- Subnet IPs: subnet-aaa (28 available), subnet-bbb (31 available), subnet-ccc (45 available)

### Workload Risks (Step 6)
- 6 deployments in non-system namespaces:
  - spark-driver: replicas=1, RollingUpdate, probes present, requests present
  - kafka-consumer: replicas=3, RollingUpdate, probes present, requests present
  - api-gateway: replicas=2, RollingUpdate, probes present, requests present
  - batch-processor: replicas=1, Recreate, no probes, no requests
  - monitoring-dashboard: replicas=2, RollingUpdate, probes present, requests present
  - data-ingestion: replicas=3, RollingUpdate, no probes, requests present
- PDBs exist for kafka-consumer, api-gateway, monitoring-dashboard
- No drain-blocking PDBs

### AWS Upgrade Insights (Step 7)
- 6 insights: 5 PASSING, 1 WARNING (deprecated FlowSchema APIs, flagged for 1.32)

### AL2 / Behavioral
- No AL2 nodes
- No behavioral changes for 1.32 beyond Anonymous Auth (already counted in Breaking Changes)

## Instructions

Generate the full report to file: `evals/outputs/03-degraded-addon-report.md`
