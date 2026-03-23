# frozen_string_literal: true

module Workflow
  class Graph
    # Visualizer generates a DOT representation of the workflow graph,
    # which can be used with Graphviz to visualize execution flow.
    class Visualizer
      TERMINAL_SIGNALS = {
        stop: 'Success / Stop',
        retry: 'Retry returned',
        compensate: 'Compensate returned'
      }.freeze

      def initialize(graph, signal_routes: {})
        @graph = graph
        @signal_routes = normalize_signal_routes(signal_routes)
      end

      def to_dot
        lines = ['digraph workflow {']
        lines.concat(vertex_lines)
        lines.concat(edge_lines)
        lines << '}'
        lines.join("\n")
      end

      private

      def vertex_lines
        workflow_vertex_lines + terminal_vertex_lines
      end

      def workflow_vertex_lines
        visible_vertices.map do |vertex|
          %(  "#{vertex_id(vertex)}" [label="#{vertex_label(vertex)}"])
        end
      end

      def terminal_vertex_lines
        used_signal_routes.map do |signal|
          %(  "#{terminal_id(signal)}" [shape=doublecircle, label="#{TERMINAL_SIGNALS.fetch(signal)}"])
        end
      end

      def edge_lines
        structural_edge_lines + signal_edge_lines
      end

      def structural_edge_lines
        @graph.edges.map do |edge|
          %(  "#{vertex_id(edge.from)}" -> "#{vertex_id(edge.to)}" [label="#{edge_label(edge)}"])
        end
      end

      def signal_edge_lines
        @signal_routes.flat_map do |vertex, signals|
          signals.map do |signal|
            %(  "#{vertex_id(vertex)}" -> "#{terminal_id(signal)}" [label="#{signal_label(signal)}"])
          end
        end
      end

      def visible_vertices
        (@graph.vertices + @graph.edges.map(&:from)).uniq.sort_by do |vertex|
          [vertex.is_a?(Workflow::Vertex::Start) ? 0 : 1, vertex_id(vertex)]
        end
      end

      def vertex_id(vertex)
        return 'start' if vertex.is_a?(Workflow::Vertex::Start)

        vertex.name.to_s
      end

      def vertex_label(vertex)
        return 'start' if vertex.is_a?(Workflow::Vertex::Start)

        vertex.name.to_s
      end

      def edge_label(edge)
        return 'Start' if edge.from.is_a?(Workflow::Vertex::Start)

        'Continue'
      end

      def terminal_id(signal)
        signal.to_s
      end

      def signal_label(signal)
        signal.to_s.capitalize
      end

      def used_signal_routes
        @signal_routes.values.flatten.uniq
      end

      def normalize_signal_routes(signal_routes)
        signal_routes.each_with_object({}) do |(vertex, signals), normalized|
          normalized[normalize_vertex(vertex)] = Array(signals).map do |signal|
            normalize_signal(signal)
          end
        end
      end

      def normalize_vertex(vertex)
        case vertex
        in Workflow::Vertex then vertex
        in Symbol
          Workflow::Vertex.new(vertex)
        in String
          Workflow::Vertex.new(vertex.to_sym)
        else
          raise ArgumentError, "unsupported vertex #{vertex.inspect}"
        end
      end

      def normalize_signal(signal)
        normalized = signal.to_sym
        return normalized if TERMINAL_SIGNALS.key?(normalized)

        raise ArgumentError, "unsupported terminal signal #{signal.inspect}"
      end
    end
  end
end
