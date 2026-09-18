## Instructions for LLMs

1. Make sure you load the file `docs/llms.md` and read it all. Never skip reading that file for any task.

## Reek (code smell detector)

- Never disable a detector, weaken a threshold, exclude a path, or suppress an offense without explicit user approval.
- Never add class-wide exclusions to make a folder pass.
- Never add inline `:reek:` suppression comments to Ruby files.
- Keep all user-approved Reek exceptions in `.reek.yml`.
- Give approved exceptions the narrowest available scope and add a short YAML comment explaining why.
- If an offense appears incorrect, conflicts with Rails conventions, or would require a harmful refactor, stop and ask the user. Include:
  - The exact offense and location.
  - Why it may not apply.
  - The refactoring options.
  - The proposed `.reek.yml` exception, if appropriate.

### Acceptance criteria

Work is not finished until `bin/reek app` returns no offenses. As of this
writing that's true for `app/models` only - see `docs/llms/development.md`
for the rest of the toolchain and its current state.

## Choosing a gem

- Never add the first gem that comes to mind. Identify at least one real
  alternative and compare them before choosing - search for existing
  comparisons/articles rather than guessing from memory.
- Prefer the actively maintained, modern option over the most popular or most
  familiar one. A gem last released years ago, with an archived repo, or with
  known unaddressed limitations (check its own README/issues) loses to one
  that's currently maintained, even if it's newer or less well-known.
- Run `bin/still_active` before adding a gem (or check its rubygems/GitHub
  page by hand if `still_active` can't reach it) - archived, last-commit
  activity, and OpenSSF Scorecard signals it surfaces are exactly what
  "actively maintained" means here. Don't add a gem that would fail its own
  check.
- Write down which alternative(s) you considered and why you picked the one
  you did, as a Gemfile comment next to the `gem` line (see the existing
  entries for the format). See `docs/llms/dependency_selection.md` for the
  full methodology and worked examples.
