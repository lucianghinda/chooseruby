# frozen_string_literal: true

SimpleCov.load_profile "rails"

SimpleCov.coverage :line do
  minimum 100
  minimum 100, per: :file
end

SimpleCov.coverage :branch do
  ignore :eval_generated
  minimum 100
  minimum 100, per: :file
end
