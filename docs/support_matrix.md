# Rails and Ruby support matrix

Use this guide when deciding whether Rails Table Preferences fits a host application's Ruby and Rails baseline.

## Runtime requirements

| Area | Current requirement | Source |
| --- | --- | --- |
| Ruby | 3.1 or later | `rails_table_preferences.gemspec` (`spec.required_ruby_version`) |
| Rails | 7.0 or later, below 9.0 | `rails_table_preferences.gemspec` (`spec.add_dependency "rails", ">= 7.0", "< 9.0"`) |
| Development Gemfile | Rails 8.0.x | `Gemfile` |
| JavaScript CI runtime | Node.js 20 for repository syntax and package-entrypoint checks | `.github/workflows/ci.yml` |

The gemspec is the package-level compatibility contract. The development Gemfile is the repository's current default development baseline, not the only supported host-app Rails version. The Node.js version above is the repository CI runtime for JavaScript syntax and package verification checks, not a package-level promise for every host-app bundler or Node version.

## Representative pull-request CI

Pull requests run the default package and test job plus representative Rails compatibility lanes.

| CI job | Ruby | Rails / Gemfile | What it represents |
| --- | --- | --- | --- |
| RSpec, JavaScript syntax, gem build, and package verification | 3.3 | development `Gemfile` / Rails 8.0.x | Current repository development baseline, package build, package contents, JavaScript package entrypoint smoke coverage, and packaged declaration metadata checks |
| PR Rails compatibility (7.0) | 3.1 | `gemfiles/rails_7_0.gemfile` | Lower-bound Rails 7.0 regression check |
| PR Rails compatibility (7.1) | 3.2 | `gemfiles/rails_7_1.gemfile` | Representative Rails 7.1 regression check |
| PR Rails compatibility (7.2) | 3.2 | `gemfiles/rails_7_2.gemfile` | Representative Rails 7.2 regression check |
| PR Rails compatibility (8.0) | 3.3 | `gemfiles/rails_8_0.gemfile` | Current Rails 8.0 compatibility check |

This matrix is representative CI coverage for this repository. It is not a blanket promise that every newer Rails release is continuously exercised here.

## JavaScript package entrypoint coverage

The default CI job sets up Node.js 20 and checks the copied Stimulus controller plus the package root and controller entrypoints with `node --check`. It then builds the gem and runs `bundle exec rake package:verify`, which verifies that the packaged `package.json` export targets point at files included in the built gem.

Current package metadata also exposes minimal TypeScript declaration targets for `rails_table_preferences` and `rails_table_preferences/controller`. Package verification checks that those `.d.ts` files ship in the gem, that `package.json` `types` / `exports.types` targets point at packaged files, and that declaration re-exports resolve to packaged declaration files.

RSpec also includes package-entrypoint smoke coverage for importing `rails_table_preferences` and `rails_table_preferences/controller` in a minimal Node sandbox. Together, those checks guard repository syntax, package metadata, export target presence, declaration target presence, and representative package-entrypoint behavior.

Host applications still own final bundler integration. Vite, custom jsbundling, resolver aliases for `rails_table_preferences` / `rails_table_preferences/controller`, and richer TypeScript declarations for host-app replacement controllers should be verified in the host app with [JavaScript entrypoints](javascript_entrypoints.md), [Package verification](package_verification.md), and the app's own frontend build.

## Evaluating newer host-app Rails releases

If a host app uses a newer release, such as Rails 8.1, treat that as additional host-app verification before assuming parity with the CI-covered matrix.

A compact verification path is:

1. Generate the demo screen with [Demo screen generator](demo.md) and confirm the bundled editor surface, scoped preset examples, current scope context summary, and export payload preview.
2. Use [Production integration checklist](production_integration_checklist.md) to bridge the working demo or quick start into a real host-app index screen, including owner, route, query params, authorization, layout, and export boundaries.
3. Use [Sandbox Rails app verification](sandbox.md) to confirm install, engine mount, copied/package JavaScript and CSS, and end-to-end preference wiring in a minimal app.
4. Run [Manual QA checklist](manual_qa.md) in the real host app to verify authentication, authorization, layout, accessibility, and existing search/export integration.

## What the matrix does not cover

Host applications still own:

- authorization and tenant/business rules
- database query behavior and joins
- CSV, Excel, and report file generation
- custom ERB/CSS/JavaScript overrides
- package-entrypoint resolver aliases, app-specific TypeScript declarations beyond the packaged minimal entrypoint declarations, and final frontend bundler compatibility
- final browser and accessibility checks in application-specific layouts

Use [Package verification](package_verification.md) and [Release checklist](release_checklist.md) before tagging or publishing a release.
