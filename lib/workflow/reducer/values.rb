# frozen_string_literal: true

module Workflow
  class Values < Reducer
    def call(results)
      results.values
    end
  end
end
