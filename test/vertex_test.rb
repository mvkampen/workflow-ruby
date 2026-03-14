# frozen_string_literal: true

require 'test_helper'

describe Workflow::Vertex do
  describe 'pattern matching' do
    it 'supports class-pattern matching with a single value slot' do
      vertex = Workflow::Vertex.new(:next)

      match = case vertex
              in Workflow::Vertex(value)
                value
              end

      expect(match).to eq(:next)
    end
  end

  describe 'eql?' do
    it 'compares by value' do
      first = Workflow::Vertex.new(:next)
      second = Workflow::Vertex.new(:next)
      different = Workflow::Vertex.new(:other)

      expect(first).to eq(second)
      expect(first).not_to eq(different)
    end
  end

  describe Workflow::Vertex::Start do
    describe 'eql?' do
      it 'compares by global identity' do
        first = Workflow::Vertex::Start.new
        second = Workflow::Vertex::Start.new

        expect(first).not_to eq(second)
      end

      it 'a normal vertex with the same value is not equal to the start vertex' do
        start_vertex = Workflow::Vertex::Start.new
        normal_vertex = Workflow::Vertex.new(:start)

        expect(start_vertex).not_to eq(normal_vertex)
      end
    end
  end
end
