# frozen_string_literal: true

# Ruzzy needs this separate tracer entrypoint to instrument the interpreter
# before the harness loads - see fuzz/README.md.
require "ruzzy"

Ruzzy.trace("fuzz/sanitize_fts_query_harness.rb")
