module CapistranoProcfile
  class Options < EnvVars

  private

    def load_defaults!
      update({
        app: "app",
      })
    end
  end
end
