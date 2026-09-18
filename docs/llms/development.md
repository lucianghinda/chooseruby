## Development Cycle

When implementing a new feature think hard first about what objects will be required or what changes to existing objects will be required and make a plan before writing any code.

Then apply TDD to create the needed changes. Always choose the simplest change.

## OOP

Write OOP in Ruby by focusing on having good objects instead of just services means designing your classes as true objects that embody both data and behavior, rather than mere collections of methods or procedural services.

Objects should be seen as domain entities that exchange messages between them.
Each one is responsible to understand the message and then act accordingly. The caller should not need to know the details of how the object performs its task.

Good objects encapsulate both state and behavior that logically belong together. Instead of creating service classes that manipulate data from outside, let each object manage its own data and provide meaningful methods that reflect real-world actions or domain operations. This increases cohesion and reduces the need for “anemic” objects that just hold data without behavior.​

Model the Domain with Meaningful Entities
Design classes to represent distinct entities or concepts in the domain, each responsible for its own rules and logic. This leads to a rich domain model where objects know how to perform their tasks internally, rather than relying on external services to do the work.​

Avoid Overusing "Service" Objects
While service objects have their place (especially for orchestration and complex workflows), relying on them too much often signals that domain objects are too "thin" or passive. Aim to push logic into the objects themselves and use services sparingly for coordination rather than brute-force behavior implementation.

Encapsulate State Changes and Validations
Objects should manage their own state changes through well-defined interfaces. Encapsulating validation logic and state transitions helps preserve invariants and hides complexity from consumers, making objects more robust and self-sufficient.

## Rails Models

All models should live in app/models and when needed we should create sub-folders there to organise models into domain contexts.
Eg: If we have multiple models related to authorization we should put them under `app/models/authorization`.

Make sure that models are correctly named and that each method has a good descriptive name and purpose.

## Rails Controllers

Keep Controllers Small: Limit controller responsibility to handling HTTP request parsing, authorization, and response formatting.

Avoid embedding business logic or domain rules in the controller layer.

Use the controller as a coordination point that delegates domain operations elsewhere. Each controller action should be concise, ideally orchestrating calls to domain model methods.

Delegate to Domain Model: Encapsulate all business logic and domain rules within domain model objects. Controllers call domain model methods to perform operations or state changes.

Domain models should represent the core business concepts and behaviors.
Separate domain concerns from infrastructure or presentation concerns, keeping the model pure.

## Rails Generation Guidelines

When using an Active Record always use `strict_loading` and make sure you prevent N+1 queries from the design phase.

## Database and Active Record models

Never edit db/schema.rb - always update it by running `bin/rails db:migrate` or `bin/rails db:rollback`

## Static analysis toolchain

Every tool below runs on `bin/ci` (`config/ci.rb`) and on `git push` via `lefthook.yml`
(install once with `bin/setup`, or `bundle exec lefthook install`). `git commit` runs the
fast ones (RuboCop, Reek, Herb) against staged files only.

| Tool | Command | Checks | Status |
|---|---|---|---|
| RuboCop (+ performance/minitest/thread_safety) | `bin/rubocop` | Style | Clean |
| Reek | `bin/reek app` | Code smells | Clean for `app/models`; not yet run on the rest of `app/` - see AGENTS.md |
| Herb | `bin/herb-lint` | ERB/HTML template lint | Not yet clean - 113 offenses as of this writing |
| ArchSpec | `bundle exec archspec check` | Component boundaries, declared in `Archspec.rb` | Clean against `archspec_todo.yml`; burn that list down, don't add to it |
| Brakeman | `bin/brakeman` | Security | Clean |
| bundler-audit / importmap audit | `bin/bundler-audit`, `bin/importmap audit` | Known CVEs in deps | Clean |
| SimpleCov | runs automatically in `bin/rails test` | Test coverage | Enforces a floor (`test/test_helper.rb`), see `docs/llms/testing.md` |
| Prosopite | runs automatically in `bin/rails test` | N+1 queries | Log-only for now, see `docs/llms/n_plus_one_todo.md` |
| debride | `bin/debride app lib` | Likely-unused methods | Exploratory only - high false-positive rate on Rails controller actions/callbacks (dynamic dispatch it can't see), always triage by hand before deleting anything it flags |
| traceroute | `bin/rake traceroute:unused_routes` | Routes with no matching view/controller reference | Exploratory; skip `traceroute:unreachable_action_methods` - it's nearly 100% noise on `Avo::*Controller` subclasses, which inherit hundreds of gem-provided helper methods it can't tell apart from real actions |
| skunk | `bin/skunk app` | Hotspot ranking (churn × complexity × smells) | Exploratory, points at what to refactor first, not a pass/fail gate - see `docs/llms/dependency_selection.md` for a caveat on Skunk's own dependency tail |
| flay | `bin/flay app` | Structural duplication *across* files/classes - Reek's DuplicateMethodCall only catches duplication *within* one method | Exploratory, no fixed threshold - a real codebase never scores 0; used this pass to find the identical FTS-sanitizer/rescue-block/query-includes duplication described in the over-engineering section below |
| still_active | `bin/still_active --baseline=still_active_baseline.json` | Dependency health / "gem smell" (maintenance activity, archived repos, OpenSSF score, poison-pill transitive caps) | Gated on regression only; runs on `Gemfile*` changes via lefthook and on every CI run |
| PropCheck | plain Minitest test files (e.g. `test/models/author_proposal_url_matching_property_test.rb`) | Property-based testing | One example in place; add more as pure functions come up |
| Mutineer | `bin/mutineer run <file> --test <test file> --rails` | Mutation testing (are your tests actually testing anything?) | Exploratory, run by hand against a file you're touching - not wired into CI (mutating the whole app on every push would be far too slow); see `--since`/`--baseline` in its own `--help` for scoping a CI job to a diff later |
| Ruzzy | see `fuzz/README.md` | Fuzz testing | Documented, not installed - needs a full LLVM/clang toolchain this sandbox doesn't have |

When you add a new gem here, add its `bin/<name>` wrapper (see `bin/reek` for the pattern)
and a line to this table, and wire it into `config/ci.rb` and/or `lefthook.yml` as
appropriate for how noisy/slow it is.

## Over-engineering audit

A pass looking specifically for unnecessary classes, dead flexibility, and
duplicated logic - not style (RuboCop/Reek) or architecture boundaries
(ArchSpec), which already have their own tools. See `AGENTS.md`'s
"Avoiding over-engineering" section for the extracted rules and good/bad
examples; this is the log of what was actually found and done about it.

**Fixed this pass** (mechanical, behavior-preserving - full suite stayed green
throughout):

- `GithubAvatarService`, `FtsReindexer`: instantiate-then-delegate ceremony
  around code with no instance state → `module_function`. Same call sites.
- `Authentication::SessionLookup`: a whole extra file/module for one 12-line
  private method with exactly one includer → inlined into `Authentication`.
- `AuthorSearchQuery`/`EntryDirectoryQuery`: identical `sanitize_fts_query`
  (down to the same doc comment) in both classes → extracted to
  `app/queries/concerns/fts_query_sanitizer.rb`, `include`d by both. Also
  dropped the `scope:` constructor keyword arg neither class's callers (in
  `app/` or `test/`) ever passed, and replaced `.yield_self { |c| f(c) }`
  chains with plain sequential calls (`flay`/`git grep` found the dead
  parameter; nothing catches that automatically).
- `Entry::RelatedResources#base_query`, `ResourcesController#related_by_author`,
  `ResourcesController#related_by_topic`: the same 5-line `.includes(...)`
  chain in 3 places → `Entry.with_card_includes` scope.
- `EntriesController`: 8 near-identical `*_params` methods plus an 8-branch
  `case` → one `ENTRYABLE_ATTRIBUTES` hash + one generic method. (Side
  finding, not fixed here since it's a feature gap, not over-engineering:
  this only ever covered 8 of the 19 types in `Entry::VALID_TYPES` - the
  public submission form is missing 11 types Avo already manages. The new
  hash-based structure makes adding them a one-line-per-type change instead
  of a new method each.)
- 4 identical `rescue ActiveRecord::RecordNotFound; render .../404.html...`
  blocks across 3 controllers (found by `bin/flay app`) → one
  `rescue_from` in `ApplicationController`.
- SimpleCov's coverage floor (`test/test_helper.rb`) nudged from 47/32 to
  46/31: deleting duplicate/dead code shrinks the denominator too, so the
  same well-tested code read as a slightly lower percentage. Confirmed this
  is the floor catching its own denominator shift, not new untested code,
  before touching it - see the comment in `test/test_helper.rb`.

**Flagged, not fixed** (needs a design call, not a mechanical extraction):

- `app/avo/resources/{blog,channel,development_environment,directory,
  documentation,framework,job_board,newsletter,product,testing_resource,
  video}.rb` - 11 Avo resource classes with an identical `fields` shape
  (`bin/flay app` mass 517, its single biggest finding). Each also has
  bespoke per-type help text and a description string, so a shared base
  trades ~15 duplicated lines/file for a parameterized one - not obviously
  a win. Worth a second look if a 12th type shows up in the same shape.
- `bin/flay app` also flags several `.html.erb` view-level duplications
  (repeated `if` blocks across `entries/index`, `entries/start`, and
  `resource_types/show`; repeated attribute assignments in
  `home/index.html.erb`) - left for the Herb/view cleanup pass, since fixing
  those means touching the same templates Herb's 112 offenses are already in.
