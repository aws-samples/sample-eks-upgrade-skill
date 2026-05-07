# Version Validation & Upgrade Path

## Purpose
Validate the upgrade path, determine support status, and enforce EKS upgrade rules.

## EKS Version Support Calendar (as of March 2026)

| Version | Standard Support Until | Extended Support Until | Status |
|---------|----------------------|----------------------|--------|
| 1.35 | March 27, 2027 | March 27, 2028 | ✅ STANDARD (latest) |
| 1.34 | December 2, 2026 | December 2, 2027 | ✅ STANDARD |
| 1.33 | July 29, 2026 | July 29, 2027 | ✅ STANDARD |
| 1.32 | March 23, 2026 | March 23, 2027 | ✅ STANDARD |
| 1.31 | November 26, 2025 | November 26, 2026 | ⚠️ EXTENDED |
| 1.30 | July 23, 2025 | July 23, 2026 | ⚠️ EXTENDED |
| 1.29 | March 23, 2025 | March 23, 2026 | 🔴 EXTENDED (ending soon) |

**CRITICAL:** The `upgradePolicy.supportType` field from the API is a CONFIGURATION PREFERENCE, not the current billing status. Always determine actual support status from the calendar above.

**Cost impact:** Extended support costs $0.60/hr vs $0.10/hr for standard support.

**IMPORTANT — Cost Calculation Formula (do NOT estimate, always compute):**
```
extra_cost_per_month = (0.60 - 0.10) × 730 = $365/month per cluster
total_extended_cost  = 0.60 × 730 = $438/month per cluster
total_standard_cost  = 0.10 × 730 = $73/month per cluster
```
Always use this formula. Do NOT round, estimate, or hallucinate cost figures.
730 = average hours per month (365 days × 24 hours ÷ 12 months).

## Checks to Execute

### 1.1 — Current Version & Support Status

**How to check:**
1. Describe the cluster → get `version` and `platformVersion`
2. Match version against the calendar table above
3. Report: version, support status, when current support period ends

**Output:** Current version, support tier, cost implications if on extended support.

### 1.2 — Upgrade Path Validation

**Rules:**
- EKS requires upgrading **one minor version at a time** (e.g., 1.30 → 1.31, not 1.30 → 1.32)
- Downgrades are not supported
- Same-version "upgrades" are invalid

**How to check:**
1. Parse current version (from cluster describe) and target version (from user input)
2. Calculate version difference: `target_minor - current_minor`
3. If difference == 1: valid direct upgrade
4. If difference > 1: show required upgrade path (e.g., 1.29 → 1.30 → 1.31 → 1.32)
5. If difference <= 0: invalid (same version or downgrade)

**Output:** Valid/invalid path, required intermediate steps if multi-hop.

### 1.3 — Version Skew Policy Check

**Rules (Kubernetes version skew policy):**
- kubelet can be at most N-2 relative to the control plane
- If control plane is upgraded to target version, nodes must be within 2 minor versions

**How to check:**
1. List all node groups → describe each for Kubernetes version
2. List nodes via Kubernetes API → get kubelet versions from `status.nodeInfo.kubeletVersion`
3. For each node/node group version, calculate skew against the TARGET version (not current)
4. Skew > 2: **BLOCKER** — nodes must be upgraded first
5. Skew == 2: **WARNING** — at maximum skew, upgrade nodes promptly after control plane

**Output:** Per-node-group version, skew against target, blocker/warning status.

## Score Impact

| Finding | Deduction | Severity |
|---------|-----------|----------|
| On extended support | 0 (informational) | INFO |
| Multi-hop upgrade needed | 0 (informational) | INFO |
| Node skew == 2 (warning) | 5-10 pts | MEDIUM |
| Node skew > 2 (blocker) | 20 pts | CRITICAL |
