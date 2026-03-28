# frozen_string_literal: true

require 'test_helper'
require 'workflow/graph/visualizer'
require_relative '../examples/option_comparison_example'

describe Workflow::Graph::Visualizer do
  include Workflow::OptionComparisonExample

  describe '#to_dot' do
    it 'renders the option comparison flow start vertices first' do
      graph = Workflow::Graph.new
      start = Workflow::Vertex::Start.new

      graph.add_node(:compare_options, compare_options(desired_days: 3, join: :review_quotes))
      graph.add_node(:request_quote, request_quote)
      graph.add_node(:review_quotes) { |state| Success([Continue(), state]) }
      graph.add_node(:confirm_quote, confirm_quote(max_price: 14))
      graph.add_edge(start, :compare_options)
      graph.add_edge(:compare_options, :request_quote)
      graph.add_edge(:request_quote, :review_quotes)
      graph.add_edge(:review_quotes, :confirm_quote)

      dot = Workflow::Graph::Visualizer.new(graph, signal_routes: { 'confirm_quote' => %i[stop retry compensate] }).to_dot

      expect(dot).to include('"start" [label="start"]')
      expect(dot).to include('"compare_options" [label="compare_options"]')
      expect(dot).to include('"request_quote" [label="request_quote"]')
      expect(dot).to include('"review_quotes" [label="review_quotes"]')
      expect(dot).to include('"confirm_quote" [label="confirm_quote"]')
      expect(dot).to include('"stop" [shape=doublecircle, label="Success / Stop"]')
      expect(dot).to include('"retry" [shape=doublecircle, label="Retry returned"]')
      expect(dot).to include('"compensate" [shape=doublecircle, label="Compensate returned"]')
      expect(dot).to include('"start" -> "compare_options" [label="Start"]')
      expect(dot).to include('"compare_options" -> "request_quote" [label="Continue"]')
      expect(dot).to include('"request_quote" -> "review_quotes" [label="Continue"]')
      expect(dot).to include('"review_quotes" -> "confirm_quote" [label="Continue"]')
      expect(dot).to include('"confirm_quote" -> "stop" [label="Stop"]')
      expect(dot).to include('"confirm_quote" -> "retry" [label="Retry"]')
      expect(dot).to include('"confirm_quote" -> "compensate" [label="Compensate"]')
      expect(dot.index('"start" [label="start"]')).to be < dot.index('"compare_options" [label="compare_options"]')
    end
  end
end
