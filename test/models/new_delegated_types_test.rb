# frozen_string_literal: true

require "test_helper"

# Tests for new delegated type models added in Resource Type Organization feature
# Testing: Newsletter, Blog, Video, Channel, Documentation, TestingResource,
# DevelopmentEnvironment, Job, Framework, Directory, Product
#
# Focused on critical behaviors:
# - display_name method
# - entry association (entryable polymorphic relationship)
# - basic model creation
class NewDelegatedTypesTest < ActiveSupport::TestCase
  test "Newsletter has display_name method that returns name when name exists" do
    newsletter = Newsletter.create!(name: "Test Newsletter")
    assert_equal "Test Newsletter", newsletter.display_name
  end

  test "Newsletter has entry association" do
    newsletter = Newsletter.create!(name: "Test Newsletter")
    entry = Entry.create!(
      title: "Ruby Weekly",
      url: "https://example.com/newsletter",
      entryable: newsletter,
      status: :approved
    )

    assert_equal entry, newsletter.entry
    assert_equal newsletter, entry.entryable
  end

  test "Blog has display_name method that returns blog name when name exists" do
    blog = Blog.create!(name: "Rails Blog")
    entry = Entry.create!(
      title: "Ruby on Rails Blog",
      url: "https://example.com/blog",
      entryable: blog,
      status: :approved
    )

    assert_equal "Rails Blog", blog.display_name
  end

  test "Video and Channel models work with entry association" do
    video = Video.create!(name: "Test Video")
    channel = Channel.create!(name: "Test Channel")

    video_entry = Entry.create!(
      title: "Ruby Tutorial Video",
      url: "https://example.com/video",
      entryable: video,
      status: :approved
    )

    channel_entry = Entry.create!(
      title: "Ruby Channel",
      url: "https://example.com/channel",
      entryable: channel,
      status: :approved
    )

    assert_equal video, video_entry.entryable
    assert_equal channel, channel_entry.entryable
    # Video and Channel have names, so display_name returns the name
    assert_equal "Test Video", video.display_name
    assert_equal "Test Channel", channel.display_name
  end

  test "Documentation model display_name returns name when name exists" do
    documentation = Documentation.create!(name: "Test Documentation")
    assert_equal "Test Documentation", documentation.display_name
  end

  test "TestingResource and DevelopmentEnvironment models creation" do
    testing_resource = TestingResource.create!(name: "Test Testing Resource")
    dev_env = DevelopmentEnvironment.create!(name: "Test Dev Environment")

    assert_not_nil testing_resource.id
    assert_not_nil dev_env.id
    assert_equal "Test Testing Resource", testing_resource.display_name
    assert_equal "Test Dev Environment", dev_env.display_name
  end

  test "Job, Framework, Directory, Product models have proper associations" do
    job = Job.create!(name: "Test Job")
    framework = Framework.create!(name: "Test Framework")
    directory = Directory.create!(name: "Test Directory")
    product = Product.create!(name: "Test Product")

    job_entry = Entry.create!(
      title: "Senior Ruby Developer",
      url: "https://example.com/job",
      entryable: job,
      status: :approved
    )

    framework_entry = Entry.create!(
      title: "Rails Framework",
      url: "https://example.com/framework",
      entryable: framework,
      status: :approved
    )

    assert_equal job, job_entry.entryable
    assert_equal framework, framework_entry.entryable
    assert_equal "Test Job", job.display_name
    assert_equal "Test Framework", framework.display_name
    assert_equal "Test Directory", directory.display_name
    assert_equal "Test Product", product.display_name
  end

  test "delegated type touches entry when updated" do
    newsletter = Newsletter.create!(name: "Test Newsletter")
    entry = Entry.create!(
      title: "Test Newsletter",
      url: "https://example.com/newsletter",
      entryable: newsletter,
      status: :approved
    )

    original_updated_at = entry.reload.updated_at
    sleep 0.1 # Ensure time difference

    newsletter.touch
    entry.reload

    assert entry.updated_at > original_updated_at,
           "Expected entry.updated_at (#{entry.updated_at}) to be greater than original (#{original_updated_at})"
  end
end
