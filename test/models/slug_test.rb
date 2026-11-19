# frozen_string_literal: true

require "test_helper"

class SlugTest < ActiveSupport::TestCase
  cover "Slug*"

  test "is the parameterized source when nobody owns it yet" do
    assert_equal "yukihiro-matsumoto", Slug.new("Yukihiro Matsumoto", taken_by: Author.none).to_s
  end

  test "counts up until it finds a slug nobody owns" do
    Author.create!(name: "Slug Owner")
    Author.create!(name: "Slug Owner")

    assert_equal "slug-owner-2", Slug.new("Slug Owner", taken_by: Author.all).to_s
  end
end
