# frozen_string_literal: true

require 'test_helper'
require_relative 'examples/math_example'

describe Workflow::MathExample do
  include Workflow::MathExample

  describe 'done? node' do
    it 'stops when the target is reached' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      state = Workflow::MathExample::State.default(target: 24)

      runner.add_node(:done?, done?(target: 24))
      runner.add_node(:choose_move) { |s| Success([Stop(), s]) }
      runner.add_edge(start, :done?)
      runner.add_edge(:done?, :choose_move)

      expect(runner.run(start:, state: state.with(value: 24))).to eq(Success(state.with(value: 24)))
    end

    it 'returns retry when the value is a multiple of five' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      retry_state = Workflow::MathExample::State.default(value: 20, target: 24)

      runner.add_node(:done?, done?(target: 24))
      runner.add_edge(start, :done?)

      expect(runner.run(start:, state: retry_state)).to eq(
        Success([Retry(Workflow::MathExample::MultipleOfFive.new('value 20 is a multiple of 5')), retry_state])
      )
    end

    it 'returns compensate when the value exceeds the limit' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      compensate_state = Workflow::MathExample::State.default(value: 11, target: 24).with(value: 26)

      runner.add_node(:done?, done?(target: 24))
      runner.add_edge(start, :done?)

      expect(runner.run(start:, state: compensate_state)).to eq(
        Success([Compensate(Workflow::MathExample::OvershotLimit.new('value 26 exceeds 24')), compensate_state])
      )
    end

    it 'continues when the value is still in progress' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      continue_state = Workflow::MathExample::State.default(value: 22, target: 24)

      runner.add_node(:done?, done?(target: 24))
      runner.add_node(:choose_move) { |state| Success([Stop(), state]) }
      runner.add_edge(start, :done?)
      runner.add_edge(:done?, :choose_move)

      continue_result = runner.run(start:, state: continue_state)

      expect(continue_result).to eq(Success(continue_state))
    end
  end

  describe 'planner flow' do
    it 'chooses a move with a simple one-step planner and then applies it' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::MathExample::State.default(value: 11, target: 24)

      runner.add_node(:choose_move, choose_move(target: 24))
      runner.add_node(:apply_move, apply_move)
      runner.add_node(:finish) { |state| Success([Stop(), state]) }
      runner.add_edge(start, :choose_move)
      runner.add_edge(:choose_move, :apply_move)
      runner.add_edge(:apply_move, :finish)

      result = runner.run(start:, state: initial_state)

      expect(result).to eq(
        Success(
          Workflow::MathExample::State.new(
            seed: 11,
            value: 22,
            target: 24,
            move: nil,
            history: [{ move: :double, from: 11, to: 22 }]
          )
        )
      )
    end

    it 'can stop with a terminal value that differs from workflow state' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::MathExample::State.default(value: 11, target: 24)

      runner.add_node(:choose_move, choose_move(target: 24))
      runner.add_node(:apply_move, apply_move)
      runner.add_node(:finish) { |state| Success([Stop(state.history), state]) }
      runner.add_edge(start, :choose_move)
      runner.add_edge(:choose_move, :apply_move)
      runner.add_edge(:apply_move, :finish)

      expect(runner.run(start:, state: initial_state)).to eq(
        Success([{ move: :double, from: 11, to: 22 }])
      )
    end

    it 'can stop with an explicit nil result' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::MathExample::State.default(value: 11, target: 24)

      runner.add_node(:finish) { |_state| Success([Stop(nil), nil]) }
      runner.add_edge(start, :finish)

      expect(runner.run(start:, state: initial_state)).to eq(Success(nil))
    end

    it 'lets the planner make risky choices that can still fail at done?' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::MathExample::State.default(value: 22, target: 24)

      runner.add_node(:choose_move, choose_move(target: 24))
      runner.add_node(:apply_move, apply_move)
      runner.add_node(:done?, done?(target: 24))
      runner.add_edge(start, :choose_move)
      runner.add_edge(:choose_move, :apply_move)
      runner.add_edge(:apply_move, :done?)

      expect(runner.run(start:, state: initial_state)).to eq(
        Success([
                  Retry(Workflow::MathExample::MultipleOfFive.new('value 20 is a multiple of 5')),
                  Workflow::MathExample::State.new(
                    seed: 22,
                    value: 20,
                    target: 24,
                    move: nil,
                    history: [{ move: :subtract_two, from: 22, to: 20 }]
                  )
                ])
      )
    end

    it 'can handle retry outside the runner and continue to completion' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      state = Workflow::MathExample::State.default(value: 22, target: 24)

      runner.add_node(:choose_move, choose_move(target: 24))
      runner.add_node(:apply_move, apply_move)
      runner.add_node(:done?, done?(target: 24))
      runner.add_edge(start, :choose_move)
      runner.add_edge(:choose_move, :apply_move)
      runner.add_edge(:apply_move, :done?)

      first_pass = runner.run(start:, state:)

      expect(first_pass).to eq(
        Success([
                  Retry(Workflow::MathExample::MultipleOfFive.new('value 20 is a multiple of 5')),
                  Workflow::MathExample::State.new(
                    seed: 22,
                    value: 20,
                    target: 24,
                    move: nil,
                    history: [{ move: :subtract_two, from: 22, to: 20 }]
                  )
                ])
      )

      signal, retried_state = first_pass.value!
      expect(signal).to eq(Retry(Workflow::MathExample::MultipleOfFive.new('value 20 is a multiple of 5')))

      second_pass = runner.run(start:, state: retried_state.with(value: retried_state.value + 1))

      expect(second_pass).to eq(
        Success(
          Workflow::MathExample::State.new(
            seed: 22,
            value: 24,
            target: 24,
            move: nil,
            history: [
              { move: :subtract_two, from: 22, to: 20 },
              { move: :add_three, from: 21, to: 24 }
            ]
          )
        )
      )
    end

    it 'keeps reset_to_seed as a regular node that can be wired into the graph' do
      runner = Workflow::Runner.new
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::MathExample::State.default(value: 11, target: 24).with(value: 30)

      runner.add_node(:reset_to_seed, reset_to_seed)
      runner.add_node(:finish) { |state| Success([Stop(), state]) }
      runner.add_edge(start, :reset_to_seed)
      runner.add_edge(:reset_to_seed, :finish)

      expect(runner.run(start:, state: initial_state)).to eq(
        Success(
          Workflow::MathExample::State.new(
            seed: 11,
            value: 11,
            target: 24,
            move: nil,
            history: []
          )
        )
      )
    end
  end
end
