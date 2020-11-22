# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/mobydock/validator"

module Mobydock
  class ValidatorTest < Minitest::Test
    def test_blank_returns_true_with_empty_string
      assert ::Mobydock::Validator.blank?("")
    end

    def test_blank_returns_true_with_nil
      assert ::Mobydock::Validator.blank?(nil)
    end

    def test_blank_returns_false_with_string
      assert_not ::Mobydock::Validator.blank?("my string")
    end
  end
end
