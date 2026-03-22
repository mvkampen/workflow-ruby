# frozen_string_literal: true

module Workflow
  # Example workflow demonstrating a simple math game where the goal is to reach a target number using a set of moves.
  # The workflow includes nodes for checking if the target is reached, choosing a move, and applying the move.
  # It also demonstrates the use of Continue, Stop, Retry, and Compensate
  module MathExample
    class Error < StandardError; end
    class MultipleOfFive < Error; end
    class OvershotLimit < Error; end

    State = Data.define(:seed, :value, :target, :move, :history) do
      def self.default(value: nil, target: nil)
        new(seed: value, value:, target:, move: nil, history: [])
      end
    end

    MOVES = {
      add_three: ->(value) { value + 3 },
      subtract_two: ->(value) { value - 2 },
      double: ->(value) { value * 2 }
    }.freeze

    module_function

    def choose_move(target:, limit: target)
      Workflow::Node.new do |state|
        value = state.value

        move = MOVES.min_by do |_name, operation|
          score_move(operation.call(value), target:, limit:)
        end.first

        Workflow::Success([Workflow::Continue(), state.with(move:)])
      end
    end

    def apply_move
      Workflow::Node.new do |state|
        next_value = MOVES.fetch(state.move).call(state.value)
        history = state.history + [{ move: state.move, from: state.value, to: next_value }]

        Workflow::Success([Workflow::Continue(), state.with(value: next_value, move: nil, history:)])
      end
    end

    def reset_to_seed
      Workflow::Node.new do |state|
        reset_state = state.with(value: state.seed, move: nil, history: [])
        Workflow::Success([Workflow::Continue(), reset_state])
      end
    end

    # rubocop:disable Metrics/MethodLength
    def done?(target:, limit: target)
      Workflow::Node.new do |state|
        if state.value == target
          Workflow::Success([Workflow::Stop(), state])
        elsif state.value > limit
          error = OvershotLimit.new("value #{state.value} exceeds #{limit}")
          Workflow::Success([Workflow::Compensate(error), state])
        elsif (state.value % 5).zero?
          error = MultipleOfFive.new("value #{state.value} is a multiple of 5")
          Workflow::Success([Workflow::Retry(error), state])
        else
          Workflow::Success([Workflow::Continue(), state])
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def score_move(next_value, target:, limit:)
      score = (target - next_value).abs
      score += 100 if (next_value % 5).zero?
      score += 1_000 if next_value > limit
      score
    end
  end
end
