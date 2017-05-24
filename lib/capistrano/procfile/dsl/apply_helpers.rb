module Capistrano
  module Procfile
    module DSL
      module ApplyHelpers
        def procfile_apply(host)
          rendered_path  = fetch(:procfile_service_path)

          execute :mkdir, "-pv", tmp_dir if test "[[ ! -f #{tmp_dir} ]]"

          exporter = exporter(host)
          # export = exporter.generate! host

          backend.as :root do
            exporter.files do |filename, content|
              backend.upload! StringIO.new(content), "#{tmp_dir}/#{filename}"

              backend.sudo :cp,    "-a", "#{tmp_dir}/#{filename}", "#{fetch(:procfile_service_path)}/#{filename}"
              backend.sudo :chmod, "+r", "#{rendered_path}/#{filename}"
            end

            backend.upload! StringIO.new(exporter.procfile_lock), "#{release_path}/Procfile.lock"
          end

          backend.info ">> #{exporter.filenames.join(", ")} services applied on #{host}"

          # diff = CapistranoProcfile::Diff.new(self, host, procfile)
          # put diff.diff("/lib/systemd/system", "/tmp").inspect

          # diff -qI "^#" /tmp/demo-app-web.service /lib/systemd/system/demo-app-web.service
          # backend.test("systemctl is-failed demo-app-web.service")
        end

        def procfile_generate_lock(host)
          backend.as :root do
            # backend.upload! StringIO.new(exporter.procfile_lock), "#{release_path}/Procfile.lock"
          end
        end

      private

        def tmp_dir
          fetch(:tmp_dir, "/tmp") # @todo Use a subdir in /tmp?
        end

        def exporter(host)
          templates_path = fetch(:procfile_service_template_path)

          options  = generate_options(host)
          env_vars = generate_env_vars(host)

          exporter = Exporter.new(procfile, host, templates_path, {
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
          @common_env_vars ||= Capistrano::Procfile::EnvVars.new(fetch(:procfile_service_env_vars))
        end

        def generate_env_vars(host)
          env_vars = common_env_vars.merge(host.properties.fetch(:procfile_env_vers) || {})
          env_vars.apply_host(host)
          env_vars
        end
      end
    end
  end
end
