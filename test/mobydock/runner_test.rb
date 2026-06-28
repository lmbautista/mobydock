# frozen_string_literal: true

require "minitest/autorun"
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

    def test_machine_ls
      expected_response = "machine-ls-command"

      Commands.stub(:machine_ls, expected_response) do
        runner = Runner.new(command: nil, env: "ls")
        response = runner.call

        assert_equal expected_response, response
      end
    end

    def test_initialize_handles_nil_args
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: nil, env: nil, args: nil)
          runner.stub(:docker_running?, true) do
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_docker_not_running
      expected_response = "helper docker_not_running"

      with_configuration_mocked do
        Helpers.stub(:docker_not_running, expected_response) do
          runner = Runner.new(command: nil, env: nil)
          runner.stub(:docker_running?, false) do
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_update_success
      expected_response = "ls"

      with_configuration_mocked do
        Commands.stub(:update, expected_response) do
          runner = Runner.new(command: "update", env: env, args: args)
          response = runner.call

          assert_equal expected_response, response
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

      with_configuration_mocked do
        Commands.stub(:reset, expected_response) do
          runner = Runner.new(command: "reset", env: env, args: [service])
          response = runner.call

          assert_equal expected_response, response
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

      with_configuration_mocked do
        Commands.stub(:setup, expected_response) do
          runner = Runner.new(command: "setup", env: env, args: [service])
          response = runner.call

          assert_equal expected_response, response
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

      with_configuration_mocked do
        Commands.stub(:default, expected_response) do
          runner = Runner.new(command: command, env: env, args: args)
          response = runner.call

          assert_equal expected_response, response
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

    def test_start_success
      expected_response = "start-command"

      with_configuration_mocked do
        Commands.stub(:start, expected_response) do
          runner = Runner.new(command: "start", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_start_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "start", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_shutdown_success_on_unprotected_env
      expected_response = "shutdown-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, false) do
          Commands.stub(:shutdown, expected_response) do
            runner = Runner.new(command: "shutdown", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_shutdown_blocked_on_protected_env_without_force
      expected_response = "shutdown protected"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Helpers.stub(:shutdown_protected, expected_response) do
            runner = Runner.new(command: "shutdown", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_shutdown_success_on_protected_env_with_force
      expected_response = "shutdown-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Commands.stub(:shutdown, expected_response) do
            runner = Runner.new(command: "shutdown", env: env, args: %w(--force))
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_shutdown_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "shutdown", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_launch_success
      expected_response = "launch-command"

      with_configuration_mocked do
        Commands.stub(:launch, expected_response) do
          runner = Runner.new(command: "launch", env: env, args: ["admin@example.com"])
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_launch_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "launch", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_launch_return_helper_without_email_for_non_dev
      expected_response = "helper launch"

      with_configuration_mocked do
        Helpers.stub(:launch, expected_response) do
          runner = Runner.new(command: "launch", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_login_success
      expected_response = "docker-machine env plantcare-beta"

      with_configuration_mocked do
        Commands.stub(:login, expected_response) do
          runner = Runner.new(command: "login", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_login_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "login", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_logout_success
      expected_response = "docker-machine env -u ; echo 'unset MOBYDOCK_ENV'"

      with_configuration_mocked do
        Commands.stub(:logout, expected_response) do
          runner = Runner.new(command: "logout", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_logout_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "logout", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_destroy_blocked_without_force
      expected_response = "destroy protected"

      with_configuration_mocked do
        Helpers.stub(:destroy_protected, expected_response) do
          runner = Runner.new(command: "destroy", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_destroy_success_with_force
      expected_response = "destroy-command"

      with_configuration_mocked do
        Commands.stub(:destroy, expected_response) do
          runner = Runner.new(command: "destroy", env: env, args: %w(--force))
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_destroy_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "destroy", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_backup_db_success
      expected_response = "backup-db-command"

      with_configuration_mocked do
        Configuration.stub(:db_service, "db") do
          Commands.stub(:backup_db, expected_response) do
            runner = Runner.new(command: "backup-db", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_backup_db_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "backup-db", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_backup_db_return_helper_without_db_service
      expected_response = "helper backup_db"

      with_configuration_mocked do
        Configuration.stub(:db_service, nil) do
          Helpers.stub(:backup_db, expected_response) do
            runner = Runner.new(command: "backup-db", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_backup_db_ls_success
      expected_response = "backup-db-ls-command"

      with_configuration_mocked do
        Commands.stub(:backup_db_ls, expected_response) do
          runner = Runner.new(command: "backup-db-ls", env: env)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_backup_db_ls_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "backup-db-ls", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_restore_db_success
      expected_response = "restore-db-command"

      with_configuration_mocked do
        Configuration.stub(:db_service, "db") do
          Commands.stub(:restore_db, expected_response) do
            runner = Runner.new(command: "restore-db", env: env, args: ["backups/dump.sql"])
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_restore_db_return_helper_without_backup_file
      expected_response = "helper restore_db"

      with_configuration_mocked do
        Configuration.stub(:db_service, "db") do
          Helpers.stub(:restore_db, expected_response) do
            runner = Runner.new(command: "restore-db", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_restore_db_return_helper_without_db_service
      expected_response = "helper restore_db"

      with_configuration_mocked do
        Configuration.stub(:db_service, nil) do
          Helpers.stub(:restore_db, expected_response) do
            runner = Runner.new(command: "restore-db", env: env, args: ["backups/dump.sql"])
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_rebuild_success
      expected_response = "rebuild-command"

      with_configuration_mocked do
        Configuration.stub(:db_service, "db") do
          Commands.stub(:rebuild, expected_response) do
            runner = Runner.new(command: "rebuild", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_rebuild_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "rebuild", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_rebuild_return_helper_without_db_service
      expected_response = "helper rebuild"

      with_configuration_mocked do
        Configuration.stub(:db_service, nil) do
          Helpers.stub(:rebuild, expected_response) do
            runner = Runner.new(command: "rebuild", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_db_protected_blocks_reset_on_protected_env
      expected_response = "db protected"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Helpers.stub(:db_protected, expected_response) do
              runner = Runner.new(command: "reset", env: env, args: ["db"])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_db_protected_allows_reset_with_force
      expected_response = "reset-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Commands.stub(:reset, expected_response) do
              runner = Runner.new(command: "reset", env: env, args: %w(db --force))
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_db_protected_allows_reset_of_other_service
      expected_response = "reset-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Commands.stub(:reset, expected_response) do
              runner = Runner.new(command: "reset", env: env, args: ["web"])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_db_protected_blocks_destructive_passthrough_on_db
      expected_response = "db protected"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Helpers.stub(:db_protected, expected_response) do
              runner = Runner.new(command: "rm", env: env, args: ["db"])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_bare_stop_in_protected_env_excludes_db
      expected_response = "stop-excluding-db"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Commands.stub(:stop_excluding_db, expected_response) do
              runner = Runner.new(command: "stop", env: env, args: [])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_stop_with_force_stops_everything
      expected_response = "default-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Commands.stub(:default, expected_response) do
              runner = Runner.new(command: "stop", env: env, args: %w(--force))
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_stop_db_explicitly_is_blocked
      expected_response = "db protected"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Helpers.stub(:db_protected, expected_response) do
              runner = Runner.new(command: "stop", env: env, args: ["db"])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_bare_stop_in_unprotected_env_uses_default
      expected_response = "default-command"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, false) do
          Commands.stub(:default, expected_response) do
            runner = Runner.new(command: "stop", env: env, args: [])
            response = runner.call

            assert_equal expected_response, response
          end
        end
      end
    end

    def test_db_protected_blocks_restore_db_without_force
      expected_response = "db protected"

      with_configuration_mocked do
        Configuration.stub(:protected_env?, true) do
          Configuration.stub(:db_service, "db") do
            Helpers.stub(:db_protected, expected_response) do
              runner = Runner.new(command: "restore-db", env: env, args: ["backups/dump.sql"])
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_deploy_success
      expected_response = "deploy-command"
      services_images = { "api-plantcare" => "lmbautista/api-plantcare:latest" }

      with_configuration_mocked do
        Configuration.stub(:deploy_services, services_images) do
          Configuration.stub(:migrate_service, nil) do
            Commands.stub(:deploy, expected_response) do
              runner = Runner.new(command: "deploy", env: env)
              response = runner.call

              assert_equal expected_response, response
            end
          end
        end
      end
    end

    def test_deploy_return_helper_with_env_blank
      expected_response = "helper global"

      with_configuration_mocked do
        Helpers.stub(:global, expected_response) do
          runner = Runner.new(command: "deploy", env: nil)
          response = runner.call

          assert_equal expected_response, response
        end
      end
    end

    def test_deploy_return_helper_without_deploy_services
      expected_response = "helper deploy"

      with_configuration_mocked do
        Configuration.stub(:deploy_services, {}) do
          Helpers.stub(:deploy, expected_response) do
            runner = Runner.new(command: "deploy", env: env)
            response = runner.call

            assert_equal expected_response, response
          end
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
          Mobydock::Configuration.stub(:machine_for, nil) do
            yield
          end
        end
      end
    end

    def base_path_mocked
      "test"
    end
  end
end
