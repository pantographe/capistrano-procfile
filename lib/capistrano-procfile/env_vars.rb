module CapistranoProcfile
  class EnvVars < OpenStruct
    def initialize(env_vars)
      super()

      load_defaults!
      update(env_vars)
    end

    def update(new_env_vars)
      new_env_vars.each do |k, v|
        self[k] = v
      end
    end

    def merge(new_env_vars)
      env_vars = self.dup
      env_vars.dup.update(new_env_vars)
      env_vars
    end

    def apply_host(host)
      self.each_pair do |var, env|
        args      = [host]
        self[var] = env.call(*args.take(env.arity)) if env.respond_to?(:call)
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
