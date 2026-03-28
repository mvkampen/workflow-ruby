# frozen_string_literal: true

require_relative 'channel'

module Workflow
  module Execution
    # RactorChannel is a minimal processor-backed channel implemented with Ractor.
    class RactorChannel < Channel
      attr_reader :ractor

      class << self
        def select(*channels)
          ractor, payload = Ractor.select(*channels.map(&:ractor))
          [channels.fetch(channels.index { |channel| channel.ractor == ractor }), payload]
        end
      end

      def initialize
        super

        @ractor = build_ractor
      end

      def publish(message)
        @ractor.send(message)
      end

      def receive
        @ractor.take
      end

      def close
        @ractor.send(Stop.new)
        @ractor.take
      end

      private

      def build_ractor
        Ractor.new do
          loop do
            command = Ractor.receive

            break if command.is_a?(Stop)

            result = Workflow::Execution::Engine.new(graph: command.graph).run(
              start: command.start,
              state: command.state
            )

            Ractor.yield([command.branch, result])
          end
        end
      end
    end
  end
end
