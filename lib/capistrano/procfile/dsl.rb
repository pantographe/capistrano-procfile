require "capistrano/procfile/env_vars"
require "capistrano/procfile/exporter"
require "capistrano/procfile/options"
require "capistrano/procfile/utils"
require "capistrano/procfile/dsl/apply_helpers"
require "capistrano/procfile/dsl/management_helpers"
require "capistrano/procfile/dsl/method_helpers"

module Capistrano
  module Procfile
    module DSL
      include ApplyHelpers
      include ManagementHelpers
      include MethodHelpers

    private

      def backend
        if !self.kind_of?(SSHKit::Backend::Abstract)
          raise RuntimeError, "#{caller[0]} must be called in a SSHKit context"
        end

        self
      end

      def is_service_exists?(procname=nil)
        if !test("[[ -f #{fetch(:procfile_service_path)}/#{service_filename(procname)} ]]")
          backend.info "Nothing to do on #{host}"
          return false
        end

        true
      end

      def service_filename(procname=nil)
        if procname != nil
          return "#{procfile_service_name}-#{procname.to_s}.service"
        end

        "#{procfile_service_name}.target"
      end
    end
  end
end
