require "erb"
require "ostruct"
require "procfile"

namespace :procfile do
  desc "Apply Procfile commands on server(s)"
  task :apply => [:set_procfile] do
    common_options = fetch(:procfile_options, {})

    on release_roles(:all) do |host|
      within release_path do
        procfile = fetch(:procfile, nil)
        next if procfile.nil?

        capture_host_specs! host

        @application_name  = fetch(:application)
        services_templates = {}

        rendered_path  = fetch(:procfile_service_path)
        templates_path = fetch(:procfile_service_template_path)
        service_name   = parameterize(fetch(:procfile_service_name))

        env_vars = process_env_vars(host, fetch(:procfile_service_env_vars))
        options  = OpenStruct.new(host.properties.fetch(:procfile_options))
        i        = 0

        execute :mkdir, "-p", rendered_path

        procfile.entries(names: host.roles) do |procname, command|
          @service_name   = procname
          @target_name    = service_name
          @user           = options.user || host.user
          @group          = options.group
          @umask          = options.umask
          @root_path      = current_path
          @command        = command
          @restart_method = "always"
          @restart_sec    = 1
          @timeout        = 5

          @env_vars      = env_vars
          @env_vars.port = (@env_vars.port || 5000).to_i + (i.to_i * 100)

          i += 1

          # Service template.
          service = ERB.new(File.read(File.join(templates_path, "process.service.erb")), nil, "-").result(binding)
          service_filename = "#{service_name}-#{procname}.service"

          as :root do
            upload! StringIO.new(service), "#{rendered_path}/#{service_filename}"
            sudo :chmod, "+r", "#{rendered_path}/#{service_filename}"
          end

          services_templates[service_filename] = service
        end

        # Target template.
        @services_filenames = services_templates.keys
        target_template = ERB.new(File.read(File.join(templates_path, "master.target.erb")), nil, "-").result(binding)

        as :root do
          upload! StringIO.new(target_template), "#{rendered_path}/#{service_name}.target"
          sudo :chmod, "+r", "#{rendered_path}/#{service_name}.target"
        end

        info ">> #{@services_filenames.join(", ")} services applied on #{host}"

        sudo :systemctl, "daemon-reload"
      end
    end
  end

  namespace :systemd do
    %w( disable enable is-active is-enabled is-failed reload restart start status stop ).each do |cmd|
      desc "#{cmd.capitalize} Procfile process on servers"
      task cmd.to_sym => [:set_procfile] do
        on release_roles(:all) do
          next if fetch(:procfile, nil).nil?

          sudo :systemctl, cmd, "#{parameterize(fetch(:procfile_service_name))}.target"
        end
      end
    end
  end

  desc "Restart services"
  task :restart => [:set_procfile] do
    on release_roles(:all) do
      within release_path do
        next if fetch(:procfile, nil).nil?

        sudo :systemctl, "restart", "#{parameterize(fetch(:procfile_service_name))}.target"
      end
    end
  end

  desc "Cleanup services"
  task :cleanup => [:set_procfile] do
    on roles(:all) do
      within release_path do
        next if fetch(:procfile, nil).nil?
      end
    end
  end

  task :set_procfile do
    procfile = nil

    on primary(:app) do |host|
      within release_path do
        procfile = capture(:cat, "#{release_path}/#{fetch(:procfile_path, "Procfile")}") if test("[[ -f #{release_path}/#{fetch(:procfile_path, "Procfile")} ]]")
      end
    end

    if procfile.nil?
      warn "Procfile not found"
    else
      procfile = Procfile.new(procfile)
    end

    set(:procfile, procfile)
  end

  private

  def capture_host_specs!(host)
    host.properties.specs = OpenStruct.new({
      number_of_cpus: capture("grep -c processor /proc/cpuinfo").to_i,
      memory: (capture("awk '/MemTotal/ {print $2}' /proc/meminfo").to_i / 1024).round,
    })
  end

  def process_env_vars(host, vars)
    vars = OpenStruct.new(vars)

    vars.each_pair do |var, env|
      args      = [host]
      vars[var] = env.call(*args.take(env.arity)) if env.respond_to?(:call)
    end

    vars
  end

  # From: https://github.com/rails/rails/blob/f90a08c193d4ec8267f4409b7a670c2b53e0621d/activesupport/lib/active_support/inflector/transliterate.rb#L83
  def parameterize(string)
    # parameterized_string = transliterate(string)
    parameterized_string = string
    separator = "-"

    # Turn unwanted chars into the separator.
    parameterized_string.gsub!(/[^a-z0-9\-_]+/i, separator)

    unless separator.nil? || separator.empty?
      if separator == "-".freeze
        re_duplicate_separator        = /-{2,}/
        re_leading_trailing_separator = /^-|-$/i
      else
        re_sep = Regexp.escape(separator)
        re_duplicate_separator        = /#{re_sep}{2,}/
        re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/i
      end
      # No more than one of the separator in a row.
      parameterized_string.gsub!(re_duplicate_separator, separator)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(re_leading_trailing_separator, "".freeze)
    end

    parameterized_string.downcase!
    parameterized_string
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, "procfile:set_procfile"
end

namespace :load do
  task :defaults do
    set_if_empty :procfile_path,                   "Procfile"
    set_if_empty :procfile_options,                {}
    set_if_empty :procfile_service_name,           -> { fetch(:application) }
    set_if_empty :procfile_service_path,           "/lib/systemd/system"
    set_if_empty :procfile_service_template_path,  File.expand_path("../../templates/systemd", __FILE__)
    set_if_empty :procfile_service_env_vars,       {}
  end
end
