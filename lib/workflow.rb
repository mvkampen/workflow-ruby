# frozen_string_literal: true

require_relative 'workflow/version'
require_relative 'workflow/result'

# Workflow engine to run isolated workflow steps with clear success/failure semantics.
module Workflow
  module_function

  def Success(value = nil)
    Workflow::Success.new(value)
  end

  def Failure(error = nil)
    Workflow::Failure.new(error)
  end
end
