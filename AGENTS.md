## Instructions for LLMs

1. Make sure you load the file `docs/llms.md` and read it all. Never skip reading that file for any task.

This project requires 100% line and branch coverage through SimpleCov.

## First check
Achieve 100% line and branch coverage. Use following commands:

```
bundle exec rake test
```

## When you find coverage issue

Decide which bucket it falls into:

- **A) The code does too much** for what the tests ask for. The
  coverage issue reveals behavior that no test requires. The
  fix is to simplify the implementation.
- **B) A test is missing.** The behavior is intentional but no test
  observes it. The fix is to add a test.

Decide between A) and B) before changing anything. If unsure, ask
the user.


## Before finishing work

Always run and make sure that there are no issues reported.

```sh
bin/ci
```

Confirm that SimpleCov reports 100% line and branch coverage with no per-file failures.
