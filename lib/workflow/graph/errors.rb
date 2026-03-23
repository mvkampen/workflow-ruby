# frozen_string_literal: true

module Workflow
  class Graph
    class Error < StandardError; end
    class BuildError < Error; end

    class DuplicateVertexError < BuildError
      attr_reader :vertex

      def initialize(vertex)
        @vertex = vertex
        super("vertex already registered: #{vertex.inspect}")
      end
    end

    class UnknownVertexError < BuildError
      attr_reader :vertex

      def initialize(vertex)
        @vertex = vertex
        super("node not found: #{vertex.inspect}")
      end
    end

    class MissingOutgoingEdgeError < BuildError
      attr_reader :vertex

      def initialize(vertex)
        @vertex = vertex
        super("vertex has no outgoing edge: #{vertex.inspect}")
      end
    end
  end
end
