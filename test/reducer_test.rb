# frozen_string_literal: true

require 'test_helper'

describe Workflow::Reducer do
  it 'requires subclasses to implement #call' do
    reducer = Workflow::Reducer.new

    expect { reducer.call({}) }
      .to raise_error(NotImplementedError, /must implement the #call method/)
  end
end
