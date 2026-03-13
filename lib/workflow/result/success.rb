# frozen_string_literal: true

module Workflow
  # Monaid result type representing a successful outcome of a workflow step.
  class Success < Result
    attr_reader :value

    def initialize(value = nil)
      super()

      @value = value
      freeze
    end

    def success?
      true
    end

    def failure?
      false
    end

    def map
      self.class.new(yield(value))
    end

    def value!
      value
    end

    def error
      nil
    end

    def error!
      raise UnwrapError, 'cannot unwrap error from Success'
    end

    protected

    def payload
      value
    end
  end
end
