# Contributing Guidelines

Thank you for your interest in contributing to our project. Whether it's a bug report, new feature, correction, or additional
documentation, we greatly value feedback and contributions from our community.

Please read through this document before submitting any issues or pull requests to ensure we have all the necessary
information to effectively respond to your bug report or contribution.


## Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check existing open, or recently closed, issues to make sure somebody else hasn't already
reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything unusual about your environment or deployment


## Contributing via Pull Requests
Contributions via pull requests are much appreciated. Before sending us a pull request, please ensure that:

1. You are working against the latest source on the *main* branch.
2. You check existing open, and recently merged, pull requests to make sure someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your time to be wasted.

To send us a pull request, please:

1. Fork the repository.
2. Modify the source; please focus on the specific change you are contributing. If you also reformat all the code, it will be hard for us to focus on your change.
3. Ensure local tests pass.
4. Commit to your fork using clear commit messages.
5. Send us a pull request, answering any default questions in the pull request interface.
6. Pay attention to any automated CI failures reported in the pull request, and stay involved in the conversation.

GitHub provides additional document on [forking a repository](https://help.github.com/articles/fork-a-repo/) and
[creating a pull request](https://help.github.com/articles/creating-a-pull-request/).


## Finding contributions to work on
Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels (enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any 'help wanted' issues is a great place to start.


## Dual-Copy Model (read before editing skill content)

This repository ships the same skill **twice**, targeting two different runtimes with two different contracts:

| | Parent — Claude Code | Port — DevOps Agent |
|---|---|---|
| Root | `.claude/skills/eks-upgrade/` | `DevOpsAgent/` |
| Assessment logic | `steering/*.md` | `references/*.md` |
| OSS add-on registry | `data/oss_addon_registry.json` | `assets/oss_addon_registry.json` |
| HTML converter | `tools/md_to_html.py` | *(none — report is rendered inline)* |
| Skill definition | `SKILL.md` | `SKILL.md` *(intentionally different)* |

**Every content fix must land in BOTH copies.** The two copies share most prose but diverge intentionally on directory names (`steering/` vs `references/`), the tool-vs-no-tool story, the CLI-form vs API-form of the same call, and Claude-Code-vs-DevOps-Agent framing. `SKILL.md` and the two READMEs are deliberately divergent (different runtime contracts) and are **not** reconciled.

**File mapping** (fix these as pairs):

- `steering/<name>.md` ↔ `references/<name>.md` — the 8 assessment files (`addon-compatibility`, `breaking-changes`, `deprecated-apis`, `node-readiness`, `report-generation`, `upgrade-insights`, `version-validation`, `workload-risks`)
- `data/oss_addon_registry.json` ↔ `assets/oss_addon_registry.json`

Do **not** blindly copy one file over the other — make the *same logical fix* in each, matching that copy's surrounding wording and paths.

### Before you push

Run the reconciliation reporter, then diff the copies yourself:

```bash
misc/sync-copies.sh            # human-readable report of every divergence
misc/sync-copies.sh --check    # CI gate: exit non-zero on newly-drifted lines
```

**What `--check` does — and does not — catch.** `--check` compares each mapped file pair and fails when a *differing line* matches neither a known-intentional pattern (`misc/sync-divergences.txt`) nor the per-file accepted baseline (`misc/sync-baseline.txt`). It catches one thing well: a **new one-copy edit to an already-mapped line** that drifts the two copies apart, and (since the hardening) a **mapped file that is missing on one side**. It does **not** prove the copies are in sync. A green `--check` is silent about, at minimum:

- **Baselined twins** — if a line's divergent counterpart is already frozen in the baseline, deleting or further editing that line can still pass.
- **Matching deletions** — a change that removes the same content from both copies (or leaves both untouched) produces no differing line to flag.
- **Unmapped content** — text in files outside the mapped `steering/` ↔ `references/` set (SKILL.md, the READMEs, prose the mapping does not glob) is never compared.
- **`--update-baseline` widens the blind spot** — every line you freeze is a line `--check` will no longer inspect, so re-baseline only after a human diff, never to silence a failure you have not read.

**The mirror-proof is the dual-copy diff, not the green check.** Before you push, and in every PR that touches skill content, diff the two copies of each changed file and confirm every remaining difference is an intentional divergence — treat a green `--check` as a regression tripwire for already-mapped lines, never as evidence that a fix landed in both copies:

```bash
git diff --no-index .claude/skills/eks-upgrade/steering/<name>.md \
                    DevOpsAgent/references/<name>.md
```

Once the fix is in both copies and every remaining divergence is confirmed intentional, re-freeze the baseline with `misc/sync-copies.sh --update-baseline` and commit the updated `misc/sync-baseline.txt` alongside your change.

## Code of Conduct
This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).
For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact
opensource-codeofconduct@amazon.com with any additional questions or comments.


## Security issue notifications
If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


## Licensing

See the [LICENSE](LICENSE) file for our project's licensing. We will ask you to confirm the licensing of your contribution.
