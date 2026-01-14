When creating a rake task, never write logic inside the Rake tasks itself. Instead, create a separate class, and then call that class or module from the Rake task.

Test first
