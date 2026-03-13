# frozen_string_literal: true

require 'test_helper'

describe Workflow::Success do
  before do
    @success = Success(2)
  end

  it 'maps the wrapped value' do
    result = @success.map { |value| value * 3 }

    expect(result).to eq(Success(6))
  end

  it 'binds to another result' do
    result = @success.bind { |value| Success(value + 1) }

    expect(result).to eq(Success(3))
  end

  it 'raises when bind does not return a result' do
    error = assert_raises(TypeError) do
      @success.bind { |value| value + 1 }
    end

    expect(error.message).to eq('bind block must return a Workflow::Result')
  end

  it 'raises when unwrapping an error' do
    error = assert_raises(Workflow::Result::UnwrapError) do
      @success.error!
    end

    expect(error.message).to eq('cannot unwrap error from Success')
  end
end
