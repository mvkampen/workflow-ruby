# frozen_string_literal: true

module Workflow
  # Monaid result type representing a failed outcome of a workflow step.
  class Failure < Result
    attr_reader :error

    def initialize(error = nil)
      super()

      @error = error
      freeze
    end

    def success?
      false
    end

    def failure?
      true
    end

    def map
      self
    end

    def bind
      self
    end

    def value
      nil
    end

    def value!
      raise UnwrapError, 'cannot unwrap value from Failure'
    end

    def error!
      error
    end

    protected

    def payload
      error
    end
  end
end
