# frozen_string_literal: true

module Workflow
  class Graph
    class InvalidError < Error
      attr_reader :problems

      def initialize(problems)
        @problems = problems
        super(problems.map(&:message).join(', '))
      end
    end

    class ValidationError < Error
      def message
        raise NotImplementedError
      end
    end

    class MissingEntryPointError < ValidationError
      def message
        'graph has no start vertices'
      end
    end

    class VertexValidationError < ValidationError
      attr_reader :vertex

      def initialize(vertex)
        super()
        @vertex = vertex
      end
    end

    class MissingIncomingEdgeError < VertexValidationError
      def message
        "vertex #{vertex.inspect} has no incoming edge"
      end
    end

    class UnreachableVertexError < VertexValidationError
      def message
        "vertex #{vertex.inspect} is not reachable from a start edge"
      end
    end
  end
end
