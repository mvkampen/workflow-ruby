# frozen_string_literal: true

module Workflow
  # Named label for node registration, allowing for descriptive identifiers
  class Vertex
    attr_reader :name

    def initialize(name)
      @name = name.to_sym
      freeze
    end

    def deconstruct
      [name]
    end

    def eql?(other)
      other.is_a?(self.class) && other.name == name
    end
    alias == eql?

    def hash
      [self.class, name].hash
    end

    # Indicates the start of a workflow sequence
    class Start < Vertex
      def initialize
        super(:start)
      end

      def eql?(other)
        equal?(other)
      end
      alias == eql?

      def hash
        object_id.hash
      end
    end
  end
end
