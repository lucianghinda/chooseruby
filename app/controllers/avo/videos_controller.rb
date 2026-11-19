# frozen_string_literal: true

# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
# Provides admin endpoints for videos.
class Avo::VideosController < Avo::ResourcesController
  private

  def model_params
    params.require(:video).permit(:name)
  end
end
