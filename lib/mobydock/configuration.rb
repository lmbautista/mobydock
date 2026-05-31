# frozen_string_literal: true

module Mobydock
  module Configuration
    module_function

    def envs
      ENV["MOBYDOCK_ENVS"].split(",")
    end

    def protected_envs
      ENV.fetch("MOBYDOCK_PROTECTED_ENVS", "").split(",")
    end

    def protected_env?(env)
      protected_envs.include?(env)
    end

    def base_path
      ENV["MOBYDOCK_PATH"]
    end

    def machine_for(env)
      map = ENV.fetch("MOBYDOCK_MACHINE_MAP", "")
      map.split(",").each do |entry|
        e, machine = entry.split(":")
        return machine if e == env
      end
      nil
    end

    def db_service
      ENV["MOBYDOCK_DB_SERVICE"]
    end

    MACHINE_DRIVER = "amazonec2"

    def machine_driver
      MACHINE_DRIVER
    end

    def machine_create_opts(env)
      ENV.fetch("MOBYDOCK_MACHINE_CREATE_OPTS_#{env.upcase}") do
        ENV.fetch("MOBYDOCK_MACHINE_CREATE_OPTS", "")
      end
    end

    def elastic_ip_alloc(env)
      alloc = ENV.fetch("MOBYDOCK_ELASTIC_IP_ALLOC_#{env.upcase}", "")
      alloc.empty? ? nil : alloc
    end

    def deploy_services(env)
      map = ENV.fetch("MOBYDOCK_DEPLOY_SERVICES_#{env.upcase}") do
        ENV.fetch("MOBYDOCK_DEPLOY_SERVICES", "")
      end
      return {} if map.empty?

      map.split(",").each_with_object({}) do |entry, hash|
        service, image = entry.split("=", 2)
        hash[service] = image
      end
    end

    def migrate_service(env)
      service = ENV.fetch("MOBYDOCK_MIGRATE_SERVICE_#{env.upcase}") do
        ENV.fetch("MOBYDOCK_MIGRATE_SERVICE", "")
      end
      service.empty? ? nil : service
    end
  end
end
