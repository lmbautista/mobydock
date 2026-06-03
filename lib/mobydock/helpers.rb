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
      help_text << "compile-assets     Compile Rails assets for production"
      help_text << "start              Start services"
      help_text << "stop               Stop services"
      help_text << "top                Display the running processes"
      help_text << "unpause            Unpause services"
      help_text << "up                 Create and start containers"
      help_text << "update             Update for a service its image and regenerate its container"
      help_text << "update-all         Update multiple services and regenerate the entire stack"
      help_text << "setup-ssl          Set up HTTPS (mkcert for dev, LetsEncrypt for production)"
      help_text << "start              Start or create docker-machine for env"
      help_text << "login              Activate docker-machine env (eval $(mobydock [ENV] login))"
      help_text << "logout             Deactivate docker-machine env and clear MOBYDOCK_ENV"
      help_text << "ls                 List the docker-machines (mobydock ls -> docker-machine ls)"
      help_text << "destroy            Remove the docker-machine for env and terminate " \
                 "its instance (requires --force)"
      help_text << "launch             Create a new docker-machine EC2 instance for env "\
                 "(and assign its Elastic IP if configured)"
      help_text << "backup-db          Dump MySQL database and save locally to backups/"
      help_text << "backup-db-ls       List the local database backups for the environment"
      help_text << "restore-db         Restore MySQL database from a local dump file"
      help_text << "deploy             Pull new images, migrate DB, rebuild and restart services"
      help_text << "rebuild            Remove service images (except db) and rebuild from scratch"
      help_text << "version            Show the Docker-Compose version information"

      "echo '#{help_text.join("\n")}'"
    end

    def docker_not_running
      "echo 'Docker does not seem to be running'"
    end

    def update
      "mobydock [ENVIRONMENT] update [SERVICE] [IMAGE]"
    end

    def update_all
      "mobydock [ENVIRONMENT] update-all [SERVICE1] [IMAGE1] [SERVICE2] [IMAGE2] ..."
    end

    def reset
      "mobydock [ENVIRONMENT] reset [SERVICE]"
    end

    def setup
      "mobydock [ENVIRONMENT] setup [SERVICE]"
    end

    def compile_assets
      "mobydock [ENVIRONMENT] compile-assets [SERVICE]"
    end

    def setup_ssl
      "mobydock [ENVIRONMENT] setup-ssl           # development (mkcert)\n" \
      "mobydock [ENVIRONMENT] setup-ssl [EMAIL]   # production (LetsEncrypt)"
    end

    def start
      "mobydock [ENVIRONMENT] start"
    end

    def login
      "eval $(mobydock [ENVIRONMENT] login)"
    end

    def logout
      "eval $(mobydock [ENVIRONMENT] logout)"
    end

    def destroy
      "mobydock [ENVIRONMENT] destroy --force"
    end

    def destroy_protected(env)
      message = []
      message << "🛡️  This removes the docker-machine for '#{env}' and"
      message << "terminates its remote instance. This cannot be undone."
      message << ""
      message << "Re-run with --force if you really intend to do this:"
      message << "  mobydock #{env} destroy --force"
      "echo '#{message.join("\n")}'"
    end

    def launch
      "mobydock dev launch                          # development\n" \
      "mobydock [ENVIRONMENT] launch [EMAIL]        # production (LetsEncrypt)"
    end

    def backup_db
      "mobydock [ENVIRONMENT] backup-db"
    end

    def backup_db_ls
      "mobydock [ENVIRONMENT] backup-db-ls"
    end

    def restore_db
      "mobydock [ENVIRONMENT] restore-db [BACKUP_FILE]"
    end

    def rebuild
      "mobydock [ENVIRONMENT] rebuild"
    end

    def db_protected(env)
      message = []
      message << "🛡️  Database protection: this operation would affect the '#{env}' database,"
      message << "which is a protected environment (see MOBYDOCK_PROTECTED_ENVS)."
      message << ""
      message << "If you really intend to do this, re-run the same command with --force."
      "echo '#{message.join("\n")}'"
    end

    def deploy
      message = []
      message << "❌ deploy is not configured: no services found for this environment."
      message << ""
      message << "Set the services and images to deploy (comma-separated, service=image),"
      message << "either per environment (preferred) or globally as a fallback:"
      message << "  export MOBYDOCK_DEPLOY_SERVICES_PRD=service1=image1,service2=image2"
      message << "  export MOBYDOCK_DEPLOY_SERVICES=service1=image1,service2=image2"
      message << ""
      message << "Optionally run migrations on a service before bringing the stack up:"
      message << "  export MOBYDOCK_MIGRATE_SERVICE_PRD=service"
      "echo '#{message.join("\n")}'"
    end
  end
end
