# frozen_string_literal: true

require_relative "commands"
require_relative "configuration"
require_relative "helpers"
require_relative "validator"

module Mobydock
  class Runner
    include Commands
    include Helpers
    include Validator

    DESTRUCTIVE_PASSTHROUGH = %w(down rm stop kill).freeze

    def initialize(command:, env:, args: [])
      args ||= []
      @command = command
      @env = env
      @force = args.delete("--force") ? true : false
      @args = args
      @service, @image = args
    end

    def call
      return Commands.machine_ls if machine_ls?
      return Helpers.docker_not_running unless docker_running?
      return Helpers.global if invalid_env? || command.nil?
      return Helpers.db_protected(env) if db_protected?
      return perform_default if default_command?

      dispatch
    end

    private

    attr_reader :command, :env, :args, :image, :service

    def dispatch # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
      case command
      when Commands::UPDATE then perform_update
      when Commands::UPDATE_ALL then perform_update_all
      when Commands::RESET then perform_reset
      when Commands::SETUP then perform_setup
      when Commands::COMPILE_ASSETS then perform_compile_assets
      when Commands::SETUP_SSL then perform_setup_ssl
      when Commands::START then perform_start
      when Commands::LOGIN then perform_login
      when Commands::LOGOUT then perform_logout
      when Commands::DESTROY then perform_destroy
      when Commands::LAUNCH then perform_launch
      when Commands::BACKUP_DB then perform_backup_db
      when Commands::RESTORE_DB then perform_restore_db
      when Commands::DEPLOY then perform_deploy
      when Commands::HELP then Helpers.global
      end
    end

    def machine_ls?
      env == Commands::MACHINE_LS && Validator.blank?(command)
    end

    def docker_running?
      system("docker info >/dev/null 2>&1")
    end

    def invalid_env?
      !Mobydock::Configuration.envs.include?(env)
    end

    def default_command?
      !Commands::LIST.include?(command)
    end

    def db_protected?
      return false if @force
      return false unless Configuration.protected_env?(env)

      db = Configuration.db_service
      return false if Validator.blank?(db)

      db_targets.include?(db)
    end

    def db_targets
      case command
      when Commands::RESET, Commands::UPDATE then [service]
      when Commands::UPDATE_ALL then args.each_slice(2).map(&:first)
      when Commands::RESTORE_DB then [Configuration.db_service]
      else
        return [] unless DESTRUCTIVE_PASSTHROUGH.include?(command)

        # destructive passthrough without an explicit service hits every service (db included)
        args.empty? ? [Configuration.db_service] : args
      end
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

      Commands.update_all(env: env, services_images: services_images) # rubocop:disable Rails/SkipsModelValidations
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

    def perform_setup_ssl
      return Helpers.setup_ssl if Validator.blank?(env)

      email = args[0]
      return Helpers.setup_ssl if env != "dev" && Validator.blank?(email)

      Commands.setup_ssl(env: env, email: Validator.blank?(email) ? nil : email)
    end

    def perform_start
      return Helpers.start if Validator.blank?(env)

      Commands.start(env: env)
    end

    def perform_login
      return Helpers.login if Validator.blank?(env)

      Commands.login(env: env)
    end

    def perform_logout
      return Helpers.logout if Validator.blank?(env)

      Commands.logout
    end

    def perform_destroy
      return Helpers.destroy if Validator.blank?(env)
      return Helpers.destroy_protected(env) unless @force

      Commands.destroy(env: env)
    end

    def perform_launch
      return Helpers.launch if Validator.blank?(env)

      email = args[0]
      return Helpers.launch if env != "dev" && Validator.blank?(email)

      Commands.launch(env: env, email: Validator.blank?(email) ? nil : email)
    end

    def perform_backup_db
      blank_db_service = Validator.blank?(Configuration.db_service)
      return Helpers.backup_db if Validator.blank?(env) || blank_db_service

      Commands.backup_db(env: env)
    end

    def perform_restore_db
      blank_db_service = Validator.blank?(Configuration.db_service)
      backup_file = args[0]
      return Helpers.restore_db if Validator.blank?(env) ||
                                   blank_db_service ||
                                   Validator.blank?(backup_file)

      Commands.restore_db(env: env, backup_file: backup_file)
    end

    def perform_deploy
      services_images = Configuration.deploy_services(env)
      return Helpers.deploy if Validator.blank?(env) || services_images.empty?

      Commands.deploy(
        env: env,
        services_images: services_images,
        migrate_service: Configuration.migrate_service(env)
      )
    end

    def perform_default
      Commands.default(env: env, command: command, args: args)
    end
  end
end
