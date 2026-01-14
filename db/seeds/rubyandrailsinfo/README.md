# RubyAndRailsInfo Data Import

This directory contains seed files for importing data from a PostgreSQL SQL dump into the Rails application.

## Overview

The import system reads data from `tmp/latest.sql` (a PostgreSQL database dump) and transforms it into Rails models following the Entry/entryable pattern used throughout the application.

## File Structure

```
lib/imports/rubyandrailsinfo/
├── sql_parser.rb          # Parses PostgreSQL COPY format
└── helpers.rb             # Utilities for ID mapping and data conversion

db/seeds/rubyandrailsinfo/
├── 01_categories.rb       # tags → Category (55 records)
├── 02_authors.rb          # authors → Author (151 records)
├── 03_books.rb           # books → Book + Entry (114 records)
├── 04_courses.rb         # courses → Course + Entry (30 records)
├── 05_newsletters.rb     # newsletters → Newsletter + Entry (34 records)
├── 06_podcasts.rb        # podcasts → Podcast + Entry (25 records)
├── 07_communities.rb     # communities → Community + Entry (18 records)
├── 08_videos.rb          # youtubes/screencasts/lessons → Video + Entry (73 records)
├── 09_authorings.rb      # authorings → entries_authors (209 records)
└── 10_taggings.rb        # taggings → categories_entries (249 records)
```

## Usage

### Running the Import

1. Place the PostgreSQL SQL dump file at `tmp/latest.sql`
2. Run the import:

```bash
IMPORT_RUBYANDRAILSINFO=true rails db:seed
```

### Expected Results

After successful import:
- **~55 categories** (from tags)
- **~151 authors** with social URLs
- **~114 books**
- **~30 courses**
- **~34 newsletters**
- **~25 podcasts**
- **~18 communities**
- **~73 videos** (from youtubes, screencasts, and lessons)
- **~294 total entries**
- **~209 author-entry associations**
- **~249 category-entry associations**

## Data Mapping

| SQL Table | Rails Model | Notes |
|-----------|-------------|-------|
| `tags` | `Category` | Tags become categories |
| `authors` | `Author` | All imported as approved |
| `books` | `Book` + `Entry` | Two-step creation |
| `courses` | `Course` + `Entry` | Two-step creation |
| `newsletters` | `Newsletter` + `Entry` | Two-step creation |
| `podcasts` | `Podcast` + `Entry` | Two-step creation |
| `communities` | `Community` + `Entry` | Two-step creation |
| `youtubes` | `Video` + `Entry` | Combined into Video |
| `screencasts` | `Video` + `Entry` | Combined into Video |
| `lessons` | `Video` + `Entry` | Combined into Video |
| `authorings` | `EntriesAuthor` | Join table |
| `taggings` | `CategoriesEntry` | Join table |

## Skipped Data

The following tables are intentionally skipped:
- **events** - No Event model exists
- **Active Storage tables** - Cover images handled separately
- **Framework tables** - schema_migrations, users, etc.

## Features

### Idempotency
All imports use `find_or_create_by!` to ensure running multiple times doesn't create duplicates.

### Error Handling
Each seed file:
- Tracks success/error/skipped counts
- Logs errors with context
- Continues processing on errors
- Prints summary at end

### Polymorphic Association Mapping
The import handles complex polymorphic associations by:
1. Registering entries during entity import
2. Looking up entries by old ID during join table import
3. Using module-level instance variables for cross-file sharing

### Full-Text Search (FTS)
Entry and Author models automatically sync to FTS tables via `after_save` callbacks - no manual intervention needed.

### ActionText
Entry descriptions use ActionText - HTML content is assigned directly and ActionText handles the rich text storage automatically.

## Module Structure

### Rubyandrailsinfo::SqlParser

Parses PostgreSQL COPY format:
- Extracts table data from tab-delimited format
- Handles escape sequences (`\N` → nil, `\t` → tab, etc.)
- Returns array of hashes for easy iteration

**Usage:**
```ruby
parser = Rubyandrailsinfo::SqlParser.new(Rails.root.join('tmp/latest.sql'))
books_data = parser.extract_table('books')
```

### Rubyandrailsinfo::Helpers

Provides utilities for:
- **ID Mapping**: Store and retrieve old IDs → new records
- **Data Conversion**: Parse timestamps, booleans, integers
- **Progress Display**: Show import progress

**Key Methods:**
- `register_entry(old_type, old_id, entry)` - Save entry for later lookup
- `find_entry(old_type, old_id)` - Find entry by old reference
- `register_author(old_id, author)` - Save author for later lookup
- `find_author(old_id)` - Find author by old ID
- `register_category(old_tag_id, category)` - Map tag to category
- `find_category(old_tag_id)` - Find category by old tag ID
- `parse_time(str)` - Convert PostgreSQL timestamps
- `parse_bool(str)` - Convert `t`/`f` to boolean
- `to_int(str)` - Safe integer conversion

## Testing

### Verify Import

After running the import, verify data integrity:

```ruby
# In Rails console
Entry.where(entryable_id: nil).count  # Should be 0
Entry.where(title: [nil, '']).count   # Should be 0
Book.first.entry.present?             # Should be true
Entry.first.authors.any?              # Should be true
Entry.first.categories.any?           # Should be true
```

### Idempotency Test

```bash
# Run twice - counts should be identical
IMPORT_RUBYANDRAILSINFO=true rails db:seed
IMPORT_RUBYANDRAILSINFO=true rails db:seed
```

### FTS Sync Check

```ruby
# In Rails console
Entry.count == ActiveRecord::Base.connection.execute(
  "SELECT COUNT(*) FROM entries_fts"
).first.values.first
# Should be true
```

## Troubleshooting

### Import doesn't run
- Ensure `IMPORT_RUBYANDRAILSINFO=true` is set
- Verify `tmp/latest.sql` exists
- Check file permissions

### Errors during import
- Check error messages for specific issues
- Verify SQL dump format matches PostgreSQL COPY format
- Ensure all required models exist

### Missing associations
- Check that authorings and taggings ran successfully
- Verify ID mapping worked (check for skipped records)
- Ensure entity imports completed before join tables

### Validation errors
- Check model validations
- Verify data format matches model requirements
- Look for missing required fields in SQL dump

## Maintenance

To reset and re-import:

```bash
# Reset database
rails db:reset

# Run import
IMPORT_RUBYANDRAILSINFO=true rails db:seed
```

## Notes

- The import preserves timestamps from the original database
- All entries are imported as `status: :approved` and `published: true`
- Default experience levels are set where not specified in source data
- Platform mappings for communities may need adjustment based on source data format
