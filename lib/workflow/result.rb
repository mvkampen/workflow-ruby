# frozen_string_literal: true

module Workflow
  # Monaid result type representing either a success or failure of a workflow step.
  class Result
    class UnwrapError < StandardError; end

    def self.valid_result?(result)
      result.is_a?(Result)
    end

    def bind
      result = yield(payload)

      raise TypeError, 'bind block must return a Workflow::Result' unless Result.valid_result?(result)

      result
    end

    def ==(other)
      other.is_a?(self.class) && other.payload == payload
    end
    alias eql? ==

    def hash
      [self.class, payload].hash
    end

    protected

    attr_reader :payload
  end
end

require_relative 'result/success'
require_relative 'result/failure'
