# frozen_string_literal: true

# Presents the directory's newest resources and curated discovery paths.
class HomeController < ApplicationController
  def index
    @directory = HomeDirectory.new
  end
end
