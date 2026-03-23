# frozen_string_literal: true

require 'test_helper'

describe Workflow::Graph do
  describe '#add_node' do
    it 'registers a node under a normalized vertex' do
      graph = Workflow::Graph.new
      node = Workflow::Node.new { |value| Workflow::Success(value) }

      vertex, registered_node = graph.add_node(:example, node)

      expect(vertex).to eq(Workflow::Vertex.new(:example))
      expect(registered_node).to eq(node)
    end
  end

  describe '#add_edge' do
    it 'registers edges between known vertices' do
      graph = Workflow::Graph.new
      graph.add_node(:first) { |value| Workflow::Success(value) }
      graph.add_node(:second) { |value| Workflow::Success(value) }

      edge = graph.add_edge(:first, :second)

      expect(edge).to be_a(Workflow::Edge)
      expect(edge.from).to eq(Workflow::Vertex.new(:first))
      expect(edge.to).to eq(Workflow::Vertex.new(:second))
    end
  end

  describe '#next_vertex_from' do
    it 'returns the only outgoing edge destination' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new
      graph.add_node(:first) { |value| Workflow::Success(value) }
      graph.add_edge(start, :first)

      expect(graph.next_vertex_from(start)).to eq(Workflow::Vertex.new(:first))
    end
  end

  describe '#freeze!' do
    it 'will mark the graph as frozen' do
      graph = Workflow::Graph.new
      graph.freeze!

      expect(graph).to be_frozen
    end

    it 'will not alter the graph' do
      graph = Workflow::Graph.new
      graph.add_node(:first) { |value| Workflow::Success(value) }
      graph.freeze!

      expect { graph.add_node(:second) { |value| Workflow::Success(value) } }
        .to raise_error(FrozenError, /can't modify frozen/)
    end
  end
end
