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
