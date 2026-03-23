# frozen_string_literal: true

module Workflow
  # Runner executes registered nodes by traversing direct edges from a start vertex.
  class Runner
    def initialize(graph)
      @graph = graph
    end

    def run(start:, state: nil)
      raise ArgumentError, 'start must be a Workflow::Vertex::Start' unless start.is_a?(Vertex::Start)

      @graph.freeze! unless @graph.frozen?

      current_vertex = @graph.next_vertex_from(start)
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
        [@graph.next_vertex_from(current_vertex), nil]
      else
        raise ArgumentError, "unsupported signal #{signal.inspect}"
      end
    end

    def call(vertex, state)
      node = @graph.fetch_node(vertex)
      result = node.call(state)
      return result if Result.valid_result?(result)

      raise TypeError, "#{node.class} must return a Workflow::Result"
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
  end
end
