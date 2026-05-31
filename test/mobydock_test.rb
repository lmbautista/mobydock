# frozen_string_literal: true

require "minitest/autorun"

Dir[File.join(__dir__, "mobydock", "*_test.rb")].sort.each { |file| require file }
