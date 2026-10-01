This is an offline preflight evaluation. Do not call AWS, kubectl, MCP, or the web.
Read `.claude/skills/eks-upgrade/SKILL.md` and apply its preflight to each independent
case below. Treat the supplied data as mocked tool results. Explain whether to
proceed, ask for input, or halt; identify the connection and the next permissible
operation. Do not generate a readiness score. No configuration changes are authorized.

The user selected production-eks in ap-southeast-1. DescribeCluster returned ACTIVE,
ARN arn:aws:eks:ap-southeast-1:123456789012:cluster/production-eks, and endpoint
https://production.example.invalid. Target is a valid single-hop upgrade. Unless
otherwise stated, all later permissions would succeed.

1. Current context is named `production-eks`, but its server is
   https://development.example.invalid. It is the only configured context.
2. Current context `development` points at development.example.invalid. Another
   context `operations-alias` points at https://production.example.invalid/.
   These are the only contexts; the user has not named a context.
3. Current context points at development. Two other contexts have the production
   endpoint: `production-reader` uses user `reader`, and `production-admin` uses
   user `admin`. The user has not selected either credential.
4. MCP is being used. Its Kubernetes tool offers a `connectionId`, but the available
   metadata does not identify that connection's cluster, account, region, or endpoint.
   Local kubectl points at production.
5. A connection to production has been verified and explicitly selected. Its
   deployment-list permission probe returns Forbidden. The user chooses to continue
   with a partial assessment if that is permitted.

Also evaluate cases 1, 4, and 5 under `DevOpsAgent/SKILL.md`, interpreting case 1
as an Agent Space connection whose display name is production but whose verified
endpoint is development. Explain any interaction difference.

Write the evaluation to `evals/outputs/09-cluster-identity-report.md`.
