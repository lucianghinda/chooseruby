# frozen_string_literal: true

class CspReportsController < ApplicationController
  skip_forgery_protection

  def create
    Rails.logger.warn("CSP VIOLATION: #{request.raw_post}")
    head :no_content
  end
end
