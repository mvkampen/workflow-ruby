# Workflow Engine

`workflow` is a small Ruby workflow runtime built around:

- a `Workflow::Graph` of nodes and edges
- `Workflow::Result` values for success and failure
- `Workflow::Signal` values for control flow
- `Workflow::Execution::Engine` as the execution entrypoint

## Core model

Nodes return `Workflow::Success([signal, value])` or `Workflow::Failure(error)`.

The built-in control signals are:

- `Continue`
- `Stop`
- `Retry`
- `Compensate`
- `FanOut`

`Continue` follows the next graph edge. `Stop` terminates execution with either
the current state or an explicit result. `Retry` and `Compensate` are returned
to the caller as successful outputs. `FanOut` executes branch work in parallel
and resumes at a join vertex.

## Building a graph

```ruby
require 'workflow_engine'

start = Workflow::Start
graph = Workflow::Graph.new

graph.add_node(:trim) { |value| Success([Continue(), value.strip]) }
graph.add_node(:upcase) { |value| Success([Continue(), value.upcase]) }
graph.add_node(:finish) { |value| Success([Stop(), "#{value}!"]) }

graph.add_edge(start, :trim)
graph.add_edge(:trim, :upcase)
graph.add_edge(:upcase, :finish)
```

Graphs are mutable while being built. The engine freezes the graph on first
execution.

## Running a graph

```ruby
engine = Workflow::Execution::Engine.new(graph:)
result = engine.run(start:, state: '  hello  ')

result
# => Success("HELLO!")
```

Execution always begins from a `Workflow::Vertex::Start`.

## FanOut

`FanOut(join:, items:)` lets a node launch branch executions in parallel. Each
branch receives one item as its full branch state.

The signal names the join vertex in the main graph. The engine then:

1. finds the next vertex after the current node
2. builds a branch subgraph from that point until `join`
3. runs one ractor branch per item
4. collects an `Array<Workflow::Result>`
5. resumes main execution at the join node with that result array as state

Example:

```ruby
start = Workflow::Start

work = Class.new do
  def call(item)
    Workflow::Success([Workflow::Continue(), item * 2])
  end
end.new.freeze

graph = Workflow::Graph.new
graph.add_node(:divide) do |state|
  Success([FanOut(join: :join, items: [1, 2, 3]), state])
end
graph.add_node(:work, work)
graph.add_node(:join) do |results|
  sum = results.sum(10, &:value!)
  Success([Continue(), sum])
end
graph.add_node(:end) do |sum|
  Success([Stop(), sum])
end

graph.add_edge(start, :divide)
graph.add_edge(:divide, :work)
graph.add_edge(:work, :join)
graph.add_edge(:join, :end)

engine = Workflow::Execution::Engine.new(graph:)
engine.run(start:, state: 10)
# => Success(22)
```

Current constraint: branch graphs must be ractor-shareable. In practice that
means branch nodes should be shareable callable objects, not arbitrary closures.

## Optional tooling

These are available as opt-in requires and are not loaded by default:

- `workflow/graph/validator`
- `workflow/graph/visualizer`

## Development

Install dependencies:

```sh
bundle install
```

Run the test suite:

```sh
bundle exec rake test
```
