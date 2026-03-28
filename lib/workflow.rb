# frozen_string_literal: true

require_relative 'workflow/version'
require_relative 'workflow/result'
require_relative 'workflow/signal'
require_relative 'workflow/edge'
require_relative 'workflow/node'
require_relative 'workflow/vertex'
require_relative 'workflow/graph'
require_relative 'workflow/reducer'
require_relative 'workflow/reducers'
require_relative 'workflow/execution/engine'

# Workflow engine to run isolated workflow steps with clear success/failure semantics.
module Workflow
  module_function

  def Success(value = nil) = Success.new(value)
  def Failure(error = nil) = Failure.new(error)
  def Continue = Signal::Continue.new
  def FanOut(join:, items:, reducer: :values) = Signal::FanOut.new(join: normalize_vertex(join), items:, reducer:)
  def Compensate(error) = Signal::Compensate.new(error)
  def Retry(error) = Signal::Retry.new(error)
  def Stop(result = Signal::Stop::UNSET) = Signal::Stop.new(result)
  def Start = Vertex::Start.new
  def Edge(from:, to:) = Edge.new(from:, to:)
  def Vertex(name) = Vertex.new(name)

  def normalize_vertex(value)
    case value
    in Vertex then value
    in Symbol
      Vertex.new(value)
    in String
      Vertex.new(value.to_sym)
    else
      raise ArgumentError, "unsupported vertex #{value.inspect}"
    end
  end
  private_class_method :normalize_vertex
end
