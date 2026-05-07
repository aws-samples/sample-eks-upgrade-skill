# Node Readiness

## Purpose
Assess node groups, AMI types, version alignment, and migration requirements for the target version.

## Checks to Execute

### 5.1 — Node Group Inventory

**How to check:**
1. List all managed node groups → describe each for:
   - Kubernetes version
   - AMI type (AL2, AL2023, AL2_ARM_64, BOTTLEROCKET_x86_64, etc.)
   - Instance types
   - Scaling config (min/max/desired)
   - Capacity type (ON_DEMAND, SPOT)
   - Health status
2. List nodes via Kubernetes API → get:
   - `status.nodeInfo.kubeletVersion`
   - `status.nodeInfo.osImage`
   - `status.nodeInfo.kernelVersion`
   - `status.nodeInfo.containerRuntimeVersion`
   - Labels: `topology.kubernetes.io/zone`, `node.kubernetes.io/instance-type`
3. Check for Karpenter NodePools (`nodepools.karpenter.sh`)
4. Check for EKS Auto Mode (`computeConfig` in cluster describe)

**Output per node group:**
- Name, version, AMI type, instance types, scaling config
- Version skew against target (calculated in version-validation)

### 5.2 — AL2 to AL2023 Migration Assessment

**Why this matters:**
- AL2 standard support ended June 2025
- EKS 1.33+ does NOT publish AL2 AMIs — cannot create new AL2 node groups
- AL2 uses cgroup v1; AL2023 uses cgroup v2 (required for EKS 1.35+)

**How to check:**
1. From node group descriptions, identify AMI type
2. From node Kubernetes API, check `kernelVersion` for `amzn2` or `osImage` for `Amazon Linux 2`
3. Count AL2 nodes and node groups

**Rating:**
- No AL2 nodes → PASS
- AL2 nodes present, target < 1.33 → WARN (plan migration)
- AL2 nodes present, target >= 1.33 → FAIL (blocker — no AL2 AMI available)

**Migration guidance:**
1. Create new node group with AL2023 AMI type
2. Cordon old AL2 nodes: `kubectl cordon <node-name>`
3. Drain workloads: `kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data`
4. Delete old node group after all pods rescheduled
5. Key differences: cgroup v2 default, dnf instead of yum, different kernel

### 5.3 — Container Runtime Version

**How to check:**
1. List nodes → `status.nodeInfo.containerRuntimeVersion`
2. Check for containerd 1.x vs 2.x

**Rating:**
- All nodes on containerd 2.x → PASS
- Any node on containerd 1.x, target < 1.35 → WARN (plan upgrade)
- Any node on containerd 1.x, target >= 1.35 → WARN (last supported version, next will block)

### 5.4 — Self-Managed Nodes

**How to check:**
1. List all nodes
2. Compare against managed node group nodes (by labels or node group membership)
3. Nodes not in any managed node group or Karpenter → self-managed

**Rating:**
- No self-managed nodes → PASS
- Self-managed nodes present → WARN (no automated upgrade path, manual AMI update required)

## Score Impact

| Finding | Deduction |
|---------|-----------|
| AL2 nodes (target < 1.33) | 2-5 pts |
| AL2 nodes (target >= 1.33) | 10-15 pts |
| Containerd 1.x | 2 pts |
| Self-managed nodes | 3 pts |
| Max category (combined with version-validation skew) | 20 pts |
