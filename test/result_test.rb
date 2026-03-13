# frozen_string_literal: true

require 'test_helper'

describe Workflow::Result do
  describe 'type hierarchy' do
    it 'uses Result as the shared base class' do
      expect(Workflow::Success.superclass).to eq(Workflow::Result)
      expect(Workflow::Failure.superclass).to eq(Workflow::Result)
    end
  end

  describe 'Success' do
    it 'builds a successful result' do
      result = Success('ok')

      expect(result).to eq(Success('ok'))
      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.value!).to eq('ok')
      expect(result.error).to be_nil
    end
  end

  describe 'Failure' do
    it 'builds a failed result' do
      error = StandardError.new('boom')
      result = Failure(error)

      expect(result).to eq(Failure(error))
      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.value).to be_nil
      expect(result.error!).to eq(error)
    end
  end

  describe 'value semantics' do
    it 'compares and hashes by type and payload' do
      first = Success('ok')
      second = Success('ok')
      failure = Failure('ok')

      expect(first).to eq(second)
      expect(first.hash).to eq(second.hash)
      expect(first).not_to eq(failure)
    end
  end
end
