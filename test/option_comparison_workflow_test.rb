# frozen_string_literal: true

require 'test_helper'
require_relative 'examples/option_comparison_example'

describe Workflow::OptionComparisonExample do
  include Workflow::OptionComparisonExample

  describe 'quote comparison flow' do
    it 'fans out option requests and reduces them to the best on-time quote' do
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::OptionComparisonExample::State.new(order_total: 40)

      graph = Workflow::Graph.new
      graph.add_node(:compare_options, compare_options(desired_days: 3, join: :review_quotes))
      graph.add_node(:request_quote, request_quote)
      graph.add_node(:review_quotes) { |state| Success([Continue(), state]) }
      graph.add_node(:confirm_quote, confirm_quote(max_price: 14))
      graph.add_node(:accept_quote, accept_quote)
      graph.add_node(:finish) { |state| Success([Stop(), state]) }
      graph.add_edge(start, :compare_options)
      graph.add_edge(:compare_options, :request_quote)
      graph.add_edge(:request_quote, :review_quotes)
      graph.add_edge(:review_quotes, :confirm_quote)
      graph.add_edge(:confirm_quote, :accept_quote)
      graph.add_edge(:accept_quote, :finish)

      engine = Workflow::Execution::Engine.new(graph:)

      expect(engine.run(start:, state: initial_state)).to eq(
        Success(
          Workflow::OptionComparisonExample::State.new(
            order_total: 40,
            selected_option: :standard,
            selected_quote: Workflow::OptionComparisonExample::Quote.new(
              option: :standard,
              price: 13,
              eta_days: 3
            )
          )
        )
      )
    end

    it 'can stop with the selected quote as the terminal result' do
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::OptionComparisonExample::State.new(order_total: 40)

      graph = Workflow::Graph.new
      graph.add_node(:compare_options, compare_options(desired_days: 3, join: :review_quotes))
      graph.add_node(:request_quote, request_quote)
      graph.add_node(:review_quotes) { |state| Success([Continue(), state]) }
      graph.add_node(:confirm_quote, confirm_quote(max_price: 14))
      graph.add_node(:finish) { |state| Success([Stop(state.selected_quote), state]) }
      graph.add_edge(start, :compare_options)
      graph.add_edge(:compare_options, :request_quote)
      graph.add_edge(:request_quote, :review_quotes)
      graph.add_edge(:review_quotes, :confirm_quote)
      graph.add_edge(:confirm_quote, :finish)

      engine = Workflow::Execution::Engine.new(graph:)

      expect(engine.run(start:, state: initial_state)).to eq(
        Success(
          Workflow::OptionComparisonExample::Quote.new(
            option: :standard,
            price: 13,
            eta_days: 3
          )
        )
      )
    end

    it 'keeps reset_selection as a regular node that can be wired into the graph' do
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::OptionComparisonExample::State.new(
        order_total: 40,
        selected_option: :express,
        selected_quote: Workflow::OptionComparisonExample::Quote.new(
          option: :express,
          price: 23,
          eta_days: 1
        )
      )

      graph = Workflow::Graph.new
      graph.add_node(:reset_selection, reset_selection)
      graph.add_node(:finish) { |state| Success([Stop(), state]) }
      graph.add_edge(start, :reset_selection)
      graph.add_edge(:reset_selection, :finish)

      engine = Workflow::Execution::Engine.new(graph:)

      expect(engine.run(start:, state: initial_state)).to eq(
        Success(
          Workflow::OptionComparisonExample::State.new(
            order_total: 40,
            selected_option: nil,
            selected_quote: nil
          )
        )
      )
    end

    it 'returns retry when the selected provider is temporarily unavailable' do
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::OptionComparisonExample::State.new(order_total: 40)

      graph = Workflow::Graph.new
      graph.add_node(:compare_options, compare_options(desired_days: 1, join: :review_quotes))
      graph.add_node(:request_quote, request_quote)
      graph.add_node(:review_quotes) { |state| Success([Continue(), state]) }
      graph.add_node(:confirm_quote, confirm_quote(max_price: 30, unavailable_options: [:express]))
      graph.add_edge(start, :compare_options)
      graph.add_edge(:compare_options, :request_quote)
      graph.add_edge(:request_quote, :review_quotes)
      graph.add_edge(:review_quotes, :confirm_quote)

      engine = Workflow::Execution::Engine.new(graph:)

      selected_state = Workflow::OptionComparisonExample::State.new(
        order_total: 40,
        selected_option: :express,
        selected_quote: Workflow::OptionComparisonExample::Quote.new(
          option: :express,
          price: 23,
          eta_days: 1
        )
      )

      expect(engine.run(start:, state: initial_state)).to eq(
        Success([
                  Retry(
                    Workflow::OptionComparisonExample::ProviderUnavailable.new(
                      'express quote is temporarily unavailable'
                    )
                  ),
                  selected_state
                ])
      )
    end

    it 'returns compensate when the selected quote exceeds the allowed budget' do
      start = Workflow::Vertex::Start.new
      initial_state = Workflow::OptionComparisonExample::State.new(order_total: 40)

      graph = Workflow::Graph.new
      graph.add_node(:compare_options, compare_options(desired_days: 3, join: :review_quotes))
      graph.add_node(:request_quote, request_quote)
      graph.add_node(:review_quotes) { |state| Success([Continue(), state]) }
      graph.add_node(:confirm_quote, confirm_quote(max_price: 12))
      graph.add_edge(start, :compare_options)
      graph.add_edge(:compare_options, :request_quote)
      graph.add_edge(:request_quote, :review_quotes)
      graph.add_edge(:review_quotes, :confirm_quote)

      engine = Workflow::Execution::Engine.new(graph:)

      selected_state = Workflow::OptionComparisonExample::State.new(
        order_total: 40,
        selected_option: :standard,
        selected_quote: Workflow::OptionComparisonExample::Quote.new(
          option: :standard,
          price: 13,
          eta_days: 3
        )
      )

      expect(engine.run(start:, state: initial_state)).to eq(
        Success([
                  Compensate(
                    Workflow::OptionComparisonExample::BudgetExceeded.new(
                      'quote price 13 exceeds 12'
                    )
                  ),
                  selected_state
                ])
      )
    end
  end
end
