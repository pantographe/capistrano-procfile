# Sidekiq with Capistrano::Procfile

```rb
# lib/capistrano/tasks/sidekiq.rake
require "capistrano/procfile/dsl"

namespace :sidekiq do
  task :quiet do
    on roles(:worker) do
      procfile_kill :tstp, :worker
    end
  end

  task :restart do
    on roles(:worker) do
      procfile_kill :term, :worker
      # OR
      # procfile_restart :worker
    end
  end
end

after "deploy:starting", "sidekiq:quiet"
after "deploy:reverted", "sidekiq:restart"
after "deploy:published", "sidekiq:restart"
```
