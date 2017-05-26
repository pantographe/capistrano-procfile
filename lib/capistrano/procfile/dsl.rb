require "capistrano/procfile/env_vars"
require "capistrano/procfile/exporter"
require "capistrano/procfile/options"
require "capistrano/procfile/utils"
require "capistrano/procfile/dsl/apply_helpers"
require "capistrano/procfile/dsl/management_helpers"

module Capistrano
  module Procfile
    module DSL
      include ApplyHelpers
      include ManagementHelpers

      def procfile
        procfile = fetch(:procfile, nil)
      end

      def procfile_service_name
        Utils.parameterize(fetch(:procfile_service_name))
      end

      def wait_until(timeout, msg)
        return unless timeout > 0

        puts msg % timeout
        sleep timeout
      end

      def rounded_on(servers, force: false, &block)
        # @todo add an option to enable this or not
        #       because in most of the case we could configure our capistrano
        #       to send correct signals.
        #       But it could be nice to have the avaibility of using this? no?
        opts = Hash.new

        if force || fetch(:my_option, false)
          opts = { in: :groups, limit: (servers.length / 3).round }
        end

        on servers, opts, &block
      end

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
