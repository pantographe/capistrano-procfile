# Puma with Capistrano::Procfile

```rb
# lib/capistrano/tasks/puma.rake
require "capistrano/procfile/dsl"

namespace :puma do
  task :phased_restart do
    on roles([:web, :websocket]) do
      procfile_kill :usr1, :web
      procfile_kill :usr1, :websocket
    end
  end

  task :hot_restart do
    on roles([:web, :websocket]) do
      procfile_kill :usr2, :web
      procfile_kill :usr2, :websocket
    end
  end

  task :restart do
    on roles([:web, :websocket]) do
      procfile_restart :web
      procfile_restart :websocket
      # OR
      # procfile_kill :term, :web
      # procfile_kill :term, :websocket
    end
  end
end

after "deploy:published", "puma:phased_restart"
```

To have `phased_restart` works corretly you need to set the ENV var
`PWD`. Else puma will stay on the first path linked by `current/`.

```rb
set :procfile_service_env, fetch(:procfile_service_env, {}).merge({
  PWD: -> { current_path }
})
```
