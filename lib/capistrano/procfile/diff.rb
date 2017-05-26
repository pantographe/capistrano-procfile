module Capistrano
  module Procfile
    class Diff
      def initialize(backend, service_pattern)
        @backend         = backend
        @service_pattern = service_pattern
      end

      def diff(current_path, new_path)
        current_services = services_list(current_path)
        new_services     = services_list(new_path)

        changes = {}

        (current_services - new_services).each do |s|
          changes[s] = :deleted
        end

        (new_services - current_services).each do |s|
          changes[s] = :added
        end

        (current_services & new_services).each do |s|
          changes[s] = service_change?(current_path, new_path, s) ? :updated : :unchanged
        end

        changes
      end

    private

      def services_list(path)
        @backend.capture(:find, path, "-name '#{@service_pattern}'", "-printf \"%f\n\"").split("\n")
      end

      def service_change?(current_path, new_path, service)
        !@backend.test("diff -qI '^#' #{current_path}/#{service} #{new_path}/#{service}")
      end
    end
  end
end
