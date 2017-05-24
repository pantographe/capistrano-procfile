module Capistrano
  module Procfile
    module DSL
      module MethodHelpers
        def procfile
          procfile = fetch(:procfile, nil)
        end

        def procfile_service_name
          Utils.parameterize(fetch(:procfile_service_name))
        end

        def wait_until(timeout, msg)
          puts msg % timeout
          sleep timeout
        end

        def rounded_on(servers, force: false, &block)
          # @todo add an option to enable this or not
          #       because in most of the case we could configure our capistrano
          #       to send correct signals.
          #       But it could be nice to have the avaibility of using this? no?
          servers = Array.new(servers)
          opts    = Hash.new

          if force || fetch(:my_option, false)
            opts = { in: :groups, limit: (servers.length / 3).round }
          end

          on servers, opts, &block
        end
      end
    end
  end
end
