# frozen_string_literal: true

require_relative 'workflow/version'
require_relative 'workflow/result'
require_relative 'workflow/signal'
require_relative 'workflow/edge'
require_relative 'workflow/node'
require_relative 'workflow/vertex'
require_relative 'workflow/graph'
require_relative 'workflow/execution/engine'

# Workflow engine to run isolated workflow steps with clear success/failure semantics.
module Workflow
  module_function

  def Success(value = nil) = Success.new(value)
  def Failure(error = nil) = Failure.new(error)
  def Continue = Signal::Continue.new
  def Compensate(error) = Signal::Compensate.new(error)
  def Retry(error) = Signal::Retry.new(error)
  def Stop(result = Signal::Stop::UNSET) = Signal::Stop.new(result)
  def Start = Vertex::Start.new
  def Edge(from:, to:) = Edge.new(from:, to:)
  def Vertex(name) = Vertex.new(name)
end
