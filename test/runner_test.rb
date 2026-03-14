# frozen_string_literal: true

require 'test_helper'

describe Workflow::Runner do
  describe '#add_node' do
    it 'registers a block as a nodes under a vertex' do
      runner = Workflow::Runner.new
      vertex, node = runner.add_node(:double) { |value| Success(value * 2) }

      expect(vertex).to eq(Workflow::Vertex.new(:double))
      expect(node).to be_a(Workflow::Node)
    end

    it 'supports explicit node objects' do
      node = Class.new(Workflow::Node).new do |value|
        Workflow::Success(value.upcase)
      end
      runner = Workflow::Runner.new
      _, registered_node = runner.add_node(:upcase, node)

      expect(registered_node).to eq(node)
    end
  end

  describe '#add_edge' do
    it 'registers edges between nodes' do
      runner = Workflow::Runner.new
      runner.add_node(:first) { |value| Success(value + 1) }
      runner.add_node(:second) { |value| Success(value * 2) }
      edge = runner.add_edge(:first, :second)

      expect(edge).to be_a(Workflow::Edge)
      expect(edge.from).to eq(Workflow::Vertex.new(:first))
      expect(edge.to).to eq(Workflow::Vertex.new(:second))
    end

    it 'validates that both nodes exist' do
      runner = Workflow::Runner.new
      runner.add_node(:existing) { |value| Success(value) }
      start = Workflow::Vertex::Start.new

      expect { runner.add_edge(:existing, :missing) }
        .to raise_error(ArgumentError, /to node not found/)
      expect { runner.add_edge(:missing, :existing) }
        .to raise_error(ArgumentError, /from node not found/)
      expect { runner.add_edge(start, :existing) }.not_to raise_error
    end
  end

  describe '#run' do
    it 'runs nodes by following direct edges from the provided start vertex' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      runner.add_node(:trim) { |value| Success([Continue(), value.strip]) }
      runner.add_node(:upcase) { |value| Success([Continue(), value.upcase]) }
      runner.add_node(:finish) { |value| Success([Stop(), "#{value}!"]) }
      runner.add_edge(start, :trim)
      runner.add_edge(:trim, :upcase)
      runner.add_edge(:upcase, :finish)

      expect(runner.run(start:, input: '  hello  ')).to eq(Success('HELLO!'))
    end

    it 'stops immediately on failure without shared state' do
      observed = []
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      runner.add_node(:first) do |value|
        observed << [:first, value]
        Failure(:boom)
      end
      runner.add_node(:second) do |value|
        observed << [:second, value]
        Success([Stop(), :unreachable])
      end
      runner.add_edge(start, :first)
      runner.add_edge(:first, :second)

      result = runner.run(start:, input: :start)

      expect(result).to eq(Failure(:boom))
      expect(observed).to eq([%i[first start]])
    end

    it 'raises when a start vertex has no outgoing edge' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      expect { runner.run(start:, input: 2) }
        .to raise_error(KeyError, /unknown outgoing edge/)
    end

    it 'raises when a vertex has multiple outgoing direct edges' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      runner.add_node(:first) { |value| Success([Continue(), value]) }
      runner.add_node(:second) { |_value| Success([Stop(), :second]) }
      runner.add_node(:third) { |_value| Success([Stop(), :third]) }
      runner.add_edge(start, :first)
      runner.add_edge(:first, :second)
      runner.add_edge(:first, :third)

      expect { runner.run(start:, input: :value) }
        .to raise_error(ArgumentError, /expected exactly one outgoing edge/)
    end

    it 'raises when a successful node does not return a signal/value pair' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      runner.add_node(:invalid) { |value| Success(value) }
      runner.add_edge(start, :invalid)

      expect { runner.run(start:, input: :value) }
        .to raise_error(TypeError, /must return \[Workflow::Signal, value\]/)
    end
  end

  describe 'validation' do
    it 'raises when a node does not return a Result' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new

      runner.add_node(:invalid) { |_value| 'not a result' }
      runner.add_edge(start, :invalid)

      expect { runner.run(start:, input: :value) }
        .to raise_error(TypeError, /must return a Workflow::Result/)
    end

    it 'requires a start vertex when running' do
      runner = Workflow::Runner.new

      expect { runner.run(start: Workflow::Vertex(:start), input: :value) }
        .to raise_error(ArgumentError, /start must be a Workflow::Vertex::Start/)
    end
  end
end
