# Breaking Changes Detection

## Purpose
Identify version-specific breaking changes that affect ACTUAL resources in the cluster. Only flag a breaking change if the cluster has resources that will be impacted.

## Principle
Every breaking change entry must be written in consultant-advisory style:
- **What we found** in YOUR cluster and why it matters
- **Real-world impact** if not addressed before upgrade
- **Concrete remediation** with commands where applicable

Do NOT list generic Kubernetes release notes. Only report changes that affect resources actually present in the cluster.

## Version-Specific Breaking Changes

### Target >= 1.25: PodSecurityPolicy Removed

**Check:** List PodSecurityPolicy resources via Kubernetes API
- If PSPs exist → HIGH severity. PSPs will cease to exist after upgrade.
- Remediation: Migrate to Pod Security Standards (PSS) by labeling namespaces: `kubectl label namespace <ns> pod-security.kubernetes.io/enforce=restricted`

### Target >= 1.29: FlowSchema API v1beta2 Removed

**Check:** Scan cluster resources for `apiVersion: flowcontrol.apiserver.k8s.io/v1beta2`
- Look at FlowSchema and PriorityLevelConfiguration resources
- If found → MEDIUM severity. Update to `flowcontrol.apiserver.k8s.io/v1`

### Target >= 1.32: FlowSchema API v1beta3 Removed

**Check:** Scan for `apiVersion: flowcontrol.apiserver.k8s.io/v1beta3`
- If found → HIGH severity. Update to `flowcontrol.apiserver.k8s.io/v1`

### Target >= 1.32: Anonymous Auth Restricted

**Always flag** (MEDIUM severity) — affects all clusters upgrading to 1.32+.
- Anonymous requests only allowed to /healthz, /livez, /readyz
- Check: `kubectl get clusterrolebindings -o json | jq '.items[] | select(.subjects[]?.name=="system:unauthenticated")'`
- Impact: Monitoring tools or LB health checks hitting non-health endpoints will get 401

### Target >= 1.33: Endpoints API Deprecated

**Check:** List Endpoints resources (exclude the default `kubernetes` endpoint)
- If custom Endpoints exist → MEDIUM severity
- Remediation: Migrate to EndpointSlices API (`discovery.k8s.io/v1`)

### Target >= 1.33: AL2 AMI Not Available

**Check:** List nodes → inspect `status.nodeInfo.kernelVersion` for `amzn2` or `osImage` for `Amazon Linux 2`
- If AL2 nodes found → HIGH severity. Cannot create new AL2 node groups for 1.33+
- Remediation: Migrate to AL2023 or Bottlerocket BEFORE upgrading control plane

### Target >= 1.34: AppArmor Deprecated

**Check:** Scan deployments/daemonsets/statefulsets for AppArmor annotations in pod template
- If found → MEDIUM severity
- Remediation: Migrate to seccomp profiles

### Target >= 1.35: Cgroup v1 Support Removed

**Always flag** (HIGH severity) for 1.35 targets.
- kubelet refuses to start on cgroup v1 nodes unless `failCgroupV1=false`
- AL2 uses cgroup v1 by default; AL2023 and Bottlerocket use cgroup v2
- Check node OS to determine impact

### Target >= 1.35: Containerd 1.x End of Support

**Check:** List nodes → inspect `status.nodeInfo.containerRuntimeVersion`
- If any node shows containerd 1.x → MEDIUM severity
- Last release supporting containerd 1.x; next version requires 2.0+

### Target >= 1.35: Ingress NGINX Retired

**Check:** List deployments/daemonsets with `ingress-nginx` or `nginx-ingress` in name
- If found → HIGH severity. No more security patches.
- Remediation: Migrate to Gateway API or AWS Load Balancer Controller

### Target >= 1.35: IPVS Proxy Mode Deprecated

**Check:** Read kube-proxy ConfigMap → check `mode` field
- If `mode: ipvs` → MEDIUM severity. Removal planned for 1.36.
- Remediation: Switch to iptables or nftables mode

### Target >= 1.35: --pod-infra-container-image Flag Removed

**Always flag** (LOW severity) for 1.35 targets.
- Affects custom AMIs with this kubelet flag in bootstrap scripts
- EKS-managed AMIs are not affected

## Score Impact

| Severity | Per-item Deduction | Max Category |
|----------|-------------------|--------------|
| HIGH | 10 pts | 25 pts total |
| MEDIUM | 4 pts | |
| LOW | 2 pts | |
