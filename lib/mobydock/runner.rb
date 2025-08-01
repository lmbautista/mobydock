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
      when Commands::UPDATE_ALL
        perform_update_all
      when Commands::RESET
        perform_reset
      when Commands::SETUP
        perform_setup
      when Commands::COMPILE_ASSETS
        perform_compile_assets
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

    def perform_update_all
      return Helpers.update_all if Validator.blank?(env) || args.empty?

      services_images = {}
      args.each_slice(2) do |service, image|
        return Helpers.update_all if Validator.blank?(service) || Validator.blank?(image)

        services_images[service] = image
      end

      Commands.update_all(env: env, services_images: services_images)
    end

    def perform_reset
      return Helpers.reset if Validator.blank?(service) || Validator.blank?(env)

      Commands.reset(env: env, service: service)
    end

    def perform_setup
      return Helpers.setup if Validator.blank?(service) || Validator.blank?(env)

      Commands.setup(env: env, service: service)
    end

    def perform_compile_assets
      return Helpers.compile_assets if Validator.blank?(service) || Validator.blank?(env)

      Commands.compile_assets(env: env, service: service)
    end

    def perform_default
      Commands.default(env: env, command: command, args: args)
    end
  end
end
