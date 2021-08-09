# frozen_string_literal: true

module Mobydock
  module Helpers
    module_function

    def global # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      help_text = []
      help_text << "Handle easily your dockerized proyect with Docker and Docker-machine"
      help_text << "\n"
      help_text << "Usage:"
      help_text << "mobydock [ENVIRONMENT] [COMMAND] [ARGS...]"
      help_text << "\n"
      help_text << "Enviroments:"
      help_text << Configuration.envs
      help_text << "\n"
      help_text << "Commands:"
      help_text << "\n"
      help_text << "build              Build or rebuild services"
      help_text << "bundle             Generate a Docker bundle from the Compose file"
      help_text << "config             Validate and view the Compose file"
      help_text << "create             Create services"
      help_text << "down               Stop and remove containers, networks, images, "\
                 "and volumes"
      help_text << "events             Receive real time events from containers"
      help_text << "exec               Execute a command in a running container"
      help_text << "help               Get help on a command"
      help_text << "images             List images"
      help_text << "kill               Kill containers"
      help_text << "logs               View output from containers"
      help_text << "pause              Pause services"
      help_text << "port               Print the public port for a port binding"
      help_text << "ps                 List containers"
      help_text << "pull               Pull service images"
      help_text << "push               Push service images"
      help_text << "restart            Restart services"
      help_text << "reset              Reset services"
      help_text << "rm                 Remove stopped containers"
      help_text << "run                Run a one-off command"
      help_text << "scale              Set number of containers for a service"
      help_text << "setup              Run for a service its bin/setup script"
      help_text << "start              Start services"
      help_text << "stop               Stop services"
      help_text << "top                Display the running processes"
      help_text << "unpause            Unpause services"
      help_text << "up                 Create and start containers"
      help_text << "update             Update for a service its image and regenerate its container"
      help_text << "version            Show the Docker-Compose version information"

      "echo '#{help_text.join("\n")}'"
    end

    def docker_not_running
      "echo 'Docker does not seem to be running'"
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
