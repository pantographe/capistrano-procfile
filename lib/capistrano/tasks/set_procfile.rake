require "procfile"

namespace :procfile do
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
end
