# ChooseRuby

A comprehensive directory for Ruby ecosystem resources built with Rails 8.1.


# A bit more about this project

I built the initial release entirely with Claude Code and Codex CLI. My goal was to experiment with what it means to develop an end-to-end product using these tools with Ruby on Rails.

There were no manual edits. I intentionally did not review the code in detail, only asked the LLMs to summarize changes and the general approach.

This repository will serve three purposes:

1. To build a real directory for the Ruby community with ChooseRuby

2. To have code that is a mix of working and buggy implementations so we can learn from refactoring it

3. To experiment with generative AI workflows and discover what works and what does not. It is best to do this with a real project that gets deployed.

# Technical and product Overview

## Overview

ChooseRuby is a curated platform for discovering and managing Ruby ecosystem resources including gems, books, courses, tutorials, articles, tools, podcasts, and communities. The platform uses Rails DelegatedTypes for flexible resource management and includes an admin interface built with Avo.

## Tech Stack

- Rails 8.1
- SQLite database
- ActionText for rich text content
- ActiveStorage for file uploads
- Avo 3.0 for admin interface
- Tailwind CSS for styling

## Features

### Core Entry Model

The application implements a comprehensive entry data model using Rails DelegatedTypes pattern:

**Base Entry Model**: Contains shared attributes across all entry types
- Title, description (rich text), URL
- Status workflow (pending, approved, rejected)
- Published toggle for visibility control
- Experience level (beginner, intermediate, advanced)
- Tags (JSON array)
- SEO-friendly slugs (auto-generated)
- Image support (ActiveStorage upload or external URL)

**8 Delegated Entry Types**:
1. **Ruby Gems** - Gems from RubyGems.org (e.g., RSpec, Devise, Sidekiq)
2. **Books** - Published books about Ruby
3. **Courses** - Online courses and training
4. **Tutorials** - Tutorial content
5. **Articles** - Blog posts and articles
6. **Tools** - Development tools and utilities
7. **Podcasts** - Ruby podcasts
8. **Communities** - Ruby communities (Discord, Slack, forums)

**Category System**: Entries can belong to multiple categories
- Testing, Authentication, Background Jobs, DevOps
- Web Development, API Development, Database
- Security, Performance, Learning Resources
- Data Processing, UI/Frontend, Email, File Handling

**Author Integration**: Entries can have multiple authors through existing Author model

### Admin Interface (Avo)

Access the admin interface at `/avo`

**Features**:
- CRUD operations for all entry types
- Filters by status, published state, experience level, entry type
- Search by title and description
- Bulk actions: approve, reject, publish, unpublish
- Rich text editor for descriptions
- Image upload or external URL
- Category and author multi-select
- Tag management

This will not be public but only used by me to review submissions or update existing entries.

## Getting Started

### Prerequisites

- Ruby 4.0.1
- Rails 8.2.0.alpha
- SQLite 3

### Installation

```bash
# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Load seed data (14 categories + 24+ sample entries)
rails db:seed

# Start the server
rails server
```

Visit `http://localhost:3000/avo` to access the admin interface.

### Creating Entries Programmatically

```ruby
# Create a Ruby Gem entry
ruby_gem = RubyGem.create!(
  gem_name: "rspec",
  rubygems_url: "https://rubygems.org/gems/rspec",
  github_url: "https://github.com/rspec/rspec"
)

entry = Entry.create!(
  title: "RSpec",
  description: "Behaviour Driven Development for Ruby",
  url: "https://rspec.info",
  entryable: ruby_gem,
  status: :approved,
  published: true,
  experience_level: :beginner,
  tags: ["testing", "bdd", "tdd"]
)

# Assign categories
testing_category = Category.find_by(slug: "testing")
entry.categories << testing_category

# Assign authors
author = Author.find_by(name: "Author Name")
entry.authors << author
```

### Type-Checking and Accessing Delegated Attributes

```ruby
entry = Entry.first

# Check entry type
entry.ruby_gem?  # => true
entry.book?      # => false

# Access delegated type attributes
entry.entryable.gem_name     # => "rspec"
entry.entryable.github_url   # => "https://github.com/rspec/rspec"
```

## Testing

Run the test suite:

```bash
# Run all tests
rails test

# Run specific test files
rails test test/models/entry_test.rb
rails test test/integration/avo_entry_admin_test.rb
```

## Database Schema

The application uses a DelegatedTypes pattern:

- `entries` table - Base table with shared attributes
- 8 delegated type tables - Type-specific attributes
  - `ruby_gems`, `books`, `courses`, `tutorials`
  - `articles`, `tools`, `podcasts`, `communities`
- `categories` table - Category definitions
- `categories_entries` - Many-to-many join table
- `authors` table - Author information (existing)
- `entries_authors` - Many-to-many join table (existing)

## Development

### Code Quality

The codebase follows Rails best practices:
- RuboCop for style enforcement
- Comprehensive test coverage
- N+1 query prevention with eager loading
- Proper foreign key constraints and cascade deletes

### Adding a New Delegated Entry Type

See `docs/DEVELOPER_GUIDE.md` for detailed instructions on extending the system.

## License

This project is available as open source under the terms of the Apache 2.0 License.

