# frozen_string_literal: true

require "test_helper"

module ApplicationCable
  # ApplicationCable::Channel has an empty body; the only behaviour it carries is
  # being the Action Cable base class every application channel inherits from.
  class ChannelTest < ActiveSupport::TestCase
    test "is the Action Cable channel base class for the application" do
      assert_operator ApplicationCable::Channel, :<, ActionCable::Channel::Base
    end
  end
end
