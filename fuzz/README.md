# Fuzz testing (Ruzzy)

Not wired into `bin/ci` or `lefthook.yml` like the rest of the toolchain (see
`docs/llms/development.md`'s table) - `gem install ruzzy` compiles a C
extension against libFuzzer, which needs a full LLVM/clang build (not Apple's
bundled `clang`, which strips the fuzzer/sanitizer runtimes) or Linux with
`clang`+`libfuzzer` installed. That toolchain isn't available in every dev
environment or CI runner without extra setup, so this stays a manual,
documented tool rather than a gate everyone's `bundle install` depends on.

## Why Ruzzy

Compared against the AFL-based options (`afl-ruby`, `kisaten`): both are
last-released years ago and Ruzzy's own comparison write-up found AFL-style
brute force needs more raw throughput than a interpreted-language harness can
give it, whereas Ruzzy's libFuzzer-based coverage guidance finds the same bugs
with far fewer iterations. Ruzzy is also the actively maintained one -
Trail of Bits shipped LibAFL support in 2026 - and its README documents an
explicit pure-Ruby harness pattern (used below), not just C-extension fuzzing.
[https://github.com/trailofbits/ruzzy](https://github.com/trailofbits/ruzzy)

## Installing it

```bash
MAKE="make --environment-overrides V=1" \
CC="/path/to/clang" CXX="/path/to/clang++" \
LDSHARED="/path/to/clang -shared" LDSHAREDXX="/path/to/clang++ -shared" \
    gem install ruzzy
```

`clang` needs to be a real LLVM build with `compiler-rt`'s fuzzer archive
(`libclang_rt.fuzzer_no_main.a`) available - on macOS that means Homebrew's
`llvm` formula, not the Xcode Command Line Tools `clang`. See Ruzzy's own
[macOS notes](https://github.com/trailofbits/ruzzy#notes-for-macos-users).

## The target: `sanitize_fts_query`

`AuthorSearchQuery#sanitize_fts_query` and `EntryDirectoryQuery#sanitize_fts_query`
(near-identical, see the churn/duplication note in the tooling report) turn
raw user search input into a SQLite FTS5 `MATCH` string. That's the highest-
value fuzz target in the app: untrusted input, hand-rolled parsing, feeds
straight into a query. `fuzz/sanitize_fts_query_harness.rb` targets it.

## Running it

```bash
LD_PRELOAD=$(ruby -e 'require "ruzzy"; print Ruzzy::ASAN_PATH') \
    bundle exec ruby fuzz/sanitize_fts_query_tracer.rb -runs=100000
```

A crash reproduces with the artifact Ruzzy writes to `./crash-*`:

```bash
LD_PRELOAD=$(ruby -e 'require "ruzzy"; print Ruzzy::ASAN_PATH') \
    bundle exec ruby fuzz/sanitize_fts_query_harness.rb ./crash-<hash>
```
