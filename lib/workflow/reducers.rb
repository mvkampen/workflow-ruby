# frozen_string_literal: true

require_relative 'reducers/registry'
require_relative 'reducer/identity'
require_relative 'reducer/values'
require_relative 'reducer/sum'
require_relative 'reducer/count'

module Workflow
  # Namespace for built-in reducers and reducer registry.
  # Reducers are used to combine results from multiple branches in a workflow.
  # Users can register custom reducers in the registry and reference them by name in workflow definitions.
  module Reducers
    module_function

    def register(name, reducer)
      registry.register(name, reducer)
    end

    def fetch(name)
      registry.fetch(name)
    end

    def resolve(reducer)
      registry.resolve(reducer)
    end

    def registered
      registry.registered
    end

    def reset!
      @registry = Registry.new(default_registry)
    end

    def registry
      @registry ||= Registry.new(default_registry)
    end

    module_function :registry

    def default_registry
      {
        identity: Identity.new,
        values: Values.new,
        sum: Sum.new,
        count: Count.new
      }
    end

    module_function :default_registry
  end
end

Workflow::Reducers.reset!
