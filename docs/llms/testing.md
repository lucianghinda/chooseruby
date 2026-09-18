# Testing Guidelines

## Creating vs Building Active Record Objects

Tend to build (instantiate) new Active Record objects in tests where persistence is not required or relevent for the test purpose.

## Fixture Data

Fixture data is used to populate the database with predefined data for testing purposes. It is typically used to create a consistent and predictable environment for testing. Fixture data can be created using factories or by manually inserting data into the database.

When creating a new model fill in the according fixtures and make sure they work.

## System Tests

Do not write system tests.

If we need to test specifics about the pages we should use view testing for views, partials and layouts if we want to check HTML elements.

We should use Controller Testing to test the behavior of controllers and their interactions with the database and other services (that is doing component testing on the controller and component integration testing between the controller and the models they are calling)

## Coverage

SimpleCov runs on every `bin/rails test` (configured in `test/test_helper.rb`, report written to `coverage/`).

Current floor: line 45%, branch 30%, both measured at the point coverage tracking was introduced.
No `maximum_drop`: it compares against the local, gitignored `coverage/.last_run.json`,
which CI never has (fresh checkout every run) and local dev accumulates from whatever
you ran last, full suite or one file - neither makes it a reliable regression check.
`minimum` doesn't have that problem, so it's the only gate.

When you add tests that raise coverage, raise `minimum` in `test/test_helper.rb` to match (round down slightly). Never lower these numbers without discussing it with the user first.

## N+1 detection

Prosopite scans every test (`test/test_helper.rb`) and logs findings to `log/prosopite.log`
and the Rails log (`config/initializers/prosopite.rb`) - log-only for now, see
`docs/llms/n_plus_one_todo.md` for the inventory. Flip `Prosopite.raise = true` once that
list is clear, to fail the suite on new N+1s.

Prosopite's default fingerprinting (anything but MySQL/MariaDB) shells out to the `pg_query`
gem, a Postgres-only parser. SQLite queries arrive already parameterized (`... = ?`), which
that parser can't read, and a bug in Prosopite's own rescue clause turns the parse failure
into `raise <the raw SQL string>`, crashing the test. `config/initializers/prosopite.rb`
overrides fingerprinting for the SQLite adapter to just use the (already-parameterized)
query string, so no parser is needed there at all.
