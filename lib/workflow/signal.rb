# frozen_string_literal: true

module Workflow
  # Immutable control signal emitted by nodes to influence runner execution.
  class Signal
    attr_reader :value

    def initialize(value = nil)
      @value = value
      freeze
    end

    def ==(other)
      other.is_a?(self.class) && other.value == value
    end
    alias eql? ==

    def hash
      [self.class, value].hash
    end

    def deconstruct
      [value]
    end

    class Continue < Signal; end
    class Stop < Signal; end
  end
end
