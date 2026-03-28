# frozen_string_literal: true

require 'test_helper'

describe Workflow::Signal do
  describe 'immutability' do
    it 'freezes continue signals' do
      expect(Workflow::Continue()).to be_frozen
    end
  end

  describe 'pattern matching' do
    it 'supports class-pattern matching for control and error signals' do
      continue_signal = Workflow::Continue()
      fan_out_signal = Workflow::FanOut(
        join: :join,
        items: [1, 2, 3],
        reducer: :values
      )
      compensate_signal = Workflow::Compensate(:rollback)
      retry_signal = Workflow::Retry(3)
      stop_signal = Workflow::Stop(:done)
      state_stop_signal = Workflow::Stop()

      continue_match = case continue_signal
                       in Workflow::Signal::Continue
                         :continue
                       end

      fan_out_match = case fan_out_signal
                      in Workflow::Signal::FanOut(Workflow::Vertex(Symbol => vertex), Array => items, Symbol => reducer)
                        [vertex, items, reducer]
                      end

      compensate_match = case compensate_signal
                         in Workflow::Signal::Compensate(Symbol => error)
                           error
                         end

      retry_match = case retry_signal
                    in Workflow::Signal::Retry(Integer => error)
                      error
                    end

      stop_match = case stop_signal
                   in Workflow::Signal::Stop(Symbol => result)
                     result
                   end

      state_stop_match = case state_stop_signal
                         in Workflow::Signal::Stop()
                           :state
                         end

      expect(continue_match).to eq(:continue)
      expect(fan_out_match).to eq([:join, [1, 2, 3], :values])
      expect(compensate_match).to eq(:rollback)
      expect(retry_match).to eq(3)
      expect(stop_match).to eq(:done)
      expect(state_stop_match).to eq(:state)
    end
  end
end
