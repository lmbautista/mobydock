# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/mobydock/helpers"
require_relative "../../lib/mobydock/configuration"

module Mobydock
  class HelpersTest < Minitest::Test
    def test_global_help
      with_configuration_mocked do
        result = Helpers.global
        expected_result =
          "echo 'Handle easily your dockerized proyect with Docker and Docker-machine\n\n\n" \
          "Usage:\nmobydock [ENVIRONMENT] [COMMAND] [ARGS...]\n\n\nEnviroments:\ntest\n\n\n" \
          "Commands:\n\n\n" \
          "build              Build or rebuild services\n" \
          "bundle             Generate a Docker bundle from the Compose file\n" \
          "config             Validate and view the Compose file\n" \
          "create             Create services\n" \
          "down               Stop and remove containers, networks, images, and volumes\n" \
          "events             Receive real time events from containers\n" \
          "exec               Execute a command in a running container\n" \
          "help               Get help on a command\n" \
          "images             List images\n" \
          "kill               Kill containers\n" \
          "logs               View output from containers\n" \
          "pause              Pause services\n" \
          "port               Print the public port for a port binding\n" \
          "ps                 List containers\n" \
          "pull               Pull service images\n" \
          "push               Push service images\n" \
          "restart            Restart services\n" \
          "reset              Reset services\n" \
          "rm                 Remove stopped containers\n" \
          "run                Run a one-off command\n" \
          "scale              Set number of containers for a service\n" \
          "setup              Run for a service its bin/setup script\n" \
          "compile-assets     Compile Rails assets for production\n" \
          "start              Start services\n" \
          "stop               Stop services\n" \
          "top                Display the running processes\n" \
          "unpause            Unpause services\n" \
          "up                 Create and start containers\n" \
          "update             Update for a service its image and regenerate its container\n" \
          "update-all         Update multiple services and regenerate the entire stack\n" \
          "setup-ssl          Set up HTTPS (mkcert for dev, LetsEncrypt for production)\n" \
          "start              Start or create docker-machine for env\n" \
          "login              Activate docker-machine env (eval $(mobydock [ENV] login))\n" \
          "logout             Deactivate docker-machine env and clear MOBYDOCK_ENV\n" \
          "ls                 List the docker-machines (mobydock ls -> docker-machine ls)\n" \
          "destroy            Remove the docker-machine for env and terminate " \
          "its instance (requires --force)\n" \
          "launch             Create a new docker-machine EC2 instance for env " \
          "(and assign its Elastic IP if configured)\n" \
          "backup-db          Dump MySQL database and save locally to backups/\n" \
          "restore-db         Restore MySQL database from a local dump file\n" \
          "deploy             Pull new images, migrate DB, rebuild and restart services\n" \
          "version            Show the Docker-Compose version information'"

        assert result
        assert_equal expected_result, result
      end
    end

    def test_docker_not_running
      result = Helpers.docker_not_running
      expected_result = "echo 'Docker does not seem to be running'"

      assert_equal expected_result, result
    end

    def test_update_help
      result = Helpers.update
      expected_result = "mobydock [ENVIRONMENT] update [SERVICE] [IMAGE]"

      assert_equal expected_result, result
    end

    def test_update_all_help
      result = Helpers.update_all
      expected_result =
        "mobydock [ENVIRONMENT] update-all [SERVICE1] [IMAGE1] [SERVICE2] [IMAGE2] ..."

      assert_equal expected_result, result
    end

    def test_reset_help
      result = Helpers.reset
      expected_result = "mobydock [ENVIRONMENT] reset [SERVICE]"

      assert_equal expected_result, result
    end

    def test_setup_help
      result = Helpers.setup
      expected_result = "mobydock [ENVIRONMENT] setup [SERVICE]"

      assert_equal expected_result, result
    end

    def test_compile_assets_help
      result = Helpers.compile_assets
      expected_result = "mobydock [ENVIRONMENT] compile-assets [SERVICE]"

      assert_equal expected_result, result
    end

    def test_setup_ssl_help
      result = Helpers.setup_ssl
      expected_result =
        "mobydock [ENVIRONMENT] setup-ssl           # development (mkcert)\n" \
        "mobydock [ENVIRONMENT] setup-ssl [EMAIL]   # production (LetsEncrypt)"

      assert_equal expected_result, result
    end

    def test_start_help
      result = Helpers.start
      expected_result = "mobydock [ENVIRONMENT] start"

      assert_equal expected_result, result
    end

    def test_launch_help
      result = Helpers.launch
      expected_result =
        "mobydock dev launch                          # development\n" \
        "mobydock [ENVIRONMENT] launch [EMAIL]        # production (LetsEncrypt)"

      assert_equal expected_result, result
    end

    def test_login_help
      result = Helpers.login
      expected_result = "eval $(mobydock [ENVIRONMENT] login)"

      assert_equal expected_result, result
    end

    def test_logout_help
      result = Helpers.logout
      expected_result = "eval $(mobydock [ENVIRONMENT] logout)"

      assert_equal expected_result, result
    end

    def test_destroy_help
      result = Helpers.destroy
      expected_result = "mobydock [ENVIRONMENT] destroy --force"

      assert_equal expected_result, result
    end

    def test_destroy_protected
      result = Helpers.destroy_protected("prd")

      assert_includes result, "'prd'"
      assert_includes result, "terminates its remote instance"
      assert_includes result, "--force"
    end

    def test_backup_db_help
      result = Helpers.backup_db
      expected_result = "mobydock [ENVIRONMENT] backup-db"

      assert_equal expected_result, result
    end

    def test_restore_db_help
      result = Helpers.restore_db
      expected_result = "mobydock [ENVIRONMENT] restore-db [BACKUP_FILE]"

      assert_equal expected_result, result
    end

    def test_db_protected
      result = Helpers.db_protected("prd")

      assert_includes result, "Database protection"
      assert_includes result, "'prd'"
      assert_includes result, "--force"
    end

    private

    def with_configuration_mocked
      Mobydock::Configuration.stub(:envs, ["test"]) do
        yield
      end
    end
  end
end
