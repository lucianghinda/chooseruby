# frozen_string_literal: true

# Fuzz harness for AuthorSearchQuery#sanitize_fts_query - see fuzz/README.md
# for why this exists and how to run it (needs Ruzzy, which needs a real
# LLVM/clang toolchain this repo doesn't assume everyone has).
require_relative "../config/environment"
require "ruzzy"

query = AuthorSearchQuery.new

test_one_input = lambda do |data|
  # Raw fuzzer bytes aren't guaranteed valid UTF-8; real search input goes
  # through the same params-encoding path Rails already handles, so scrub
  # here rather than let an encoding error look like a harness bug.
  input = data.dup.force_encoding("UTF-8").scrub

  result = query.send(:sanitize_fts_query, input)
  raise "expected a String, got #{result.class}" unless result.is_a?(String)

  0
end

Ruzzy.fuzz(test_one_input)
