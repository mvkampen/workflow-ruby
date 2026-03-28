# frozen_string_literal: true

require 'test_helper'

describe Workflow::Reducers do
  before do
    Workflow::Reducers.reset!
  end

  it 'resolves the identity reducer by default' do
    expect(Workflow::Reducers.resolve(nil)).to be_a(Workflow::Identity)
  end

  it 'resolves built-in reducers by key' do
    reducer = Workflow::Reducers.resolve(:values)

    expect(reducer.call({ 2 => :b, 1 => :a })).to eq(%i[b a])
  end

  it 'allows registering custom reducers' do
    custom_reducer = ->(results) { results.keys.join('-') }

    Workflow::Reducers.register(:keys, custom_reducer)

    expect(Workflow::Reducers.resolve(:keys)).to eq(custom_reducer)
  end

  it 'returns a defensive copy of the registry' do
    registered = Workflow::Reducers.registered
    registered.delete(:identity)

    expect(Workflow::Reducers.fetch(:identity)).to be_a(Workflow::Identity)
  end

  it 'raises for unknown reducers' do
    expect { Workflow::Reducers.resolve(:missing) }
      .to raise_error(ArgumentError, /Unknown reducer/)
  end
end
