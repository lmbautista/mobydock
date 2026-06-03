# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/mobydock/configuration"

module Mobydock
  class ConfigurationTest < Minitest::Test
    def test_protected_envs
      ENV["MOBYDOCK_PROTECTED_ENVS"] = "stg,prd"

      assert_equal %w(stg prd), Configuration.protected_envs
    ensure
      ENV.delete("MOBYDOCK_PROTECTED_ENVS")
    end

    def test_protected_envs_without_env_var
      ENV.delete("MOBYDOCK_PROTECTED_ENVS")

      assert_equal [], Configuration.protected_envs
    end

    def test_protected_env_is_true_for_listed_env
      ENV["MOBYDOCK_PROTECTED_ENVS"] = "stg,prd"

      assert Configuration.protected_env?("prd")
    ensure
      ENV.delete("MOBYDOCK_PROTECTED_ENVS")
    end

    def test_protected_env_is_false_for_unlisted_env
      ENV["MOBYDOCK_PROTECTED_ENVS"] = "stg,prd"

      refute Configuration.protected_env?("dev")
    ensure
      ENV.delete("MOBYDOCK_PROTECTED_ENVS")
    end

    def test_machine_for_with_mapped_env
      ENV["MOBYDOCK_MACHINE_MAP"] = "stg:plantcare-beta,prd:plantcare-prd"

      assert_equal "plantcare-beta", Configuration.machine_for("stg")
      assert_equal "plantcare-prd", Configuration.machine_for("prd")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_MAP")
    end

    def test_machine_for_with_unmapped_env
      ENV["MOBYDOCK_MACHINE_MAP"] = "stg:plantcare-beta,prd:plantcare-prd"

      assert_nil Configuration.machine_for("dev")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_MAP")
    end

    def test_machine_for_with_empty_map
      ENV["MOBYDOCK_MACHINE_MAP"] = ""

      assert_nil Configuration.machine_for("stg")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_MAP")
    end

    def test_machine_for_without_env_var
      ENV.delete("MOBYDOCK_MACHINE_MAP")

      assert_nil Configuration.machine_for("stg")
    end

    def test_machine_create_opts_per_env
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS_PRD"] = "--amazonec2-instance-type t3.large"

      assert_equal "--amazonec2-instance-type t3.large", Configuration.machine_create_opts("prd")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_PRD")
    end

    def test_machine_create_opts_falls_back_to_global
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_STG")
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS"] = "--amazonec2-region eu-west-1"

      assert_equal "--amazonec2-region eu-west-1", Configuration.machine_create_opts("stg")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS")
    end

    def test_machine_create_opts_prefers_env_specific_over_global
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS"] = "--amazonec2-instance-type t3.small"
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS_PRD"] = "--amazonec2-instance-type t3.large"

      assert_equal "--amazonec2-instance-type t3.large", Configuration.machine_create_opts("prd")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS")
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_PRD")
    end

    def test_machine_create_opts_without_env_var
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS")
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_DEV")

      assert_equal "", Configuration.machine_create_opts("dev")
    end

    def test_elastic_ip_alloc_per_env
      ENV["MOBYDOCK_ELASTIC_IP_ALLOC_PRD"] = "eipalloc-0abc123"

      assert_equal "eipalloc-0abc123", Configuration.elastic_ip_alloc("prd")
    ensure
      ENV.delete("MOBYDOCK_ELASTIC_IP_ALLOC_PRD")
    end

    def test_elastic_ip_alloc_without_env_var
      ENV.delete("MOBYDOCK_ELASTIC_IP_ALLOC_STG")

      assert_nil Configuration.elastic_ip_alloc("stg")
    end

    def test_elastic_ip_alloc_with_empty_value
      ENV["MOBYDOCK_ELASTIC_IP_ALLOC_STG"] = ""

      assert_nil Configuration.elastic_ip_alloc("stg")
    ensure
      ENV.delete("MOBYDOCK_ELASTIC_IP_ALLOC_STG")
    end

    def test_aws_region_extracted_from_create_opts
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS_PRD"] =
        "--amazonec2-region eu-west-1 --amazonec2-instance-type t2.medium"

      assert_equal "eu-west-1", Configuration.aws_region("prd")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_PRD")
    end

    def test_aws_region_without_region_in_create_opts
      ENV["MOBYDOCK_MACHINE_CREATE_OPTS_PRD"] = "--amazonec2-instance-type t2.medium"

      assert_nil Configuration.aws_region("prd")
    ensure
      ENV.delete("MOBYDOCK_MACHINE_CREATE_OPTS_PRD")
    end

    def test_machine_driver_is_always_amazonec2
      ENV["MOBYDOCK_MACHINE_DRIVER"] = "virtualbox"

      assert_equal "amazonec2", Configuration.machine_driver
    ensure
      ENV.delete("MOBYDOCK_MACHINE_DRIVER")
    end

    def test_db_service
      ENV["MOBYDOCK_DB_SERVICE"] = "db"

      assert_equal "db", Configuration.db_service
    ensure
      ENV.delete("MOBYDOCK_DB_SERVICE")
    end

    def test_db_service_without_env_var
      ENV.delete("MOBYDOCK_DB_SERVICE")

      assert_nil Configuration.db_service
    end

    def test_deploy_services_per_env
      ENV["MOBYDOCK_DEPLOY_SERVICES_PRD"] =
        "api-plantcare=lmbautista/api-plantcare:latest,plantcare=lmbautista/plantcare:latest"

      expected = {
        "api-plantcare" => "lmbautista/api-plantcare:latest",
        "plantcare" => "lmbautista/plantcare:latest"
      }
      assert_equal expected, Configuration.deploy_services("prd")
    ensure
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES_PRD")
    end

    def test_deploy_services_falls_back_to_global
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES_STG")
      ENV["MOBYDOCK_DEPLOY_SERVICES"] = "api-plantcare=lmbautista/api-plantcare:latest"

      expected = { "api-plantcare" => "lmbautista/api-plantcare:latest" }
      assert_equal expected, Configuration.deploy_services("stg")
    ensure
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES")
    end

    def test_deploy_services_prefers_env_specific_over_global
      ENV["MOBYDOCK_DEPLOY_SERVICES"] = "api-plantcare=lmbautista/api-plantcare:latest"
      ENV["MOBYDOCK_DEPLOY_SERVICES_STG"] = "api-plantcare=lmbautista/api-plantcare:staging"

      expected = { "api-plantcare" => "lmbautista/api-plantcare:staging" }
      assert_equal expected, Configuration.deploy_services("stg")
    ensure
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES")
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES_STG")
    end

    def test_deploy_services_without_env_var
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES")
      ENV.delete("MOBYDOCK_DEPLOY_SERVICES_PRD")

      assert_equal({}, Configuration.deploy_services("prd"))
    end

    def test_migrate_service_per_env
      ENV["MOBYDOCK_MIGRATE_SERVICE_PRD"] = "api-plantcare"

      assert_equal "api-plantcare", Configuration.migrate_service("prd")
    ensure
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE_PRD")
    end

    def test_migrate_service_falls_back_to_global
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE_STG")
      ENV["MOBYDOCK_MIGRATE_SERVICE"] = "api-plantcare"

      assert_equal "api-plantcare", Configuration.migrate_service("stg")
    ensure
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE")
    end

    def test_migrate_service_prefers_env_specific_over_global
      ENV["MOBYDOCK_MIGRATE_SERVICE"] = "global-service"
      ENV["MOBYDOCK_MIGRATE_SERVICE_PRD"] = "api-plantcare"

      assert_equal "api-plantcare", Configuration.migrate_service("prd")
    ensure
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE")
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE_PRD")
    end

    def test_migrate_service_without_env_var
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE")
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE_PRD")

      assert_nil Configuration.migrate_service("prd")
    end

    def test_migrate_service_with_empty_value
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE")
      ENV["MOBYDOCK_MIGRATE_SERVICE_PRD"] = ""

      assert_nil Configuration.migrate_service("prd")
    ensure
      ENV.delete("MOBYDOCK_MIGRATE_SERVICE_PRD")
    end
  end
end
