# frozen_string_literal: true

module Workflow
  # Immutable control signal emitted by nodes to influence runner execution.
  class Signal
    def ==(other)
      other.is_a?(self.class)
    end
    alias eql? ==

    def hash
      self.class.hash
    end

    def deconstruct
      []
    end

    # Continue is emitted by a node to indicate that the workflow execution should continue to the next node as usual.
    class Continue < Signal
      def initialize
        super
        freeze
      end
    end

    # FanOut is emitted by a node to indicate that it wants to execute multiple branches in parallel.
    # It contains the join vertex where the branches will converge, the items to fan out over,
    # and an optional reducer to combine the results of the branches.
    class FanOut < Signal
      attr_reader :join, :items, :reducer

      def initialize(join:, items:, reducer: :values)
        raise ArgumentError, "join must be a vertex, got #{join.inspect}" unless join.is_a?(Vertex)

        unless items.is_a?(Array) || items.is_a?(Hash)
          raise ArgumentError, "items must be a non-empty array or hash, got #{items.inspect}"
        end

        super()

        @join = join
        @items = items
        @reducer = reducer
        freeze
      end

      def ==(other)
        super && other.deconstruct == deconstruct
      end
      alias eql? ==

      def hash
        [self.class, deconstruct].hash
      end

      def deconstruct = [@join, @items, @reducer]
    end

    # Stop is emitted by a node to indicate that the workflow execution should stop after this node.
    # It can optionally contain a result that will be returned as the final output of the workflow
    class Stop < Signal
      UNSET = Object.new.freeze

      def initialize(result = UNSET)
        super()

        @result = result
        freeze
      end

      def ==(other)
        super && other.deconstruct == deconstruct
      end
      alias eql? ==

      def hash
        [self.class, deconstruct].hash
      end

      def deconstruct
        return [] if @result.equal?(UNSET)

        [@result]
      end
    end

    # Error is a base class for signals that indicate an error condition.
    # It contains an error object that describes the error.
    class Error < Signal
      def initialize(error)
        super()

        @error = error
        freeze
      end

      def ==(other)
        super && other.deconstruct == deconstruct
      end
      alias eql? ==

      def hash
        [self.class, @error].hash
      end

      def deconstruct
        [@error]
      end
    end

    class Compensate < Error; end
    class Retry < Error; end
  end
end
