# frozen_string_literal: true

module Mobydock
  module Commands
    LIST = [
      UPDATE = "update",
      UPDATE_ALL = "update-all",
      RESET = "reset",
      SETUP = "setup",
      COMPILE_ASSETS = "compile-assets",
      HELP = "help"
    ].freeze

    module_function

    def update(env:, service:, image:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << "docker login"
      command << working_path_cmd
      command << "#{docker_compose_prefix} stop #{service}"
      command << "#{docker_compose_prefix} rm -f #{service}"
      command << ["docker images --filter=\"reference=#{image}\" -q",
                  "xargs -r docker rmi -f"].join(" | ")
      command << "docker pull #{image}"
      command << "#{docker_compose_prefix} build --no-cache --pull #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"
      command.join(" ; ")
    end

    def update_all(env:, services_images:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << "docker login"
      command << working_path_cmd

      services = services_images.keys.join(" ")

      command << "#{docker_compose_prefix} stop #{services}"
      command << "#{docker_compose_prefix} rm -f #{services}"

      services_images.each do |service, image|
        command << ["docker images --filter=\"reference=#{image}\" -q",
                    "xargs -r docker rmi -f"].join(" | ")
        command << "docker pull #{image}"
      end

      command << "#{docker_compose_prefix} build --no-cache --pull #{services}"
      command << "#{docker_compose_prefix} up -d #{services}"

      command.join(" ; ")
    end

    def reset(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << working_path_cmd
      command << "#{docker_compose_prefix} stop #{service}"
      command << "#{docker_compose_prefix} rm #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"

      command.join(" ; ")
    end

    def setup(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << working_path_cmd
      command << "#{docker_compose_prefix} run #{service} bin/setup"

      command.join(" ; ")
    end

    def compile_assets(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << working_path_cmd
      command << "echo 'Compiling assets for #{env}...'"
      command << "#{docker_compose_prefix} exec #{service} rails assets:precompile RAILS_ENV=#{env == 'dev' ? 'development' : 'production'}"
      command << "echo '✅ Assets compiled'"

      command.join(" ; ")
    end

    def default(env:, command:, args:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      default_command = []
      default_command << working_path_cmd
      default_command << [docker_compose_prefix, command, *args[0..]].join(" ")

      default_command.join(" ; ")
    end

    def docker_compose_cmd_for(env)
      "docker-compose -f docker-compose-#{env}.yml"
    end

    def working_path_cmd
      "cd #{Configuration.base_path}"
    end

    private_methods :docker_compose_cmd
  end
end
