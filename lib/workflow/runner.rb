# frozen_string_literal: true

module Workflow
  # Runner is responsible for managing and executing workflow nodes.
  # It allows registering nodes by name and running them in sequence, passing results between them.
  class Runner
    def initialize(nodes: {})
      @nodes = {}
      nodes.each do |name, node|
        register(name, node)
      end
    end

    def register(name, node = nil, &block)
      raise ArgumentError, 'provide a node or a block, not both' if node.is_a?(Node) && block

      callable = node || Workflow::Node.new(&block)
      @nodes[normalize_name(name)] = callable
      self
    end

    def registered?(name)
      @nodes.key?(normalize_name(name))
    end

    def call(name, message = nil)
      execute(fetch(name), message)
    end

    def run(*names, input: nil)
      names.reduce(Workflow::Success(input)) do |result, name|
        result.bind { |value| call(name, value) }
      end
    end

    private

    def execute(node, message)
      result = node.call(message)

      raise TypeError, "#{node.class} must return a Workflow::Result" unless Result.valid_result?(result)

      result
    end

    def fetch(name)
      @nodes.fetch(normalize_name(name))
    rescue KeyError
      raise KeyError, "unknown node registered as #{name.inspect}"
    end

    def normalize_name(name)
      name.to_sym
    end
  end
end
