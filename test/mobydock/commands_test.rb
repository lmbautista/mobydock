# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/mobydock/commands"
require_relative "../../lib/mobydock/configuration"

module Mobydock
  class CommandsTest < Minitest::Test
    def test_update
      expected_result =
        "echo '🚀 Updating test-service in test...' ; " \
        "docker login ; cd ./ ; docker-compose -f docker-compose-test.yml stop test-service ; " \
        "docker-compose -f docker-compose-test.yml rm -f test-service ; " \
        "docker images --filter=\"reference=my-image\" -q | xargs -r docker rmi -f ; " \
        "docker pull my-image ; " \
        "docker-compose -f docker-compose-test.yml build --no-cache --pull test-service ; " \
        "docker-compose -f docker-compose-test.yml up -d test-service ; " \
        "echo '✅ test-service updated'"

      with_mocked_base_path do
        result = Commands.update(env: "test", image: "my-image", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_reset
      expected_result = "cd ./ ; echo '🚀 Resetting test-service in test...' ; "\
        "docker-compose -f docker-compose-test.yml stop test-service ; "\
        "docker-compose -f docker-compose-test.yml rm test-service ; "\
        "docker-compose -f docker-compose-test.yml up -d test-service ; "\
        "echo '✅ test-service reset'"

      with_mocked_base_path do
        result = Commands.reset(env: "test", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_setup
      expected_result =
        "cd ./ ; echo '🚀 Running bin/setup for test-service in test...' ; " \
        "docker-compose -f docker-compose-test.yml run test-service bin/setup ; " \
        "echo '✅ test-service setup complete'"

      with_mocked_base_path do
        result = Commands.setup(env: "test", service: "test-service")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_default
      expected_result = "cd ./ ; docker-compose -f docker-compose-test.yml up -d test-service"

      with_mocked_base_path do
        result = Commands.default(env: "test", command: "up", args: %w(-d test-service))

        assert result
        assert_equal expected_result, result
      end
    end

    def test_stop_excluding_db
      expected_result =
        "cd ./ ; " \
        "echo '🛡️  Skipping db. Pass --force to include it.' ; " \
        "docker-compose -f docker-compose-prd.yml stop " \
        "$(docker-compose -f docker-compose-prd.yml config --services | grep -vx db)"

      with_mocked_base_path do
        Configuration.stub(:db_service, "db") do
          result = Commands.stop_excluding_db(env: "prd", command: "stop")

          assert result
          assert_equal expected_result, result
        end
      end
    end

    def test_rebuild
      expected_result =
        "cd ./ ; " \
        "echo '🔨 Rebuilding services for prd (excluding db)...' ; " \
        "SERVICES=$(docker-compose -f docker-compose-prd.yml config --services | grep -vx db) ; " \
        "docker-compose -f docker-compose-prd.yml stop $SERVICES ; " \
        "docker-compose -f docker-compose-prd.yml rm -f $SERVICES ; " \
        "docker-compose -f docker-compose-prd.yml images -q $SERVICES | xargs -r docker rmi -f ; " \
        "docker-compose -f docker-compose-prd.yml build --no-cache $SERVICES ; " \
        "docker-compose -f docker-compose-prd.yml up -d $SERVICES ; " \
        "echo '✅ Rebuild complete'"

      with_mocked_base_path do
        Configuration.stub(:db_service, "db") do
          result = Commands.rebuild(env: "prd")

          assert result
          assert_equal expected_result, result
        end
      end
    end

    def test_setup_ssl_dev
      expected_result = "cd ./ ; " \
        "echo '🚀 Setting up mkcert certificate for development...' ; " \
        "mkdir -p compose/gateway-plantcare/certs ; " \
        "ENV_FILE=$([ -f ./.env.dev ] && echo ./.env.dev || echo ./.env) && source $ENV_FILE && mkcert" \
        " -cert-file compose/gateway-plantcare/certs/gateway-plantcare.crt" \
        " -key-file compose/gateway-plantcare/certs/gateway-plantcare.key" \
        " dev.$GATEWAY_HOST api.dev.$GATEWAY_HOST ; " \
        "echo '📦 Rebuilding gateway with mkcert certificate...' ; " \
        "docker-compose -f docker-compose-dev.yml up --build -d gateway-plantcare ; " \
        "echo '✅ SSL setup complete'"

      with_mocked_base_path do
        result = Commands.setup_ssl(env: "dev")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_setup_ssl
      expected_result = "cd ./ ; " \
        "echo '🚀 Starting gateway with temporary certificate...' ; " \
        "docker-compose -f docker-compose-pro.yml up -d gateway-plantcare ; " \
        "sleep 5 ; " \
        "echo \"📦 Obtaining Let's Encrypt certificate...\" ; " \
        "ENV_FILE=$([ -f ./.env.pro ] && echo ./.env.pro || echo ./.env) && source $ENV_FILE && " \
        "docker-compose -f docker-compose-pro.yml run --rm --entrypoint certbot " \
        "certbot certonly --webroot -w /var/www/certbot" \
        " -d $GATEWAY_HOST -d www.$GATEWAY_HOST -d api.$GATEWAY_HOST" \
        " --email admin@example.com --agree-tos --non-interactive ; " \
        "echo \"📦 Restarting gateway with Let's Encrypt certificate...\" ; " \
        "docker-compose -f docker-compose-pro.yml restart gateway-plantcare ; " \
        "echo '📦 Starting certbot renewal loop...' ; " \
        "docker-compose -f docker-compose-pro.yml up -d certbot ; " \
        "echo '✅ SSL setup complete'"

      with_mocked_base_path do
        result = Commands.setup_ssl(env: "pro", email: "admin@example.com")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_machine_activate_cmd_without_machine
      Configuration.stub(:machine_for, nil) do
        result = Commands.machine_activate_cmd("dev")
        assert_nil result
      end
    end

    def test_machine_activate_cmd_with_machine
      Configuration.stub(:machine_for, "plantcare-beta") do
        result = Commands.machine_activate_cmd("stg")
        assert_equal "eval $(docker-machine env plantcare-beta)", result
      end
    end

    def test_start_without_machine
      expected_result = "echo 'No docker-machine configured for dev'"

      Configuration.stub(:machine_for, nil) do
        result = Commands.start(env: "dev")
        assert_equal expected_result, result
      end
    end

    def test_start_starts_existing_stopped_machine
      expected_result =
        "status=$(docker-machine status plantcare-beta 2>&1) ; " \
        "if [ \"$status\" = \"Running\" ]; then " \
        "echo 'Machine plantcare-beta is already running, nothing to do' ; " \
        "elif [ \"$status\" = \"Stopped\" ]; then " \
        "echo 'Starting machine plantcare-beta...' ; " \
        "docker-machine start plantcare-beta ; " \
        "echo '✅ Machine plantcare-beta is now running' ; " \
        "else " \
        "echo 'Machine plantcare-beta not found, creating...' ; " \
        "docker-machine create --driver amazonec2  plantcare-beta ; " \
        "echo '✅ Machine plantcare-beta created and running' ; " \
        "fi"

      Configuration.stub(:machine_for, "plantcare-beta") do
        Configuration.stub(:machine_driver, "amazonec2") do
          Configuration.stub(:machine_create_opts, "") do
            result = Commands.start(env: "stg")

            assert result
            assert_equal expected_result, result
          end
        end
      end
    end

    def test_login_without_machine_disconnects
      expected_result = "docker-machine env -u ; echo 'export MOBYDOCK_ENV=dev'"

      Configuration.stub(:machine_for, nil) do
        result = Commands.login(env: "dev")
        assert_equal expected_result, result
      end
    end

    def test_login
      expected_result = "docker-machine env plantcare-beta ; echo 'export MOBYDOCK_ENV=stg'"

      Configuration.stub(:machine_for, "plantcare-beta") do
        result = Commands.login(env: "stg")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_logout
      result = Commands.logout

      assert_equal "docker-machine env -u ; echo 'unset MOBYDOCK_ENV'", result
    end

    def test_machine_ls
      result = Commands.machine_ls

      assert_equal "docker-machine ls", result
    end

    def test_destroy
      expected_result =
        "echo 'Removing machine plantcare-prd...' ; " \
        "docker-machine rm -y plantcare-prd && echo '✅ Machine plantcare-prd removed'"

      Configuration.stub(:machine_for, "plantcare-prd") do
        result = Commands.destroy(env: "prd")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_destroy_without_machine
      expected_result = "echo 'No docker-machine configured for dev'"

      Configuration.stub(:machine_for, nil) do
        result = Commands.destroy(env: "dev")

        assert_equal expected_result, result
      end
    end

    def test_launch_when_machine_exists
      expected_result =
        "if docker-machine inspect plantcare-dev > /dev/null 2>&1 ; then " \
        "echo 'Error: Machine plantcare-dev already exists' ; " \
        "exit 1 ; " \
        "else " \
        "echo 'Creating machine plantcare-dev...' ; " \
        "docker-machine create --driver amazonec2  plantcare-dev ; " \
        "echo '✅ Machine plantcare-dev created' ; " \
        "fi ; " \
        "eval $(docker-machine env plantcare-dev) ; cd ./ ; " \
        "echo '🚀 Setting up mkcert certificate for development...' ; " \
        "mkdir -p compose/gateway-plantcare/certs ; " \
        "ENV_FILE=$([ -f ./.env.dev ] && echo ./.env.dev || echo ./.env) && source $ENV_FILE && mkcert" \
        " -cert-file compose/gateway-plantcare/certs/gateway-plantcare.crt" \
        " -key-file compose/gateway-plantcare/certs/gateway-plantcare.key" \
        " dev.$GATEWAY_HOST api.dev.$GATEWAY_HOST ; " \
        "echo '📦 Rebuilding gateway with mkcert certificate...' ; " \
        "docker-compose -f docker-compose-dev.yml up --build -d gateway-plantcare ; " \
        "echo '✅ SSL setup complete'"

      Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-dev") do
          Configuration.stub(:machine_driver, "amazonec2") do
            Configuration.stub(:machine_create_opts, "") do
              Configuration.stub(:elastic_ip_alloc, nil) do
                result = Commands.launch(env: "dev")

                assert result
                assert_equal expected_result, result
              end
            end
          end
        end
      end
    end

    def test_launch_assigns_elastic_ip_when_configured
      config = "${MACHINE_STORAGE_PATH:-$HOME/.docker/machine}/machines/plantcare-prd/config.json"
      expected_result =
        "if docker-machine inspect plantcare-prd > /dev/null 2>&1 ; then " \
        "echo 'Error: Machine plantcare-prd already exists' ; " \
        "exit 1 ; " \
        "else " \
        "echo 'Creating machine plantcare-prd...' ; " \
        "docker-machine create --driver amazonec2 --amazonec2-region eu-west-1 plantcare-prd ; " \
        "echo '✅ Machine plantcare-prd created' ; " \
        "echo 'Assigning Elastic IP to plantcare-prd...' ; " \
        "INSTANCE_ID=$(docker-machine inspect plantcare-prd --format '{{.Driver.InstanceId}}') ; " \
        "OLD_IP=$(docker-machine ip plantcare-prd) ; " \
        "aws ec2 associate-address --region eu-west-1 " \
        "--instance-id $INSTANCE_ID --allocation-id eipalloc-0abc123 " \
        "|| { echo '❌ Failed to associate Elastic IP to plantcare-prd' ; exit 1 ; } ; " \
        "ELASTIC_IP=$(aws ec2 describe-addresses --region eu-west-1 --allocation-ids eipalloc-0abc123 " \
        "--query 'Addresses[0].PublicIp' --output text) ; " \
        "sed -i.bak \"s/$OLD_IP/$ELASTIC_IP/\" #{config} ; " \
        "sleep 5 ; " \
        "docker-machine regenerate-certs -f plantcare-prd ; " \
        "echo \"✅ Elastic IP $ELASTIC_IP assigned to plantcare-prd\" ; " \
        "fi ; " \
        "eval $(docker-machine env plantcare-prd) ; cd ./ ; " \
        "echo '🚀 Starting gateway with temporary certificate...' ; " \
        "docker-compose -f docker-compose-prd.yml up -d gateway-plantcare ; " \
        "sleep 5 ; " \
        "echo \"📦 Obtaining Let's Encrypt certificate...\" ; " \
        "ENV_FILE=$([ -f ./.env.prd ] && echo ./.env.prd || echo ./.env) && source $ENV_FILE && " \
        "docker-compose -f docker-compose-prd.yml run --rm --entrypoint certbot " \
        "certbot certonly --webroot -w /var/www/certbot" \
        " -d $GATEWAY_HOST -d www.$GATEWAY_HOST -d api.$GATEWAY_HOST" \
        " --email admin@example.com --agree-tos --non-interactive ; " \
        "echo \"📦 Restarting gateway with Let's Encrypt certificate...\" ; " \
        "docker-compose -f docker-compose-prd.yml restart gateway-plantcare ; " \
        "echo '📦 Starting certbot renewal loop...' ; " \
        "docker-compose -f docker-compose-prd.yml up -d certbot ; " \
        "echo '✅ SSL setup complete'"

      Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-prd") do
          Configuration.stub(:machine_driver, "amazonec2") do
            Configuration.stub(:machine_create_opts, "--amazonec2-region eu-west-1") do
              Configuration.stub(:elastic_ip_alloc, "eipalloc-0abc123") do
                result = Commands.launch(env: "prd", email: "admin@example.com")

                assert_equal expected_result, result
              end
            end
          end
        end
      end
    end

    def test_launch_without_machine
      expected_result = "echo 'No docker-machine configured for dev'"

      Configuration.stub(:machine_for, nil) do
        result = Commands.launch(env: "dev")
        assert_equal expected_result, result
      end
    end

    def test_launch_seeds_database_when_migrate_service_present
      command = Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-stg") do
          Configuration.stub(:machine_driver, "amazonec2") do
            Configuration.stub(:machine_create_opts, "") do
              Configuration.stub(:elastic_ip_alloc, nil) do
                Commands.launch(env: "stg", email: "me@example.com", migrate_service: "api-plantcare")
              end
            end
          end
        end
      end

      assert_includes command, "echo '📦 Setting up database on api-plantcare...'"
      assert_includes command,
                      "docker-compose -f docker-compose-stg.yml " \
                      "run --rm api-plantcare rails db:create db:migrate db:seed"
      assert_includes command, "echo '✅ Database ready'"
    end

    def test_launch_skips_database_without_migrate_service
      command = Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-stg") do
          Configuration.stub(:machine_driver, "amazonec2") do
            Configuration.stub(:machine_create_opts, "") do
              Configuration.stub(:elastic_ip_alloc, nil) do
                Commands.launch(env: "stg", email: "me@example.com")
              end
            end
          end
        end
      end

      refute_includes command, "rails db:create db:migrate db:seed"
    end

    def test_backup_db
      expected_result =
        "eval $(docker-machine env plantcare-prd) ; cd ./ ; mkdir -p backups ; " \
        "echo 'Starting database backup for prd...' ; " \
        "BACKUP_FILE=backups/backup-prd-$(date +%Y%m%d-%H%M%S).sql ; " \
        "ENV_FILE=$([ -f ./.env.prd ] && echo ./.env.prd || echo ./.env) && source $ENV_FILE && " \
        "docker-compose -f docker-compose-prd.yml exec -T db " \
        "mysqldump -u\"$MYSQL_USER\" -p\"$MYSQL_ROOT_PASSWORD\" \"$MYSQL_DATABASE\" " \
        "> $BACKUP_FILE ; " \
        "echo \"✅ Backup saved to $BACKUP_FILE\""

      Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-prd") do
          Configuration.stub(:db_service, "db") do
            result = Commands.backup_db(env: "prd")

            assert result
            assert_equal expected_result, result
          end
        end
      end
    end

    def test_backup_db_ls
      expected_result =
        "cd ./ ; " \
        "echo '📂 Backups for prd:' ; " \
        "ls -lh backups/backup-prd-*.sql"

      with_mocked_base_path do
        result = Commands.backup_db_ls(env: "prd")

        assert result
        assert_equal expected_result, result
      end
    end

    def test_restore_db
      expected_result =
        "eval $(docker-machine env plantcare-prd) ; cd ./ ; " \
        "echo '🚀 Restoring database for prd from backups/dump.sql...' ; " \
        "ENV_FILE=$([ -f ./.env.prd ] && echo ./.env.prd || echo ./.env) && source $ENV_FILE && " \
        "cat backups/dump.sql | docker-compose -f docker-compose-prd.yml exec -T db " \
        "mysql -u\"$MYSQL_USER\" -p\"$MYSQL_ROOT_PASSWORD\" \"$MYSQL_DATABASE\" ; " \
        "echo '✅ Database restored'"

      Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, "plantcare-prd") do
          Configuration.stub(:db_service, "db") do
            result = Commands.restore_db(env: "prd", backup_file: "backups/dump.sql")

            assert result
            assert_equal expected_result, result
          end
        end
      end
    end

    def test_deploy_without_migrate_service
      services_images = {
        "api-plantcare" => "lmbautista/api-plantcare:latest",
        "plantcare" => "lmbautista/plantcare:latest"
      }
      expected_result =
        "echo '🚀 Deploying to prd...' ; " \
        "cd ./ ; " \
        "docker-compose -f docker-compose-prd.yml stop ; " \
        "docker-compose -f docker-compose-prd.yml rm -f api-plantcare plantcare ; " \
        "docker images --filter=\"reference=lmbautista/api-plantcare:latest\" -q | xargs -r docker rmi -f ; " \
        "docker pull lmbautista/api-plantcare:latest ; " \
        "docker images --filter=\"reference=lmbautista/plantcare:latest\" -q | xargs -r docker rmi -f ; " \
        "docker pull lmbautista/plantcare:latest ; " \
        "docker-compose -f docker-compose-prd.yml build --no-cache --pull ; " \
        "docker-compose -f docker-compose-prd.yml up -d ; " \
        "echo '✅ Deploy complete'"

      with_mocked_base_path do
        result = Commands.deploy(env: "prd", services_images: services_images)

        assert result
        assert_equal expected_result, result
      end
    end

    def test_deploy_with_migrate_service
      services_images = {
        "api-plantcare" => "lmbautista/api-plantcare:latest",
        "plantcare" => "lmbautista/plantcare:latest"
      }
      expected_result =
        "echo '🚀 Deploying to prd...' ; " \
        "cd ./ ; " \
        "docker-compose -f docker-compose-prd.yml stop ; " \
        "docker-compose -f docker-compose-prd.yml rm -f api-plantcare plantcare ; " \
        "docker images --filter=\"reference=lmbautista/api-plantcare:latest\" -q | xargs -r docker rmi -f ; " \
        "docker pull lmbautista/api-plantcare:latest ; " \
        "docker images --filter=\"reference=lmbautista/plantcare:latest\" -q | xargs -r docker rmi -f ; " \
        "docker pull lmbautista/plantcare:latest ; " \
        "docker-compose -f docker-compose-prd.yml build --no-cache --pull ; " \
        "echo '📦 Running migrations on api-plantcare...' ; " \
        "docker-compose -f docker-compose-prd.yml run --rm api-plantcare rails db:migrate ; " \
        "docker-compose -f docker-compose-prd.yml up -d ; " \
        "echo '✅ Deploy complete'"

      with_mocked_base_path do
        result = Commands.deploy(env: "prd", services_images: services_images, migrate_service: "api-plantcare")

        assert result
        assert_equal expected_result, result
      end
    end

    private

    def with_mocked_base_path
      Configuration.stub(:base_path, "./") do
        Configuration.stub(:machine_for, nil) do
          yield
        end
      end
    end
  end
end
