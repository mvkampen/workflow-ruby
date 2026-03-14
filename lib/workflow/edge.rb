# frozen_string_literal: true

module Workflow
  # A workflow edge that represents a directed connection between two vertices (nodes) in the workflow graph.
  class Edge
    attr_reader :from, :to

    def initialize(from:, to:)
      raise ArgumentError, 'from node not found' unless from.is_a?(Vertex)
      raise ArgumentError, 'to node not found' unless to.is_a?(Vertex)

      @from = from
      @to = to
      freeze
    end
  end
end
