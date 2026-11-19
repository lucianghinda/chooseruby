# frozen_string_literal: true

require "test_helper"

class DelegatedTypeDisplayNameTest < ActiveSupport::TestCase
  Entry::VALID_TYPES.each_value do |type|
    test "#{type} displays its entry title when no own name is present" do
      resource = type.constantize.new
      resource.build_entry(title: "Resource title")

      assert_equal "Resource title", resource.display_name
    end

    test "#{type} identifies an unnamed resource without an entry" do
      resource = type.constantize.new(id: 42)

      assert_equal "#{type} #42", resource.display_name
    end
  end

  %w[Newsletter Blog Video Channel Documentation TestingResource DevelopmentEnvironment JobBoard Framework Directory Product].each do |type|
    test "#{type} prefers its own name over the entry title" do
      resource = type.constantize.new(name: "Resource name")
      resource.build_entry(title: "Entry title")

      assert_equal "Resource name", resource.display_name
    end
  end

  test "gem falls back to its package name before its identifier" do
    assert_equal "ruby-package", RubyGem.new(gem_name: "ruby-package").display_name
  end
end
