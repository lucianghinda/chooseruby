# frozen_string_literal: true

# Lists community destinations ordered by official status and membership.
class CommunitiesController < ApplicationController
  def index
    @communities = Community.order(is_official: :desc, member_count: :desc, platform: :asc)
  end
end
