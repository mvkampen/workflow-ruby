# frozen_string_literal: true

require 'test_helper'
require 'workflow/graph/visualizer'
require_relative '../examples/math_example'

describe Workflow::Graph::Visualizer do
  include Workflow::MathExample

  describe '#to_dot' do
    it 'renders the math example planner flow start vertices first' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new

      graph.add_node(:choose_move, choose_move(target: 24))
      graph.add_node(:apply_move, apply_move)
      graph.add_node(:done?, done?(target: 24))
      graph.add_edge(start, :choose_move)
      graph.add_edge(:choose_move, :apply_move)
      graph.add_edge(:apply_move, :done?)

      dot = Workflow::Graph::Visualizer.new(graph, signal_routes: { 'done?' => %i[stop retry compensate] }).to_dot

      expect(dot).to include('"start" [label="start"]')
      expect(dot).to include('"choose_move" [label="choose_move"]')
      expect(dot).to include('"apply_move" [label="apply_move"]')
      expect(dot).to include('"done?" [label="done?"]')
      expect(dot).to include('"stop" [shape=doublecircle, label="Success / Stop"]')
      expect(dot).to include('"retry" [shape=doublecircle, label="Retry returned"]')
      expect(dot).to include('"compensate" [shape=doublecircle, label="Compensate returned"]')
      expect(dot).to include('"start" -> "choose_move" [label="Start"]')
      expect(dot).to include('"choose_move" -> "apply_move" [label="Continue"]')
      expect(dot).to include('"apply_move" -> "done?" [label="Continue"]')
      expect(dot).to include('"done?" -> "stop" [label="Stop"]')
      expect(dot).to include('"done?" -> "retry" [label="Retry"]')
      expect(dot).to include('"done?" -> "compensate" [label="Compensate"]')
      expect(dot.index('"start" [label="start"]')).to be < dot.index('"choose_move" [label="choose_move"]')
    end
  end
end
