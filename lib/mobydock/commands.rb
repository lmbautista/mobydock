# frozen_string_literal: true

module Mobydock
  module Commands
    LIST = [
      UPDATE = "update",
      RESET = "reset",
      SETUP = "setup",
      HELP = "help"
    ].freeze

    module_function

    def update(env:, service:, image:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << "docker login"
      command << "docker stop #{service}"
      command << "docker rm #{service}"
      command << ["docker images -a",
                  "grep \"#{image}\"",
                  "awk \"{print $3}\"",
                  "xargs docker rmi"].join(" | ")
      command << "docker pull #{image}"
      command << "#{docker_compose_prefix} build #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"
      command.join(" ; ")
    end

    def reset(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << "#{docker_compose_prefix} stop #{service}"
      command << "#{docker_compose_prefix} rm #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"

      command.join(" ; ")
    end

    def setup(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)

      "#{docker_compose_prefix} run #{service} bin/setup"
    end

    def default(env:, command:, args:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      default_command = []
      default_command << docker_compose_prefix
      default_command << command
      default_command << args.reverse[1..]&.join(" ")

      default_command.join(" ")
    end

    def docker_compose_cmd_for(env)
      docker_compose_file_path = File.join(Configuration.base_path, "docker-compose-#{env}.yml")

      "docker-compose -f #{docker_compose_file_path}"
    end

    private_methods :docker_compose_cmd
  end
end
