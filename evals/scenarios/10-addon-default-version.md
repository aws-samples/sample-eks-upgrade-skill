This is an offline assessment with synthetic versions. Do not access AWS, Kubernetes,
or the web. Read `.claude/skills/eks-upgrade/steering/addon-compatibility.md` and
`report-generation.md`. Evaluate each independent managed-add-on case below.
Return the current and target compatibility, target verdict, Category 4 deduction,
and recommended action. These are independent cases, not eight add-ons in one cluster.

Current Kubernetes is 1.34; target is 1.35. The add-on is optional, healthy, ACTIVE,
and is not kube-proxy. All returned rows match the add-on name and the relevant
architecture, platform, and compute type. Current-version lookups are complete
and include the installed build in every case. There are no documented update
recommendations beyond the default flags described below.

| Case | Installed | Target API results |
|------|-----------|--------------------|
| A | v1.20.2-eksbuild.1 | Complete: installed build plus v1.20.1-eksbuild.1, which is the target default |
| B | v1.20.1-eksbuild.1 | Complete: installed is target default; v1.20.2-eksbuild.1 also compatible |
| C | v1.19.6-eksbuild.1 | Complete: installed plus target default v1.20.1-eksbuild.1 |
| D | v1.20.1-eksbuild.10 | Page 1: target default v1.20.1-eksbuild.9, nextToken present. Page 2: installed build, no nextToken. Both pages supplied successfully |
| E | v1.20.2-eksbuild.1 | Complete: installed is compatible with target, but its default=true entry is for 1.34; default for 1.35 is v1.20.1-eksbuild.1 |
| F | v1.20.2-eksbuild.1 | Complete: installed plus v1.20.3-eksbuild.1; no default flags |
| G | v1.18.0-eksbuild.1 | Complete: only target default v1.20.1-eksbuild.1 |
| H | v1.20.2-eksbuild.1 | Page 1: only v1.20.1-eksbuild.1; fetching nextToken fails with AccessDenied |

Do not infer an install sequence from these results; no candidate's current-version
compatibility or migration instructions have been supplied.

Write the evaluation to `evals/outputs/10-addon-default-version-report.md`.
