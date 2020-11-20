# frozen_string_literal: true

module Mobydock
  module Helpers
    module_function

    def global # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      command = []
      command << "Handle easily your dockerized proyect with Docker and Docker-machine"
      command << "\n"
      command << "Usage:"
      command << "mobydock [ENVIRONMENT] [COMMAND] [ARGS...]"
      command << "\n"
      command << "Enviroments:"
      command << Configuration.envs
      command << "\n"
      command << "Commands:"
      command << "\n"
      command << "build              Build or rebuild services"
      command << "bundle             Generate a Docker bundle from the Compose file"
      command << "config             Validate and view the Compose file"
      command << "create             Create services"
      command << "down               Stop and remove containers, networks, images, "\
                 "and volumes"
      command << "events             Receive real time events from containers"
      command << "exec               Execute a command in a running container"
      command << "help               Get help on a command"
      command << "images             List images"
      command << "kill               Kill containers"
      command << "logs               View output from containers"
      command << "pause              Pause services"
      command << "port               Print the public port for a port binding"
      command << "ps                 List containers"
      command << "pull               Pull service images"
      command << "push               Push service images"
      command << "restart            Restart services"
      command << "reset              Reset services"
      command << "rm                 Remove stopped containers"
      command << "run                Run a one-off command"
      command << "scale              Set number of containers for a service"
      command << "setup              Run for a service its bin/setup script"
      command << "start              Start services"
      command << "stop               Stop services"
      command << "top                Display the running processes"
      command << "unpause            Unpause services"
      command << "up                 Create and start containers"
      command << "update             Update for a service its image and regenerate its container"
      command << "version            Show the Docker-Compose version information"

      command.join("\n")
    end

    def update
      "mobydock [ENVIRONMENT] update [SERVICE] [IMAGE]"
    end

    def reset
      "mobydock [ENVIRONMENT] reset [SERVICE]"
    end

    def setup
      "mobydock [ENVIRONMENT] setup [SERVICE]"
    end
  end
end
