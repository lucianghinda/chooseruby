## Instructions for LLMs

1. Make sure you load the file `docs/llms.md` and read it all. Never skip reading that file for any task.

## Test coverage

This project requires 100% line and branch coverage through SimpleCov. `.simplecov`
enforces it globally and per file, so `bin/rails test` fails when any file drops
below it.

When you find a coverage issue, decide which bucket it falls into:

- **A) The code does too much** for what the tests ask for. The coverage issue
  reveals behaviour that no test requires. The fix is to simplify the implementation.
- **B) A test is missing.** The behaviour is intentional but no test observes it.
  The fix is to add a test.

Decide between A) and B) before changing anything. If unsure, ask the user.

Never lower a minimum, add a SimpleCov filter, or mark code with `:nocov:` to make
the run pass.

## Code smells

`bin/reek .` must report no offenses.

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

## Mutation testing

Line coverage says a line ran, not that a test would notice if it changed.
[Mutant](https://github.com/mbj/mutant) changes the code and expects the suite to
go red.

```
bin/mutant run
```

`config/mutant.yml` lists the covered subjects. Value objects are on it because
they are pure and fast to mutate; add a subject once its tests survive mutation.

- Never remove a subject, weaken the matcher, or ignore a mutation to make a run
  green. A surviving mutation means a test is missing or the code does more than
  the tests ask for - the same two buckets as a coverage gap.
- A test file only covers its subject when it declares `cover "Subject*"`.
- The run is not part of `bin/ci`: it is slow and is meant for the subjects you
  touched, not for every commit.
- A full run is not usable yet: on a Rails boot with the default worker settings
  mutant exhausts the machine's memory. Keep it out of any automated step until
  that is tuned.

## Before finishing work

Run `bin/ci` and make sure it reports no issues. Confirm that SimpleCov reports
100% line and branch coverage with no per-file failures.
