# frozen_string_literal: true

require 'test_helper'

describe Workflow::Signal do
  describe 'pattern matching' do
    it 'supports class-pattern matching with a single value slot' do
      continue_signal = Workflow::Continue('next')
      stop_signal = Workflow::Stop(:done)

      continue_match = case continue_signal
                       in Workflow::Signal::Continue(String => value)
                         value
                       end

      stop_match = case stop_signal
                   in Workflow::Signal::Stop(Symbol => value)
                     value
                   end

      expect(continue_match).to eq('next')
      expect(stop_match).to eq(:done)
    end
  end
end
