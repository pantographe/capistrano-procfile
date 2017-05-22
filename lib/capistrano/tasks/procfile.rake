require "capistrano-procfile"

namespace :procfile do
  desc "Apply Procfile commands on server(s)"
  task :apply do
    invoke "procfile:applying"
    invoke "procfile:start"

    puts "Wait 15 second before check"
    sleep 15

    invoke "procfile:check"
  end

  desc "Applying Procfile commands on server(s)"
  task :applying => [:set_procfile, :set_host_properties] do
    procfile = fetch(:procfile, nil)
    next if procfile.nil?

    servers = release_roles(:all) # @todo Use Procfile.keys as roles?
    tmp_dir = fetch(:tmp_dir, "/tmp") # @todo Use a subdir in /tmp?

    rendered_path  = fetch(:procfile_service_path)
    templates_path = fetch(:procfile_service_template_path)

    common_options  = CapistranoProcfile::Options.new(fetch(:procfile_options))
    common_env_vars = CapistranoProcfile::EnvVars.new(fetch(:procfile_service_env_vars))

    on servers, in: :groups, limit: (servers.length / 3).round do |host|
      within release_path do
        execute :mkdir, "-pv", tmp_dir if test "[[ ! -f #{tmp_dir} ]]"

        options = common_options.merge(host.properties.fetch(:procfile_options) || {})
        options.apply_host(host)

        env_vars = common_env_vars.merge(host.properties.fetch(:procfile_env_vers) || {})
        env_vars.apply_host(host)

        exporter = CapistranoProcfile::Exporter.new(procfile, host, templates_path, {
          app: service_name,
          user: options.user || host.user,
          group: options.group,
          umask: options.umask,
          root:  current_path,
          env_vars: env_vars,
        })

        as :root do
          exporter.files do |filename, content|
            upload! StringIO.new(content), "#{tmp_dir}/#{filename}"

            sudo :cp,    "-a", "#{tmp_dir}/#{filename}", "#{fetch(:procfile_service_path)}/#{filename}"
            sudo :chmod, "+r", "#{rendered_path}/#{filename}"
          end

          upload! StringIO.new(exporter.procfile_lock), "#{release_path}/Procfile.lock"
        end

        info ">> #{exporter.filenames.join(", ")} services applied on #{host}"

        sudo :systemctl, "daemon-reload"
      end
    end
  end

  # Loop to have "start" and "enable".
  %w{ start stop restart }.each do |cmd|
    desc "#{cmd.capitalize} Procfile services"
    # manage options to be able to specify a service or services?
    task cmd.to_sym => [:set_procfile] do
      next if fetch(:procfile, nil).nil?

      on release_roles(:all) do
        if !test("[[ -f #{fetch(:procfile_service_path)}/#{service_name}.target ]]")
          info "Nothing to do on #{host}"
          next
        end

        sudo :systemctl, cmd, "#{service_name}.target"
      end
    end
  end

  %w{ enable disable }.each do |cmd|
    desc "#{cmd.capitalize} Procfile services"
    task cmd.to_sym => [:set_procfile] do
      next if fetch(:procfile, nil).nil?

      on release_roles(:all) do
        sudo :systemctl, cmd, "#{service_name}.target"
      end
    end
  end

  desc "Check services status"
  task :check => [:set_procfile] do
    procfile = fetch(:procfile, nil)
    next if procfile.nil?

    on release_roles(:all) do |host|
      procfile.entries(names: @host.roles) do |procname, command|
        if test "sudo systemctl is-active #{service_name}-#{procname}.service"
          info "#{procname} service is active on #{host}"
        else
          is_failed = test "sudo systemctl is-failed #{service_name}-#{procname}.service"

          if is_failed
            error "#{procname} service is failed on #{host}"
          else
            warn "#{procname} service is not active on #{host}"
          end

          if fetch(:deploying, false) === true && is_failed
            # @todo invoke rollback
            # Rake::Task["deploy:rollback"].invoke
          end
        end
      end
    end
  end

  desc "Cleanup services"
  task :cleanup => [:set_procfile] do
    next if fetch(:procfile, nil).nil?

    on roles(:all) do |host|
      Rake::Task["procfile:disable"].invoke
      Rake::Task["procfile:stop"].invoke

      files = capture(:ls, "-x", "#{fetch(:procfile_service_path)}/#{service_name}-*.service", raise_on_non_zero_exit: false).split
      files << capture(:ls, "-x", "#{fetch(:procfile_service_path)}/#{service_name}.target", raise_on_non_zero_exit: false)

      files.each do |file|
        sudo :rm, file if test("[[ -f #{file} ]]")
      end

      sudo :systemctl, "daemon-reload"
    end
  end
private
  def service_name
    CapistranoProcfile::Utils.parameterize(fetch(:procfile_service_name))
  end
end

Capistrano::DSL.stages.each do |stage|
  # after stage, "procfile:set_procfile"
end

namespace :load do
  task :defaults do
    set_if_empty :procfile_path,                   "Procfile"
    set_if_empty :procfile_options,                {}
    set_if_empty :procfile_service_name,           -> { fetch(:application) }
    set_if_empty :procfile_service_path,           "/lib/systemd/system"
    set_if_empty :procfile_service_template_path,  File.expand_path("../../templates/systemd", __FILE__)
    set_if_empty :procfile_service_env_vars,       -> { fetch(:default_env, {}) }
  end
end
