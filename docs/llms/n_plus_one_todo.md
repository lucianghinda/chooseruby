# N+1 query inventory

Captured by running the full test suite once with Prosopite scanning enabled
(log-only, see `config/initializers/prosopite.rb`): `rm log/prosopite.log &&
bin/rails test`, then `log/prosopite.log`. 536 raw detections. Below is that
list triaged into what's actually worth fixing.

**Caveat on methodology:** `test/test_helper.rb` wraps each *test method* in
one `Prosopite.scan`/`finish`, not each *request*. A test that hits several
URLs in a loop (integration tests especially) makes cross-request queries
look like an N+1 within one page render when they aren't. Read "occurrences"
below as "how often this call site showed up", not "how bad it is in
production" - the Confidence column is the actual signal.

## Confirmed - same page render, worth fixing

| Call site | Query shape | Confidence | Notes |
|---|---|---|---|
| `app/views/home/_type_section.html.erb:14,29,74` | 3 queries (`MAX(updated_at)`, `SELECT *`, `COUNT`) per resource type | High | `home/index.html.erb` renders this partial once per type (~19 types: gems, books, courses, ...). One request → ~57 queries from this partial alone. Fix: precompute the 19 types' stats in `HomeController#index` with one grouped query (or a handful), pass a hash into the partial instead of querying per type. |
| `app/models/entry/related_resources.rb:56` (`fetch_from_category`) | `SELECT DISTINCT entries... WHERE category_id = ?` | High | `related_by_top_categories` deliberately queries once per top category (max 3) to spread results evenly - see the class comment. Bounded and intentional, but still 3 queries where 1 could work with a single `IN (...)` + client-side grouping if this ever shows up as slow in production. |
| `app/models/category.rb:65` (`Category#entries_count`) | `COUNT(*) ... WHERE category_id = ?` | Medium | Called once per category. Wherever this runs in a loop over `Category.all` (categories index page), it's a real per-category N+1 - fix with a single grouped count query, cached on the controller side. |

## False positive - artifact of per-test scanning, not a real N+1

| Call site | Why it's not real |
|---|---|
| `app/controllers/concerns/block_banned_requests.rb:19` (`banned_ip?`) | One query per HTTP request (checking the current request's IP) - correct behavior. Only looks like N+1 because a test issues several requests inside one `Prosopite.scan` window. |
| `app/controllers/home_controller.rb:39-41` (`build_entry_stats`), `:146` (`popular_queries`) | Each is a single query per request (3 different `COUNT`s, not the same query repeated). Flagged because a test calls `HomeController#index` more than once inside one scan. |
| `app/controllers/resource_types_controller.rb:67` (`fetch_category_stats`) | Same shape, same reason - one grouped query per request, test called the action twice. |

## Expected - one write per record, not batchable in the normal case

| Call site | Why |
|---|---|
| `app/models/concerns/sluggable.rb:33` (`Sluggable#unique_slug`) | One `exists?` check per record on create/update, to guarantee a unique slug. Only becomes a real N+1 if something bulk-creates many records in one request/job without batching (e.g. an import rake task) - `lib/imports/...` does exactly that, so if that import is ever slow, this is where to look first. |
| `app/models/entry.rb:298` (`Entry#sync_to_fts`) | One delete+insert into the FTS5 virtual table per saved record - same reasoning as above. |

## Next step

Once this list is either fixed or explicitly accepted, flip
`Prosopite.raise = true` in `config/environments/test.rb` (see
`config/initializers/prosopite.rb`) so new N+1s fail the test suite instead
of just logging.
