require "erb"
require "capistrano/procfile/helpers"

module Capistrano
  module Procfile
    class Exporter
      include Helpers

      def initialize(procfile, host, templates_path, options)
        raise ArgumentError, "procfile argument must be a kind of Caspitrano::Procfile::Procfile" unless procfile.kind_of?(Procfile)
        # raise Exception, "Options unvalid" unless procfile.kind_of?(Options)

        @procfile       = procfile
        @host           = host
        @templates_path = templates_path
        @files          = {}
        @options        = options

        generate! host
      end

      def generate!(host)
        processes_names = []
        i = 0

        @procfile.entries(names: host.roles) do |procname, command|
          service_filename = "#{app}-#{procname}.service"

          env_vars.port += i.to_i * 100 if env_vars.port.is_a? Integer

          add_file service_filename, template("process.service.erb", binding)
          processes_names << service_filename

          i += 1
        end

        add_file "#{app}.target", template("master.target.erb", binding)
      end

      def processes
        @procfile.entries(names: @host.roles) || {}
      end

      def procfile_lock
        {
          processes_names: processes.keys,
          services: filenames,
        }.to_yaml
      end

      def filenames(&block)
        keys = @files.keys

        if block_given?
          keys.each do |(filename)|
            yield filename
          end
        else
          keys
        end
      end

      def files(&block)
        if block_given?
          @files.each do |(filename, content)|
            yield filename, content
          end
        else
          @files
        end
      end

      def service_files(&block)
        if block_given?
          @files.each do |(filename, content)|
            yield filename, content if filename.end_with? ".service"
          end
        else
          @files
        end
      end

      def global_files(&block)
        if block_given?
          @files.each do |(filename, content)|
            yield filename, content if filename.end_with? ".target"
          end
        else
          @files
        end
      end

    private

      def add_file(filename, content)
        @files[filename] = content
      end

      def template(template, binding)
        template = File.read(File.join(@templates_path, template))
        ERB.new(template, nil, "-").result(binding)
      end
    end
  end
end
