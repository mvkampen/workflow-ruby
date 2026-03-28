# frozen_string_literal: true

module Workflow
  class Sum < Reducer
    def call(results)
      results.values.sum
    end
  end
end
