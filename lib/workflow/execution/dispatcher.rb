# frozen_string_literal: true

require_relative 'ractor_channel'

module Workflow
  module Execution
    # Dispatcher manages the processor pool and coordinates branch execution using
    # channels as the transport boundary.
    class Dispatcher
      DEFAULT_MAX_PROCESSORS = 10

      class << self
        def default
          @default ||= new
        end
      end

      def initialize(max_processors: DEFAULT_MAX_PROCESSORS, channel_class: RactorChannel)
        @max_processors = max_processors
        @channel_class = channel_class
        @processors = Array.new(@max_processors) { build_processor }
        @closed = false
        @dispatching = false
      end

      def dispatch(branch_graph:, start_vertex:, items:, workflow_id:, node:)
        raise ArgumentError, 'dispatcher is closed' if @closed
        raise ArgumentError, 'dispatcher does not support concurrent dispatch calls' if @dispatching

        @dispatching = true
        pending_jobs = normalize_items(items)
        processors = @processors.first([@processors.size, pending_jobs.size].min)
        busy_processors = []

        until pending_jobs.empty? && busy_processors.empty?
          while pending_jobs.any? && processors.any?
            processor = processors.shift
            branch, item = pending_jobs.shift
            processor.publish(
              Channel::Start.new(
                graph: branch_graph,
                start: start_vertex,
                branch:,
                state: item
              )
            )
            busy_processors << processor
          end

          processor, payload = @channel_class.select(*busy_processors)
          branch, result = payload
          busy_processors.delete(processor)
          processors << processor
          yield(
            Channel::Result.new(
              workflow_id:,
              node:,
              branch:,
              result:
            )
          )
        end
      ensure
        @dispatching = false
      end

      def close
        return if @closed

        @processors.each(&:close)
        @closed = true
      end

      private

      def normalize_items(items)
        if items.is_a?(Hash)
          items.to_a
        else
          items.each_with_index.map { |item, branch| [branch, item] }
        end
      end

      def build_processor
        @channel_class.new
      end
    end
  end
end
