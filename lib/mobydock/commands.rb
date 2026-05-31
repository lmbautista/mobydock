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
      LOGIN = "login",
      LOGOUT = "logout",
      DESTROY = "destroy",
      LAUNCH = "launch",
      BACKUP_DB = "backup-db",
      RESTORE_DB = "restore-db",
      DEPLOY = "deploy",
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
      command << "source ./.env && mkcert" \
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
      command << "source ./.env && #{docker_compose_prefix} run --rm --entrypoint certbot" \
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

    def launch(env:, email: nil)
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
      "#{setup_ssl(env: env, email: email)}"
    end

    def assign_elastic_ip_cmd(env, machine) # rubocop:disable Metrics/MethodLength
      alloc_id = Configuration.elastic_ip_alloc(env)
      return "" unless alloc_id

      config = "${MACHINE_STORAGE_PATH:-$HOME/.docker/machine}/machines/#{machine}/config.json"
      "echo 'Assigning Elastic IP to #{machine}...' ; " \
      "INSTANCE_ID=$(docker-machine inspect #{machine} --format '{{.Driver.InstanceId}}') ; " \
      "OLD_IP=$(docker-machine ip #{machine}) ; " \
      "ELASTIC_IP=$(aws ec2 describe-addresses --allocation-ids #{alloc_id} " \
      "--query 'Addresses[0].PublicIp' --output text) ; " \
      "docker-machine ssh #{machine} " \
      "\"sudo sed -i 's/$OLD_IP/$ELASTIC_IP/' /var/lib/boot2docker/profile " \
      "&& sudo /etc/init.d/docker restart\" ; " \
      "sed -i.bak \"s/$OLD_IP/$ELASTIC_IP/\" #{config} ; " \
      "aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id #{alloc_id} ; " \
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
      command << "source ./.env && #{docker_compose_prefix} exec -T #{service} " \
                 "mysqldump -u\"$MYSQL_USER\" -p\"$MYSQL_PASSWORD\" \"$MYSQL_DATABASE\" " \
                 "> backups/backup-#{env}-$(date +%Y%m%d-%H%M%S).sql"
      command << "echo '✅ Backup saved to backups/'"
      command.compact.join(" ; ")
    end

    def restore_db(env:, backup_file:)
      docker_compose_prefix = docker_compose_cmd_for(env)
      service = Configuration.db_service
      command = []
      command << machine_activate_cmd(env)
      command << working_path_cmd
      command << "echo '🚀 Restoring database for #{env} from #{backup_file}...'"
      command << "source ./.env && cat #{backup_file} | " \
                 "#{docker_compose_prefix} exec -T #{service} " \
                 "mysql -u\"$MYSQL_USER\" -p\"$MYSQL_PASSWORD\" \"$MYSQL_DATABASE\""
      command << "echo '✅ Database restored'"
      command.compact.join(" ; ")
    end

    def deploy(env:, services_images:, migrate_service: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      docker_compose_prefix = docker_compose_cmd_for(env)
      command = []
      command << machine_activate_cmd(env)
      command << "echo '🚀 Deploying to #{env}...'"
      command << "docker login"
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
      command << "echo '✅ Deploy complete'"

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

    private_methods :docker_compose_cmd
  end
end
