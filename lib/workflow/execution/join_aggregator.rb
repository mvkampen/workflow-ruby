# frozen_string_literal: true

module Workflow
  module Execution
    # JoinAggregator is responsible for collecting results from multiple branches of a workflow and applying
    # a reducer function once all expected results have been collected.
    class JoinAggregator
      attr_reader :node

      def initialize(node:, branches:, reducer:)
        @node = node
        @expected_count = branches.size
        @reducer = reducer
        @results = branches.each_with_object({}) { |branch, results| results[branch] = nil }
        @completed = 0
      end

      def record(result)
        workflow_result = result.result
        return workflow_result if workflow_result.failure?

        @completed += 1 if @results[result.branch].nil?
        @results[result.branch] = workflow_result.value!
        return nil unless complete?

        @reducer.call(@results)
      end

      def complete?
        @completed == @expected_count
      end
    end
  end
end
