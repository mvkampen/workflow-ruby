# frozen_string_literal: true

module Workflow
  # Runner executes registered nodes by traversing direct edges from a start vertex.
  class Runner
    def initialize
      @nodes = {}
      @edges = Hash.new { |h, k| h[k] = [] }
    end

    def add_node(vertex, node = nil, &block)
      raise ArgumentError, 'provide a node or a block, not both' if node.is_a?(Node) && block

      vertex = normalize_vertex(vertex)
      node ||= Workflow::Node.new(&block)
      @nodes[vertex] = node

      [vertex, node]
    end

    def add_edge(from, to)
      from = normalize_vertex(from)
      to = normalize_vertex(to)

      raise ArgumentError, 'from node not found' unless from.is_a?(Vertex::Start) || @nodes.key?(from)
      raise ArgumentError, 'to node not found' unless @nodes.key?(to)

      edge = Workflow::Edge(from:, to:)
      @edges[edge.from] << edge
      edge
    end

    def run(start:, state:)
      raise ArgumentError, 'start must be a Workflow::Vertex::Start' unless start.is_a?(Vertex::Start)

      current_vertex = next_vertex_from(start)
      current_value = state

      loop do
        result = call(current_vertex, current_value)
        return result if result.failure?

        signal, current_value = unpack_success(result)
        current_vertex, terminal_result = advance(signal, current_value, current_vertex)
        return terminal_result if terminal_result
      end
    end

    private

    def advance(signal, state, current_vertex)
      case signal
      in Signal::Stop()
        [current_vertex, Workflow::Success(state)]
      in Signal::Stop(result)
        [current_vertex, Workflow::Success(result)]
      in Signal::Compensate | Signal::Retry
        [current_vertex, Workflow::Success([signal, state])]
      in Signal::Continue
        [next_vertex_from(current_vertex), nil]
      else
        raise ArgumentError, "unsupported signal #{signal.inspect}"
      end
    end

    def call(vertex, state)
      node = fetch_node(vertex)
      result = node.call(state)
      return result if Result.valid_result?(result)

      raise TypeError, "#{node.class} must return a Workflow::Result"
    end

    def fetch_node(vertex)
      @nodes.fetch(vertex)
    rescue KeyError
      raise KeyError, "unknown node registered as #{vertex}"
    end

    def next_vertex_from(vertex)
      edges = @edges.fetch(vertex) do
        raise KeyError, "unknown outgoing edge from #{vertex.inspect}"
      end

      raise ArgumentError, "expected exactly one outgoing edge from #{vertex.inspect}" unless edges.one?

      edges.first.to
    end

    def unpack_success(result)
      payload = result.value!

      case payload
      in [Signal => signal, value]
        [signal, value]
      else
        raise TypeError, 'successful node results must return [Workflow::Signal, value]'
      end
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
