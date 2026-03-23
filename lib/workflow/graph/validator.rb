# frozen_string_literal: true

require_relative 'validator/errors'

module Workflow
  class Graph
    # Validates the structure of a workflow graph, checking for issues such as missing entry points,
    # unreachable vertices, and vertices without incoming edges.
    class Validator
      def initialize(graph)
        @graph = graph
      end

      def validate
        problems = []
        incoming = Hash.new { |h, k| h[k] = [] }
        start_vertices = []

        @graph.edges.each do |edge|
          start_vertices << edge.from if edge.from.is_a?(Workflow::Vertex::Start)
          incoming[edge.to] << edge.from
        end

        problems << MissingEntryPointError.new if @graph.vertices.any? && start_vertices.empty?

        reachable = reachable_vertices_from(start_vertices)

        @graph.vertices.each do |vertex|
          problems << MissingIncomingEdgeError.new(vertex) if incoming[vertex].empty?
          problems << UnreachableVertexError.new(vertex) unless reachable.include?(vertex)
        end

        problems.uniq { |problem| [problem.class, problem.respond_to?(:vertex) ? problem.vertex : nil] }
      end

      private

      def reachable_vertices_from(start_vertices)
        frontier = start_vertices.dup
        reachable = {}

        until frontier.empty?
          current_vertex = frontier.shift

          @graph.edges.each do |edge|
            next unless edge.from == current_vertex
            next if reachable.key?(edge.to)

            reachable[edge.to] = true
            frontier << edge.to
          end
        end

        reachable.keys
      end
    end
  end
end
