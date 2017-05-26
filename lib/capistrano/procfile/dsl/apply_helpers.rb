require "capistrano/procfile/diff"

module Capistrano
  module Procfile
    module DSL
      module ApplyHelpers
        def procfile_apply(host)
          rendered_path  = fetch(:procfile_service_path)

          backend.execute :mkdir, "-p", tmp_dir
          backend.execute :rm, "-rf", "#{tmp_dir}/*"

          backend.execute :mkdir, "-p", rendered_path unless backend.test "[[ -d #{rendered_path} ]]"

          exporter = exporter(host)
          # export = exporter.generate! host
          diff = Diff.new(backend, "#{procfile_service_name}-*.service")

          exporter.service_files do |filename, content|
            backend.upload! StringIO.new(content), "#{tmp_dir}/#{filename}"
          end

          backend.as :root do
            diff.diff(rendered_path, tmp_dir).each do |service, state|
              case state
              when :deleted
                backend.execute :systemctl, "stop", service
                backend.execute :rm, "#{rendered_path}/#{service}"
              when :added
                backend.execute :cp, "-a", "#{tmp_dir}/#{service}", "#{rendered_path}/#{service}"
                backend.execute :chmod, "+r", "#{rendered_path}/#{service}"
              when :updated
                backend.execute :systemctl, "stop", service
                backend.execute :cp, "-a", "#{tmp_dir}/#{service}", "#{rendered_path}/#{service}"
                backend.execute :chmod, "+r", "#{rendered_path}/#{service}"
              end

              backend.info "#{service} is #{state} on #{host}"
            end

            exporter.global_files do |filename, content|
              backend.upload! StringIO.new(content), "#{rendered_path}/#{filename}"
            end
          end
        end

        def procfile_generate_lock(host)
          backend.as :root do
            # backend.upload! StringIO.new(exporter.procfile_lock), "#{release_path}/Procfile.lock"
          end
        end

      private

        def tmp_dir
          @tmp_dir ||= "#{fetch(:tmp_dir, "/tmp")}/#{fetch(:application)}_procfile"
        end

        def exporter(host)
          templates_path = fetch(:procfile_service_template_path)

          options  = generate_options(host)
          env_vars = generate_env_vars(host)

          Exporter.new(procfile, host, templates_path, {
            app: procfile_service_name,
            user: "deploy", # options.user || host.user,
            # group: options.group,
            # umask: options.umask,
            root:  current_path,
            env_vars: env_vars,
          })
        end

        def common_options
          @common_options ||= Capistrano::Procfile::Options.new(fetch(:procfile_options))
        end

        def generate_options(host)
          options = common_options.merge(host.properties.fetch(:procfile_options) || {})
          options.apply_host(host)
          options
        end

        def common_env_vars
          env = fetch(:default_env, {}).merge(fetch(:procfile_service_env_vars))
          @common_env_vars ||= Capistrano::Procfile::EnvVars.new(env)
        end

        def generate_env_vars(host)
          env_vars = common_env_vars.merge(host.properties.fetch(:procfile_env_vers) || {})
          env_vars.apply_host(host)
          env_vars.cleanup!
          env_vars
        end
      end
    end
  end
end
