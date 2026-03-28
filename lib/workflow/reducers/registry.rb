# frozen_string_literal: true

module Workflow
  module Reducers
    # Internal registry class for managing reducers. Not intended for direct use by users of the library.
    # Users should interact with the registry through the Workflow::Reducers module methods.
    class Registry
      def initialize(reducers = {})
        @reducers = reducers
      end

      def register(name, reducer)
        validate_name!(name)
        validate_callable!(reducer, message: 'Reducer must respond to #call')

        @reducers[name] = reducer
      end

      def fetch(name)
        @reducers.fetch(name) do
          raise ArgumentError, "Unknown reducer: #{name.inspect}"
        end
      end

      def resolve(reducer)
        case reducer
        when nil
          fetch(:identity)
        when Symbol
          fetch(reducer)
        else
          validate_callable!(reducer, message: 'Reducer must be a Symbol or respond to #call')
          reducer
        end
      end

      def registered
        @reducers.dup
      end

      private

      def validate_name!(name)
        return if name.is_a?(Symbol)

        raise ArgumentError, 'Reducer name must be a Symbol'
      end

      def validate_callable!(reducer, message:)
        return if reducer.respond_to?(:call)

        raise ArgumentError, message
      end
    end
  end
end
