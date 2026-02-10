# frozen_string_literal: true

require "test_helper"

class ParseAgentSkillJobTest < ActiveJob::TestCase
  setup do
    @agent_skill = AgentSkill.create!(skill_file_url: "https://example.com/skill.md", name: "Test Skill")
  end

  test "handles non-existent agent_skill gracefully" do
    assert_nothing_raised do
      ParseAgentSkillJob.perform_now(999_999)
    end
  end

  test "rejects non-HTTPS URLs" do
    invalid_skill = AgentSkill.new(skill_file_url: "http://example.com/skill.md", name: "Test Skill 2")

    assert_not invalid_skill.valid?
    assert_includes invalid_skill.errors[:skill_file_url], "must be a valid HTTPS URL"
  end
end
