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

    class Continue < Signal; end

    class FanOut < Signal
      attr_reader :join, :items

      def initialize(join:, items:)
        super()

        @join = join
        @items = items
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
        [@join, @items]
      end
    end

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
