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
          "echo 'Handle easily your dockerized proyect with Docker and Docker-machine


Usage:
mobydock [ENVIRONMENT] [COMMAND] [ARGS...]


Enviroments:
test


Commands:


build              Build or rebuild services
bundle             Generate a Docker bundle from the Compose file
config             Validate and view the Compose file
create             Create services
down               Stop and remove containers, networks, images, and volumes
events             Receive real time events from containers
exec               Execute a command in a running container
help               Get help on a command
images             List images
kill               Kill containers
logs               View output from containers
pause              Pause services
port               Print the public port for a port binding
ps                 List containers
pull               Pull service images
push               Push service images
restart            Restart services
reset              Reset services
rm                 Remove stopped containers
run                Run a one-off command
scale              Set number of containers for a service
setup              Run for a service its bin/setup script
start              Start services
stop               Stop services
top                Display the running processes
unpause            Unpause services
up                 Create and start containers
update             Update for a service its image and regenerate its container
version            Show the Docker-Compose version information'"

        assert result
        assert_equal expected_result, result
      end
    end

    def test_update_help
      result = Helpers.update
      expected_result = "mobydock [ENVIRONMENT] update [SERVICE] [IMAGE]"

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

    private

    def with_configuration_mocked
      Mobydock::Configuration.stub(:envs, ["test"]) do
        yield
      end
    end
  end
end
