# frozen_string_literal: true

# == Schema Information
#
# Table name: authors
# Database name: primary
#
#  id              :integer          not null, primary key
#  avatar_url      :string
#  bio             :text
#  blog_url        :string
#  bluesky_url     :string
#  github_url      :string
#  gitlab_url      :string
#  linkedin_url    :string
#  name            :string           not null
#  ruby_social_url :string
#  slug            :string           not null
#  status          :integer          default("pending"), not null
#  twitch_url      :string
#  twitter_url     :string
#  website_url     :string
#  youtube_url     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_authors_on_name    (name)
#  index_authors_on_slug    (slug) UNIQUE
#  index_authors_on_status  (status)
#
require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "should not save author without name" do
    author = Author.new(bio: "Test bio")
    assert_not author.save, "Saved author without a name"
  end

  test "should not save author with name shorter than 2 characters" do
    author = Author.new(name: "A")
    assert_not author.save, "Saved author with name shorter than 2 characters"
  end

  test "should not save author with bio longer than 500 characters" do
    author = Author.new(name: "Test Author", bio: "a" * 501)
    assert_not author.save, "Saved author with bio longer than 500 characters"
  end

  test "should have pending status by default" do
    author = Author.create(name: "Test Author")
    assert author.pending?, "Author should have pending status by default"
    assert_equal 0, author.status_before_type_cast
  end

  test "should be able to change status to approved" do
    author = Author.create(name: "Test Author")
    author.approved!
    assert author.approved?, "Author should be approved"
    assert_equal 1, author.status_before_type_cast
  end

  test "should auto-generate slug from name" do
    author = Author.create(name: "Yukihiro Matsumoto")
    assert_equal "yukihiro-matsumoto", author.slug
  end

  test "should ensure slug uniqueness by appending number" do
    author1 = Author.create(name: "John Doe")
    author2 = Author.create(name: "John Doe")
    assert_equal "john-doe", author1.slug
    assert_equal "john-doe-1", author2.slug
  end

  test "should validate URL format for github_url" do
    author = Author.new(name: "Test Author", github_url: "not-a-url")
    assert_not author.save, "Saved author with invalid github_url"

    author.github_url = "https://github.com/testuser"
    assert author.save, "Did not save author with valid github_url"
  end
end
