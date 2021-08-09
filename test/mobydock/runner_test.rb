# frozen_string_literal: true

require "minitest/autorun"
require "byebug"
require_relative "../../lib/mobydock/runner"
require_relative "../../lib/mobydock/helpers"
require_relative "../../lib/mobydock/commands"
require_relative "../../lib/mobydock/configuration"

module Mobydock
  class RunnerTest < Minitest::Test
    include Commands
    include Helpers
    include Validator

    def test_help
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "help", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_help_when_command_is_nil
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: nil, env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_update_success
      expected_response = "ls"
      params = [env: env, service: service, image: image]

      command_update_mock = MiniTest::Mock.new
      command_update_mock.expect(:call, expected_response, params)

      exec_mock = MiniTest::Mock.new
      exec_mock.expect(:call, expected_response, [expected_response])

      with_configuration_mocked do
        Kernel.stub(:exec, exec_mock) do
          Commands.stub(:update, command_update_mock) do
            runner = Runner.new(command: "update", env: env, args: args)
            response = runner.call

            assert response
          end
        end
      end
    end

    def test_update_return_helper_with_env_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "update", args: args, env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_update_return_helper_with_service_blank
      expected_response = "helper"
      with_configuration_mocked do
        Helpers.stub(:update, expected_response) do
          runner = Runner.new(command: "update", env: env, args: [image])
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_update_return_helper_with_image_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:update, expected_response) do
          runner = Runner.new(command: "update", env: env, args: [service])
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_reset_success
      expected_response = "ls"
      params = [env: env, service: service]

      command_reset_mock = MiniTest::Mock.new
      command_reset_mock.expect(:call, expected_response, params)

      exec_mock = MiniTest::Mock.new
      exec_mock.expect(:call, expected_response, [expected_response])

      with_configuration_mocked do
        Kernel.stub(:exec, exec_mock) do
          Commands.stub(:reset, command_reset_mock) do
            runner = Runner.new(command: "reset", env: env, args: [service])
            response = runner.call

            assert response
          end
        end
      end
    end

    def test_reset_return_helper_with_env_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "reset", args: args, env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_reset_return_helper_with_service_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:reset, expected_response) do
          runner = Runner.new(command: "reset", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_setup_success
      expected_response = "ls"
      params = [env: env, service: service]

      command_setup_mock = MiniTest::Mock.new
      command_setup_mock.expect(:call, expected_response, params)

      exec_mock = MiniTest::Mock.new
      exec_mock.expect(:call, expected_response, [expected_response])

      with_configuration_mocked do
        Kernel.stub(:exec, exec_mock) do
          Commands.stub(:setup, command_setup_mock) do
            runner = Runner.new(command: "setup", env: env, args: [service])
            response = runner.call

            assert response
          end
        end
      end
    end

    def test_setup_return_helper_with_env_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "setup", args: args, env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_setup_return_helper_with_service_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:setup, expected_response) do
          runner = Runner.new(command: "setup", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_default_success
      expected_response = "ls"
      command = "whatever"
      params = [env: env, command: command, args: args]

      command_default_mock = MiniTest::Mock.new
      command_default_mock.expect(:call, expected_response, params)

      exec_mock = MiniTest::Mock.new
      exec_mock.expect(:call, expected_response, [expected_response])
      with_configuration_mocked do
        Kernel.stub(:exec, exec_mock) do
          Commands.stub(:default, command_default_mock) do
            runner = Runner.new(command: command, env: env, args: args)
            response = runner.call

            assert response
          end
        end
      end
    end

    def test_default_return_helper_with_env_blank
      expected_response = "helper"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "default", args: args, env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_default_return_default_with_service_blank
      expected_response = "cd #{base_path_mocked} ; docker-compose -f "\
        "docker-compose-test.yml default"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "default", env: env, args: [])
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    private

    def env
      "test"
    end

    def image
      "image:latest"
    end

    def service
      "service"
    end

    def args
      [service, image]
    end

    def with_configuration_mocked
      Mobydock::Configuration.stub(:envs, ["test"]) do
        Mobydock::Configuration.stub(:base_path, base_path_mocked) do
          yield
        end
      end
    end

    def base_path_mocked
      "test"
    end
  end
end
