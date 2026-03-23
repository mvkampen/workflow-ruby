# frozen_string_literal: true

require 'test_helper'

describe Workflow::Execution::Engine do
  describe '#run' do
    it 'runs nodes by following direct edges from the provided start vertex' do
      start = Workflow::Vertex::Start.new

      graph = Workflow::Graph.new
      graph.add_node(:trim) { |value| Success([Continue(), value.strip]) }
      graph.add_node(:upcase) { |value| Success([Continue(), value.upcase]) }
      graph.add_node(:finish) { |value| Success([Stop(), "#{value}!"]) }
      graph.add_edge(start, :trim)
      graph.add_edge(:trim, :upcase)
      graph.add_edge(:upcase, :finish)

      engine = Workflow::Execution::Engine.new(graph:)
      expect(engine.run(start:, state: '  hello  ')).to eq(Success('HELLO!'))
    end

    it 'stops immediately on failure without shared state' do
      observed = []

      start = Workflow::Vertex::Start.new

      graph = Workflow::Graph.new
      graph.add_node(:first) do |value|
        observed << [:first, value]
        Failure(:boom)
      end
      graph.add_node(:second) do |value|
        observed << [:second, value]
        Success([Stop(), :unreachable])
      end
      graph.add_edge(start, :first)
      graph.add_edge(:first, :second)

      engine = Workflow::Execution::Engine.new(graph:)
      result = engine.run(start:, state: :start)

      expect(result).to eq(Failure(:boom))
      expect(observed).to eq([%i[first start]])
    end

    it 'raises when a start vertex has no outgoing edge' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new
      engine = Workflow::Execution::Engine.new(graph:)

      expect { engine.run(start:, state: nil) }
        .to raise_error(Workflow::Graph::MissingOutgoingEdgeError, /no outgoing edge/)
    end

    it 'raises when a vertex has multiple outgoing direct edges' do
      start = Workflow::Vertex::Start.new

      graph = Workflow::Graph.new
      graph.add_node(:first) { |value| Success([Continue(), value]) }
      graph.add_node(:second) { |_value| Success([Stop(), :second]) }
      graph.add_node(:third) { |_value| Success([Stop(), :third]) }
      graph.add_edge(start, :first)
      graph.add_edge(:first, :second)
      graph.add_edge(:first, :third)

      engine = Workflow::Execution::Engine.new(graph:)

      expect { engine.run(start:, state: :value) }
        .to raise_error(ArgumentError, /expected exactly one outgoing edge/)
    end

    it 'raises when a successful node does not return a signal/value pair' do
      start = Workflow::Vertex::Start.new

      graph = Workflow::Graph.new
      graph.add_node(:invalid) { |value| Success(value) }
      graph.add_edge(start, :invalid)

      engine = Workflow::Execution::Engine.new(graph:)

      expect { engine.run(start:, state: :value) }
        .to raise_error(TypeError, /must return \[Workflow::Signal, value\]/)
    end

  end

  describe 'validation' do
    it 'raises when a node does not return a Result' do
      start = Workflow::Vertex::Start.new

      graph = Workflow::Graph.new
      graph.add_node(:invalid) { |_value| 'not a result' }
      graph.add_edge(start, :invalid)

      engine = Workflow::Execution::Engine.new(graph:)

      expect { engine.run(start:, state: :value) }
        .to raise_error(TypeError, /must return a Workflow::Result/)
    end

    it 'requires a start vertex when running' do
      graph = Workflow::Graph.new
      engine = Workflow::Execution::Engine.new(graph:)

      expect { engine.run(start: Workflow::Vertex(:start), state: :value) }
        .to raise_error(ArgumentError, /start must be a Workflow::Vertex::Start/)
    end
  end
end
