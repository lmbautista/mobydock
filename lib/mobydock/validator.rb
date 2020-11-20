# frozen_string_literal: true

module Mobydock
  module Validator
    module_function

    def blank?(element)
      element.respond_to?(:empty?) ? !!element.empty? : !element
    end
  end
end
