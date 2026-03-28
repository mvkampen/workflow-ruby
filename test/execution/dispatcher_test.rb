# frozen_string_literal: true

require 'test_helper'

describe Workflow::Execution::Dispatcher do
  def build_graph
    start = Workflow::Vertex::Start.new
    work = Class.new do
      def call(value)
        Workflow::Success([Workflow::Stop(), value * 2])
      end
    end.new

    graph = Workflow::Graph.new
    graph.add_node(:work, work)
    graph.add_edge(start, :work)
    [graph, start]
  end

  def dispatch_items(items)
    dispatcher = Workflow::Execution::Dispatcher.new(max_processors: 4)
    graph, start = build_graph
    results = {}

    dispatcher.dispatch(
      branch_graph: graph,
      start_vertex: start,
      items:,
      workflow_id: 'workflow-1',
      node: :split
    ) do |branch_result|
      results[branch_result.branch] = branch_result.result.value!
    end

    results
  ensure
    dispatcher.close
  end

  it 'dispatches array items across a smaller processor pool' do
    items = (1..30).to_a.shuffle
    results = dispatch_items(items)

    expect(results).to eq(items.each_with_index.to_h { |value, index| [index, value * 2] })
  end

  it 'dispatches hash items across a smaller processor pool' do
    items = ('a'..'z').to_a.shuffle
                      .each_with_index.to_h
    results = dispatch_items(items)

    expect(results).to eq(items.transform_values { |value| value * 2 })
  end
end
