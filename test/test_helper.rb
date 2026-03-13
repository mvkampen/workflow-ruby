# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/spec'
require 'rspec/expectations/minitest_integration'
require 'rspec/mocks/minitest_integration'

require 'workflow_engine'

module Minitest
  class Spec
    include Workflow
  end
end
