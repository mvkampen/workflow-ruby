# frozen_string_literal: true

require 'test_helper'

describe Workflow::Failure do
  before do
    @failure = Failure(:nope)
  end

  it 'does not map the error' do
    result = @failure.map { |value| value.to_s.upcase }

    expect(result).to eq(@failure)
  end

  it 'does not bind the error' do
    result = @failure.bind { |value| Success(value) }

    expect(result).to eq(@failure)
  end

  it 'raises when unwrapping a value' do
    error = assert_raises(Workflow::Result::UnwrapError) do
      @failure.value!
    end

    expect(error.message).to eq('cannot unwrap value from Failure')
  end
end
