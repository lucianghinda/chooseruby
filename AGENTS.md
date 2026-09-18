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

The end goal is `bin/reek app` clean everywhere. Get there one directory at a
time, the way `app/models` already did: `bin/reek app/<dir>`, fix everything
it reports (narrow `.reek.yml` exceptions only where a fix would be wrong,
per the rules above), then widen the enforced glob in `lefthook.yml` and
`config/ci.rb` (currently `app/models` only - see `docs/llms/development.md`
for the rest of app/'s current warning count) to include that directory.
Never widen the glob before the directory is actually clean.

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

## Avoiding over-engineering (YAGNI / DRY)

Linters catch style and single-method smells. They do not catch a class that
exists for no reason, a parameter nobody overrides, or the same query chain
copy-pasted into three files - that takes reading the code and asking "does
this abstraction earn its keep?" See `docs/llms/development.md`'s
over-engineering audit for the full worked examples this section is drawn
from.

**Don't wrap a stateless function in an instantiate-then-delegate service
object.** If a "service" has no instance state that outlives one call, it
doesn't need `.new`.

```ruby
# Bad: instantiate-then-delegate ceremony for a function with no state
class GithubAvatarService
  def self.call(url) = new(url).call
  def initialize(url) = @url = url
  def call = ...  # uses @url
end

# Good: module_function - same call site (GithubAvatarService.call(url)),
# no ceremony
module GithubAvatarService
  module_function
  def call(url) = ...
end
```

**Don't add a module/concern layer that has exactly one includer.** A
`Concern` earns its keep by being shared, or by needing `included do...end`/
`class_methods do...end`. One include site with neither is just an extra file
to open.

```ruby
# Bad: Authentication::SessionLookup, its own file, included nowhere else
module Authentication
  include Authentication::SessionLookup
end

# Good: inline it - it was always private to Authentication anyway
module Authentication
  private
  def find_session_by_cookie = ...
end
```

**Don't add a constructor parameter "for flexibility" before a second caller
needs a different value.** Grep every call site before assuming a parameter
is pulling weight.

```ruby
# Bad: scope: is never overridden anywhere in app/ or test/
def initialize(params = {}, scope: default_scope)
  @scope = scope
end

# Good: inline it. Add the parameter back the day a second caller actually
# needs a different scope - that's what git history and the YAGNI rule are for.
def initialize(params = {})
end

private

def scope = Entry.visible
```

**Don't write N near-identical methods dispatched by a case/if chain when
the only thing that varies is data.** A hash keyed by the same thing the
case statement switches on replaces both the dispatch and every branch body.

```ruby
# Bad: one *_params method per type, differing only in the field list
def build_entryable
  case resource_type
  when "RubyGem" then RubyGem.new(ruby_gem_params)
  when "Book" then Book.new(book_params)
  # ...6 more
  end
end
def ruby_gem_params = all_permitted_params.slice(:gem_name, :github_url, ...)
def book_params = all_permitted_params.slice(:isbn, :publisher, ...)
# ...6 more

# Good: one hash holds what varies; one method reads it
ENTRYABLE_ATTRIBUTES = { "RubyGem" => %i[gem_name github_url ...], "Book" => %i[isbn publisher ...] }.freeze
def build_entryable
  attributes = ENTRYABLE_ATTRIBUTES.fetch(resource_type) { raise ArgumentError, "..." }
  resource_type.constantize.new(all_permitted_params.slice(*attributes))
end
```

**Extract a shared scope/method the moment the same non-trivial query chain
appears in a second place** - don't wait for a third copy to notice.

```ruby
# Bad: the same 5-line .includes(...) chain, copy-pasted into 3 places
Entry.strict_loading.visible.includes(:categories, :rich_text_description, :entryable, { image_attachment: :blob }, authors: { avatar_attachment: :blob })

# Good: name it once as a scope, call the name everywhere
scope :with_card_includes, -> { strict_loading.includes(:categories, :rich_text_description, :entryable, { image_attachment: :blob }, authors: { avatar_attachment: :blob }) }
# ...
Entry.visible.with_card_includes
```

**A `rescue` block copy-pasted into multiple controller actions is a
`rescue_from` in `ApplicationController`, not a per-action pattern.**

```ruby
# Bad: repeated in every action that can 404
def show
  @entry = Entry.find(...)
rescue ActiveRecord::RecordNotFound
  render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
end

# Good: once, in ApplicationController
rescue_from ActiveRecord::RecordNotFound do
  render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
end
```
