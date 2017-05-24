require "capistrano/procfile/env_vars"
module Capistrano
  module Procfile
    class Options < EnvVars

    private
      def load_defaults!
        update({
          app: "app",
        })
      end
    end
  end
end
