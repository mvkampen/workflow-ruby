# frozen_string_literal: true

module Workflow
  # Example workflow demonstrating how to compare several delivery options in
  # parallel, reduce the branch results to the best quote, and then confirm the
  # chosen option.
  module OptionComparisonExample
    Option = Data.define(:name, :base_fee, :divisor, :eta_days)
    Quote = Data.define(:option, :price, :eta_days)
    State = Data.define(:order_total, :selected_option, :selected_quote) do
      def initialize(order_total:, selected_option: nil, selected_quote: nil)
        super
      end
    end

    class ProviderUnavailable < StandardError; end
    class BudgetExceeded < StandardError; end

    OPTIONS = {
      economy: Option.new(name: :economy, base_fee: 5, divisor: 10, eta_days: 5),
      standard: Option.new(name: :standard, base_fee: 8, divisor: 8, eta_days: 3),
      express: Option.new(name: :express, base_fee: 15, divisor: 5, eta_days: 1)
    }.freeze

    module_function

    def compare_options(desired_days:, join: :review_quotes)
      reducer = best_quote_reducer(desired_days:)

      Workflow::Node.new do |state|
        items = candidate_option_states(state)

        Workflow::Success([Workflow::FanOut(join:, items:, reducer:), state])
      end
    end

    def request_quote
      Class.new do
        def call(state)
          quote = OptionComparisonExample.quote_for(
            state.selected_option,
            order_total: state.order_total
          )

          Workflow::Success([Workflow::Continue(), state.with(selected_quote: quote)])
        end
      end.new.freeze
    end

    def accept_quote
      Workflow::Node.new do |state|
        Workflow::Success([Workflow::Continue(), state])
      end
    end

    def confirm_quote(max_price:, unavailable_options: [])
      Workflow::Node.new do |state|
        if unavailable_options.include?(state.selected_option)
          error = ProviderUnavailable.new("#{state.selected_option} quote is temporarily unavailable")
          Workflow::Success([Workflow::Retry(error), state])
        elsif state.selected_quote.price > max_price
          error = BudgetExceeded.new("quote price #{state.selected_quote.price} exceeds #{max_price}")
          Workflow::Success([Workflow::Compensate(error), state])
        else
          Workflow::Success([Workflow::Continue(), state])
        end
      end
    end

    def reset_selection
      Workflow::Node.new do |state|
        Workflow::Success([
                            Workflow::Continue(),
                            state.with(selected_option: nil, selected_quote: nil)
                          ])
      end
    end

    def candidate_option_states(state)
      OPTIONS.each_key.with_object({}) do |option, states|
        states[option] = state.with(selected_option: option, selected_quote: nil)
      end
    end

    def quote_for(option, order_total:)
      details = OPTIONS.fetch(option)

      Quote.new(
        option: details.name,
        price: details.base_fee + (order_total / details.divisor),
        eta_days: details.eta_days
      )
    end

    def quote_score(quote, desired_days:)
      [
        quote.eta_days > desired_days ? 1 : 0,
        quote.price,
        quote.eta_days
      ]
    end

    def best_quote_reducer(desired_days:)
      lambda do |results|
        results.values.min_by do |state|
          quote_score(state.selected_quote, desired_days:)
        end
      end
    end
  end
end
