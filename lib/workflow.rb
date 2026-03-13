# frozen_string_literal: true

require_relative 'workflow/version'
require_relative 'workflow/result'
require_relative 'workflow/nodes/node'
require_relative 'workflow/runner'

# Workflow engine to run isolated workflow steps with clear success/failure semantics.
module Workflow
  module_function

  def Success(value = nil)
    Success.new(value)
  end

  def Failure(error = nil)
    Failure.new(error)
  end
end
