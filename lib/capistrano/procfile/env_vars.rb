module Capistrano
  module Procfile
    class EnvVars < OpenStruct
      def initialize(env_vars)
        super()

        load_defaults!
        update(env_vars)
      end

      def update(new_env_vars)
        new_env_vars.to_h.each do |k, v|
          self[k] = v
        end
      end

      def merge(new_env_vars)
        env_vars = self.dup
        env_vars.dup.update(new_env_vars)
        env_vars
      end

      def apply_host(host)
        self.each_pair do |k, v|
          args    = [host]
          self[k] = v.call(*args.take(v.arity)) if v.respond_to?(:call)
        end
      end

      def cleanup!
        self.each_pair do |k, v|
          self.delete_field(k) if v.nil?
        end
      end

    private

      def load_defaults!
        update({
          port: 5000,
        })
      end
    end
  end
end
