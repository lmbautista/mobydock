# frozen_string_literal: true

module Mobydock
  module Commands
    LIST = [
      UPDATE = "update",
      UPDATE_ALL = "update-all",
      RESET = "reset",
      SETUP = "setup",
      COMPILE_ASSETS = "compile-assets",
      SETUP_SSL = "setup-ssl",
      START = "start",
      SHUTDOWN = "shutdown",
      LOGIN = "login",
      LOGOUT = "logout",
      DESTROY = "destroy",
      LAUNCH = "launch",
      BACKUP_DB = "backup-db",
      BACKUP_DB_LS = "backup-db-ls",
      RESTORE_DB = "restore-db",
      DEPLOY = "deploy",
      REBUILD = "rebuild",
      HELP = "help"
    ].freeze

    MACHINE_LS = "ls"

    module_function

    def machine_ls
      "docker-machine ls"
    end

    def update(env:, service:, image:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << "echo '🚀 Updating #{service} in #{env}...'"
      command << "docker login"
      command << working_path_cmd
      command << "#{docker_compose_prefix} stop #{service}"
      command << "#{docker_compose_prefix} rm -f #{service}"
      command << remove_image_cmd(image)
      command << "docker pull #{image}"
      command << "#{docker_compose_prefix} build --no-cache --pull #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"
      command << "echo '✅ #{service} updated'"
      command.compact.join(" ; ")
    end

    def update_all(env:, services_images:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << "docker login"
      command << working_path_cmd

      services = services_images.keys.join(" ")

      command << "echo '🚀 Updating #{services} in #{env}...'"
      command << "#{docker_compose_prefix} stop #{services}"
      command << "#{docker_compose_prefix} rm -f #{services}"

      services_images.each_value do |image|
        command << remove_image_cmd(image)
        command << "docker pull #{image}"
      end

      command << "#{docker_compose_prefix} build --no-cache --pull #{services}"
      command << "#{docker_compose_prefix} up -d #{services}"
      command << "echo '✅ #{services} updated'"

      command.compact.join(" ; ")
    end

    def reset(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Resetting #{service} in #{env}...'"
      command << "#{docker_compose_prefix} stop #{service}"
      command << "#{docker_compose_prefix} rm #{service}"
      command << "#{docker_compose_prefix} up -d #{service}"
      command << "echo '✅ #{service} reset'"

      command.compact.join(" ; ")
    end

    def setup(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Running bin/setup for #{service} in #{env}...'"
      command << "#{docker_compose_prefix} run #{service} bin/setup"
      command << "echo '✅ #{service} setup complete'"

      command.compact.join(" ; ")
    end

    def compile_assets(env:, service:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo 'Compiling assets for #{env}...'"
      command << "#{docker_compose_prefix} exec #{service} rails assets:precompile " \
                 "RAILS_ENV=#{env == "dev" ? "development" : "production"}"
      command << "echo '✅ Assets compiled'"

      command.compact.join(" ; ")
    end

    def setup_ssl(env:, email: nil)
      env == "dev" ? setup_ssl_dev(env: env) : setup_ssl_pro(env: env, email: email)
    end

    def setup_ssl_dev(env:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Setting up mkcert certificate for development...'"
      command << "mkdir -p compose/gateway-plantcare/certs"
      command << "#{source_env_file_cmd(env)} && mkcert" \
                 " -cert-file compose/gateway-plantcare/certs/gateway-plantcare.crt" \
                 " -key-file compose/gateway-plantcare/certs/gateway-plantcare.key" \
                 " dev.$GATEWAY_HOST api.dev.$GATEWAY_HOST"
      command << "echo '📦 Rebuilding gateway with mkcert certificate...'"
      command << "#{docker_compose_prefix} up --build -d gateway-plantcare"
      command << "echo '✅ SSL setup complete'"
      command.compact.join(" ; ")
    end

    def setup_ssl_pro(env:, email:) # rubocop:disable Metrics/MethodLength
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Starting gateway with temporary certificate...'"
      command << "#{docker_compose_prefix} up -d gateway-plantcare"
      command << "sleep 5"
      command << "echo \"📦 Obtaining Let's Encrypt certificate...\""
      command << "#{source_env_file_cmd(env)} && #{docker_compose_prefix}" \
                 " run --rm --entrypoint certbot" \
                 " certbot certonly --webroot -w /var/www/certbot" \
                 " -d $GATEWAY_HOST -d www.$GATEWAY_HOST -d api.$GATEWAY_HOST" \
                 " --email #{email} --agree-tos --non-interactive"
      command << "echo \"📦 Restarting gateway with Let's Encrypt certificate...\""
      command << "#{docker_compose_prefix} restart gateway-plantcare"
      command << "echo '📦 Starting certbot renewal loop...'"
      command << "#{docker_compose_prefix} up -d certbot"
      command << "echo '✅ SSL setup complete'"
      command.compact.join(" ; ")
    end

    def start(env:) # rubocop:disable Metrics/MethodLength
      machine = Configuration.machine_for(env)
      return "echo 'No docker-machine configured for #{env}'" unless machine

      driver = Configuration.machine_driver
      create_opts = Configuration.machine_create_opts(env)

      "status=$(docker-machine status #{machine} 2>&1) ; " \
      "if [ \"$status\" = \"Running\" ]; then " \
      "echo 'Machine #{machine} is already running, nothing to do' ; " \
      "elif [ \"$status\" = \"Stopped\" ]; then " \
      "echo 'Starting machine #{machine}...' ; " \
      "docker-machine start #{machine} ; " \
      "echo '✅ Machine #{machine} is now running' ; " \
      "else " \
      "echo 'Machine #{machine} not found, creating...' ; " \
      "docker-machine create --driver #{driver} #{create_opts} #{machine} ; " \
      "echo '✅ Machine #{machine} created and running' ; " \
      "fi"
    end

    def shutdown(env:)
      machine = Configuration.machine_for(env)
      return "echo 'No docker-machine configured for #{env}'" unless machine

      "status=$(docker-machine status #{machine} 2>&1) ; " \
      "if [ \"$status\" = \"Stopped\" ]; then " \
      "echo 'Machine #{machine} is already stopped, nothing to do' ; " \
      "elif [ \"$status\" = \"Running\" ]; then " \
      "echo 'Stopping machine #{machine}...' ; " \
      "docker-machine stop #{machine} ; " \
      "echo '✅ Machine #{machine} is now stopped' ; " \
      "else " \
      "echo 'Machine #{machine} not found' ; " \
      "fi"
    end

    def login(env:)
      machine = Configuration.machine_for(env)
      base = machine ? "docker-machine env #{machine}" : "docker-machine env -u"

      "#{base} ; echo 'export MOBYDOCK_ENV=#{env}'"
    end

    def logout
      "docker-machine env -u ; echo 'unset MOBYDOCK_ENV'"
    end

    def destroy(env:)
      machine = Configuration.machine_for(env)
      return "echo 'No docker-machine configured for #{env}'" unless machine

      "echo 'Removing machine #{machine}...' ; " \
      "docker-machine rm -y #{machine} && echo '✅ Machine #{machine} removed'"
    end

    def launch(env:, email: nil, migrate_service: nil)
      machine = Configuration.machine_for(env)
      return "echo 'No docker-machine configured for #{env}'" unless machine

      driver = Configuration.machine_driver
      create_opts = Configuration.machine_create_opts(env)

      "if docker-machine inspect #{machine} > /dev/null 2>&1 ; then " \
      "echo 'Error: Machine #{machine} already exists' ; " \
      "exit 1 ; " \
      "else " \
      "echo 'Creating machine #{machine}...' ; " \
      "docker-machine create --driver #{driver} #{create_opts} #{machine} ; " \
      "echo '✅ Machine #{machine} created' ; " \
      "#{assign_elastic_ip_cmd(env, machine)}" \
      "fi ; " \
      "#{setup_ssl(env: env, email: email)}" \
      "#{setup_db_cmd(env, migrate_service)}"
    end

    def setup_db_cmd(env, migrate_service)
      return "" unless migrate_service

      docker_compose_prefix = docker_compose_cmd_for(env)
      " ; echo '📦 Setting up database on #{migrate_service}...'" \
      " ; #{docker_compose_prefix} run --rm #{migrate_service} rails db:create db:migrate db:seed" \
      " ; echo '✅ Database ready'"
    end

    def assign_elastic_ip_cmd(env, machine) # rubocop:disable Metrics/MethodLength
      alloc_id = Configuration.elastic_ip_alloc(env)
      return "" unless alloc_id

      region = Configuration.aws_region(env)
      region_opt = region ? " --region #{region}" : ""
      config = "${MACHINE_STORAGE_PATH:-$HOME/.docker/machine}/machines/#{machine}/config.json"
      "echo 'Assigning Elastic IP to #{machine}...' ; " \
      "INSTANCE_ID=$(docker-machine inspect #{machine} --format '{{.Driver.InstanceId}}') ; " \
      "OLD_IP=$(docker-machine ip #{machine}) ; " \
      "aws ec2 associate-address#{region_opt} " \
      "--instance-id $INSTANCE_ID --allocation-id #{alloc_id} " \
      "|| { echo '❌ Failed to associate Elastic IP to #{machine}' ; exit 1 ; } ; " \
      "ELASTIC_IP=$(aws ec2 describe-addresses#{region_opt} --allocation-ids #{alloc_id} " \
      "--query 'Addresses[0].PublicIp' --output text) ; " \
      "sed -i.bak \"s/$OLD_IP/$ELASTIC_IP/\" #{config} ; " \
      "sleep 5 ; " \
      "docker-machine regenerate-certs -f #{machine} ; " \
      "echo \"✅ Elastic IP $ELASTIC_IP assigned to #{machine}\" ; "
    end

    def backup_db(env:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      service = Configuration.db_service
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "mkdir -p backups"
      command << "echo 'Starting database backup for #{env}...'"
      command << "BACKUP_FILE=backups/backup-#{env}-$(date +%Y%m%d-%H%M%S).sql"
      command << "#{source_env_file_cmd(env)} && #{docker_compose_prefix} exec -T #{service} " \
                 "mysqldump -u\"$MYSQL_USER\" -p\"$MYSQL_ROOT_PASSWORD\" \"$MYSQL_DATABASE\" " \
                 "> $BACKUP_FILE"
      command << "echo \"✅ Backup saved to $BACKUP_FILE\""
      command.compact.join(" ; ")
    end

    def backup_db_ls(env:)
      command = []
      command << working_path_cmd
      command << "echo '📂 Backups for #{env}:'"
      command << "ls -lh backups/backup-#{env}-*.sql"
      command.compact.join(" ; ")
    end

    def restore_db(env:, backup_file:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      service = Configuration.db_service
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Restoring database for #{env} from #{backup_file}...'"
      command << "#{source_env_file_cmd(env)} && cat #{backup_file} | " \
                 "#{docker_compose_prefix} exec -T #{service} " \
                 "mysql -u\"$MYSQL_USER\" -p\"$MYSQL_ROOT_PASSWORD\" \"$MYSQL_DATABASE\""
      command << "echo '✅ Database restored'"
      command.compact.join(" ; ")
    end

    def deploy(env:, services_images:, migrate_service: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << "echo '🚀 Deploying to #{env}...'"
      command << working_path_cmd

      services = services_images.keys.join(" ")

      command << "#{docker_compose_prefix} stop"
      command << "#{docker_compose_prefix} rm -f #{services}"

      services_images.each_value do |image|
        command << remove_image_cmd(image)
        command << "docker pull #{image}"
      end

      command << "#{docker_compose_prefix} build --no-cache --pull"
      if migrate_service
        command << "echo '📦 Running migrations on #{migrate_service}...'"
        command << "#{docker_compose_prefix} run --rm #{migrate_service} rails db:migrate"
      end
      command << "#{docker_compose_prefix} up -d"
      command << "docker image prune -f"
      command << "echo '✅ Deploy complete'"

      command.compact.join(" ; ")
    end

    def rebuild(env:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      db_service = Configuration.db_service
      services = "$(#{docker_compose_prefix} config --services | grep -vx #{db_service})"
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🔨 Rebuilding services for #{env} (excluding #{db_service})...'"
      command << "SERVICES=#{services}"
      command << "#{docker_compose_prefix} stop $SERVICES"
      command << "#{docker_compose_prefix} rm -f $SERVICES"
      command << "#{docker_compose_prefix} images -q $SERVICES | xargs -r docker rmi -f"
      command << "#{docker_compose_prefix} build --no-cache $SERVICES"
      command << "#{docker_compose_prefix} up -d $SERVICES"
      command << "echo '✅ Rebuild complete'"
      command.compact.join(" ; ")
    end

    def default(env:, command:, args:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      default_command = []
      default_command << machine_activate_cmd(env)
      default_command << working_path_cmd
      default_command << [docker_compose_prefix, command, *args[0..]].join(" ")

      default_command.compact.join(" ; ")
    end

    def stop_excluding_db(env:, command:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      db_service = Configuration.db_service
      services = "$(#{docker_compose_prefix} config --services | grep -vx #{db_service})"
      command_list = []
      command_list << machine_activate_cmd(env)
      command_list << working_path_cmd
      command_list << "echo '🛡️  Skipping #{db_service}. Pass --force to include it.'"
      command_list << "#{docker_compose_prefix} #{command} #{services}"
      command_list.compact.join(" ; ")
    end

    def docker_compose_cmd_for(env)
      "docker-compose -f docker-compose-#{env}.yml"
    end

    def machine_activate_cmd(env)
      machine = Configuration.machine_for(env)
      "eval $(docker-machine env #{machine})" if machine
    end

    def remove_image_cmd(image)
      ["docker images --filter=\"reference=#{image}\" -q",
       "xargs -r docker rmi -f"].join(" | ")
    end

    def working_path_cmd
      "cd #{Configuration.base_path}"
    end

    def source_env_file_cmd(env)
      "ENV_FILE=$([ -f ./.env.#{env} ] && echo ./.env.#{env} || echo ./.env) && source $ENV_FILE"
    end

    private_methods :docker_compose_cmd
  end
end
