# frozen_string_literal: true

require "test_helper"

class AvoControllerParametersTest < ActiveSupport::TestCase
  {
    Avo::BlogsController => :blog,
    Avo::ChannelsController => :channel,
    Avo::DevelopmentEnvironmentsController => :development_environment,
    Avo::DirectoriesController => :directory,
    Avo::DocumentationsController => :documentation,
    Avo::FrameworksController => :framework,
    Avo::JobBoardsController => :job_board,
    Avo::NewslettersController => :newsletter,
    Avo::ProductsController => :product,
    Avo::TestingResourcesController => :testing_resource,
    Avo::VideosController => :video
  }.each do |controller_class, parameter_key|
    test "#{parameter_key} admin forms accept name without allowing extra attributes" do
      controller = controller_class.new
      controller.params = ActionController::Parameters.new(parameter_key => { name: "Resource name", id: 98, created_at: "2020-01-01" })

      permitted = controller.send(:model_params)

      assert permitted.permitted?
      assert_equal({ "name" => "Resource name" }, permitted.to_h)
    end

    test "#{parameter_key} admin forms require their nested parameter object" do
      controller = controller_class.new
      controller.params = ActionController::Parameters.new(name: "Resource name")

      assert_raises(ActionController::ParameterMissing) { controller.send(:model_params) }
    end
  end
end
