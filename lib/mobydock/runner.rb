# frozen_string_literal: true

require_relative "commands"
require_relative "helpers"
require_relative "validator"

module Mobydock
  class Runner
    include Commands
    include Helpers
    include Validator

    def initialize(command:, env:, args: [])
      @command = command
      @env = env
      @args = args
      @service, @image = args
    end

    def call
      return Helpers.docker_not_running unless docker_running?
      return Helpers.global if invalid_env? || command.nil?
      return perform_default if default_command?

      case command
      when Commands::UPDATE
        perform_update
      when Commands::RESET
        perform_reset
      when Commands::SETUP
        perform_setup
      when Commands::HELP
        Helpers.global
      end
    end

    private

    attr_reader :command, :env, :args, :image, :service

    def docker_running?
      system("docker info >/dev/null 2>&1")
    end

    def invalid_env?
      !Mobydock::Configuration.envs.include?(env)
    end

    def default_command?
      !Commands::LIST.include?(command)
    end

    def perform_update
      return Helpers.update if Validator.blank?(service) ||
                               Validator.blank?(image) ||
                               Validator.blank?(env)

      Commands.update(env: env, service: service, image: image)
    end

    def perform_reset
      return Helpers.reset if Validator.blank?(service) || Validator.blank?(env)

      Commands.reset(env: env, service: service)
    end

    def perform_setup
      return Helpers.setup if Validator.blank?(service) || Validator.blank?(env)

      Commands.setup(env: env, service: service)
    end

    def perform_default
      Commands.default(env: env, command: command, args: args)
    end
  end
end
