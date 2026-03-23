# frozen_string_literal: true

require 'test_helper'

require 'workflow/graph/validator'

describe Workflow::Graph::Validator do
  describe '#validate' do
    it 'accepts a connected graph with a start edge' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new
      graph.add_node(:first) { |value| Workflow::Success(value) }
      graph.add_node(:second) { |value| Workflow::Success(value) }
      graph.add_edge(start, :first)
      graph.add_edge(:first, :second)

      expect(Workflow::Graph::Validator.new(graph).validate).to eq([])
    end

    it 'returns structured validation problems' do
      graph = Workflow::Graph.new
      orphaned = Workflow::Vertex.new(:orphaned)
      graph.add_node(orphaned) { |value| Workflow::Success(value) }

      problems = Workflow::Graph::Validator.new(graph).validate

      expect(problems.map(&:class)).to include(
        Workflow::Graph::MissingEntryPointError,
        Workflow::Graph::MissingIncomingEdgeError,
        Workflow::Graph::UnreachableVertexError
      )
      expect(problems.grep(Workflow::Graph::MissingIncomingEdgeError).map(&:vertex)).to include(orphaned)
      expect(problems.grep(Workflow::Graph::UnreachableVertexError).map(&:vertex)).to include(orphaned)
    end

    it 'returns validation problems for an unconnected vertex' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new
      graph.add_node(:connected) { |value| Workflow::Success(value) }
      graph.add_node(:orphaned) { |value| Workflow::Success(value) }
      graph.add_edge(start, :connected)

      problems = Workflow::Graph::Validator.new(graph).validate

      expect(problems.map(&:class)).to include(
        Workflow::Graph::MissingIncomingEdgeError,
        Workflow::Graph::UnreachableVertexError
      )
      expect(problems.grep(Workflow::Graph::MissingIncomingEdgeError).map(&:vertex))
        .to include(Workflow::Vertex.new(:orphaned))
    end

    it 'returns a missing entry point problem when a graph has no start edge' do
      graph = Workflow::Graph.new
      graph.add_node(:first) { |value| Workflow::Success(value) }

      problems = Workflow::Graph::Validator.new(graph).validate

      expect(problems.map(&:class)).to include(Workflow::Graph::MissingEntryPointError)
    end
  end
end
