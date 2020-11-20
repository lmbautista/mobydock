# frozen_string_literal: true

module Mobydock
  module Configuration
    module_function

    def envs
      ENV["MOBYDOCK_ENVS"].split(",")
    end

    def base_path
      ENV["MOBYDOCK_PATH"]
    end
  end
end
