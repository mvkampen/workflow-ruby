# frozen_string_literal: true

module Workflow
  # A workflow graph that manages nodes and edges representing the structure of a workflow.
  # Nodes represent individual steps in the workflow, while edges define the flow between these steps.
  class Graph
    def initialize(nodes: {}, edges: {})
      @nodes = nodes
      @edges = edges
    end

    def add_node(vertex, node = nil, &block)
      raise FrozenError, "can't modify frozen #{self.class}" if frozen?
      raise ArgumentError, 'provide a node or a block, not both' if node.is_a?(Node) && block

      normalized_vertex = normalize_vertex(vertex)
      node ||= Workflow::Node.new(&block)

      @nodes[normalized_vertex] = node
      [normalized_vertex, node]
    end

    def add_edge(from, to)
      raise FrozenError, "can't modify frozen #{self.class}" if frozen?

      from_vertex = normalize_vertex(from)
      to_vertex = normalize_vertex(to)

      raise ArgumentError, 'from node not found' unless from_vertex.is_a?(Vertex::Start) || @nodes.key?(from_vertex)
      raise ArgumentError, 'to node not found' unless @nodes.key?(to_vertex)

      edge = Workflow::Edge(from: from_vertex, to: to_vertex)

      @edges[edge.from] ||= []
      @edges[edge.from] << edge
      edge
    end

    def freeze!
      @nodes.freeze
      @edges.each_value(&:freeze)
      @edges.freeze
      freeze
    end

    def fetch_node(vertex)
      @nodes.fetch(vertex)
    rescue KeyError
      raise KeyError, "unknown node registered as #{vertex}"
    end

    def outgoing_edges_from(vertex)
      @edges.fetch(vertex) do
        raise KeyError, "unknown outgoing edge from #{vertex.inspect}"
      end
    end

    def next_vertex_from(vertex)
      edges = outgoing_edges_from(vertex)
      raise ArgumentError, "expected exactly one outgoing edge from #{vertex.inspect}" unless edges.one?

      edges.first.to
    end

    def normalize_vertex(value)
      case value
      in Vertex then value
      in Symbol
        Vertex.new(value)
      in String
        Vertex.new(value.to_sym)
      else
        raise ArgumentError, "unsupported vertex #{value.inspect}"
      end
    end
  end
end
