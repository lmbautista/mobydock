# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/mobydock/commands"
require_relative "../../lib/mobydock/configuration"

module Mobydock
  class CommandsTest < Minitest::Test
    def test_update
      expected_result = "docker login ; docker stop test-service ; docker rm test-service ; "\
        "docker images -a | grep \"my-image\" | awk \"{print $3}\" | xargs docker rmi ; "\
        "docker pull my-image ; "\
        "docker-compose -f ./docker-compose-test.yml build test-service ; "\
        "docker-compose -f ./docker-compose-test.yml up -d test-service"

      with_mocked_base_path do
        result = Commands.update(env: "test", image: "my-image", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_reset
      expected_result = "docker-compose -f ./docker-compose-test.yml stop test-service ; "\
        "docker-compose -f ./docker-compose-test.yml rm test-service ; "\
        "docker-compose -f ./docker-compose-test.yml up -d test-service"

      with_mocked_base_path do
        result = Commands.reset(env: "test", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_setup
      expected_result = "docker-compose -f ./docker-compose-test.yml run test-service bin/setup"

      with_mocked_base_path do
        result = Commands.setup(env: "test", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_default
      expected_result = "docker-compose -f ./docker-compose-test.yml up -d test-service"

      with_mocked_base_path do
        result = Commands.default(env: "test", command: "up", args: %w(-d test-service))

        assert result
        assert_equal expected_result, result
      end
    end

    private

    def with_mocked_base_path
      Configuration.stub(:base_path, "./") do
        yield
      end
    end
  end
end
