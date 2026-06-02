# Rails and Ruby support matrix

Use this guide when deciding whether Rails Table Preferences fits a host application's Ruby and Rails baseline.

## Runtime requirements

| Area | Current requirement | Source |
| --- | --- | --- |
| Ruby | 3.1 or later | `rails_table_preferences.gemspec` (`spec.required_ruby_version`) |
| Rails | 7.0 or later, below 9.0 | `rails_table_preferences.gemspec` (`spec.add_dependency "rails", ">= 7.0", "< 9.0"`) |
| Development Gemfile | Rails 8.0.x | `Gemfile` |

The gemspec is the package-level compatibility contract. The development Gemfile is the repository's current default development baseline, not the only supported host-app Rails version.

## Representative pull-request CI

Pull requests run the default package and test job plus representative Rails compatibility lanes.

| CI job | Ruby | Rails / Gemfile | What it represents |
| --- | --- | --- | --- |
| RSpec, JavaScript syntax, gem build, and package verification | 3.3 | development `Gemfile` / Rails 8.0.x | Current repository development baseline, package build, and package contents |
| PR Rails compatibility (7.0) | 3.1 | `gemfiles/rails_7_0.gemfile` | Lower-bound Rails 7.0 regression check |
| PR Rails compatibility (7.1) | 3.2 | `gemfiles/rails_7_1.gemfile` | Representative Rails 7.1 regression check |
| PR Rails compatibility (7.2) | 3.2 | `gemfiles/rails_7_2.gemfile` | Representative Rails 7.2 regression check |
| PR Rails compatibility (8.0) | 3.3 | `gemfiles/rails_8_0.gemfile` | Current Rails 8.0 compatibility check |

This matrix is representative CI coverage for this repository. It is not a blanket promise that every newer Rails release is continuously exercised here.

## Evaluating newer host-app Rails releases

If a host app uses a newer release, such as Rails 8.1, treat that as additional host-app verification before assuming parity with the CI-covered matrix.

A compact verification path is:

1. Generate the demo screen with [Demo screen generator](demo.md) and confirm the bundled editor surface, scoped preset examples, current scope context summary, and export payload preview.
2. Use [Sandbox Rails app verification](sandbox.md) to confirm install, engine mount, copied/package JavaScript and CSS, and end-to-end preference wiring in a minimal app.
3. Run [Manual QA checklist](manual_qa.md) in the real host app to verify authentication, authorization, layout, accessibility, and existing search/export integration.

## What the matrix does not cover

Host applications still own:

- authorization and tenant/business rules
- database query behavior and joins
- CSV, Excel, and report file generation
- custom ERB/CSS/JavaScript overrides
- final browser and accessibility checks in application-specific layouts

Use [Package verification](package_verification.md) and [Release checklist](release_checklist.md) before tagging or publishing a release.
