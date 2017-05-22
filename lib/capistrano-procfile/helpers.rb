class CapistranoProcfile::Exporter
  module Helpers
    def app
      options[:app] || "app"
    end

    def user
      options[:user] || app
    end

    def group
      options[:group] || user
    end

    def umask
      options[:umask] || nil
    end

    def root
      options[:root] || ""
    end

    def timeout
      options[:timeout] || 5
    end

    def restart_sec
      options[:restart_sec] || 1
    end

    def restart_method
      options[:restart_method] || "always"
    end

    def env_vars
      options[:env_vars] || {}
    end

  private

    def options
      @options
    end
  end
end
