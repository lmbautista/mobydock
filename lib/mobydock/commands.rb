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
      command << working_path_cmd
      command << "#{docker_compose_prefix} build #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"
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
