require "capistrano/procfile/procfile"

namespace :procfile do
  task :set_procfile do
    procfile = nil

    on primary(:app) do |host|
      procfile_path = "#{release_path}/#{fetch(:procfile_path)}"
      procfile = capture(:cat, procfile_path) if test("[[ -f #{procfile_path} ]]")
    end

    if procfile.nil?
      warn "#{fetch(:procfile_path)} not found"
    else
      procfile = Capistrano::Procfile::Procfile.new(procfile)
    end

    set(:procfile, procfile)
  end
end
