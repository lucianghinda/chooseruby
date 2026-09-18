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
`maximum_drop 2` fails the suite if coverage regresses by more than 2 points, so it can only go up from here.

When you add tests that raise coverage, raise `minimum` in `test/test_helper.rb` to match (round down slightly). Never lower these numbers without discussing it with the user first.
