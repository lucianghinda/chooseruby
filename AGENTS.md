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
