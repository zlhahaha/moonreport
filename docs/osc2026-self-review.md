# OSC 2026 self-review

Review date: 2026-07-28.

This review follows the local `osc2026-guide` checklist. It distinguishes
locally verifiable facts from publication steps that require external accounts.

| Check | Status | Evidence or action |
| --- | --- | --- |
| Valid open-source project | Pass | Original MoonBit developer library; Apache-2.0 |
| Ecosystem overlap | Pass with search limitation | `docs/ecosystem-survey.md`; no equivalent complete package found |
| MoonBit is the main implementation | Pass | All runtime implementation and tests are `.mbt` |
| Scale is meaningful | In progress | 2,114 physical MoonBit lines now; concrete 4k-5.5k acceptance roadmap |
| Strict local check | Pass | `moon check --deny-warn` |
| Format, build, and tests | Pass | `moon fmt --check`, `moon build`, 39 tests |
| Runnable example | Pass | `moon run cmd/main` |
| Cross-platform CI definition | Pass | Ubuntu and Windows matrix in `.github/workflows/ci.yml` |
| Latest hosted CI run | Pending publication | Requires pushing the repository to GitHub |
| Public GitHub repository | Pending publication | Planned URL is in `moon.mod` |
| Public GitLink mirror | Pending publication | Create after GitHub publication |
| Published on mooncakes.io | Pending publication | Publish after public repository and release validation |
| Proposal matches repository | Pass | Proposal uses current features and labels future scope explicitly |
| Clean repository | Pass | Build, editor, environment, coverage, and render artifacts ignored |
| Meaningful history | Pass | 13 feature-sized commits before proposal/audit commits |

## Timing warning

The bundled competition charter lists development through 2026-07-10 and
acceptance during 2026-07-11 to 2026-07-17. This review occurs on 2026-07-28,
so those dates have passed. Publication should proceed only after confirming
with the organizers that late submission, a supplemental round, or another
submission window is available.

## Publication gate

Before declaring the entry fully eligible:

1. create an empty public GitHub repository named `moonreport` and push `main`;
2. verify the hosted CI matrix is green;
3. create and synchronize the required GitLink repository;
4. publish the package to mooncakes.io and verify its public package page;
5. update this file and the proposal from “planned” to the actual public URLs;
6. tag the exact reviewed commit and retain the successful CI run link.
