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

    it 'raises when the vertex is already registered' do
      graph = Workflow::Graph.new
      graph.add_node(:example) { |value| Workflow::Success(value) }

      error = assert_raises(Workflow::Graph::DuplicateVertexError) do
        graph.add_node(:example) { |value| Workflow::Success(value) }
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:example))
    end
  end

  describe '#replace_node' do
    it 'replaces an existing node explicitly' do
      graph = Workflow::Graph.new
      graph.add_node(:example) { |value| Workflow::Success(value) }

      _, node = graph.replace_node(:example) { |value| Workflow::Success(value * 2) }

      expect(node.call(3)).to eq(Workflow::Success(6))
    end

    it 'raises when replacing an unknown vertex' do
      graph = Workflow::Graph.new

      error = assert_raises(Workflow::Graph::UnknownVertexError) do
        graph.replace_node(:missing) { |value| Workflow::Success(value) }
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:missing))
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

    it 'raises a specialized error when the source vertex is unknown' do
      graph = Workflow::Graph.new
      graph.add_node(:known) { |value| Workflow::Success(value) }

      error = assert_raises(Workflow::Graph::UnknownVertexError) do
        graph.add_edge(:missing, :known)
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:missing))
    end

    it 'raises a specialized error when the target vertex is unknown' do
      graph = Workflow::Graph.new
      graph.add_node(:known) { |value| Workflow::Success(value) }

      error = assert_raises(Workflow::Graph::UnknownVertexError) do
        graph.add_edge(Workflow::Start(), :missing)
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:missing))
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

    it 'raises when a known vertex has no outgoing edge' do
      graph = Workflow::Graph.new
      graph.add_node(:first) { |value| Workflow::Success(value) }

      error = assert_raises(Workflow::Graph::MissingOutgoingEdgeError) do
        graph.next_vertex_from(:first)
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:first))
    end

    it 'raises when an unknown vertex is used for outgoing edge lookup' do
      graph = Workflow::Graph.new

      error = assert_raises(Workflow::Graph::UnknownVertexError) do
        graph.next_vertex_from(:missing)
      end

      expect(error.vertex).to eq(Workflow::Vertex.new(:missing))
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
