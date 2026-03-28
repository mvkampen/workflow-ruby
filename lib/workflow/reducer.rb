# frozen_string_literal: true

module Workflow
  # Reducer is responsible for taking the results of multiple branches and combining them into a single result.
  class Reducer
    def call(_results)
      raise(NotImplementedError, 'reducer subclasses must implement the #call method')
    end
  end
end
