# Workflow Engine

A Ruby gem scaffold for a distributed workflow engine with clear separation
between orchestration, transport, and worker execution.

Nodes return `Workflow::Success([signal, value])`, where `signal` is one of
`Continue`, `Stop`, `Compensate`, or `Retry`.

Workflow routing is modeled in the graph: non-start edges can be labeled with
the signal class they handle, and `Retry`/`Compensate` follow those edges.

## Development

Install dependencies:

```sh
bundle install
```

Run the test suite:

```sh
bundle exec rake test
```
