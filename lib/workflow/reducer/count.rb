# frozen_string_literal: true

module Workflow
  class Count < Reducer
    def call(results)
      results.size
    end
  end
end
