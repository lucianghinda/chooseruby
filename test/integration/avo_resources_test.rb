# frozen_string_literal: true

require "test_helper"

class AvoResourcesTest < ActionDispatch::IntegrationTest
  # Task 6.1: Test Avo resources for all 19 delegated types

  test "can create entries for all 11 new delegated types via Avo" do
    # Newsletter
    newsletter = Newsletter.create!(name: "Test Newsletter")
    entry1 = Entry.create!(
      title: "Newsletter Test",
      description: "Test newsletter",
      url: "https://example.com",
      entryable: newsletter,
      status: :approved
    )
    assert entry1.persisted?
    assert entry1.newsletter?
    assert_equal "Newsletter", entry1.entryable_type

    # Blog
    blog = Blog.create!(name: "Test Blog")
    entry2 = Entry.create!(
      title: "Blog Test",
      description: "Test blog",
      url: "https://example.com",
      entryable: blog,
      status: :approved
    )
    assert entry2.persisted?
    assert entry2.blog?
    assert_equal "Blog", entry2.entryable_type

    # Video
    video = Video.create!(name: "Test Video")
    entry3 = Entry.create!(
      title: "Video Test",
      description: "Test video",
      url: "https://example.com",
      entryable: video,
      status: :approved
    )
    assert entry3.persisted?
    assert entry3.video?
    assert_equal "Video", entry3.entryable_type

    # Channel
    channel = Channel.create!(name: "Test Channel")
    entry4 = Entry.create!(
      title: "Channel Test",
      description: "Test channel",
      url: "https://example.com",
      entryable: channel,
      status: :approved
    )
    assert entry4.persisted?
    assert entry4.channel?
    assert_equal "Channel", entry4.entryable_type

    # Documentation
    documentation = Documentation.create!(name: "Test Documentation")
    entry5 = Entry.create!(
      title: "Documentation Test",
      description: "Test documentation",
      url: "https://example.com",
      entryable: documentation,
      status: :approved
    )
    assert entry5.persisted?
    assert entry5.documentation?
    assert_equal "Documentation", entry5.entryable_type

    # TestingResource
    testing_resource = TestingResource.create!(name: "Test Testing Resource")
    entry6 = Entry.create!(
      title: "Testing Resource Test",
      description: "Test testing resource",
      url: "https://example.com",
      entryable: testing_resource,
      status: :approved
    )
    assert entry6.persisted?
    assert entry6.testing_resource?
    assert_equal "TestingResource", entry6.entryable_type

    # DevelopmentEnvironment
    development_environment = DevelopmentEnvironment.create!(name: "Test Dev Environment")
    entry7 = Entry.create!(
      title: "Development Environment Test",
      description: "Test development environment",
      url: "https://example.com",
      entryable: development_environment,
      status: :approved
    )
    assert entry7.persisted?
    assert entry7.development_environment?
    assert_equal "DevelopmentEnvironment", entry7.entryable_type

    # Job
    job = Job.create!(name: "Test Job")
    entry8 = Entry.create!(
      title: "Job Test",
      description: "Test job",
      url: "https://example.com",
      entryable: job,
      status: :approved
    )
    assert entry8.persisted?
    assert entry8.job?
    assert_equal "Job", entry8.entryable_type

    # Framework
    framework = Framework.create!(name: "Test Framework")
    entry9 = Entry.create!(
      title: "Framework Test",
      description: "Test framework",
      url: "https://example.com",
      entryable: framework,
      status: :approved
    )
    assert entry9.persisted?
    assert entry9.framework?
    assert_equal "Framework", entry9.entryable_type

    # Directory
    directory = Directory.create!(name: "Test Directory")
    entry10 = Entry.create!(
      title: "Directory Test",
      description: "Test directory",
      url: "https://example.com",
      entryable: directory,
      status: :approved
    )
    assert entry10.persisted?
    assert entry10.directory?
    assert_equal "Directory", entry10.entryable_type

    # Product
    product = Product.create!(name: "Test Product")
    entry11 = Entry.create!(
      title: "Product Test",
      description: "Test product",
      url: "https://example.com",
      entryable: product,
      status: :approved
    )
    assert entry11.persisted?
    assert entry11.product?
    assert_equal "Product", entry11.entryable_type
  end

  test "new delegated types have display_name method" do
    newsletter = Newsletter.create!(name: "Test Newsletter")
    assert_match(/Test Newsletter/, newsletter.display_name)

    blog = Blog.create!(name: "Test Blog")
    assert_match(/Test Blog/, blog.display_name)

    video = Video.create!(name: "Test Video")
    assert_match(/Test Video/, video.display_name)

    channel = Channel.create!(name: "Test Channel")
    assert_match(/Test Channel/, channel.display_name)

    documentation = Documentation.create!(name: "Test Documentation")
    assert_match(/Test Documentation/, documentation.display_name)

    testing_resource = TestingResource.create!(name: "Test Testing Resource")
    assert_match(/Test Testing Resource/, testing_resource.display_name)

    development_environment = DevelopmentEnvironment.create!(name: "Test Dev Environment")
    assert_match(/Test Dev Environment/, development_environment.display_name)

    job = Job.create!(name: "Test Job")
    assert_match(/Test Job/, job.display_name)

    framework = Framework.create!(name: "Test Framework")
    assert_match(/Test Framework/, framework.display_name)

    directory = Directory.create!(name: "Test Directory")
    assert_match(/Test Directory/, directory.display_name)

    product = Product.create!(name: "Test Product")
    assert_match(/Test Product/, product.display_name)
  end

  test "new delegated types have entry association" do
    newsletter = Newsletter.create!(name: "Test Newsletter")
    entry = Entry.create!(
      title: "Test Newsletter",
      description: "Test",
      url: "https://example.com",
      entryable: newsletter,
      status: :approved
    )
    assert_equal entry, newsletter.entry

    blog = Blog.create!(name: "Test Blog")
    entry = Entry.create!(
      title: "Test Blog",
      description: "Test",
      url: "https://example.com",
      entryable: blog,
      status: :approved
    )
    assert_equal entry, blog.entry
  end
end
