# Choosing a gem

See the rule in `AGENTS.md`. This is the methodology and the worked examples
behind it.

## The process

1. **Name the need**, not a gem. "Detect N+1 queries in tests" is a need;
   "add bullet" is skipping straight to an answer.
2. **Find at least one real alternative.** Search for existing comparisons
   ("X vs Y ruby gem", "X alternatives") before reading either gem's own
   pitch - a maintainer's README undersells its competitors by default.
3. **Check maintenance, not just features.** Run `bin/still_active` (or check
   the gem's RubyGems/GitHub page by hand: last release date, last commit,
   open issues the maintainer responds to, archived banner). A gem with more
   features but no commits since 2019 loses to a leaner, current one - the
   features don't help once it stops getting security fixes.
4. **Check the license fits how the gem is actually used here** (dev/test
   tooling vs. something that ships in production; copyleft on a shipped
   dependency is a different conversation than copyleft on a local dev tool).
5. **Write the comparison down** as a Gemfile comment: what you picked, what
   you compared it against, and the concrete reason. The next person (human
   or agent) reading the Gemfile shouldn't have to redo this research.

## Worked examples from this repo

| Need | Chosen | Compared against | Why |
|---|---|---|---|
| Ruby style linter/formatter | `standard` (+ `standard-rails`) | staying on `rubocop-rails-omakase` | Both are "just pick one, stop bikeshedding" configs built on RuboCop. Standard is the more actively-adopted community default (2.9k GitHub stars vs. omakase's few hundred), ships its own bundled performance plugin, and has the same `.rubocop_todo.yml`-style adoption path via `--generate-todo`/`ignore:`. `standard-minitest`/`standard-thread_safety` exist as Standard plugins for the two cop gems we still wanted, but both are single-maintainer wrappers stale since March 2025 - failed our own "actively maintained" bar - so `rubocop-minitest`/`rubocop-thread_safety` are required directly via `.standard_ext.yml` instead. |
| HTML+ERB linting | `herb-embedded` | `herb`'s own `lint` command | `herb lint` shells out to `npx @herb-tools/linter` (Node) every run; this app deliberately keeps Node off its stack (importmap-rails, `tailwindcss-ruby`). `herb-embedded` runs the same upstream rule engine inside Ruby via an embedded JS runtime - no Node, no per-run `npx` install. |
| Architecture boundaries | `archspec` | `packwerk` | Packwerk expects the app already split into packages with `package.yml` per package - a large upfront restructuring. ArchSpec checks boundaries against the app's existing directory layout as-is and has a `--update-todo` brownfield-adoption flow, so it fit a codebase that isn't already modularized. |
| Unused-method detection | `debride` | (none found actively competing in this niche) | Documented as exploratory-only regardless (see `docs/llms/development.md`) - static analysis can't see Rails' dynamic dispatch (callbacks, `respond_to`, view-called helpers), so every hit needs a human to confirm before deleting anything. |
| Complexity/churn hotspot ranking | `skunk` | rolling a custom `git log` + `flog`/`flay` script | Skunk already combines exactly those signals (plus Reek) into one ranked score. **Caveat surfaced by `still_active` after adding it:** several of Skunk's own transitive dependencies (`virtus`, `coercible`, `axiom-types`, `ice_nine`, `descendants_tracker`, `thread_safe`) are abandoned, last touched 2013-2017. They're dev-only, pure Ruby, and carry no known vulnerabilities, so the practical risk is low - but this is the "gem smell" check catching exactly the kind of thing it's meant to catch. Worth a second look before this is treated as settled; a hand-rolled `flog`+`flay`+churn script has zero such baggage if Skunk's transitive tail becomes a real problem. |
| Property-based testing | `prop_check` | `rantly` | Both have zero external dependencies. PropCheck's shrinking (reducing a failing case to the smallest one that still fails) is the more complete implementation of the two, and it documents explicit Minitest/RSpec/test-unit integration; Rantly needs a hand-rolled Minitest adapter and its own docs note its shrinking is weaker. |
| Mutation testing | `mutineer` | `mutant` | `mutant` is the best-known tool in this space, but its free tier's license excludes closed-source/commercial use in practice, and it carries 6 runtime dependencies plus a separate `mutant-minitest` adapter gem. Mutineer is Prism + Ruby stdlib only (zero runtime deps, needs Ruby >= 3.4), has first-class `--rails`/`--daemon` support with a fork-safe per-worker SQLite test DB, and `--since`/`--baseline` scope a run to a diff - relevant for adopting mutation testing on an app that already has years of code, instead of mutating everything on day one. |
| Fuzz testing | `ruzzy` | `afl-ruby`, `kisaten` | The AFL-based Ruby fuzzers are both last-released years ago. Ruzzy is actively maintained (Trail of Bits shipped LibAFL support in 2026) and is - per its own README - "currently the only production-ready coverage-guided fuzzer for Ruby." Not wired into CI/lefthook here: it compiles a C extension against libFuzzer, which needs a full LLVM/clang build this sandbox doesn't have. See `fuzz/README.md`. |
| Dependency health / "gem smell" checks | `still_active` | `holepicker` | Holepicker only re-covers `bundler-audit`'s CVE ground (last released 2016, itself unmaintained by the standard this whole exercise is about). `still_active` is actively released, adds the maintenance signals neither `bundler-audit` nor `bundle outdated` provide (last-commit activity, archived-repo detection, OpenSSF Scorecard, poison-pill transitive caps), and ships CI gate flags plus a `--baseline` diff mode built for exactly this kind of adoption-into-an-existing-app rollout. |

## Codifying it

- `bin/still_active` + `still_active_baseline.json`: a `still_active
  --baseline=still_active_baseline.json` job runs in `lefthook.yml`'s
  pre-commit (only when `Gemfile*` is staged) and in `config/ci.rb` - so
  adding or bumping a gem gets an automatic maintenance-health check, not a
  rule that only lives in this doc. It fails only on a *regression* against
  the committed baseline (new critical/archived/vulnerable dependency), not
  on the pre-existing findings - update the baseline
  (`bin/still_active --json > still_active_baseline.json`) once a finding is
  actually addressed or consciously accepted.
- The `AGENTS.md` rule is the enforcement point for the "compare candidates,
  write it down" half of this - a linter can check a gem's health, but not
  whether you actually looked at an alternative first.
