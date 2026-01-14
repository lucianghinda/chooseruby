# frozen_string_literal: true

# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
class Avo::TestingResourcesController < Avo::ResourcesController
  private

  def model_params
    params.require(:testing_resource).permit(:name)
  end
end
