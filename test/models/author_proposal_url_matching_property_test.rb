# frozen_string_literal: true

require "test_helper"
require "prop_check"

# Property-based tests for AuthorProposal::UrlMatching.normalize_url: instead of
# a handful of example URLs, PropCheck throws hundreds of generated strings at
# it per run and shrinks any failure to the smallest reproducing input.
#
# See docs/llms/development.md for why PropCheck over Rantly.
class AuthorProposalUrlMatchingPropertyTest < ActiveSupport::TestCase
  G = PropCheck::Generators

  test "normalize_url never raises, for any string" do
    PropCheck.forall(G.printable_ascii_string) do |input|
      result = AuthorProposal.normalize_url(input)

      assert(result.nil? || result.is_a?(String))
    end
  end

  test "normalize_url is idempotent (normalizing twice equals normalizing once)" do
    PropCheck.forall(G.printable_ascii_string) do |input|
      once = AuthorProposal.normalize_url(input)
      twice = AuthorProposal.normalize_url(once)

      if once.nil?
        assert_nil twice
      else
        assert_equal once, twice
      end
    end
  end

  test "normalize_url output is always lowercase" do
    PropCheck.forall(G.printable_ascii_string) do |input|
      result = AuthorProposal.normalize_url(input)

      if result.nil?
        assert_nil result
      else
        assert_equal result.downcase, result
      end
    end
  end

  test "normalize_url output never ends with a trailing slash unless it's the root" do
    PropCheck.forall(G.printable_ascii_string) do |input|
      result = AuthorProposal.normalize_url(input)

      refute_match(%r{[^/]/\z}, result.to_s)
    end
  end
end
