# frozen_string_literal: true

require_relative 'dispatcher'
require_relative 'join_aggregator'

module Workflow
  module Execution
    # The Engine is responsible for executing a workflow graph. It starts from a given vertex and initial state,
    # and processes nodes according to the graph structure and the signals returned by each node.
    class Engine
      Continuation = Data.define(:vertex, :output, :state) do
        def initialize(vertex:, state:, output: nil)
          super
        end
      end

      BRANCH_END_VERTEX = Workflow::Vertex.new(:__branch_end__)
      BRANCH_END_NODE = Class.new do
        def call(state)
          Workflow::Success([Workflow::Stop(), state])
        end
      end.new.freeze

      def initialize(graph:, dispatcher: nil)
        @graph = graph
        @dispatcher = dispatcher || default_dispatcher
        @workflow_id = "workflow-#{object_id}"
      end

      def run(start:, state:)
        raise ArgumentError, 'start must be a Workflow::Vertex::Start' unless start.is_a?(Vertex::Start)

        @graph.freeze! unless @graph.frozen?

        current_vertex = @graph.next_vertex_from(start)
        current_value = state

        loop do
          result = call(current_vertex, current_value)
          return result if result.failure?

          signal, current_value = unpack_success(result)
          continuation = advance(signal, current_value, current_vertex)
          return continuation.output if continuation.output

          current_vertex = continuation.vertex
          current_value = continuation.state
        end
      end

      private

      def default_dispatcher
        return Dispatcher.default if Ractor.current == Ractor.main

        Dispatcher.new(max_processors: 1)
      end

      def advance(signal, state, current_vertex)
        case signal
        in Signal::FanOut => fan_out
          fan_out_continuation(fan_out, current_vertex)
        in Signal::Stop()
          Continuation.new(vertex: current_vertex, output: Workflow::Success(state), state:)
        in Signal::Stop(result)
          Continuation.new(vertex: current_vertex, output: Workflow::Success(result), state:)
        in Signal::Compensate | Signal::Retry
          Continuation.new(vertex: current_vertex, output: Workflow::Success([signal, state]), state:)
        in Signal::Continue
          Continuation.new(vertex: @graph.next_vertex_from(current_vertex), state:)
        else
          raise ArgumentError, "unsupported signal #{signal.inspect}"
        end
      end

      def fan_out_continuation(signal, current_vertex)
        branch_start = @graph.next_vertex_from(current_vertex)
        branch_graph, branch_start_vertex = build_branch_graph(start_vertex: branch_start, join_vertex: signal.join)
        branch_graph = ensure_shareable_graph!(branch_graph)
        branch_items = normalize_branch_items(signal.items)

        join_aggregator = JoinAggregator.new(
          node: signal.join,
          branches: branch_items.map(&:first),
          reducer: Workflow::Reducers.resolve(signal.reducer)
        )

        @dispatcher.dispatch(
          branch_graph:,
          start_vertex: branch_start_vertex,
          items: signal.items,
          workflow_id: @workflow_id,
          node: current_vertex.name
        ) do |branch_result|
          tracked_result = join_aggregator.record(branch_result)
          next unless tracked_result

          if Result.valid_result?(tracked_result) && tracked_result.failure?
            return Continuation.new(vertex: current_vertex, output: tracked_result, state: nil)
          end

          return Continuation.new(vertex: join_aggregator.node, state: tracked_result)
        end

        raise ArgumentError, "fan-out join #{signal.join.inspect} did not produce a completion"
      end

      def normalize_branch_items(items)
        if items.is_a?(Hash)
          items.to_a
        else
          items.each_with_index.map { |item, branch| [branch, item] }
        end
      end

      # To handle it as a complete branch, it requires a start and terminal node.
      # We walk the graph starting from the branch start vertex. Build a new
      # graph with the reachable vertices, until we reach the join vertex.
      def build_branch_graph(start_vertex:, join_vertex:)
        if start_vertex == join_vertex
          raise ArgumentError,
                "branch start #{start_vertex.inspect} cannot be the join vertex #{join_vertex.inspect}"
        end

        branch_start = Vertex::Start.new
        branch_graph = Workflow::Graph.new
        reachable = [start_vertex]
        visited = {}
        reaches_join = false

        branch_graph.add_node(start_vertex, @graph.fetch_node(start_vertex))
        branch_graph.add_edge(branch_start, start_vertex)

        until reachable.empty?
          current_vertex = reachable.shift
          next if visited[current_vertex]

          visited[current_vertex] = true

          outgoing_edges_from(current_vertex).each do |edge|
            if edge.to == join_vertex
              unless branch_graph.vertices.include?(BRANCH_END_VERTEX)
                branch_graph.add_node(BRANCH_END_VERTEX, BRANCH_END_NODE)
              end
              branch_graph.add_edge(current_vertex, BRANCH_END_VERTEX)
              reaches_join = true
              next
            end

            branch_graph.add_node(edge.to, @graph.fetch_node(edge.to)) unless branch_graph.vertices.include?(edge.to)
            branch_graph.add_edge(current_vertex, edge.to)
            reachable << edge.to
          end
        end

        unless reaches_join
          raise ArgumentError,
                "branch starting at #{start_vertex.inspect} does not reach join vertex #{join_vertex.inspect}"
        end

        [branch_graph, branch_start]
      end

      def outgoing_edges_from(vertex)
        @graph.edges.select { |edge| edge.from == vertex }
      end

      def ensure_shareable_graph!(graph)
        graph.freeze! unless graph.frozen?
        Ractor.make_shareable(graph)
      rescue Ractor::Error, TypeError => e
        raise ArgumentError, "fan-out branch graph must be ractor-shareable: #{e.message}"
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
end
