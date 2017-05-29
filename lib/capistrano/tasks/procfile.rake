require "capistrano/procfile/dsl"

include Capistrano::Procfile::DSL

namespace :procfile do
  desc "Apply Procfile commands on server(s)"
  task :apply do
    invoke "procfile:apply:updating"
    invoke "procfile:apply:updated"
    invoke "procfile:apply:starting"
    invoke "procfile:apply:started"
    invoke "procfile:apply:enable"
  end

  namespace :apply do
    task :update do
      next unless fetch(:procfile_apply_automatically)

      invoke "procfile:apply:updating"
      invoke "procfile:apply:updated"
    end

    task :updating => [:set_procfile, :set_host_properties]  do
      next if procfile.nil?

      rounded_on release_roles(:all) do |host|
        within release_path do
          procfile_apply host

          procfile_reload_daemon
        end
      end
    end

    task :updated do
    end

    task :start do
      next unless fetch(:procfile_apply_automatically)

      invoke "procfile:apply:starting"
      invoke "procfile:apply:started"
    end

    task :starting do
      invoke "procfile:start"

      wait_until fetch(:procfile_check_timeout), "Wait %s second before check"

      invoke "procfile:check"
    end

    task :started do
    end

    task :enable do
      next unless fetch(:procfile_enable_automatically)

      invoke "procfile:enable"
    end
  end

  # Loop to have "start" and "enable".
  %w{ start stop restart }.each do |cmd|
    desc "#{cmd.capitalize} Procfile service(s)"
    task cmd.to_sym, [:procname] => [:set_procfile] do |t, args|
      next if procfile.nil?

      rounded_on release_roles(:all), force: (cmd == "restart") do
        public_send "procfile_#{cmd}", args[:procname]
      end
    end
  end

  %w{ enable disable }.each do |cmd|
    desc "#{cmd.capitalize} Procfile services"
    task cmd.to_sym => [:set_procfile] do
      next if procfile.nil?

      on release_roles(:all) do |host|
        public_send "procfile_#{cmd}"
      end
    end
  end

  desc "Kill Procfile service(s)"
  task :kill, [:signal, :procname] => [:set_procfile] do |t, args|
    next if procfile.nil?

    rounded_on release_roles(:all) do |host|
      procfile.entries(names: host.roles) do |procname, command|
        if args[:procname].nil? || args[:procname].to_s == procname.to_s
          procfile_kill(args[:signal], procname)
        end
      end
    end
  end

  desc "Check services status"
  task :check, [:procname] => [:set_procfile] do |t, args|
    next if procfile.nil?

    on release_roles(:all) do |host|
      # @todo Have Procfile who contain both Procfile and Procfile.lock
      procfile.entries(names: host.roles) do |procname, command|
        case status = procfile_process_status(procname)
        when :not_installed
          warn "#{procname} service is not installed on #{host}"
        when :active
          info "#{procname} service is active on #{host}"
        when :not_active
          warn "#{procname} service is not active on #{host}"
        when :failed
          error "#{procname} service is failed on #{host}"
        end

        if fetch(:deploying, false) && status == :failed
          invoke "deploy:rollback"
        end
      end
    end
  end

  desc "Cleanup services"
  task :cleanup => [:set_procfile] do
    next if procfile.nil?

    invoke "procfile:disable"
    invoke "procfile:stop"

    on release_roles(:all) do |host|
      procfile_cleanup

      procfile_reload_daemon
    end
  end
end

before "deploy:publishing", "procfile:apply:update"
before "deploy:finishing",  "procfile:apply:start"
after  "deploy:finished",   "procfile:apply:enable"

namespace :load do
  task :defaults do
    set_if_empty :procfile_path,                   "Procfile"
    set_if_empty :procfile_options,                {
      user: ->(host) { host.user }
    }

    set_if_empty :procfile_service_name,           -> { fetch(:application) }
    set_if_empty :procfile_service_path,           "/lib/systemd/system"
    set_if_empty :procfile_service_template_path,  File.expand_path("../../templates/systemd", __FILE__)
    set_if_empty :procfile_service_env_vars,       -> { fetch(:default_env, {}) }
    set_if_empty :procfile_check_timeout,          15

    set_if_empty :procfile_apply_automatically,  true
    set_if_empty :procfile_enable_automatically, -> { fetch(:procfile_apply_automatically) }
  end
end
