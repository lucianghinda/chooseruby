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
