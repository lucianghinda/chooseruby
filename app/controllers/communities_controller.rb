# frozen_string_literal: true

class CommunitiesController < ApplicationController
  def index
    @communities = Community.order(is_official: :desc, member_count: :desc, platform: :asc)
  end
end
