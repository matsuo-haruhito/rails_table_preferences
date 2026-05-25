# AGENTS

This file is a maintainer-oriented guide for agents or contributors working in this repository.

## Start here

Read these in order before changing docs or behavior summaries:

1. [`README.md`](README.md)
2. [`docs/index.md`](docs/index.md)
3. [`Product Profile.md`](Product%20Profile.md)
4. the focused `docs/*.md` page closest to the feature you are touching
5. [`CHANGELOG.md`](CHANGELOG.md) when release framing matters

## Source of truth

Use this priority when deciding whether documentation needs to move:

1. current code
2. focused docs closest to the feature contract
3. high-level summaries in `README.md`, `docs/index.md`, and `Product Profile.md`
4. roadmap or release framing text

Do not document planned behavior as already shipped.

If code and docs disagree and the correct behavior is not clear from the repository, stop and ask for human confirmation instead of inventing a contract.

## Repository shape

This repository is a Rails engine/gem for server-rendered Rails applications.

Main areas:

- `app/`: engine assets, controllers, helpers, views, and JavaScript
- `config/`: engine routes, locale files, and generator wiring
- `lib/`: configuration, models, services, adapters, generators, and rake tasks
- `docs/`: feature-level integration and maintenance documentation
- `README.md`: public overview and installation entrypoint
- `Product Profile.md`: durable product framing for maintainers

## What this repository owns

Rails Table Preferences owns:

- table preference editor behavior
- saved display preference settings and preset scope resolution
- filter/sort UI state and adapter params
- export payload metadata
- generators and copy-based customization paths
- baseline accessibility hooks for the bundled controls

Host applications still own:

- database query execution
- authorization and business logic
- final table markup decisions around grouped headers and advanced sticky layouts
- CSV/Excel/report generation
- complex admin UI for shared preset management
- product-specific styling and UX

Keep that boundary visible in docs. Avoid drifting into query-builder, admin-framework, or export-generator promises.

## Documentation expectations

When updating high-level docs, keep these files aligned:

- `README.md`
- `docs/index.md`
- `Product Profile.md`
- the focused feature doc for the changed area

Typical focused docs include:

- `docs/quick_start.md`
- `docs/decision_guide.md`
- `docs/scoped_presets.md`
- `docs/fixed_columns_and_groups.md`
- `docs/export_integration.md`
- `docs/controller_integration.md`
- `docs/javascript_entrypoints.md`
- `docs/demo.md`
- `docs/manual_qa.md`
- `docs/release_checklist.md`
- `docs/troubleshooting.md`
- `docs/non_goals.md`

Prefer small, reviewable docs updates. Do not rewrite unrelated sections just for tone consistency.

## Release and verification baseline

The current lightweight verification baseline described by the repo is:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
bundle exec rake package:verify
```

Before release, docs also expect:

- green GitHub Actions on the release commit
- one sandbox or demo verification pass
- package inspection via `docs/package_verification.md`
- README/docs consistency against released behavior

## Safe editing rules

- Do not add helpers, APIs, or generator behavior to docs unless the code or focused docs already support them.
- Do not collapse host-app responsibilities into gem responsibilities for convenience.
- Keep README concise as a public entrypoint; push detailed operating guidance into `docs/`.
- Keep `Product Profile.md` about product framing, not step-by-step setup.
- Keep `AGENTS.md` about maintainer workflow and source-of-truth rules, not user-facing onboarding.
- If a docs gap requires code changes to become true, stop and note that the repo is code-ahead-of-docs only once the implementation exists.

## When adding docs

Good additions for this repo include:

- copyable host-app integration examples grounded in existing helpers or adapters
- clearer responsibility boundaries where host apps often over-assume gem ownership
- release, QA, troubleshooting, or demo guidance that reflects current behavior
- maintainer-facing entry documents such as `Product Profile.md` when they help keep README and focused docs consistent

Avoid adding:

- speculative product direction presented as committed scope
- host-app-specific architecture or design-system rules as if they were universal
- broad roadmap promises without existing repository support
