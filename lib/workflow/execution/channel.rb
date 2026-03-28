# frozen_string_literal: true

module Workflow
  module Execution
    # Channel defines the minimal transport contract for passing messages
    # between the dispatcher and a processor.
    class Channel
      Start = Data.define(:graph, :start, :branch, :state)
      Stop = Data.define
      Result = Data.define(:workflow_id, :node, :branch, :result)

      def publish(message)
        raise NotImplementedError, "#{self.class} must implement #publish"
      end

      def receive
        raise NotImplementedError, "#{self.class} must implement #receive"
      end

      def close; end
    end
  end
end
