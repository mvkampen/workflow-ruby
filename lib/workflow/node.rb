# frozen_string_literal: true

module Workflow
  # A workflow node that wraps a callable object (e.g., a Proc, lambda, or any object that responds to #call).
  # This allows for flexible definition of workflow steps using simple callables.
  class Node
    def initialize(callable = nil, &block)
      super()

      @callable = callable || block

      raise ArgumentError, 'callable node requires a callable object or block' unless @callable
    end

    def call(state)
      @callable.call(state)
    end
  end
end
