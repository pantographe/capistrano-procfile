module Capistrano
  module Procfile
    module DSL
      module ManagementHelpers
        def procfile_enable
          return unless is_service_exists?

          backend.sudo :systemctl, :enable, service_filename
        end

        def procfile_disable
          return unless is_service_exists?

          backend.sudo :systemctl, :disable, service_filename
        end

        def procfile_start(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, "start", service_filename(procname)
        end

        def procfile_stop(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, "stop", service_filename(procname)
        end

        def procfile_restart(procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, "restart", service_filename(procname)
        end

        def procfile_kill(sig=:term, procname=nil)
          return unless is_service_exists?(procname)

          backend.sudo :systemctl, "kill", service_filename(procname), "--signal=#{sig.to_s.upcase}"
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
          is_failed = backend.test "sudo systemctl is-failed #{procfile_service_name}-#{procname}.service"
          status    = nil

          if is_failed
            status = :failed
          else
            if backend.test "sudo systemctl is-active #{procfile_service_name}-#{procname}.service"
              status = :active
            else
              status = :not_active
            end
          end

          status
        end
      end
    end
  end
end
