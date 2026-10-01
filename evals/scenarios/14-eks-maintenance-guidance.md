This is an offline evaluation. Do not call AWS, Kubernetes, MCP, or the web.
Read the skill's node-readiness.md, workload-risks.md, and report-generation.md.
Use the synthetic evidence below. These are independent cases; do not combine scores.
All omitted scoring checks pass and all reads succeed unless stated otherwise.
No actual upgrade or remediation is authorized.

For each case explain the decision, score where requested, and maintenance advice.
Distinguish documented AWS behavior from assessment scoring policy.

1. **Subnet counts:** Two cluster subnets report 3 and 12 available IPv4 addresses.
   Security-group connectivity and subnet reservations have not been inspected.
   Calculate node-category points and calculated/final scores. What does the
   address evidence establish about whether EKS can update the control plane?
2. **Low total:** Repeat with 1 and 2 available addresses. Give the category
   points, calculated/final scores, and explain what the blocker actually means.
3. **Partial evidence:** One subnet reports 3 available addresses; the read for
   the second subnet was denied. Can the total-capacity guard be evaluated?
4. **Default node update:** A managed group spans five AZs, uses the DEFAULT
   strategy and maxUnavailable=1. The operator has budgeted for one extra node.
   Is that assumption justified? No precise IP-demand simulation is available.
5. **Minimal node update:** Repeat with MINIMAL. Explain capacity and application
   availability implications without changing the group's strategy.
6. **Prefix proposal:** A subnet has 24 free individual IPv4 addresses scattered
   across the subnet and no free contiguous /28. An operator proposes prefix
   delegation to reduce each pod's IP consumption. Assess that proposal.
7. **Fargate rollback:** Control plane 1.34 was upgraded from 1.33 two days ago.
   All worker nodes are Fargate, their kubelets are 1.34, and there are no managed
   node groups. Rollback Insights reports a kubelet-skew ERROR. The operator asks
   whether control-plane rollback is categorically unsupported and whether the
   existing Fargate nodes will downgrade in place. Give an advisory plan only.
8. **Dormant application:** Deployment archived-api has desired replicas=0,
   no live pods, Recreate strategy, no readiness probe, and no resource requests.
   It has no external Service or Ingress. Calculate its existing Category 6
   score impact and explain which activity would expose the configuration risks.
9. **Active singleton:** Deployment ledger has one healthy replica, RollingUpdate,
   probes and requests, no external Service, and a fresh PDB with maxUnavailable=0,
   expectedPods=currentHealthy=desiredHealthy=1, disruptionsAllowed=0. Its Running
   non-terminating pod is on the node being replaced; only this PDB selects it.
   Explain the PDB's purpose and calculate the existing workload deductions.

Write the evaluation to `evals/outputs/14-eks-maintenance-guidance-report.md`.
