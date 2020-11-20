# frozen_string_literal: true

require_relative "commands"
require_relative "helpers"
require_relative "validator"

module Mobydock
  class Runner
    include Commands
    include Helpers
    include Validator

    def initialize(command:, env: "", args: [])
      @command = command
      @env = env
      @args = args
      @service, @image = args
    end

    def call
      return perform_default if default_command?

      case command
      when Commands::UPDATE
        perform_update
      when Commands::RESET
        perform_reset
      when Commands::SETUP
        perform_setup
      when Commands::HELP, nil
        Helpers.global
      end
    end

    private

    attr_reader :command, :env, :args, :image, :service

    def default_command?
      !Commands::LIST.include?(command)
    end

    def perform_update
      return Helpers.update if Validator.blank?(service) ||
                               Validator.blank?(image) ||
                               Validator.blank?(env)

      update_command = Commands.update(env: env, service: service, image: image)
      system(update_command)
    end

    def perform_reset
      return Helpers.reset if Validator.blank?(service) || Validator.blank?(env)

      reset_command = Commands.reset(env: env, service: service)
      system(reset_command)
    end

    def perform_setup
      return Helpers.setup if Validator.blank?(service) || Validator.blank?(env)

      setup_command = Commands.setup(env: env, service: service)
      system(setup_command)
    end

    def perform_default
      return Helpers.global if Validator.blank?(service) ||
                               Validator.blank?(env)

      default_command = Commands.default(env: env, command: command, args: args)
      system(default_command)
    end
  end
end
