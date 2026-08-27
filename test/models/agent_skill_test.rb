# frozen_string_literal: true

require "test_helper"

class AgentSkillTest < ActiveSupport::TestCase
  test "skill_file_url must be present" do
    agent_skill = AgentSkill.new
    assert_not agent_skill.valid?
    assert_includes agent_skill.errors[:skill_file_url], "can't be blank"
  end

  test "skill_file_url must be valid HTTPS URL" do
    agent_skill = AgentSkill.new(skill_file_url: "http://example.com/skill.md")
    assert_not agent_skill.valid?
    assert_includes agent_skill.errors[:skill_file_url], "must be a valid HTTPS URL"
  end

  test "valid HTTPS URL passes validation" do
    agent_skill = AgentSkill.new(skill_file_url: "https://example.com/skill.md")
    assert agent_skill.valid?
    assert_empty agent_skill.errors[:skill_file_url]
  end

  test "name validation only on update" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")

    agent_skill.name = "a"
    assert_not agent_skill.valid?
    assert_includes agent_skill.errors[:name], "is too short (minimum is 2 characters)"

    agent_skill.name = "A" * 201
    assert_not agent_skill.valid?
    assert_includes agent_skill.errors[:name], "is too long (maximum is 200 characters)"

    agent_skill.name = "Test Skill"
    assert agent_skill.valid?
  end

  test "display_name returns entry title when entry exists" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")
    entry = Entry.create!(
      title: "My Agent Skill",
      url: "https://example.com",
      entryable: agent_skill,
      status: :approved
    )

    assert_equal "My Agent Skill", agent_skill.display_name
  end

  test "display_name returns name when entry does not exist" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")
    assert_equal "Test Skill", agent_skill.display_name
  end

  test "display_name returns fallback when name and entry are nil" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md")
    assert_equal "Agent Skill ##{agent_skill.id}", agent_skill.display_name
  end

  test "has entry association" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")
    entry = Entry.create!(
      title: "Ruby Agent Skill",
      url: "https://example.com",
      entryable: agent_skill,
      status: :approved
    )

    assert_equal entry, agent_skill.entry
    assert_equal agent_skill, entry.entryable
  end

  test "parse_status enum works correctly" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md")
    assert_equal "parse_pending", agent_skill.parse_status

    agent_skill.update!(parse_status: :parse_completed)
    assert_equal "parse_completed", agent_skill.reload.parse_status

    agent_skill.update!(parse_status: :parse_failed)
    assert_equal "parse_failed", agent_skill.reload.parse_status
  end

  test "metadata serialization stores and retrieves JSON" do
    metadata = { "key1" => "value1", "key2" => "value2" }
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", metadata: metadata)

    assert_equal metadata, agent_skill.metadata
  end

  test "allowed_tools serialization stores and retrieves Array" do
    tools = [ { "name" => "read" }, { "name" => "webfetch" } ]
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", allowed_tools: tools)

    assert_equal tools, agent_skill.allowed_tools
  end

  test "delegated type touches entry when updated" do
    agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")
    entry = Entry.create!(
      title: "Test Agent Skill",
      url: "https://example.com",
      entryable: agent_skill,
      status: :approved
    )

    original_updated_at = entry.reload.updated_at
    sleep 0.1

    agent_skill.update!(name: "Updated Skill")
    entry.reload

    assert entry.updated_at > original_updated_at,
           "Expected entry.updated_at (#{entry.updated_at}) to be greater than original (#{original_updated_at})"
  end
end
