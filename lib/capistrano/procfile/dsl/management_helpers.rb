module Capistrano
  module Procfile
    module DSL
      module ManagementHelpers
        def procfile_enable(procname=nil)
          return unless is_service_exists?(procname)
          return if is_service_enabled?(procname)

          backend.sudo :systemctl, :enable, service_filename(procname)
        end

        def procfile_disable(procname=nil)
          return unless is_service_exists?(procname)
          return unless is_service_enabled?(procname)

          backend.sudo :systemctl, :disable, service_filename(procname)
        end

        def procfile_start(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, :start, service_filename(procname)
        end

        def procfile_stop(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, :stop, service_filename(procname)
        end

        def procfile_restart(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, :restart, service_filename(procname)
        end

        def procfile_kill(sig, procname)
          return unless is_service_exists?(procname)
          return unless procfile_process_status(procname) == :active
          raise ArgumentError, "`procname' must not be nil" if procname.nil?

          sig ||= :term

          backend.sudo :systemctl, :kill, service_filename(procname), "--signal=#{sig.to_s.upcase}"
        end

        def procfile_reload_daemon
          backend.sudo :systemctl, "daemon-reload"
        end

        def procfile_cleanup
          files = backend.capture(:ls, "-x", "#{fetch(:procfile_service_path)}/#{procfile_service_name}-*.service", raise_on_non_zero_exit: false).split
          files << backend.capture(:ls, "-x", "#{fetch(:procfile_service_path)}/#{procfile_service_name}.target", raise_on_non_zero_exit: false)

          files.each do |file|
            backend.sudo :rm, file if test("[[ -f #{file} ]]")
          end
        end

        def procfile_process_status(procname)
          status = nil

          if !is_service_exists?(procname, verbose: false)
            status = :not_installed
          elsif backend.test "sudo systemctl is-failed #{service_filename(procname)}"
            status = :failed
          else
            if backend.test "sudo systemctl is-active #{service_filename(procname)}"
              status = :active
            else
              status = :not_active
            end
          end

          status
        end

      private

        def is_service_enabled?(procname=nil)
          backend.test "sudo systemctl is-enabled #{service_filename(procname)}"
        end
      end
    end
  end
end
