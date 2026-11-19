# frozen_string_literal: true

module ApplicationCable
  # Base class for application channels sharing the authenticated connection.
  class Channel < ActionCable::Channel::Base
  end
end
