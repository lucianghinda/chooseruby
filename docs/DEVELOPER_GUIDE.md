# Developer Guide: Core Entry Model

This guide explains how to work with and extend the Core Entry Model in ChooseRuby.

## Table of Contents

1. [Understanding DelegatedTypes](#understanding-delegatedtypes)
2. [Adding a New Delegated Entry Type](#adding-a-new-delegated-entry-type)
3. [Adding New Categories](#adding-new-categories)
4. [Avo Customization Patterns](#avo-customization-patterns)
5. [Seed Data Management](#seed-data-management)
6. [N+1 Query Prevention](#n1-query-prevention)

## Understanding DelegatedTypes

Rails DelegatedTypes is a pattern for polymorphic associations that uses separate tables for each type. This is different from Single Table Inheritance (STI).

### How It Works

```ruby
# Base model (Entry) contains shared attributes
class Entry < ApplicationRecord
  delegated_type :entryable, types: %w[RubyGem Book Course ...]
end

# Each delegated type has its own table and model
class RubyGem < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy
end
```

### Benefits

- **Separate tables**: Each type has its own table with type-specific columns
- **Type safety**: Built-in type checking methods (`entry.ruby_gem?`)
- **Clean queries**: No null columns from unused type-specific attributes
- **Easy to extend**: Add new types without modifying existing tables

### Creating Records

```ruby
# Create the delegated type first
ruby_gem = RubyGem.create!(gem_name: "rspec")

# Then create the entry
entry = Entry.create!(
  title: "RSpec",
  url: "https://rspec.info",
  entryable: ruby_gem
)
```

### Accessing Attributes

```ruby
entry.title                      # Base attribute
entry.ruby_gem?                  # Type check (returns true/false)
entry.entryable.gem_name         # Delegated type attribute
```

## Adding a New Delegated Entry Type

Follow these steps to add a new entry type (example: "Video"):

### 1. Create Migration

```bash
rails generate migration CreateVideos platform:string duration_minutes:integer video_url:string
```

Edit the migration:

```ruby
class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.string :platform        # e.g., "YouTube", "Vimeo"
      t.integer :duration_minutes
      t.string :video_url
      t.timestamps
    end

    add_index :videos, :video_url
  end
end
```

Run migration:
```bash
rails db:migrate
```

### 2. Create Model

Create `app/models/video.rb`:

```ruby
class Video < ApplicationRecord
  has_one :entry, as: :entryable, touch: true, dependent: :destroy

  # Validations
  validates :video_url, presence: true,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :duration_minutes, numericality: { greater_than: 0 }, allow_blank: true
end
```

### 3. Update Entry Model

Add "Video" to the delegated types list in `app/models/entry.rb`:

```ruby
delegated_type :entryable,
                types: %w[RubyGem Book Course Tutorial Article Tool Podcast Community Video],
                optional: true
```

### 4. Create Avo Resource

Create `app/avo/resources/video.rb`:

```ruby
class Avo::Resources::Video < Avo::BaseResource
  self.title = :id
  self.includes = [:entry]

  def fields
    field :id, as: :id, link_to_record: true

    # Video-specific information
    field :platform, as: :text, help: "Platform (e.g., YouTube, Vimeo)"
    field :duration_minutes, as: :number, help: "Video duration in minutes"
    field :video_url, as: :text, required: true, help: "Direct link to video"

    # Association to base entry
    field :entry, as: :has_one

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [:index]
    field :updated_at, as: :date_time, readonly: true, hide_on: [:index]
  end
end
```

### 5. Update Entry Avo Resource

Add "Video" to the entryable_type enum in `app/avo/resources/entry.rb`:

```ruby
field :entryable_type, as: :select,
      required: true,
      enum: {
        "Ruby Gem" => "RubyGem",
        "Book" => "Book",
        # ... existing types ...
        "Video" => "Video"
      }
```

### 6. Add Test Fixtures

Create `test/fixtures/videos.yml`:

```yaml
youtube_video:
  platform: YouTube
  duration_minutes: 30
  video_url: https://youtube.com/watch?v=example
```

### 7. Write Tests

Add to `test/models/delegated_types_test.rb`:

```ruby
test "can create Video delegated type" do
  video = Video.create!(
    platform: "YouTube",
    video_url: "https://youtube.com/watch?v=test"
  )
  entry = Entry.create!(
    title: "Test Video",
    url: "https://example.com",
    entryable: video
  )

  assert entry.video?
  assert_equal "YouTube", entry.entryable.platform
end
```

### 8. Update Seed Data (Optional)

Add sample videos to `db/seeds.rb`.

## Adding New Categories

Categories are simple to add via seeds or console:

```ruby
# Via console or seeds
Category.create!(
  name: "Mobile Development",
  description: "Tools and resources for mobile app development",
  display_order: 15
)
```

The slug will be auto-generated from the name.

## Avo Customization Patterns

### Adding Filters

Example from `app/avo/filters/entry_status_filter.rb`:

```ruby
class Avo::Filters::EntryStatusFilter < Avo::Filters::SelectFilter
  self.name = "Status"

  def apply(request, query, value)
    return query if value.blank?
    query.where(status: value)
  end

  def options
    {
      "Pending" => "pending",
      "Approved" => "approved",
      "Rejected" => "rejected"
    }
  end
end
```

Register in resource:

```ruby
def filters
  filter Avo::Filters::EntryStatusFilter
end
```

### Adding Bulk Actions

Example from `app/avo/actions/approve_entries.rb`:

```ruby
class Avo::Actions::ApproveEntries < Avo::BaseAction
  self.name = "Approve Entries"
  self.message = "Are you sure you want to approve the selected entries?"

  def handle(records:, fields:, current_user:, resource:, **args)
    records.each do |entry|
      entry.update(status: :approved)
    end

    succeed "#{records.count} #{'entry'.pluralize(records.count)} approved!"
  end
end
```

Register in resource:

```ruby
def actions
  action Avo::Actions::ApproveEntries
end
```

### Eager Loading Associations

Prevent N+1 queries by defining includes:

```ruby
class Avo::Resources::Entry < Avo::BaseResource
  self.includes = [:entryable, :categories, :authors]
end
```

## Seed Data Management

### Strategy

Seeds in `db/seeds.rb` should be idempotent (safe to run multiple times):

```ruby
# Use find_or_create_by for categories
Category.find_or_create_by!(name: "Testing") do |category|
  category.description = "Testing frameworks, tools, and best practices"
  category.display_order = 1
end
```

### Running Seeds

```bash
# Run all seeds
rails db:seed

# Reset database and reseed (CAUTION: destroys data)
rails db:reset
```

### Seed Organization

For larger seed files, split into separate files:

```ruby
# db/seeds.rb
Dir[Rails.root.join('db', 'seeds', '*.rb')].sort.each do |file|
  puts "Processing #{file}..."
  require file
end
```

Then create:
- `db/seeds/01_categories.rb`
- `db/seeds/02_entries.rb`

## N+1 Query Prevention

### Common Patterns

#### In Controllers
```ruby
# Bad - causes N+1 queries
@entries = Entry.all

# Good - eager loads associations
@entries = Entry.includes(:entryable, :categories, :authors)
```

#### In Avo Resources
```ruby
# Set includes at the class level
class Avo::Resources::Entry < Avo::BaseResource
  self.includes = [:entryable, :categories, :authors]
end
```

#### Testing for N+1 Queries

Use the `bullet` gem in development to detect N+1 queries automatically.

### Checking Query Performance

In Rails console:

```ruby
# Enable SQL logging
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Run queries and observe SQL
Entry.includes(:entryable, :categories).limit(10).each do |e|
  puts e.entryable.try(:gem_name)
  puts e.categories.map(&:name)
end
```

## Best Practices

### Model Organization

1. **Keep models focused**: Delegated types should only contain type-specific logic
2. **Use concerns for shared behavior**: Extract reusable code into `app/models/concerns/`
3. **Document complex logic**: Add comments explaining business rules

### Validation Strategy

1. **Base model validates shared attributes**: URL format, title length, etc.
2. **Delegated types validate their own attributes**: Type-specific rules
3. **Use custom validators for complex rules**: Extract into `app/validators/`

### Testing Strategy

1. **Test each layer separately**: Models, integrations, system tests
2. **Focus on critical paths**: Complete workflows, edge cases
3. **Keep tests fast**: Use fixtures strategically, avoid unnecessary setup

### Migration Strategy

1. **Always reversible**: Use `change` method or define `up`/`down`
2. **Test rollback**: Run `rails db:rollback` after `rails db:migrate`
3. **Add indexes for foreign keys**: Improves query performance
4. **Use strong migrations gem**: Prevents dangerous production migrations

## Common Pitfalls

### 1. Forgetting to Eager Load

```ruby
# Bad - N+1 queries
entries.each { |e| puts e.entryable.some_attribute }

# Good - eager load
entries.includes(:entryable).each { |e| puts e.entryable.some_attribute }
```

### 2. Orphaned Delegated Types

When deleting an Entry, the delegated type is NOT automatically deleted (by design). If you need different behavior, update the Entry model:

```ruby
# Add to Entry model if you want cascade delete
delegated_type :entryable,
                types: %w[...],
                dependent: :destroy  # This will delete delegated type
```

### 3. Incorrect Type Checking

```ruby
# Bad - can raise errors if entryable is nil
entry.entryable.class.name == "RubyGem"

# Good - use built-in type checkers
entry.ruby_gem?
```

## Resources

- [Rails DelegatedTypes Guide](https://edgeapi.rubyonrails.org/classes/ActiveRecord/DelegatedType.html)
- [Avo Documentation](https://docs.avohq.io/)
- [ActionText Guide](https://edgeguides.rubyonrails.org/action_text_overview.html)
- [ActiveStorage Guide](https://edgeguides.rubyonrails.org/active_storage_overview.html)
