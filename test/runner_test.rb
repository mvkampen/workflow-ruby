# frozen_string_literal: true

require 'test_helper'

describe Workflow::Runner do
  describe '#register and #call' do
    it 'registers compute nodes by name and executes them' do
      runner = Workflow::Runner.new
      runner.register(:double) { |value| Success(value * 2) }

      expect(runner.call(:double, 21)).to eq(Success(42))
      expect(runner).to be_registered(:double)
    end

    it 'supports explicit node objects' do
      node = Class.new(Workflow::Node).new do |value|
        Workflow::Success(value.upcase)
      end
      runner = Workflow::Runner.new(nodes: { upcase: node })

      expect(runner.call(:upcase, 'hello')).to eq(Success('HELLO'))
    end
  end

  describe '#run' do
    it 'returns the initial value wrapped in Success if no transformations are provided' do
      runner = Workflow::Runner.new

      expect(runner.run(input: 'seed')).to eq(Success('seed'))
    end

    it 'pipes the successful value through registered nodes' do
      runner = Workflow::Runner.new
      runner.register(:trim) { |value| Success(value.strip) }
      runner.register(:upcase) { |value| Success(value.upcase) }

      result = runner.run(:trim, :upcase, input: '  hello  ')

      expect(result).to eq(Success('HELLO'))
    end

    it 'short-circuits on failures without shared state' do
      observed = []
      runner = Workflow::Runner.new
      runner.register(:first) do |value|
        observed << [:first, value]
        Failure(:stop)
      end
      runner.register(:second) do |value|
        observed << [:second, value]
        Success(:unreachable)
      end

      result = runner.run(:first, :second, input: :start)

      expect(result).to eq(Failure(:stop))
      expect(observed).to eq([%i[first start]])
    end
  end

  describe 'validation' do
    it 'raises when a node is missing' do
      runner = Workflow::Runner.new

      expect { runner.call(:missing, 'value') }
        .to raise_error(KeyError, /unknown node registered/)
    end

    it 'raises when a node does not return a Result' do
      runner = Workflow::Runner.new
      runner.register(:invalid) { |_value| 'not a result' }

      expect { runner.call(:invalid, 'value') }
        .to raise_error(TypeError, /must return a Workflow::Result/)
    end
  end
end
